import CryptoKit
import Foundation
import MacPhotoKit
import MacPhotoTestSupport

// The handoff fixtures (PH42; FILE_FORMATS.md §5): good files from the real
// writers, made from the generated test images, and deliberately broken
// ones. The Transfer Utility copies them into its own tests.

enum HandoffFixtures {
    struct Item {
        let name: String
        let tests: String
        let valid: Bool
        let bytes: [UInt8]
    }

    static func make(into folder: URL) throws -> [Item] {
        let fm = FileManager.default
        let sources = fm.temporaryDirectory.appendingPathComponent("mpu-fixture-sources-\(UUID().uuidString)")
        try fm.createDirectory(at: sources, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: sources) }
        func load(_ name: String) throws -> GreyImage {
            try Importer.load(try TestImages.write(name, to: sources)).image
        }
        let landscape = try load("landscape-4x3.jpg"), portrait = try load("portrait-3x4.jpg"),
            ramp = try load("ramp.png")

        var items = [Item]()
        func good(_ name: String, _ tests: String, _ bytes: [UInt8]) {
            items.append(Item(name: name, tests: tests, valid: true, bytes: bytes))
        }
        func bad(_ name: String, _ tests: String, from base: [UInt8], _ change: (inout [UInt8]) -> Void) {
            var b = base
            change(&b)
            items.append(Item(name: name, tests: tests, valid: false, bytes: b))
        }

        // Print PICTs, all four sizes.
        var prints = [String: [UInt8]]()
        for (photo, o) in [(portrait, Orientation.portrait), (landscape, .landscape)] {
            for r in PrintResolution.allCases {
                var c = Composition(uprightWidth: photo.width, height: photo.height)
                c.setOrientation(o)
                let p = PrintRenderer.render(photo, c, resolution: r)
                let name = "print-\(o.rawValue)-\(r.ppi).pict"
                prints[name] = PrintPICTWriter.write(p.image, profile: p.profile)
                good(name, "8-bit print PICT, \(p.image.width) × \(p.image.height), \(r.ppi) PPI, \(o.rawValue)", prints[name]!)
            }
        }
        // Screen images: the pattern, and the dithered ramp (near the largest a screen PICT gets).
        let screen = ScreenRenderer.render(landscape, Composition(uprightWidth: 4000, height: 3000)).bits
        let noisy = ScreenRenderer.render(ramp, Composition(uprightWidth: 1050, height: 750)).bits
        let screenPICT = ScreenPICTWriter.write(screen), macPaint = MacPaintWriter.write(screen)
        good("screen.pict", "1-bit screen PICT", screenPICT)
        good("screen-ramp.pict", "1-bit screen PICT, dithered grey ramp (packs badly)", ScreenPICTWriter.write(noisy))
        good("macpaint.MAC", "MacPaint, screen image centred", macPaint)
        good("macpaint-ramp.MAC", "MacPaint, dithered grey ramp", MacPaintWriter.write(noisy))

        // Broken print PICTs. Offsets from FILE_FORMATS.md §1: the colour
        // table's entries start at 646, the first row's length at 2712.
        let p = prints["print-landscape-300.pict"]!
        bad("bad-print-truncated.pict", "cut short in the pixel rows", from: p) { $0.removeLast($0.count / 3) }
        bad("bad-print-header.pict", "512-byte header not all zeros", from: p) { $0[100] = 1 }
        bad("bad-print-version.pict", "version 02FF changed to 01FF", from: p) { $0[524] = 0x01 }
        bad("bad-print-size.pict", "picFrame 1000 × 750, not a print size", from: p) { $0[520] = 0x03; $0[521] = 0xE8 }
        bad("bad-print-colour-table.pict", "colour 128's red changed", from: p) { $0[646 + 8 * 128 + 2] ^= 0x01 }
        bad("bad-print-row-length.pict", "row 0's length one more than its data", from: p) { $0[2713] &+= 1 }
        bad("bad-print-crc.pict", "MacPhoto's record's CRC-32 wrong", from: p) {
            let at = $0.firstRange(of: Array("MPho".utf8))!.lowerBound + 19
            $0[at] ^= 0xFF
        }
        bad("bad-print-pixels.pict", "one pixel changed (only the CRC-32 notices)", from: p) {
            // The last row ends with a literal or a repeat; change its last byte.
            $0[$0.count - 3] ^= 0x01
        }
        // Broken screen PICTs. picFrame at 514, rowBytes at 536.
        bad("bad-screen-truncated.pict", "cut short", from: screenPICT) { $0.removeLast(2000) }
        bad("bad-screen-picsize.pict", "picSize one too big", from: screenPICT) { $0[513] &+= 1 }
        bad("bad-screen-rowbytes.pict", "rowBytes 72, not 64", from: screenPICT) { $0[537] = 72 }
        bad("bad-screen-end.pict", "no FF at the end", from: screenPICT) { $0[$0.count - 1] = 0 }
        // Broken MacPaint files.
        bad("bad-macpaint-version.MAC", "header version 2 (would replace the user's patterns)", from: macPaint) { $0[3] = 2 }
        bad("bad-macpaint-row-length.MAC", "row 0 unpacks to 73 bytes (MacPaint beeps)", from: macPaint) { $0[512] = 0xB8 }
        bad("bad-macpaint-outside.MAC", "a dot outside the centred image (MacPhoto's placement rule)", from: macPaint) { $0[513] = 0x01 }
        bad("bad-macpaint-padding.MAC", "not a multiple of 512 bytes", from: macPaint) { $0.append(0) }
        items.append(Item(name: "bad-not-a-picture.pict", tests: "text, not a picture", valid: false,
                          bytes: Array("This is not a picture.\n".utf8)))

        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        for item in items { try Data(item.bytes).write(to: folder.appendingPathComponent(item.name)) }
        try Data(readme(items).utf8).write(to: folder.appendingPathComponent("README.md"))
        return items
    }

    static func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }

    static func readme(_ items: [Item]) -> String {
        var s = """
        # Handoff fixtures

        Made by `mpu fixtures` (MacPhoto Utility \(AppVersion.string)) from the
        generated test images, so nothing private. FILE_FORMATS.md §5: the
        Macintosh Transfer Utility copies these into its own tests and never
        writes here. Every `bad-` file has exactly one thing wrong with it,
        listed below; MacPhoto's validators refuse each one (a test checks).

        The print PICTs are made of test patterns, so they pack far smaller
        than photographs do (about 1.1 MB at 360 PPI).

        | File | Tests | Valid | Bytes | SHA-256 |
        |---|---|---|---:|---|

        """
        for i in items {
            s += "| `\(i.name)` | \(i.tests) | \(i.valid ? "yes" : "**no**") | \(i.bytes.count) | `\(sha256(i.bytes))` |\n"
        }
        return s
    }
}
