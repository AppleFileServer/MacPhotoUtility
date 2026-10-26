import Testing
@testable import MacPhotoKit

struct PrintPICTTests {
    static let photo = try! Importer.load(Fixtures.url("landscape-4x3.jpg")).image

    static func render(_ o: Orientation, _ r: PrintResolution) -> (GreyImage, PrintProfile) {
        var c = Composition(uprightWidth: 4000, height: 3000)
        c.setOrientation(o)
        let p = PrintRenderer.render(photo, c, resolution: r)
        return (p.image, p.profile)
    }

    @Test(arguments: Orientation.allCases, PrintResolution.allCases)
    func roundTrip(o: Orientation, r: PrintResolution) throws {
        let (image, profile) = Self.render(o, r)
        let file = PrintPICTWriter.write(image, profile: profile)
        let back = try PrintPICTValidator.validate(file)
        #expect(back.image == image)
        #expect(back.record.profile == profile)
        #expect(back.record.pixelChecksum == CRC32.of(image.pixels.map { 255 - $0 }))
    }

    @Test func aRealisticSize() throws {
        // A noisy photograph doesn't pack: the ramp at 360 PPI landscape is
        // close to the 1.1 MB FILE_FORMATS.md expects; never far above it.
        var noisy = GreyImage(width: 1260, height: 900, grey: 0)
        var x: UInt32 = 1
        for i in noisy.pixels.indices { x = x &* 1_103_515_245 &+ 12345; noisy.pixels[i] = UInt8(x >> 24) }
        let file = PrintPICTWriter.write(noisy, profile: PrintProfile(orientation: .landscape, resolution: .ppi360))
        #expect(file.count > 1_134_000 && file.count < 1_160_000)
        #expect(try PrintPICTValidator.validate(file).image == noisy)
    }

    @Test func layout() {
        let (image, profile) = Self.render(.portrait, .ppi360)
        let f = PrintPICTWriter.write(image, profile: profile)
        #expect(f[0..<512].allSatisfy { $0 == 0 })
        #expect(Array(f[514..<522]) == [0, 0, 0, 0, 0x04, 0xEC, 0x03, 0x84])  // 0,0,1260,900
        #expect(Array(f[522..<530]) == [0x00, 0x11, 0x02, 0xFF, 0x0C, 0x00, 0xFF, 0xFE])
        #expect(Array(f[532..<536]) == [0x01, 0x68, 0x00, 0x00])                // 360.0 as Fixed
        #expect(Array(f[(f.count - 2)...]) == [0x00, 0xFF])
        #expect((f.count - 512) % 2 == 0)
        let comment = f.firstRange(of: Array("MPho".utf8))!.lowerBound
        #expect(Array(f[(comment - 6)..<comment]) == [0x00, 0xA1, 0x00, 0x64, 0x00, 0x14])
        #expect((comment - 6 - 512) % 2 == 0)                                 // opcodes at even offsets
    }

    // No ImageIO comparison (PH37): macOS's PICT reader draws this file
    // blank too (checked 26 Oct 2026). See PHASE-2-REPORT.md.

    @Test func refusesDamage() {
        let (image, profile) = Self.render(.landscape, .ppi300)
        let good = PrintPICTWriter.write(image, profile: profile)
        var f = good
        f[f.count - 3] ^= 0xFF                                          // a pixel near the end
        #expect(throws: FormatError.self) { try PrintPICTValidator.validate(f) }
        f = good
        let comment = good.firstRange(of: Array("MPho".utf8))!.lowerBound
        f[comment + 19] ^= 1                                            // the CRC itself
        #expect(throws: FormatError.self) { try PrintPICTValidator.validate(f) }
        f = good
        f[512 + 2 + 8 + 2 + 2 + 2 + 2 + 2 + 3] = 0x01                  // header vRes 300 → 300 + 1/65536
        #expect(throws: FormatError.self) { try PrintPICTValidator.validate(f) }
        // 1000 × 750 isn't a print size.
        var w = ByteWriter(); w.u16(1000)
        f = good
        f.replaceSubrange((512 + 8)..<(512 + 10), with: w.bytes)
        #expect(throws: FormatError("1000 × 750 isn't one of the four print sizes")) {
            try PrintPICTValidator.validate(f)
        }
        #expect(throws: FormatError.self) { try PrintPICTValidator.validate(Array(good.dropLast(5000))) }
        #expect(throws: FormatError.self) { try PrintPICTValidator.validate(good + [0, 0]) }
    }
}
