/// How one photograph is framed (PH24–PH27). Nothing here depends on the
/// window or the PPI: switching between 300 and 360 PPI renders the same
/// crop at a different size (specification §5).
///
/// Coordinates refer to the **turned image**: the upright photograph (EXIF
/// orientation applied) turned clockwise by `quarterTurns`.

/// One crop: its centre as fractions of the turned image's width and
/// height, and a zoom, where 1 is the largest crop of its shape that fits.
public struct Crop: Sendable, Equatable, Hashable, Codable {
    public var centreX: Double
    public var centreY: Double
    public var zoom: Double

    public init(centreX: Double = 0.5, centreY: Double = 0.5, zoom: Double = 1) {
        self.centreX = centreX
        self.centreY = centreY
        self.zoom = zoom
    }

    public static let centred = Crop()
    public static let maxZoom = 8.0
}

/// A rectangle of whole pixels.
public struct PixelRect: Sendable, Equatable, Hashable, CustomStringConvertible {
    public var x, y, width, height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }

    public var description: String { "\(width) × \(height) at (\(x), \(y))" }

    /// The same pixels in the image before `quarters` clockwise quarter
    /// turns, given the turned image's size.
    public func unturned(_ quarters: Int, turnedWidth w: Int, turnedHeight h: Int) -> PixelRect {
        switch ((quarters % 4) + 4) % 4 {
        case 1: PixelRect(x: y, y: w - x - width, width: height, height: width)
        case 2: PixelRect(x: w - x - width, y: h - y - height, width: width, height: height)
        case 3: PixelRect(x: h - y - height, y: x, width: height, height: width)
        default: self
        }
    }
}

public struct Composition: Sendable, Equatable, Hashable, Codable {
    /// Clockwise quarter turns, 0–3, applied to the upright photograph.
    public private(set) var quarterTurns: Int
    public private(set) var orientation: Orientation
    public var printCrop: Crop
    public var screenCrop: Crop

    /// The defaults for a photograph whose upright size is `width` ×
    /// `height` (PH26): landscape if wider than tall, otherwise portrait;
    /// both crops centred at zoom 1.
    public init(uprightWidth width: Int, height: Int) {
        quarterTurns = 0
        orientation = width > height ? .landscape : .portrait
        printCrop = .centred
        screenCrop = .centred
    }

    /// The print's shape, width over height: 5:7 or 7:5, from the profile's
    /// own sides so it can't disagree with the output.
    public static func printAspect(_ o: Orientation) -> Double {
        let h = PrintProfile(orientation: o).hundredths
        return Double(h.width) / Double(h.height)
    }

    public static let screenAspect = Double(ScreenImage.width) / Double(ScreenImage.height)

    /// The turned image's size.
    public func turnedSize(uprightWidth w: Int, height h: Int) -> (width: Int, height: Int) {
        quarterTurns % 2 == 0 ? (w, h) : (h, w)
    }

    /// Turns the photograph clockwise. Each crop's centre turns with it and
    /// keeps its zoom; an odd number of turns also swaps the print between
    /// portrait and landscape, so the framing stays the same shape on the
    /// picture.
    public mutating func turn(by quarters: Int = 1) {
        let q = ((quarters % 4) + 4) % 4
        for _ in 0..<q {
            quarterTurns = (quarterTurns + 1) % 4
            for keyPath in [\Composition.printCrop, \Composition.screenCrop] {
                let c = self[keyPath: keyPath]
                self[keyPath: keyPath] = Crop(centreX: 1 - c.centreY, centreY: c.centreX, zoom: c.zoom)
            }
            orientation = orientation == .portrait ? .landscape : .portrait
        }
    }

    public mutating func setOrientation(_ o: Orientation) { orientation = o }

    /// The print crop, in whole pixels of the turned image (PH25, PH27).
    public func printRect(uprightWidth w: Int, height h: Int) -> PixelRect {
        let t = turnedSize(uprightWidth: w, height: h)
        return Self.rect(printCrop, aspect: Self.printAspect(orientation), in: t.width, t.height)
    }

    /// The screen crop, in whole pixels of the turned image.
    public func screenRect(uprightWidth w: Int, height h: Int) -> PixelRect {
        let t = turnedSize(uprightWidth: w, height: h)
        return Self.rect(screenCrop, aspect: Self.screenAspect, in: t.width, t.height)
    }

    /// The crop limited to what's allowed (PH25): zoom 1 to 8, centre so
    /// the whole crop lies inside the image.
    public static func clamped(_ c: Crop, aspect: Double, in w: Int, _ h: Int) -> Crop {
        let zoom = min(max(c.zoom.isFinite ? c.zoom : 1, 1), Crop.maxZoom)
        let s = size(aspect: aspect, zoom: zoom, in: w, h)
        func centre(_ v: Double, _ half: Double) -> Double {
            let v = v.isFinite ? v : 0.5
            return min(max(v, half), 1 - half)
        }
        return Crop(centreX: centre(c.centreX, s.width / 2 / Double(w)),
                    centreY: centre(c.centreY, s.height / 2 / Double(h)), zoom: zoom)
    }

    /// The crop's size in pixels, before rounding.
    static func size(aspect: Double, zoom: Double, in w: Int, _ h: Int) -> (width: Double, height: Double) {
        let W = Double(w), H = Double(h)
        let fit = W / H > aspect ? (width: H * aspect, height: H) : (width: W, height: W / aspect)
        return (fit.width / zoom, fit.height / zoom)
    }

    static func rect(_ crop: Crop, aspect: Double, in w: Int, _ h: Int) -> PixelRect {
        let c = clamped(crop, aspect: aspect, in: w, h)
        let s = size(aspect: aspect, zoom: c.zoom, in: w, h)
        // Each edge to the nearest whole pixel, inside the image.
        let x0 = (c.centreX * Double(w) - s.width / 2).rounded()
        let y0 = (c.centreY * Double(h) - s.height / 2).rounded()
        let x1 = (c.centreX * Double(w) + s.width / 2).rounded()
        let y1 = (c.centreY * Double(h) + s.height / 2).rounded()
        let left = min(max(Int(x0), 0), w - 1), top = min(max(Int(y0), 0), h - 1)
        let right = min(max(Int(x1), left + 1), w), bottom = min(max(Int(y1), top + 1), h)
        return PixelRect(x: left, y: top, width: right - left, height: bottom - top)
    }
}

extension GreyImage {
    /// The pixels inside `r`, copied.
    public func cropped(_ r: PixelRect) -> GreyImage {
        precondition(r.x >= 0 && r.y >= 0 && r.width > 0 && r.height > 0
                     && r.x + r.width <= width && r.y + r.height <= height)
        var out = [UInt8]()
        out.reserveCapacity(r.width * r.height)
        for y in r.y..<(r.y + r.height) {
            out.append(contentsOf: pixels[(y * width + r.x)..<(y * width + r.x + r.width)])
        }
        return GreyImage(width: r.width, height: r.height, pixels: out)
    }
}
