/// The screen image as a MacPaint document (FILE_FORMATS.md §3; PH4,
/// PH12), centred on the 576 × 720 page.

public enum MacPaintWriter {
    public static func write(_ image: BitImage) -> [UInt8] {
        precondition(image.width == ScreenImage.width && image.height == ScreenImage.height)
        var file = ByteWriter()
        file.u32(0)                                   // version 0: keep the user's patterns
        file.zeros(304 + 204)                         // patterns, unused
        let origin = MacPaintPage.screenOrigin
        let byteX = origin.x / 8                      // 4
        for y in 0..<MacPaintPage.height {
            var row = [UInt8](repeating: 0, count: MacPaintPage.rowBytes)
            let sy = y - origin.y
            if (0..<ScreenImage.height).contains(sy) {
                let start = sy * image.rowBytes
                row.replaceSubrange(byteX..<(byteX + ScreenImage.rowBytes),
                                    with: image.bytes[start..<(start + ScreenImage.rowBytes)])
            }
            file.append(PackBits.pack(row))
        }
        let padding = (512 - file.count % 512) % 512    // as MacPaint saves (MacPaint.p 1489)
        file.zeros(padding)
        return file.bytes
    }
}

public enum MacPaintValidator {
    /// Checks every rule of FILE_FORMATS.md §3 and returns the screen image
    /// from its centred place on the page.
    public static func validate(_ file: [UInt8]) throws -> BitImage {
        var r = ByteReader(file)
        try r.expect32(0, "the version")
        try r.expectZeros(304, "the patterns")
        try r.expectZeros(204, "the unused header")

        // Rows unpack one at a time; a row's packed length isn't stored, so
        // read count bytes until the row is complete, as MacPaint does.
        var page = [UInt8]()
        page.reserveCapacity(MacPaintPage.rowBytes * MacPaintPage.height)
        for y in 0..<MacPaintPage.height {
            let start = r.offset
            var produced = 0
            while produced < MacPaintPage.rowBytes {
                let n = Int(Int8(bitPattern: UInt8(try r.u8("row \(y)"))))
                if n >= 0 { _ = try r.take(n + 1, "row \(y)"); produced += n + 1 }
                else if n != -128 { _ = try r.take(1, "row \(y)"); produced += 1 - n }
            }
            page += try PackBits.unpack(file[start..<r.offset], length: MacPaintPage.rowBytes, row: y)
        }
        guard file.count % 512 == 0 else { throw FormatError("the file is \(file.count) bytes, not a multiple of 512") }
        guard r.remaining < 512 else { throw FormatError("\(r.remaining) bytes follow the picture") }
        try r.expectZeros(r.remaining, "the padding")

        // The screen image centred (PH12); white everywhere else.
        let origin = MacPaintPage.screenOrigin, byteX = origin.x / 8
        var image = BitImage(width: ScreenImage.width, height: ScreenImage.height)
        for y in 0..<MacPaintPage.height {
            let row = page[(y * 72)..<(y * 72 + 72)]
            let sy = y - origin.y
            if (0..<ScreenImage.height).contains(sy) {
                let inside = row[(row.startIndex + byteX)..<(row.startIndex + byteX + 64)]
                guard row.prefix(byteX).allSatisfy({ $0 == 0 }), row.suffix(72 - byteX - 64).allSatisfy({ $0 == 0 })
                else { throw FormatError("row \(y) has black outside the centred image") }
                image.bytes.replaceSubrange((sy * 64)..<(sy * 64 + 64), with: inside)
            } else if !row.allSatisfy({ $0 == 0 }) {
                throw FormatError("row \(y) is outside the centred image but isn't white")
            }
        }
        return image
    }
}
