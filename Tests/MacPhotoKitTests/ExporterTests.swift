import Foundation
import Testing
@testable import MacPhotoKit

struct ExporterTests {
    static let photo = try! Importer.load(Fixtures.url("landscape-4x3.jpg"))

    func freshFolder() throws -> URL {
        let f = FileManager.default.temporaryDirectory.appendingPathComponent("export-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: f, withIntermediateDirectories: true)
        return f
    }

    /// Every file under `folder`, relative, sorted.
    func listing(_ folder: URL) -> [String] {
        (FileManager.default.subpaths(atPath: folder.path) ?? [])
            .filter { !$0.hasSuffix("Files") }.sorted()
    }

    var composition: Composition { Composition(uprightWidth: 4000, height: 3000) }

    @Test func exportsAllThree() throws {
        let folder = try freshFolder()
        let result = try Exporter.export(Self.photo, composition, to: folder)
        #expect(listing(folder) == ["MacPaint Files/landscape-4x3.MAC", "PICT Files/landscape-4x3.pict",
                                    "Print Files/landscape-4x3.pict", "manifest.json"])
        #expect(result.files.map(\.kind) == [.print, .screen, .macPaint])
        let print = [UInt8](try Data(contentsOf: folder.appendingPathComponent("Print Files/landscape-4x3.pict")))
        #expect(try PrintPICTValidator.validate(print).record.profile.pixels == (1260, 900))
        let m = try Manifest.read(from: folder)
        #expect(m.files.count == 3 && m.files.allSatisfy { $0.validation == "passed" })
        #expect(m.files.first { $0.kind == .print }?.ppi == 360)
        #expect(m.files.first { $0.kind == .screen }?.ppi == nil)
        #expect(m.files.first?.source.sha256.count == 64)
    }

    @Test func onlySomeKinds() throws {
        let folder = try freshFolder()
        try Exporter.export(Self.photo, composition, kinds: [.screen], to: folder)
        #expect(listing(folder) == ["PICT Files/landscape-4x3.pict", "manifest.json"])
    }

    @Test func neverOverwritesSilently() throws {
        let folder = try freshFolder()
        try Exporter.export(Self.photo, composition, to: folder)
        let before = try Data(contentsOf: folder.appendingPathComponent("manifest.json"))
        #expect(throws: ExportError.exists(["Print Files/landscape-4x3.pict", "PICT Files/landscape-4x3.pict",
                                            "MacPaint Files/landscape-4x3.MAC"])) {
            try Exporter.export(Self.photo, composition, to: folder)
        }
        #expect(try Data(contentsOf: folder.appendingPathComponent("manifest.json")) == before)

        try Exporter.export(Self.photo, composition, to: folder, ifExists: .keepBoth)
        try Exporter.export(Self.photo, composition, to: folder, ifExists: .keepBoth)
        #expect(listing(folder).contains("PICT Files/landscape-4x3 3.pict"))
        #expect(try Manifest.read(from: folder).files.count == 9)

        var c = composition
        c.screenCrop.zoom = 2
        try Exporter.export(Self.photo, c, kinds: [.screen], to: folder, ifExists: .replace)
        let m = try Manifest.read(from: folder)
        #expect(m.files.count == 9)
        #expect(m.files.first { $0.path == "PICT Files/landscape-4x3.pict" }?.composition.screenCrop.zoom == 2)
    }

    @Test func aFailedCheckLeavesNothing() throws {
        let folder = try freshFolder()
        #expect(throws: ExportError.self) {
            try Exporter.export(Self.photo, composition, to: folder) { kind, bytes in
                if kind == .macPaint { bytes[600] ^= 0x55 }        // the last file to be checked
            }
        }
        #expect(listing(folder).isEmpty)                            // no temporaries, no partial set
    }

    @Test func aDamagedManifestStopsTheExport() throws {
        let folder = try freshFolder()
        try Data("not json".utf8).write(to: folder.appendingPathComponent("manifest.json"))
        #expect(throws: ExportError.self) { try Exporter.export(Self.photo, composition, to: folder) }
        #expect(listing(folder) == ["manifest.json"])
    }

    @Test func warningsGoWithTheirFiles() throws {
        let folder = try freshFolder()
        let small = try Importer.load(Fixtures.url("small.jpg"))
        try Exporter.export(small, Composition(uprightWidth: 640, height: 480), to: folder)
        let m = try Manifest.read(from: folder)
        #expect(m.files.first { $0.kind == .print }?.warnings.count == 1)
        #expect(m.files.first { $0.kind == .screen }?.warnings.isEmpty == true)
    }

    @Test(arguments: [
        ("IMG_8691.HEIC", "pict", 1, "IMG_8691.pict"),
        ("Café: été.jpg", "pict", 1, "Cafe_ ete.pict"),
        ("東京.jpg", "MAC", 1, "dong jing.MAC"),
        ("🙂.png", "pict", 1, "_.pict"),
        (".hidden.jpg", "pict", 1, "_hidden.pict"),
        ("A very long photograph name from a camera.jpg", "pict", 1, "A very long photograph nam.pict"),
        ("A very long photograph name from a camera.jpg", "pict", 12, "A very long photograph 12.pict"),
        ("IMG_8691.HEIC", "MAC", 2, "IMG_8691 2.MAC"),
    ])
    func macSafeNames(source: String, ext: String, copy: Int, expected: String) {
        let n = MacNames.name(for: source, extension: ext, copy: copy)
        #expect(n == expected)
        #expect(n.count <= 31 && n.unicodeScalars.allSatisfy { (0x20...0x7E).contains($0.value) && $0 != ":" })
    }
}
