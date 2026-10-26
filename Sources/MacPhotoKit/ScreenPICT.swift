/// The screen image as a 1-bit version 1 PICT (FILE_FORMATS.md §2; PH5).
/// The writer and the validator are written separately from the document
/// (PH35, PH36); they share only PackBits and the byte helpers.

public enum ScreenPICTWriter {
    public static func write(_ image: BitImage) -> [UInt8] {
        precondition(image.width == ScreenImage.width && image.height == ScreenImage.height)
        let h = ScreenImage.height, w = ScreenImage.width
        var pic = ByteWriter()
        pic.u16(0)                                   // picSize, filled in below
        pic.rect(0, 0, h, w)                         // picFrame
        pic.append([0x11, 0x01])                     // version 1
        pic.u8(0x01); pic.u16(10); pic.rect(0, 0, h, w)       // clipRgn
        pic.u8(0x98)                                 // PackBitsRect
        pic.u16(ScreenImage.rowBytes)
        pic.rect(0, 0, h, w)                         // bounds
        pic.rect(0, 0, h, w)                         // srcRect
        pic.rect(0, 0, h, w)                         // dstRect
        pic.u16(0)                                   // srcCopy
        for y in 0..<h {
            let start = y * image.rowBytes
            let packed = PackBits.pack(image.bytes[start..<(start + ScreenImage.rowBytes)])
            pic.u8(UInt8(packed.count))              // ≤ 65 for 64 bytes: one byte
            pic.append(packed)
        }
        pic.u8(0xFF)                                 // end of picture
        var bytes = pic.bytes
        bytes[0] = UInt8(bytes.count >> 8)
        bytes[1] = UInt8(bytes.count & 0xFF)
        return [UInt8](repeating: 0, count: 512) + bytes
    }
}

public enum ScreenPICTValidator {
    /// Checks every rule of FILE_FORMATS.md §2 and returns the picture.
    public static func validate(_ file: [UInt8]) throws -> BitImage {
        var r = ByteReader(file)
        try r.expectZeros(512, "the 512-byte file header")
        let pictureLength = file.count - 512
        let picSize = try r.u16("picSize")
        guard picSize == pictureLength else {
            throw FormatError("picSize is \(picSize) but the picture is \(pictureLength) bytes")
        }
        let frame = [0, 0, 342, 512]
        try r.expectRect(frame, "picFrame")
        try r.expect16(0x1101, "the version opcode")
        guard try r.u8("the clip opcode") == 0x01 else { throw FormatError("the clipRgn opcode is missing") }
        try r.expect16(10, "the clip region's size")
        try r.expectRect(frame, "the clip region")
        guard try r.u8("the PackBitsRect opcode") == 0x98 else { throw FormatError("PackBitsRect (98) is missing") }
        try r.expect16(64, "rowBytes")
        try r.expectRect(frame, "the bitmap's bounds")
        try r.expectRect(frame, "srcRect")
        try r.expectRect(frame, "dstRect")
        try r.expect16(0, "the transfer mode")

        var image = BitImage(width: 512, height: 342)
        for y in 0..<342 {
            let count = try r.u8("row \(y)'s length")
            let row = try PackBits.unpack(try r.take(count, "row \(y)"), length: 64, row: y)
            image.bytes.replaceSubrange((y * 64)..<(y * 64 + 64), with: row)
        }
        guard try r.u8("the end opcode") == 0xFF else { throw FormatError("the picture doesn't end with FF") }
        guard r.remaining == 0 else { throw FormatError("\(r.remaining) bytes follow the end of the picture") }
        return image
    }
}
