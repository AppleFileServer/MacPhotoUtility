/// The print image as an 8-bit greyscale version 2 PICT (FILE_FORMATS.md
/// §1; PH16), with MacPhoto's record in a LongComment.

/// MacPhoto's record (FILE_FORMATS.md §1): what the print is.
public struct PrintRecord: Sendable, Equatable {
    public let profile: PrintProfile
    public let pixelChecksum: UInt32
}

public enum PrintPICTWriter {
    public static func write(_ image: GreyImage, profile: PrintProfile) -> [UInt8] {
        let size = profile.pixels
        precondition(image.width == size.width && image.height == size.height)
        let w = image.width, h = image.height, ppi = profile.resolution.ppi
        let fixedPPI = UInt32(ppi) << 16

        // Stored values: 0 white … 255 black (the colour table below).
        let stored = image.pixels.map { 255 - $0 }

        var pic = ByteWriter()
        pic.u16(0)                                      // picSize, filled in below
        pic.rect(0, 0, h, w)                            // picFrame
        pic.u16(0x0011); pic.u16(0x02FF)                // version 2
        pic.u16(0x0C00)                                 // extended HeaderOp
        pic.i16(-2); pic.u16(0)
        pic.u32(fixedPPI); pic.u32(fixedPPI)
        pic.rect(0, 0, h, w); pic.u32(0)
        pic.u16(0x0001); pic.u16(10); pic.rect(0, 0, h, w)       // Clip
        pic.u16(0x00A1); pic.u16(100); pic.u16(20)               // LongComment, MacPhoto's record
        pic.append(Array("MPho".utf8))
        pic.u16(1)                                      // recordVersion
        pic.u16(ppi)
        pic.u16(profile.hundredths.width); pic.u16(profile.hundredths.height)
        pic.u16(profile.orientation == .portrait ? 0 : 1)
        pic.u16(1)                                      // checksumType: CRC-32
        pic.u32(CRC32.of(stored))

        pic.u16(0x0098)                                 // PackBitsRect
        pic.u16(0x8000 | w)                             // rowBytes, PixMap
        pic.rect(0, 0, h, w)                            // bounds
        pic.u16(0); pic.u16(0); pic.u32(0)              // pmVersion, packType, packSize
        pic.u32(fixedPPI); pic.u32(fixedPPI)
        pic.u16(0); pic.u16(8); pic.u16(1); pic.u16(8)  // pixelType, pixelSize, cmpCount, cmpSize
        pic.u32(0); pic.u32(0); pic.u32(0)              // planeBytes, pmTable, pmReserved
        pic.u32(0); pic.u16(0); pic.u16(255)            // ctSeed, ctFlags, ctSize
        for i in 0..<256 {
            let c = (255 - i) * 257
            pic.u16(i); pic.u16(c); pic.u16(c); pic.u16(c)
        }
        pic.rect(0, 0, h, w); pic.rect(0, 0, h, w)      // srcRect, dstRect
        pic.u16(0)                                      // srcCopy
        for y in 0..<h {
            let packed = PackBits.pack(stored[(y * w)..<(y * w + w)])
            pic.u16(packed.count)                       // rowBytes > 250: two bytes
            pic.append(packed)
        }
        if pic.count % 2 == 1 { pic.u8(0) }             // the next opcode on an even offset
        pic.u16(0x00FF)                                 // OpEndPic

        var bytes = pic.bytes
        bytes[0] = UInt8(bytes.count >> 8 & 0xFF)       // the length modulo 65,536
        bytes[1] = UInt8(bytes.count & 0xFF)
        return [UInt8](repeating: 0, count: 512) + bytes
    }
}

public enum PrintPICTValidator {
    /// Checks every rule of FILE_FORMATS.md §1 and returns the picture (in
    /// grey, 0 black … 255 white) and MacPhoto's record.
    public static func validate(_ file: [UInt8]) throws -> (image: GreyImage, record: PrintRecord) {
        var r = ByteReader(file)
        try r.expectZeros(512, "the 512-byte file header")
        let picSize = try r.u16("picSize")
        guard picSize == (file.count - 512) & 0xFFFF else {
            throw FormatError("picSize is \(picSize), not the picture's length modulo 65,536")
        }
        let frame = try r.rect("picFrame")
        guard frame[0] == 0, frame[1] == 0 else { throw FormatError("picFrame doesn't start at 0, 0") }
        let h = frame[2], w = frame[3]
        guard let profile = PrintProfile.matching(width: w, height: h) else {
            throw FormatError("\(w) × \(h) isn't one of the four print sizes")
        }
        let ppi = profile.resolution.ppi, fixedPPI = UInt32(ppi) << 16
        try r.expect16(0x0011, "the VersionOp")
        try r.expect16(0x02FF, "the version")
        try r.expect16(0x0C00, "the HeaderOp")
        try r.expect16(0xFFFE, "the header version")
        try r.expect16(0, "the header's reserved word")
        try r.expect32(fixedPPI, "the header's hRes")
        try r.expect32(fixedPPI, "the header's vRes")
        try r.expectRect(frame, "the header's srcRect")
        try r.expect32(0, "the header's reserved long")
        try r.expect16(0x0001, "the Clip opcode")
        try r.expect16(10, "the clip region's size")
        try r.expectRect(frame, "the clip region")

        try r.expect16(0x00A1, "the LongComment opcode")
        try r.expect16(100, "the comment's kind")
        try r.expect16(20, "the comment's size")
        guard Array(try r.take(4, "the record's signature")) == Array("MPho".utf8) else {
            throw FormatError("the comment isn't MacPhoto's record")
        }
        try r.expect16(1, "the record's version")
        try r.expect16(ppi, "the record's ppi")
        try r.expect16(profile.hundredths.width, "the record's printWidth")
        try r.expect16(profile.hundredths.height, "the record's printHeight")
        try r.expect16(profile.orientation == .portrait ? 0 : 1, "the record's orientation")
        try r.expect16(1, "the record's checksumType")
        let checksum = try r.u32("the record's pixelChecksum")

        try r.expect16(0x0098, "the PackBitsRect opcode")
        try r.expect16(0x8000 | w, "rowBytes")
        try r.expectRect(frame, "the PixMap's bounds")
        try r.expect16(0, "pmVersion"); try r.expect16(0, "packType"); try r.expect32(0, "packSize")
        try r.expect32(fixedPPI, "the PixMap's hRes"); try r.expect32(fixedPPI, "the PixMap's vRes")
        try r.expect16(0, "pixelType"); try r.expect16(8, "pixelSize")
        try r.expect16(1, "cmpCount"); try r.expect16(8, "cmpSize")
        try r.expect32(0, "planeBytes"); try r.expect32(0, "pmTable"); try r.expect32(0, "pmReserved")
        try r.expect32(0, "ctSeed"); try r.expect16(0, "ctFlags"); try r.expect16(255, "ctSize")
        for i in 0..<256 {
            let c = (255 - i) * 257
            try r.expect16(i, "colour \(i)'s value")
            for part in ["red", "green", "blue"] { try r.expect16(c, "colour \(i)'s \(part)") }
        }
        try r.expectRect(frame, "srcRect")
        try r.expectRect(frame, "dstRect")
        try r.expect16(0, "the transfer mode")

        var crc = CRC32()
        var grey = [UInt8]()
        grey.reserveCapacity(w * h)
        for y in 0..<h {
            let count = try r.u16("row \(y)'s length")
            let row = try PackBits.unpack(try r.take(count, "row \(y)"), length: w, row: y)
            crc.update(row)
            grey += row.map { 255 - $0 }
        }
        guard crc.value == checksum else {
            throw FormatError(String(format: "the pixels' CRC-32 is %08X, but the record says %08X", crc.value, checksum))
        }
        if (r.offset - 512) % 2 == 1 { try r.expectZeros(1, "the padding byte") }
        try r.expect16(0x00FF, "OpEndPic")
        guard r.remaining == 0 else { throw FormatError("\(r.remaining) bytes follow OpEndPic") }
        return (GreyImage(width: w, height: h, pixels: grey), PrintRecord(profile: profile, pixelChecksum: checksum))
    }
}

extension PrintProfile {
    /// The one profile with exactly this pixel size, if any.
    public static func matching(width: Int, height: Int) -> PrintProfile? {
        for r in PrintResolution.allCases {
            for o in Orientation.allCases {
                let p = PrintProfile(orientation: o, resolution: r)
                if p.pixels == (width, height) { return p }
            }
        }
        return nil
    }
}
