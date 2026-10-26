import Foundation
import Testing
@testable import MacPhotoKit

/// Saved projects (PH70–PH79).
@MainActor
struct ProjectTests {
    let fm = FileManager.default

    func queue() -> PhotoQueue {
        PhotoQueue(editor: EditorSession(defaults: UserDefaults(suiteName: "MacPhotoTests-\(UUID().uuidString)")!,
                                         previewDelay: .zero))
    }

    func folder(_ name: String) throws -> URL {
        let f = fm.temporaryDirectory.appendingPathComponent("\(name)-\(UUID().uuidString)")
        try fm.createDirectory(at: f, withIntermediateDirectories: true)
        return f
    }

    /// Three photographs in a folder of their own, added to a fresh queue.
    func setUp() async throws -> (PhotoQueue, URL) {
        let photos = try folder("photos")
        for n in ["landscape-4x3.jpg", "portrait-3x4.jpg", "square.png"] {
            try fm.copyItem(at: Fixtures.url(n), to: photos.appendingPathComponent(n))
        }
        let q = queue()
        await q.add([photos])
        return (q, photos)
    }

    func id(_ q: PhotoQueue, _ name: String) -> UUID { q.entries.first { $0.name == name }!.id }

    @Test func fingerprintsAreTakenOnAdding() async throws {
        let (q, photos) = try await setUp()
        let e = q.entries.first { $0.name == "square.png" }!
        #expect(try e.fingerprint == Fingerprint.of(photos.appendingPathComponent("square.png")))
        #expect(e.bookmark != nil)
    }

    @Test func roundTrip() async throws {
        let (q, _) = try await setUp()
        let out = try folder("out")
        q.settings.destination = out
        q.settings.resolution = .ppi300
        q.settings.outputs = [.screen, .macPaint]
        await q.select(id(q, "portrait-3x4.jpg"))
        q.editor.setZoom(2)
        q.editor.setScreenTone(ScreenTone(brightness: 20, contrast: -10))
        await q.editor.export()
        await q.select(id(q, "landscape-4x3.jpg"))
        q.editor.turn(by: 1)
        #expect(q.isDirty)

        let file = try folder("projects").appendingPathComponent("Holiday.macphoto")
        try q.save(to: file)
        #expect(!q.isDirty && q.title == "Holiday")

        let r = queue()
        let report = try await r.openProject(file)
        #expect(report == PhotoQueue.OpenReport())
        #expect(!r.isDirty && r.projectURL == file)
        #expect(r.entries.map(\.name) == q.entries.map(\.name))
        #expect(r.entries.map(\.composition) == q.entries.map(\.composition))
        #expect(r.entries.map(\.seen) == [true, true, false])
        #expect(r.entries.allSatisfy { $0.state == .ready && $0.thumbnail != nil })
        #expect(r.settings.resolution == .ppi300 && r.settings.outputs == [.screen, .macPaint])
        #expect(r.settings.destination?.standardizedFileURL.path == out.standardizedFileURL.path)
        let history = r.entries.first { $0.name == "portrait-3x4.jpg" }!.history
        #expect(history.count == 1 && history[0].files.map(\.path) == ["PICT Files/portrait-3x4.pict",
                                                                         "MacPaint Files/portrait-3x4.MAC"])
        #expect(history[0].ppi == nil && history[0].folder == out.path)
        // The photographs themselves are never in the project.
        #expect(try Data(contentsOf: file).count < 20_000)
    }

    @Test func aMovedPhotographIsFoundByItsBookmark() async throws {
        let (q, photos) = try await setUp()
        let file = try folder("p").appendingPathComponent("P.macphoto")
        try q.save(to: file)
        let elsewhere = try folder("elsewhere")
        try fm.moveItem(at: photos.appendingPathComponent("square.png"), to: elsewhere.appendingPathComponent("square.png"))
        try fm.moveItem(at: photos.appendingPathComponent("portrait-3x4.jpg"),
                        to: photos.appendingPathComponent("renamed.jpg"))
        let r = queue()
        let report = try await r.openProject(file)
        #expect(Set(report.moved) == ["square.png", "portrait-3x4.jpg"] && report.missing.isEmpty)
        #expect(r.entries.allSatisfy { $0.state == .ready })
        #expect(r.entries.contains { $0.name == "renamed.jpg" })
        #expect(r.isDirty)                                        // the new places want saving
    }

    @Test func aMissingPhotographKeepsItsFramingAndIsFoundAgain() async throws {
        let (q, photos) = try await setUp()
        await q.select(id(q, "square.png"))
        q.editor.setZoom(3)
        let framing = q.entries.first { $0.name == "square.png" }!.composition
        let file = try folder("p").appendingPathComponent("P.macphoto")
        try q.save(to: file)
        // A copy elsewhere, the original gone: the bookmark can't follow it.
        let backup = try folder("backup")
        try fm.copyItem(at: photos.appendingPathComponent("square.png"), to: backup.appendingPathComponent("square.png"))
        try fm.removeItem(at: photos.appendingPathComponent("square.png"))

        let r = queue()
        let report = try await r.openProject(file)
        #expect(report.missing == ["square.png"])
        let missing = r.entries.first { $0.name == "square.png" }!
        #expect(missing.state == .missing && missing.composition == framing)
        await r.select(missing.id)
        #expect(r.editor.photo == nil)                            // nothing to show

        #expect(await r.locate(inFolder: backup) == 1)
        #expect(r.editor.photo?.url.lastPathComponent == "square.png")   // shown once found
        let back = r.entries.first { $0.id == missing.id }!
        #expect(back.state == .ready && back.composition == framing && !back.acceptedDifferentFile)
    }

    @Test func aDifferentFileIsNeverUsedSilently() async throws {
        let (q, photos) = try await setUp()
        let file = try folder("p").appendingPathComponent("P.macphoto")
        try q.save(to: file)
        try fm.removeItem(at: photos.appendingPathComponent("square.png"))
        let r = queue()
        try await r.openProject(file)
        let sq = id(r, "square.png")
        let other = try folder("other").appendingPathComponent("square.png")
        try fm.copyItem(at: Fixtures.url("ramp.png"), to: other)   // same name, different photograph
        #expect(await r.locate(inFolder: other.deletingLastPathComponent()) == 0)
        #expect(await r.relink(sq, to: other) == .differs)
        #expect(r.entries.first { $0.id == sq }!.state == .missing)
        #expect(await r.relinkAcceptingDifferent(sq, to: other) == .linked)
        let e = r.entries.first { $0.id == sq }!
        #expect(e.state == .ready && e.acceptedDifferentFile)
        #expect(try e.fingerprint == Fingerprint.of(other))
        // Saved and reopened: the choice is remembered and the new file accepted.
        try r.save(to: file)
        let s = queue()
        let report = try await s.openProject(file)
        #expect(report.missing.isEmpty && s.entries.first { $0.name == "square.png" }!.acceptedDifferentFile)
    }

    @Test func damagedAndNewerProjectsChangeNothing() async throws {
        let (q, _) = try await setUp()
        let dir = try folder("bad")
        let garbage = dir.appendingPathComponent("Bad.macphoto")
        try Data("not a project".utf8).write(to: garbage)
        await #expect(throws: ProjectFile.Problem.unreadable("it isn't a MacPhoto project")) {
            try await q.openProject(garbage)
        }
        var newer = q.projectFile()
        newer.projectVersion = 2
        let n = dir.appendingPathComponent("New.macphoto")
        try newer.write(to: n)
        await #expect(throws: ProjectFile.Problem.newer(2)) { try await q.openProject(n) }
        #expect(q.entries.count == 3)                              // the open project untouched
        let missing = dir.appendingPathComponent("Gone.macphoto")
        await #expect(throws: ProjectFile.Problem.self) { try await q.openProject(missing) }
    }

    @Test func unknownFieldsAreIgnored() throws {
        var json = try JSONSerialization.jsonObject(with: try queue().projectFile().encoded()) as! [String: Any]
        json["somethingNew"] = ["a": 1]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(try ProjectFile.decode(data).projectVersion == 1)
    }

    @Test func whatCountsAsUnsaved() async throws {
        let (q, _) = try await setUp()
        #expect(q.isDirty)                                         // added
        let file = try folder("p").appendingPathComponent("P.macphoto")
        try q.save(to: file)
        await q.select(id(q, "square.png"))
        #expect(!q.isDirty)                                        // only looked at
        q.editor.setZoom(2)
        #expect(q.isDirty)
        try q.save(to: file)
        q.settings.resolution = .ppi300
        #expect(q.isDirty)
        try q.save(to: file)
        q.remove([id(q, "square.png")])
        #expect(q.isDirty)
        q.newProject()
        #expect(!q.isDirty && q.entries.isEmpty && q.title == "Untitled")
    }
}
