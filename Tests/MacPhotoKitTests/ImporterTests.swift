import CryptoKit
import Foundation
import Testing
@testable import MacPhotoKit
import MacPhotoTestSupport

/// The test images (PH31), written once per test run into a temporary folder.
enum Fixtures {
    static let folder: URL = {
        let f = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacPhotoKitTests-\(ProcessInfo.processInfo.processIdentifier)")
        try! FileManager.default.createDirectory(at: f, withIntermediateDirectories: true)
        try! TestImages.writeAll(to: f)
        return f
    }()

    static func url(_ name: String) -> URL { folder.appendingPathComponent(name) }
}

struct ImporterTests {
    @Test(arguments: [("landscape-4x3.jpg", "JPEG", 4000, 3000), ("portrait-3x4.jpg", "JPEG", 3000, 4000),
                      ("square.png", "PNG", 3000, 3000), ("panorama.jpg", "JPEG", 6000, 2000),
                      ("colour.heic", "HEIC", 4032, 3024), ("grey-16bit.tiff", "TIFF", 2000, 1500),
                      ("ramp.png", "PNG", 1050, 750), ("small.jpg", "JPEG", 640, 480)])
    func eachKindLoads(name: String, kind: String, w: Int, h: Int) throws {
        let p = try Importer.load(Fixtures.url(name))
        #expect(p.kind == kind)
        #expect(p.image.width == w && p.image.height == h)
    }

    @Test(arguments: 1...8)
    func exifOrientationComesOutUpright(n: Int) throws {
        let p = try Importer.load(Fixtures.url("exif-\(n).jpg"))
        #expect(p.exifOrientation == n)
        #expect(p.image.width == 600 && p.image.height == 400)
        // The middle of each quarter, against the upright picture.
        for (x, y) in [(150, 100), (450, 100), (150, 300), (450, 300)] {
            let want = Int(TestImages.exifUprightGrey(x: x, y: y))
            #expect(abs(Int(p.image[x, y]) - want) <= 4, "exif-\(n) at (\(x), \(y))")
        }
    }

    @Test func patternIsWhereItWasDrawn() throws {
        let p = try Importer.load(Fixtures.url("square.png")).image   // lossless
        let f = TestImages.fRect(3000, 3000)
        #expect(p[f.x0 + 2, f.y0 + 40] == 0)          // the F's stem
        #expect(p[f.x1 - 2, f.y1 - 2] == 255)         // beside its short bar
        #expect(p[1500, 1500] == 0 && p[200, 600] == 255)
    }

    @Test func colourToGrey() throws {
        let p = try Importer.load(Fixtures.url("colour.heic")).image
        func at(_ k: Int) -> Int {
            let b = TestImages.colourBlock(k)
            return Int(p[(b.x0 + b.x1) / 2, (b.y0 + b.y1) / 2])
        }
        // Luminance of sRGB primaries, re-encoded at gamma 2.2:
        // red 126, green 219, blue 77; sRGB grey 128 → 127.
        #expect(abs(at(0) - 126) <= 12)
        #expect(abs(at(1) - 219) <= 12)
        #expect(abs(at(2) - 77) <= 12)
        #expect(abs(at(3) - 127) <= 4)
    }

    @Test func transparencyGoesWhite() throws {
        let p = try Importer.load(Fixtures.url("transparent.png")).image
        #expect(p[50, 150] == 255 && p[350, 150] == 0)
    }

    @Test func sixteenBitGrey() throws {
        let p = try Importer.load(Fixtures.url("grey-16bit.tiff")).image
        #expect(p[0, 700] <= 1 && p[1999, 700] >= 254)
        #expect(abs(Int(p[1000, 700]) - 128) <= 2)
    }

    @Test func errors() {
        #expect(throws: ImportError.missing("nowhere.jpg")) {
            try Importer.load(Fixtures.url("nowhere.jpg"))
        }
        #expect(throws: ImportError.empty("bad-empty.png")) {
            try Importer.load(Fixtures.url("bad-empty.png"))
        }
        #expect(throws: ImportError.notAnImage("bad-text.jpg")) {
            try Importer.load(Fixtures.url("bad-text.jpg"))
        }
        #expect(throws: ImportError.damaged("bad-truncated.jpg", reason: "it ends before the picture does")) {
            try Importer.load(Fixtures.url("bad-truncated.jpg"))
        }
        do {
            _ = try Importer.load(Fixtures.url("unsupported.gif"))
            Issue.record("a GIF was accepted")
        } catch let e as ImportError {
            guard case .unsupported(_, let kind) = e else { Issue.record("\(e)"); return }
            #expect(kind.contains("GIF"))
        } catch { Issue.record("\(error)") }
    }

    @Test func truncatedPNGIsDamaged() throws {
        let whole = try Data(contentsOf: Fixtures.url("square.png"))
        let cut = FileManager.default.temporaryDirectory.appendingPathComponent("cut-\(UUID()).png")
        try whole.prefix(whole.count - 20).write(to: cut)
        defer { try? FileManager.default.removeItem(at: cut) }
        #expect(throws: ImportError.self) { try Importer.load(cut) }
    }

    @Test func sourcesAreNeverWritten() throws {
        func fingerprint(_ name: String) throws -> (String, Date) {
            let url = Fixtures.url(name)
            let hash = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
            let date = try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as! Date
            return (hash, date)
        }
        let names = TestImages.all.map(\.name)
        let before = try names.map(fingerprint)
        for n in names { _ = try? Importer.load(Fixtures.url(n)) }
        let after = try names.map(fingerprint)
        for (n, (b, a)) in zip(names, zip(before, after)) {
            #expect(b.0 == a.0 && b.1 == a.1, "\(n) changed")
        }
    }

    // Exact moves, on a 3 × 2 picture:  1 2 3
    //                                    4 5 6
    let small = GreyImage(width: 3, height: 2, pixels: [1, 2, 3, 4, 5, 6])

    @Test func turnsAndMirrors() {
        #expect(small.turned(1) == GreyImage(width: 2, height: 3, pixels: [4, 1, 5, 2, 6, 3]))
        #expect(small.turned(2) == GreyImage(width: 3, height: 2, pixels: [6, 5, 4, 3, 2, 1]))
        #expect(small.turned(3) == GreyImage(width: 2, height: 3, pixels: [3, 6, 2, 5, 1, 4]))
        #expect(small.turned(4) == small && small.turned(-1) == small.turned(3))
        #expect(small.mirrored() == GreyImage(width: 3, height: 2, pixels: [3, 2, 1, 6, 5, 4]))
    }
}
