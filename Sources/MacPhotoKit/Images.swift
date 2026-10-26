/// The engine's two in-memory images (PH20). Neither is a file format:
/// the Phase 2 writers turn them into PICT and MacPaint.

/// An 8-bit greyscale image: one byte per pixel, rows top to bottom with no
/// padding, **0 black … 255 white**, gamma-encoded (Gray Gamma 2.2, PH9).
public struct GreyImage: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        precondition(width > 0 && height > 0 && pixels.count == width * height)
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    /// A flat image of one grey.
    public init(width: Int, height: Int, grey: UInt8) {
        self.init(width: width, height: height,
                  pixels: [UInt8](repeating: grey, count: width * height))
    }

    public subscript(x: Int, y: Int) -> UInt8 {
        get { pixels[y * width + x] }
        set { pixels[y * width + x] = newValue }
    }
}

/// A 1-bit image as QuickDraw holds one: rows top to bottom, each padded to
/// an even number of bytes, the leftmost pixel in the top bit, **1 = black**.
/// The screen image is 512 × 342 with 64 bytes a row.
public struct BitImage: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public let rowBytes: Int
    public var bytes: [UInt8]

    public init(width: Int, height: Int) {
        precondition(width > 0 && height > 0)
        self.width = width
        self.height = height
        rowBytes = (width + 15) / 16 * 2
        bytes = [UInt8](repeating: 0, count: rowBytes * height)
    }

    public subscript(x: Int, y: Int) -> Bool {
        get { bytes[y * rowBytes + x / 8] & (0x80 >> UInt8(x % 8)) != 0 }
        set {
            let i = y * rowBytes + x / 8, bit: UInt8 = 0x80 >> UInt8(x % 8)
            if newValue { bytes[i] |= bit } else { bytes[i] &= ~bit }
        }
    }

    /// How many pixels are black.
    public var blackCount: Int {
        var n = 0
        for y in 0..<height {
            for x in 0..<width where self[x, y] { n += 1 }
        }
        return n
    }
}
