import Testing
@testable import MacPhotoKit

struct MacPaintTests {
    static let bits = ScreenPICTTests.bits
    static let file = MacPaintWriter.write(bits)

    @Test func roundTrip() throws {
        #expect(try MacPaintValidator.validate(Self.file) == Self.bits)
        #expect(Self.file.count % 512 == 0)
        #expect(Self.file.count < 52 * 1024)
    }

    @Test func headerAndPlacement() throws {
        let f = Self.file
        #expect(f[0..<512].allSatisfy { $0 == 0 })                   // version 0, no patterns
        // Unpack the page independently of the validator: the first 189
        // rows are white, each packed as one repeat of 72 zeros (B9 00).
        #expect(Array(f[512..<516]) == [0xB9, 0x00, 0xB9, 0x00])
        // The centre square: screen (256, 171) is page (288, 360).
        var r = ByteReader(f, at: 512)
        var page = [UInt8]()
        while page.count < 72 * 720 {
            let n = Int(Int8(bitPattern: UInt8(try r.u8("data"))))
            if n >= 0 { page += try r.take(n + 1, "literal") } else { page += repeatElement(UInt8(try r.u8("repeat")), count: 1 - n) }
        }
        #expect(page[360 * 72 + 288 / 8] & (0x80 >> (288 % 8)) != 0)
        #expect(page[(189 + 0) * 72 + 3] == 0 && page[(189 + 341) * 72 + 68] == 0)
    }

    @Test func blackEdgesStayInside() throws {
        // An all-black screen: page rows 189–530, bytes 4–67, and nothing else.
        var black = BitImage(width: 512, height: 342)
        black.bytes = [UInt8](repeating: 0xFF, count: black.bytes.count)
        let f = MacPaintWriter.write(black)
        #expect(try MacPaintValidator.validate(f) == black)
    }

    @Test func refusesDamage() {
        var f = Self.file
        f[3] = 2                                                         // version 2
        #expect(throws: FormatError("the version is 00000002, not 00000000")) { try MacPaintValidator.validate(f) }
        f = Self.file
        f[512] = 0xB8                                                    // first row: 73 zeros
        #expect(throws: FormatError.self) { try MacPaintValidator.validate(f) }
        f = Self.file
        f[512 + 1] = 0x01                                                // a dot in row 0, outside the image
        #expect(throws: FormatError("row 0 is outside the centred image but isn't white")) {
            try MacPaintValidator.validate(f)
        }
        #expect(throws: FormatError.self) { try MacPaintValidator.validate(Array(Self.file.prefix(9000))) }
        #expect(throws: FormatError.self) { try MacPaintValidator.validate(Self.file + [0]) }
    }
}
