import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// The synthetic test images (TESTING.md §2, PH31), drawn pixel by pixel
/// so every one is exactly reproducible and no one's photographs go into
/// the repository.
public enum TestImages {
    public struct Spec: Sendable {
        public let name: String
        public let purpose: String
    }

    public static let all: [Spec] = [
        Spec(name: "landscape-4x3.jpg", purpose: "landscape; crop to 7:5"),
        Spec(name: "portrait-3x4.jpg", purpose: "portrait; crop to 5:7"),
        Spec(name: "square.png", purpose: "both orientations crop"),
        Spec(name: "panorama.jpg", purpose: "extreme aspect"),
    ] + (1...8).map { Spec(name: "exif-\($0).jpg", purpose: "EXIF orientation \($0)") } + [
        Spec(name: "colour.heic", purpose: "HEIC; colour to grey"),
        Spec(name: "grey-16bit.tiff", purpose: "TIFF; 16-bit grey source"),
        Spec(name: "ramp.png", purpose: "a grey ramp: tone and dithering"),
        Spec(name: "small.jpg", purpose: "smaller than the output (PH14)"),
        Spec(name: "transparent.png", purpose: "transparency flattened onto white"),
        Spec(name: "unsupported.gif", purpose: "a kind ImageIO reads but we refuse"),
        Spec(name: "bad-truncated.jpg", purpose: "a JPEG cut short"),
        Spec(name: "bad-empty.png", purpose: "an empty file"),
        Spec(name: "bad-text.jpg", purpose: "text with a picture's extension"),
    ]

    /// Writes every test image into `folder` (which must exist).
    @discardableResult
    public static func writeAll(to folder: URL) throws -> [URL] {
        try all.map { try write($0.name, to: folder) }
    }

    /// Writes one test image, by name, into `folder`.
    @discardableResult
    public static func write(_ name: String, to folder: URL) throws -> URL {
        let url = folder.appendingPathComponent(name)
        switch name {
        case "landscape-4x3.jpg": try save(grey(pattern(4000, 3000), 4000, 3000), url, .jpeg)
        case "portrait-3x4.jpg": try save(grey(pattern(3000, 4000), 3000, 4000), url, .jpeg)
        case "square.png": try save(grey(pattern(3000, 3000), 3000, 3000), url, .png)
        case "panorama.jpg": try save(grey(pattern(6000, 2000), 6000, 2000), url, .jpeg)
        case "colour.heic": try save(colourImage(), url, .heic)
        case "grey-16bit.tiff": try save(grey16Ramp(2000, 1500), url, .tiff)
        case "ramp.png": try save(grey(ramp(1050, 750), 1050, 750), url, .png)
        case "small.jpg": try save(grey(pattern(640, 480), 640, 480), url, .jpeg)
        case "transparent.png": try save(halfTransparent(), url, .png)
        case "unsupported.gif": try save(grey(pattern(200, 150), 200, 150), url, .gif)
        case "bad-truncated.jpg":
            let whole = folder.appendingPathComponent(".whole.jpg")
            try save(grey(pattern(1200, 900), 1200, 900), whole, .jpeg)
            let data = try Data(contentsOf: whole)
            try data.prefix(data.count * 4 / 10).write(to: url)
            try FileManager.default.removeItem(at: whole)
        case "bad-empty.png": try Data().write(to: url)
        case "bad-text.jpg": try Data("This is not a picture.\n".utf8).write(to: url)
        default:
            guard name.hasPrefix("exif-"), let n = Int(name.dropFirst(5).prefix(1)), (1...8).contains(n)
            else { throw CocoaError(.fileNoSuchFile) }
            let s = exifStored(n)
            try save(grey(s.pixels, s.width, s.height), url, .jpeg, orientation: n)
        }
        return url
    }

    // MARK: Pictures

    /// The test pattern, as grey bytes (0 black … 255 white): white, a
    /// black grid dividing the picture into eighths each way, a black
    /// square at the centre, and an "F" in the top-left cell, so crops,
    /// turns and mirrors all show.
    public static func pattern(_ w: Int, _ h: Int) -> [UInt8] {
        var p = [UInt8](repeating: 255, count: w * h)
        func fill(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int) {
            for y in max(y0, 0)..<min(y1, h) {
                for x in max(x0, 0)..<min(x1, w) { p[y * w + x] = 0 }
            }
        }
        let t = max(2, min(w, h) / 300)
        for k in 1..<8 {
            fill(k * w / 8 - t / 2, 0, k * w / 8 - t / 2 + t, h)
            fill(0, k * h / 8 - t / 2, w, k * h / 8 - t / 2 + t)
        }
        let c = min(w, h) / 20
        fill(w / 2 - c, h / 2 - c, w / 2 + c, h / 2 + c)
        drawF(w, h, fill: fill)
        return p
    }

    /// Where the "F" sits: inside the top-left cell (x and y from 1/32 to
    /// 3/32 of the picture), a stem with a full and a shorter bar.
    public static func fRect(_ w: Int, _ h: Int) -> (x0: Int, y0: Int, x1: Int, y1: Int) {
        (w / 32, h / 32, w * 3 / 32, h * 3 / 32)
    }

    static func drawF(_ w: Int, _ h: Int, fill: (Int, Int, Int, Int) -> Void) {
        let f = fRect(w, h)
        let fw = f.x1 - f.x0, fh = f.y1 - f.y0, s = max(1, fw / 5)
        fill(f.x0, f.y0, f.x0 + s, f.y1)                         // stem
        fill(f.x0, f.y0, f.x1, f.y0 + s)                         // top bar
        fill(f.x0, f.y0 + fh / 2 - s / 2, f.x0 + fw * 2 / 3, f.y0 + fh / 2 - s / 2 + s)  // middle bar
    }

    /// Black on the left to white on the right.
    public static func ramp(_ w: Int, _ h: Int) -> [UInt8] {
        var p = [UInt8](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w { p[y * w + x] = UInt8((x * 255 + (w - 1) / 2) / (w - 1)) }
        }
        return p
    }

    /// The upright picture every exif-N.jpg shows when its orientation is
    /// applied: 600 × 400 in four flat quarters, top-left 0, top-right 85,
    /// bottom-left 170, bottom-right 255.
    public static let exifUpright = (width: 600, height: 400)
    public static func exifUprightGrey(x: Int, y: Int) -> UInt8 {
        let (w, h) = exifUpright
        return [[0, 85], [170, 255]][y < h / 2 ? 0 : 1][x < w / 2 ? 0 : 1]
    }

    /// The pixels as stored for EXIF orientation `n`, worked out from the
    /// upright picture by the EXIF definitions (TIFF 6.0 / EXIF 2.3),
    /// independently of the importer: displayed (x, y) = stored (sx, sy).
    static func exifStored(_ n: Int) -> (pixels: [UInt8], width: Int, height: Int) {
        let (w, h) = exifUpright
        let transposed = n >= 5
        let sw = transposed ? h : w, sh = transposed ? w : h
        var s = [UInt8](repeating: 0, count: sw * sh)
        for y in 0..<h {
            for x in 0..<w {
                let (sx, sy): (Int, Int)
                switch n {
                case 1: (sx, sy) = (x, y)
                case 2: (sx, sy) = (w - 1 - x, y)                // mirrored left-right
                case 3: (sx, sy) = (w - 1 - x, h - 1 - y)        // turned 180°
                case 4: (sx, sy) = (x, h - 1 - y)                // mirrored top-bottom
                case 5: (sx, sy) = (y, x)                        // transposed
                case 6: (sx, sy) = (y, w - 1 - x)                // shown turned 90° clockwise
                case 7: (sx, sy) = (h - 1 - y, w - 1 - x)        // transversed
                default: (sx, sy) = (h - 1 - y, x)               // 8: shown turned 90° anticlockwise
                }
                s[sy * sw + sx] = exifUprightGrey(x: x, y: y)
            }
        }
        return (s, sw, sh)
    }

    /// 4032 × 3024 colour: the pattern in grey, with four blocks across
    /// the lower part: pure red, green and blue, and a neutral grey 128.
    static func colourImage() -> CGImage {
        let w = 4032, h = 3024
        let g = pattern(w, h)
        var rgb = [UInt8](repeating: 0, count: w * h * 3)
        for i in 0..<(w * h) { rgb[i * 3] = g[i]; rgb[i * 3 + 1] = g[i]; rgb[i * 3 + 2] = g[i] }
        for (k, colour) in colourBlocks.enumerated() {
            let b = colourBlock(k, w, h)
            for y in b.y0..<b.y1 {
                for x in b.x0..<b.x1 {
                    let i = (y * w + x) * 3
                    rgb[i] = colour.0; rgb[i + 1] = colour.1; rgb[i + 2] = colour.2
                }
            }
        }
        return image(rgb, w, h, bitsPerComponent: 8, components: 3,
                     space: CGColorSpace(name: CGColorSpace.sRGB)!, alpha: .none)
    }

    public static let colourBlocks: [(UInt8, UInt8, UInt8)] = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (128, 128, 128)]

    /// Block k of colour.heic, in its 4032 × 3024 pixels.
    public static func colourBlock(_ k: Int, _ w: Int = 4032, _ h: Int = 3024)
        -> (x0: Int, y0: Int, x1: Int, y1: Int) {
        (w * (2 * k + 1) / 9, h * 5 / 8 + h / 32, w * (2 * k + 2) / 9, h * 7 / 8 - h / 32)
    }

    /// 400 × 300: the left half fully transparent, the right half opaque black.
    static func halfTransparent() -> CGImage {
        let w = 400, h = 300
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in w / 2..<w { rgba[(y * w + x) * 4 + 3] = 255 }
        }
        return image(rgba, w, h, bitsPerComponent: 8, components: 4,
                     space: CGColorSpace(name: CGColorSpace.sRGB)!, alpha: .premultipliedLast)
    }

    /// 16-bit grey, black on the left to white on the right.
    static func grey16Ramp(_ w: Int, _ h: Int) -> CGImage {
        var p = [UInt8](repeating: 0, count: w * h * 2)
        for y in 0..<h {
            for x in 0..<w {
                let v = UInt16(x * 65535 / (w - 1))
                p[(y * w + x) * 2] = UInt8(v >> 8)          // big-endian
                p[(y * w + x) * 2 + 1] = UInt8(v & 0xFF)
            }
        }
        return image(p, w, h, bitsPerComponent: 16, components: 1,
                     space: CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!, alpha: .none,
                     order: .order16Big)
    }

    // MARK: Writing

    static func grey(_ p: [UInt8], _ w: Int, _ h: Int) -> CGImage {
        image(p, w, h, bitsPerComponent: 8, components: 1,
              space: CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!, alpha: .none)
    }

    static func image(_ bytes: [UInt8], _ w: Int, _ h: Int, bitsPerComponent: Int, components: Int,
                      space: CGColorSpace, alpha: CGImageAlphaInfo,
                      order: CGImageByteOrderInfo = .orderDefault) -> CGImage {
        let bytesPerPixel = bitsPerComponent / 8 * components
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(width: w, height: h, bitsPerComponent: bitsPerComponent,
                       bitsPerPixel: bytesPerPixel * 8, bytesPerRow: w * bytesPerPixel,
                       space: space,
                       bitmapInfo: CGBitmapInfo(rawValue: alpha.rawValue | order.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false,
                       intent: .defaultIntent)!
    }

    static func save(_ image: CGImage, _ url: URL, _ type: UTType, orientation: Int = 1) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil)
        else { throw CocoaError(.fileWriteUnknown) }
        var props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.95]
        if orientation != 1 { props[kCGImagePropertyOrientation] = orientation }
        CGImageDestinationAddImage(dest, image, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
    }
}
