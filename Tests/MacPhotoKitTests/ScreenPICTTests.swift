import Testing
@testable import MacPhotoKit

struct ScreenPICTTests {
    static let bits: BitImage = {
        let photo = try! Importer.load(Fixtures.url("landscape-4x3.jpg")).image
        return ScreenRenderer.render(photo, Composition(uprightWidth: 4000, height: 3000)).bits
    }()
    static let file = ScreenPICTWriter.write(bits)

    @Test func roundTrip() throws {
        #expect(try ScreenPICTValidator.validate(Self.file) == Self.bits)
        // A noisy picture too: the dithered ramp.
        let ramp = try Importer.load(Fixtures.url("ramp.png")).image
        let b = ScreenRenderer.render(ramp, Composition(uprightWidth: 1050, height: 750)).bits
        let f = ScreenPICTWriter.write(b)
        #expect(try ScreenPICTValidator.validate(f) == b)
        #expect(f.count < 23_200)                                  // FILE_FORMATS.md: about 22.6 KB at most
    }

    @Test func layout() {
        let f = Self.file
        #expect(f[0..<512].allSatisfy { $0 == 0 })
        #expect(Int(f[512]) << 8 | Int(f[513]) == f.count - 512)
        #expect(Array(f[514..<522]) == [0, 0, 0, 0, 0x01, 0x56, 0x02, 0x00])   // 0,0,342,512
        #expect(Array(f[522..<525]) == [0x11, 0x01, 0x01])
        #expect(f[535] == 0x98 && f.last == 0xFF)
    }

    // No ImageIO comparison (PH37): macOS's PICT reader draws this file as
    // blank white, and a 1990 After Dark PICT as solid black, so it can't
    // judge. See PHASE-2-REPORT.md; the emulator check (PH43) stands in.

    @Test func refusesDamage() {
        var f = Self.file
        f[513] ^= 1                                                     // picSize wrong
        #expect(throws: FormatError.self) { try ScreenPICTValidator.validate(f) }
        #expect(throws: FormatError.self) { try ScreenPICTValidator.validate(Array(Self.file.dropLast(100))) }
        f = Self.file
        f[3] = 1                                                        // header not zeros
        #expect(throws: FormatError("the 512-byte file header isn't all zeros")) {
            try ScreenPICTValidator.validate(f)
        }
        f = Self.file
        f[536 + 1] = 0x48                                               // rowBytes 72
        #expect(throws: FormatError.self) { try ScreenPICTValidator.validate(f) }
        // The first row's length one short: that row and everything after it shifts.
        f = Self.file
        f[512 + 2 + 8 + 2 + 11 + 1 + 2 + 8 * 3 + 2] -= 1
        #expect(throws: FormatError.self) { try ScreenPICTValidator.validate(f) }
        #expect(throws: FormatError.self) { try ScreenPICTValidator.validate(Self.file + [0]) }
    }
}
