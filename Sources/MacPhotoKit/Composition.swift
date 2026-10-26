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

/// Which of a photograph's two crops (PH13).
public enum CropKind: String, Sendable, CaseIterable {
    case print, screen
}

/// A corner of a crop, for resizing it.
public enum Corner: Sendable, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
    var isLeft: Bool { self == .topLeft || self == .bottomLeft }
    var isTop: Bool { self == .topLeft || self == .topRight }
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
    /// Brightness and contrast for the screen image only (PH57).
    public var screenTone: ScreenTone = .neutral

    /// The defaults for a photograph whose upright size is `width` ×
    /// `height` (PH26): landscape if wider than tall, otherwise portrait;
    /// both crops centred at zoom 1.
    public init(uprightWidth width: Int, height: Int) {
        quarterTurns = 0
        orientation = width > height ? .landscape : .portrait
        printCrop = .centred
        screenCrop = .centred
    }

    private enum CodingKeys: String, CodingKey {
        case quarterTurns, orientation, printCrop, screenCrop, screenTone
    }

    /// Reads manifests written before PH57, which have no screen tone.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        quarterTurns = try c.decode(Int.self, forKey: .quarterTurns)
        orientation = try c.decode(Orientation.self, forKey: .orientation)
        printCrop = try c.decode(Crop.self, forKey: .printCrop)
        screenCrop = try c.decode(Crop.self, forKey: .screenCrop)
        screenTone = try c.decodeIfPresent(ScreenTone.self, forKey: .screenTone) ?? .neutral
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

    // MARK: Editing (PH48): what the window does, as arithmetic it can't get wrong.

    public func crop(_ kind: CropKind) -> Crop { kind == .print ? printCrop : screenCrop }

    public func aspect(_ kind: CropKind) -> Double {
        kind == .print ? Self.printAspect(orientation) : Self.screenAspect
    }

    mutating func set(_ kind: CropKind, _ c: Crop, uprightWidth w: Int, height h: Int) {
        let t = turnedSize(uprightWidth: w, height: h)
        let clamped = Self.clamped(c, aspect: aspect(kind), in: t.width, t.height)
        if kind == .print { printCrop = clamped } else { screenCrop = clamped }
    }

    /// Moves a crop by fractions of the turned photograph's width and height,
    /// stopping at the edges.
    public mutating func move(_ kind: CropKind, dx: Double, dy: Double, uprightWidth w: Int, height h: Int) {
        let c = crop(kind)
        set(kind, Crop(centreX: c.centreX + dx, centreY: c.centreY + dy, zoom: c.zoom), uprightWidth: w, height: h)
    }

    /// Sets a crop's zoom about its centre, within 1–8, moving the centre
    /// only as far as needed to keep the crop inside.
    public mutating func setZoom(_ kind: CropKind, _ zoom: Double, uprightWidth w: Int, height h: Int) {
        var c = crop(kind)
        c.zoom = zoom
        set(kind, c, uprightWidth: w, height: h)
    }

    /// Resizes a crop by dragging one of its corners to `point` (fractions
    /// of the turned photograph), keeping its shape: the opposite corner
    /// stays where it is, and the crop follows whichever way the corner
    /// moved further. It stops at full size (zoom 1), at zoom 8 and at the
    /// photograph's edges.
    public mutating func resize(_ kind: CropKind, corner: Corner, to point: (x: Double, y: Double),
                                uprightWidth w: Int, height h: Int) {
        let t = turnedSize(uprightWidth: w, height: h)
        let W = Double(t.width), H = Double(t.height), a = aspect(kind)
        let f = fractions(kind, uprightWidth: w, height: h)
        // The opposite corner, in pixels, and which way the crop grows from it.
        let sx: Double = corner.isLeft ? -1 : 1, sy: Double = corner.isTop ? -1 : 1
        let ax = (corner.isLeft ? f.x + f.width : f.x) * W
        let ay = (corner.isTop ? f.y + f.height : f.y) * H
        let px = point.x * W, py = point.y * H
        let fit = Self.size(aspect: a, zoom: 1, in: t.width, t.height).width
        var width = max((px - ax) * sx, (py - ay) * sy * a)
        // Room from the anchor to the photograph's edge, both ways.
        let roomX = sx > 0 ? W - ax : ax, roomY = sy > 0 ? H - ay : ay
        width = min(width, fit, roomX, roomY * a)
        width = max(width, fit / Crop.maxZoom)
        let height = width / a
        let centre = Crop(centreX: (ax + sx * width / 2) / W, centreY: (ay + sy * height / 2) / H,
                          zoom: fit / width)
        set(kind, centre, uprightWidth: w, height: h)
    }

    /// Back to centred at zoom 1.
    public mutating func reset(_ kind: CropKind, uprightWidth w: Int, height h: Int) {
        set(kind, .centred, uprightWidth: w, height: h)
    }

    /// Clamps both stored crops after a turn or an orientation change.
    public mutating func clampCrops(uprightWidth w: Int, height h: Int) {
        set(.print, printCrop, uprightWidth: w, height: h)
        set(.screen, screenCrop, uprightWidth: w, height: h)
    }

    /// A crop as fractions of the turned photograph (x, y, width, height),
    /// before rounding to pixels: for drawing it.
    public func fractions(_ kind: CropKind, uprightWidth w: Int, height h: Int)
        -> (x: Double, y: Double, width: Double, height: Double) {
        let t = turnedSize(uprightWidth: w, height: h)
        let c = Self.clamped(crop(kind), aspect: aspect(kind), in: t.width, t.height)
        let s = Self.size(aspect: aspect(kind), zoom: c.zoom, in: t.width, t.height)
        let fw = s.width / Double(t.width), fh = s.height / Double(t.height)
        return (c.centreX - fw / 2, c.centreY - fh / 2, fw, fh)
    }

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
