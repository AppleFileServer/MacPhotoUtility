import CoreGraphics
import Foundation
import MacPhotoKit
import SwiftUI

/// The engine's images as pictures for the window. Drawing only: nothing
/// here touches what's exported.
enum Pictures {
    static let grey = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!

    static func cgImage(_ g: GreyImage) -> CGImage {
        make(g.pixels, g.width, g.height, bits: 8, rowBytes: g.width)
    }

    /// 1-bit, 1 = black, drawn through inverted bytes (QuickDraw's black is
    /// a 1; CoreGraphics' grey 0 is black).
    static func cgImage(_ b: BitImage) -> CGImage {
        make(b.bytes.map { ~$0 }, b.width, b.height, bits: 1, rowBytes: b.rowBytes)
    }

    private static func make(_ bytes: [UInt8], _ w: Int, _ h: Int, bits: Int, rowBytes: Int) -> CGImage {
        CGImage(width: w, height: h, bitsPerComponent: bits, bitsPerPixel: bits, bytesPerRow: rowBytes,
                space: grey, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: CGDataProvider(data: Data(bytes) as CFData)!, decode: nil,
                shouldInterpolate: false, intent: .defaultIntent)!
    }
}
