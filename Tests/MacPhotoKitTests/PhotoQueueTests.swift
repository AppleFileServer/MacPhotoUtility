import CryptoKit
import Darwin
import Foundation
import Testing
@testable import MacPhotoKit

/// The queue and Export All (PH59–PH68), with specification §11's batch
/// tests: mixed orientations, individual crops surviving the batch, shared
/// PPI not changing framing, one failure not stopping the rest, nothing
/// overwritten silently, sources unchanged.
@MainActor
struct PhotoQueueTests {
    func queue() -> PhotoQueue {
        PhotoQueue(editor: EditorSession(defaults: UserDefaults(suiteName: "MacPhotoTests-\(UUID().uuidString)")!,
                                         previewDelay: .zero))
    }

    func folder(_ name: String = "q") throws -> URL {
        let f = FileManager.default.temporaryDirectory.appendingPathComponent("\(name)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: f, withIntermediateDirectories: true)
        return f
    }

    /// A mixed folder: landscape, portrait, square, IMG_2 and IMG_10 (for
    /// the order), a damaged JPEG, a text file, an empty file and a GIF.
    func mixedFolder() throws -> URL {
        let f = try folder("mixed")
        let fm = FileManager.default
        for (from, to) in [("landscape-4x3.jpg", "landscape-4x3.jpg"), ("portrait-3x4.jpg", "portrait-3x4.jpg"),
                           ("square.png", "square.png"), ("small.jpg", "IMG_10.jpg"), ("small.jpg", "IMG_2.jpg"),
                           ("bad-truncated.jpg", "damaged.jpg"), ("bad-text.jpg", "notes.jpg"),
                           ("bad-empty.png", "empty.png"), ("unsupported.gif", "anim.gif")] {
            try fm.copyItem(at: Fixtures.url(from), to: f.appendingPathComponent(to))
        }
        try Data("x".utf8).write(to: f.appendingPathComponent(".hidden.jpg"))
        return f
    }

    @Test func addingAFolder() async throws {
        let q = queue()
        let r = await q.add([try mixedFolder()])
        #expect(q.entries.map(\.name) == ["damaged.jpg", "IMG_2.jpg", "IMG_10.jpg", "landscape-4x3.jpg",
                                         "portrait-3x4.jpg", "square.png"])   // Finder order; hidden left out
        #expect(r.added == 6 && r.skipped.count == 3)
        #expect(r.skipped.contains { $0.hasPrefix("notes.jpg:") } && r.skipped.contains { $0.hasPrefix("anim.gif:") })
        #expect(q.entries[0].state == .failed("the file is damaged (it ends before the picture does)."))
        let portrait = q.entries.first { $0.name == "portrait-3x4.jpg" }!
        #expect(portrait.composition?.orientation == .portrait && portrait.uprightWidth == 3000)
        #expect(portrait.thumbnail.map { max($0.width, $0.height) } == 160)
        #expect(!portrait.seen)
    }

    @Test func noPhotographTwice() async throws {
        let q = queue()
        let f = try mixedFolder()
        await q.add([f])
        let r = await q.add([f, f.appendingPathComponent("square.png")])
        #expect(r.added == 0 && r.alreadyThere == 7)
        #expect(q.entries.count == 6)
    }

    @Test func eachPhotographKeepsItsFraming() async throws {
        let q = queue()
        await q.add([try mixedFolder()])
        let land = q.entries.first { $0.name == "landscape-4x3.jpg" }!.id
        let port = q.entries.first { $0.name == "portrait-3x4.jpg" }!.id
        await q.select(land)
        q.editor.setZoom(2)
        q.editor.editing = .screen
        q.editor.setZoom(2)                                        // full width at zoom 1: nowhere to move
        q.editor.move(dx: 0.1, dy: 0)
        await q.select(port)
        q.editor.turn(by: 1)
        await q.select(land)
        #expect(q.editor.composition?.printCrop.zoom == 2)
        #expect(q.editor.composition?.screenCrop.centreX == 0.6)
        #expect(q.entries.first { $0.id == port }?.composition?.quarterTurns == 1)
        #expect(q.entries.allSatisfy { $0.id == land || $0.id == port ? $0.seen : !$0.seen })
        // A shared setting doesn't touch anyone's framing (PH63).
        let before = q.entries.map(\.composition)
        q.settings.resolution = .ppi300
        #expect(q.entries.map(\.composition) == before)
    }

    @Test func aDamagedPhotographFoundOnSelecting() async throws {
        let q = queue()
        let f = try folder()
        let url = f.appendingPathComponent("photo.jpg")
        try FileManager.default.copyItem(at: Fixtures.url("landscape-4x3.jpg"), to: url)
        await q.add([f])
        // Replaced after adding by something that isn't a picture: found
        // when it's selected, and marked; the editor stays empty.
        try Data("not a picture".utf8).write(to: url)
        await q.select(q.entries[0].id)
        #expect(q.editor.photo == nil)
        #expect(q.entries[0].state == .failed("not a picture this app can read."))
        #expect(q.editor.message == nil)                            // shown on the row, not as an alert
    }

    func exportFolder(_ q: PhotoQueue) throws -> URL {
        let out = try folder("out")
        q.settings.destination = out
        q.settings.outputs = [.print, .screen]
        return out
    }

    func seeAll(_ q: PhotoQueue) async {
        for e in q.entries where e.state == .ready { await q.select(e.id) }
    }

    @Test func exportAllAsksAboutUnseenThenExportsEachAsFramed() async throws {
        let q = queue()
        await q.add([try mixedFolder()])
        let out = try exportFolder(q)
        let port = q.entries.first { $0.name == "portrait-3x4.jpg" }!.id
        await q.select(port)
        q.editor.setOrientation(.landscape)                       // this one printed landscape
        await q.exportAll()
        guard case .unseen(let names) = q.question else { Issue.record("no question"); return }
        #expect(names.count == 4 && !names.contains("portrait-3x4.jpg"))
        await q.answer(.exportUnseen)
        let s = try #require(q.summary)
        #expect(s.exported.count == 5 && s.failed.isEmpty && s.files == 10)
        #expect(s.warnings == 2)                                   // the two 640 × 480 prints
        // Each as framed: the portrait photograph's print is landscape.
        let p = [UInt8](try Data(contentsOf: out.appendingPathComponent("Print Files/portrait-3x4.pict")))
        #expect(try PrintPICTValidator.validate(p).record.profile.orientation == .landscape)
        let l = [UInt8](try Data(contentsOf: out.appendingPathComponent("Print Files/square.pict")))
        #expect(try PrintPICTValidator.validate(l).record.profile.orientation == .portrait)
        #expect(q.entries.filter(\.exported).count == 5)
        #expect(q.unexportedChanges == 0)
        // Exported once: Export All doesn't ask about them again.
        await q.exportAll()
        #expect(q.question == .taken(["IMG_2.jpg", "IMG_10.jpg", "landscape-4x3.jpg", "portrait-3x4.jpg", "square.png"]))
        await q.answer(.cancel)
    }

    @Test func sameNameTwiceInTheQueueIsNumbered() async throws {
        let q = queue()
        let a = try folder("a"), b = try folder("b")
        try FileManager.default.copyItem(at: Fixtures.url("landscape-4x3.jpg"), to: a.appendingPathComponent("IMG_1.jpg"))
        try FileManager.default.copyItem(at: Fixtures.url("portrait-3x4.jpg"), to: b.appendingPathComponent("IMG_1.jpg"))
        await q.add([a, b])
        let out = try exportFolder(q)
        await seeAll(q)
        await q.exportAll()
        #expect(q.question == nil)
        #expect(q.summary?.renumbered == ["IMG_1.jpg"])
        let names = try FileManager.default.contentsOfDirectory(atPath: out.appendingPathComponent("Print Files").path).sorted()
        #expect(names == ["IMG_1 2.pict", "IMG_1.pict"])
    }

    @Test func takenNamesAreAskedAboutOnce() async throws {
        let q = queue()
        await q.add([try mixedFolder()])
        let out = try exportFolder(q)
        await seeAll(q)
        await q.exportAll()
        let first = try Data(contentsOf: out.appendingPathComponent("Print Files/square.pict"))

        await q.exportAll()
        #expect(q.question == .taken(["IMG_2.jpg", "IMG_10.jpg", "landscape-4x3.jpg", "portrait-3x4.jpg", "square.png"]))
        await q.answer(.cancel)
        #expect(q.summary == nil || q.summary?.exported.isEmpty == true)
        #expect(try Data(contentsOf: out.appendingPathComponent("Print Files/square.pict")) == first)

        await q.exportAll(); await q.answer(.skipTaken)
        #expect(q.summary?.skipped.count == 5 && q.summary?.exported.isEmpty == true)

        await q.exportAll(); await q.answer(.keepBoth)
        #expect(FileManager.default.fileExists(atPath: out.appendingPathComponent("Print Files/square 2.pict").path))

        await q.exportAll(); await q.answer(.replace)
        #expect(q.summary?.exported.count == 5)
        #expect(!FileManager.default.fileExists(atPath: out.appendingPathComponent("Print Files/square 3.pict").path))
    }

    @Test func oneFailureDoesntStopTheRest() async throws {
        let q = queue()
        let f = try mixedFolder()
        await q.add([f])
        _ = try exportFolder(q)
        await seeAll(q)
        // Taken away after adding: that one fails, the others export.
        try FileManager.default.removeItem(at: f.appendingPathComponent("IMG_10.jpg"))
        await q.exportAll()
        let s = try #require(q.summary)
        #expect(s.failed.map(\.name) == ["IMG_10.jpg"])
        #expect(s.failed.first?.reason == "the file isn't there.")
        #expect(s.exported.count == 4)
    }

    @Test func stopFinishesThePhotographInHand() async throws {
        let q = queue()
        await q.add([try mixedFolder()])
        _ = try exportFolder(q)
        await seeAll(q)
        let run = Task { await q.exportAll() }
        while q.progress == nil { await Task.yield() }
        q.stop()
        await run.value
        let s = try #require(q.summary)
        #expect(s.stopped && s.exported.count >= 1 && s.exported.count < 5)
    }

    @Test func sourcesAreNeverWritten() async throws {
        let q = queue()
        let f = try mixedFolder()
        func hashes() throws -> [String: String] {
            var h = [String: String]()
            for n in try FileManager.default.contentsOfDirectory(atPath: f.path) {
                h[n] = SHA256.hash(data: try Data(contentsOf: f.appendingPathComponent(n))).description
            }
            return h
        }
        let before = try hashes()
        await q.add([f])
        _ = try exportFolder(q)
        await seeAll(q)
        q.editor.setZoom(3)
        await q.exportAll()
        #expect(try hashes() == before)
    }

    @Test func removingOnlyLeavesTheQueue() async throws {
        let q = queue()
        let f = try mixedFolder()
        await q.add([f])
        let id = q.entries.first { $0.name == "square.png" }!.id
        await q.select(id)
        q.remove([id])
        #expect(q.editor.photo == nil && q.editingID == nil)
        #expect(FileManager.default.fileExists(atPath: f.appendingPathComponent("square.png").path))
        q.removeAll()
        #expect(q.entries.isEmpty)
    }

    @Test func unexportedChangesAreCounted() async throws {
        let q = queue()
        await q.add([try mixedFolder()])
        _ = try exportFolder(q)
        let id = q.entries.first { $0.name == "square.png" }!.id
        await q.select(id)
        #expect(q.unexportedChanges == 0)                          // looking isn't changing
        q.editor.setZoom(2)
        #expect(q.unexportedChanges == 1)
        await q.editor.export()
        #expect(q.unexportedChanges == 0 && q.entries.first { $0.id == id }!.exported)
    }

    @Test func smallIsWorkedOutWithoutRendering() async throws {
        let q = queue()
        await q.add([try mixedFolder()])
        let small = q.entries.first { $0.name == "IMG_2.jpg" }!
        let big = q.entries.first { $0.name == "landscape-4x3.jpg" }!
        #expect(q.isSmall(small) && !q.isSmall(big))
    }

    /// Memory stays flat over a long batch (PH67): 200 photographs of
    /// 12 megapixels, each decoded only while it's exported. Run on its own
    /// (other tests in parallel move the footprint), and it takes a while:
    ///     MPU_MEMORY_TEST=1 tools/test.sh --filter memoryStaysFlat
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MPU_MEMORY_TEST"] != nil))
    func memoryStaysFlat() async throws {
        let f = try folder("many")
        for i in 1...200 {
            try FileManager.default.copyItem(at: Fixtures.url("landscape-4x3.jpg"),
                                             to: f.appendingPathComponent(String(format: "P%03d.jpg", i)))
        }
        let q = queue()
        await q.add([f])
        #expect(q.entries.count == 200)
        _ = try exportFolder(q)
        q.settings.outputs = [.screen]
        await q.select(q.entries[0].id)                            // the editor holds one
        let before = footprint()
        var peak = before
        let sampler = Task {
            while !Task.isCancelled {
                peak = max(peak, footprint())
                try? await Task.sleep(for: .milliseconds(20))
            }
        }
        await q.exportAll()
        if case .unseen = q.question { await q.answer(.exportUnseen) }
        sampler.cancel()
        #expect(q.summary?.exported.count == 200)
        let grew = peak - before
        // One 12 MP grey photograph is 12 MB; all 200 would be 2.4 GB.
        print("memoryStaysFlat: before \(before / 1_000_000) MB, peak \(peak / 1_000_000) MB, after \(footprint() / 1_000_000) MB")
        #expect(grew < 150_000_000, "grew by \(grew / 1_000_000) MB")
    }

    func footprint() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let r = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return r == KERN_SUCCESS ? Int(info.phys_footprint) : 0
    }
}
