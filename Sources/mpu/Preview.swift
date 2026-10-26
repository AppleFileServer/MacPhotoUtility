import CoreGraphics
import CoreText
import Foundation
import ImageIO
import MacPhotoKit
import UniformTypeIdentifiers

// PNG previews for looking at the engine's results (Phase 1). Diagnostics
// only: the real outputs are the Phase 2 PICT and MacPaint files.

enum Preview {
    static let grey = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!

    static func cgImage(_ g: GreyImage) -> CGImage {
        cgImage(bytes: g.pixels, g.width, g.height, bits: 8, rowBytes: g.width)
    }

    /// 1-bit, as stored (1 = black), shown through an inverted decode.
    static func cgImage(_ b: BitImage) -> CGImage {
        cgImage(bytes: b.bytes.map { ~$0 }, b.width, b.height, bits: 1, rowBytes: b.rowBytes)
    }

    static func cgImage(bytes: [UInt8], _ w: Int, _ h: Int, bits: Int, rowBytes: Int) -> CGImage {
        CGImage(width: w, height: h, bitsPerComponent: bits, bitsPerPixel: bits, bytesPerRow: rowBytes,
                space: grey, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: CGDataProvider(data: Data(bytes) as CFData)!, decode: nil,
                shouldInterpolate: false, intent: .defaultIntent)!
    }

    static func writePNG(_ image: CGImage, to url: URL, ppi: Int? = nil) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw CocoaError(.fileWriteUnknown) }
        var props: [CFString: Any] = [:]
        if let ppi { props = [kCGImagePropertyDPIWidth: ppi, kCGImagePropertyDPIHeight: ppi] }
        CGImageDestinationAddImage(dest, image, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
    }

    /// Several 512 × 342 panels on one sheet, `columns` across, each drawn at 2×
    /// with square pixels and labelled underneath.
    static func sheet(_ panels: [(label: String, image: CGImage)], columns cols: Int = 2) -> CGImage {
        let pw = 1024, ph = 684, labelH = 44, gap = 24
        let rows = (panels.count + cols - 1) / cols
        let w = cols * pw + (cols + 1) * gap, h = rows * (ph + labelH) + (rows + 1) * gap
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: grey, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        ctx.setFillColor(gray: 0.85, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.interpolationQuality = .none
        let font = CTFontCreateWithName("Helvetica" as CFString, 26, nil)
        for (i, panel) in panels.enumerated() {
            let x = gap + (i % cols) * (pw + gap)
            let top = gap + (i / cols) * (ph + labelH + gap)            // from the top
            let y = h - top - ph                                         // CoreGraphics counts from the bottom
            ctx.draw(panel.image, in: CGRect(x: x, y: y, width: pw, height: ph))
            let text = NSAttributedString(string: "\(i + 1). \(panel.label)",
                                          attributes: [kCTFontAttributeName as NSAttributedString.Key: font])
            ctx.textPosition = CGPoint(x: x + 4, y: y - 32)
            CTLineDraw(CTLineCreateWithAttributedString(text), ctx)
        }
        return ctx.makeImage()!
    }
}
