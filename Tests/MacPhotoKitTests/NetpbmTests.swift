import Foundation
import Testing
@testable import MacPhotoKit

/// A second reader for our PICTs (PH37): netpbm's `picttoppm`, written
/// outside Apple. macOS's own ImageIO draws them blank. Skipped where
/// netpbm isn't installed (`brew install netpbm`).
struct NetpbmTests {
    static let picttoppm = ["/opt/homebrew/bin/picttoppm", "/usr/local/bin/picttoppm"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }

    /// Decodes a PICT with picttoppm into its width, height and RGB bytes.
    func decode(_ file: URL) throws -> (width: Int, height: Int, rgb: [UInt8]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: Self.picttoppm!)
        p.arguments = [file.path]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        try p.run()
        let data = [UInt8](out.fileHandleForReading.readDataToEndOfFile())
        p.waitUntilExit()
        // P6 header: "P6", width, height, maxval, each followed by white space.
        var fields = [String](), i = 0
        while fields.count < 4 {
            while data[i] == 0x20 || data[i] == 0x0A { i += 1 }
            let start = i
            while data[i] != 0x20 && data[i] != 0x0A { i += 1 }
            fields.append(String(decoding: data[start..<i], as: UTF8.self))
        }
        #expect(fields[0] == "P6" && fields[3] == "255")
        return (Int(fields[1])!, Int(fields[2])!, Array(data[(i + 1)...]))
    }

    @Test(.enabled(if: picttoppm != nil), arguments: ["screen.pict", "screen-ramp.pict"])
    func screenPICTs(name: String) throws {
        let url = FixtureTests.folder.appendingPathComponent(name)
        let ours = try ScreenPICTValidator.validate([UInt8](try Data(contentsOf: url)))
        let theirs = try decode(url)
        #expect(theirs.width == 512 && theirs.height == 342)
        var differ = 0
        for y in 0..<342 {
            for x in 0..<512 where (theirs.rgb[(y * 512 + x) * 3] < 128) != ours[x, y] { differ += 1 }
        }
        #expect(differ == 0)
    }

    @Test(.enabled(if: picttoppm != nil),
          arguments: ["print-portrait-300.pict", "print-landscape-300.pict",
                      "print-portrait-360.pict", "print-landscape-360.pict"])
    func printPICTs(name: String) throws {
        let url = FixtureTests.folder.appendingPathComponent(name)
        let ours = try PrintPICTValidator.validate([UInt8](try Data(contentsOf: url))).image
        let theirs = try decode(url)
        #expect(theirs.width == ours.width && theirs.height == ours.height)
        // Grey through the colour table: index i is (255 − i) × 257, which
        // netpbm brings back to 255 − i in each of R, G and B.
        var differ = 0
        for (i, g) in ours.pixels.enumerated() {
            let r = theirs.rgb[i * 3], gg = theirs.rgb[i * 3 + 1], b = theirs.rgb[i * 3 + 2]
            if r != g || gg != g || b != g { differ += 1 }
        }
        #expect(differ == 0)
    }
}
