import Foundation
import Testing
@testable import MacPhotoKit

/// The window's model (PH46) and the editing arithmetic (PH48).
@MainActor
struct EditorSessionTests {
    func session() -> EditorSession {
        let suite = "MacPhotoTests-\(UUID().uuidString)"
        return EditorSession(defaults: UserDefaults(suiteName: suite)!, previewDelay: .zero)
    }

    func freshFolder() throws -> URL {
        let f = FileManager.default.temporaryDirectory.appendingPathComponent("session-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: f, withIntermediateDirectories: true)
        return f
    }

    @Test func openGivesWorkingCopyAndPreviews() async {
        let s = session()
        await s.open(Fixtures.url("landscape-4x3.jpg"))
        #expect(s.photo?.image.width == 4000)
        #expect(s.working?.width == 2000 && s.working?.height == 1500)       // PH49
        #expect(s.composition?.orientation == .landscape)
        await s.previewsSettled()
        #expect(s.printPreview?.image.width == 1260)                           // 360 PPI by default
        #expect(s.screenPreview?.bits.width == 512)
        #expect(!s.isRendering)
    }

    @Test func openErrorIsAMessage() async {
        let s = session()
        await s.open(Fixtures.url("bad-truncated.jpg"))
        #expect(s.photo == nil)
        #expect(s.message?.detail.contains("ends before the picture does") == true)
    }

    @Test func editingTheRightCrop() async {
        let s = session()
        await s.open(Fixtures.url("landscape-4x3.jpg"))
        s.editing = .screen
        s.setZoom(2)
        s.move(dx: 0.1, dy: 0)
        #expect(s.composition?.screenCrop == Crop(centreX: 0.6, centreY: 0.5, zoom: 2))
        #expect(s.composition?.printCrop == .centred)
        s.move(dx: 5, dy: -5)                                                   // far past the corner
        let c = s.composition!.screenCrop
        #expect(c.centreX == 0.75 && c.zoom == 2)
        s.resetCrop()
        #expect(s.composition?.screenCrop == .centred)
    }

    @Test func turningAndOrientation() async {
        let s = session()
        await s.open(Fixtures.url("landscape-4x3.jpg"))
        s.turn(by: 1)
        #expect(s.composition?.quarterTurns == 1 && s.composition?.orientation == .portrait)
        #expect(s.turnedWorkingSize! == (1500, 2000))
        #expect(s.turnedWorking?.width == 1500 && s.turnedWorking?.height == 2000)
        s.setOrientation(.landscape)
        await s.previewsSettled()
        #expect(s.printPreview?.image.width == 1260 && s.printPreview?.image.height == 900)
    }

    @Test func ppiChangeRerendersWithoutChangingTheCrop() async {
        let s = session()
        await s.open(Fixtures.url("landscape-4x3.jpg"))
        await s.previewsSettled()
        let crop = s.printPreview!.source
        s.settings.resolution = .ppi300
        await s.previewsSettled()
        #expect(s.printPreview?.image.width == 1050)
        #expect(s.printPreview?.source == crop)
    }

    @Test func smallPhotographWarningIsLive() async {
        let s = session()
        await s.open(Fixtures.url("small.jpg"))
        await s.previewsSettled()
        #expect(s.printWarnings.count == 1 && s.screenWarnings.isEmpty)
        s.editing = .screen
        s.setZoom(3)
        await s.previewsSettled()
        #expect(s.screenWarnings.count == 1)
    }

    @Test func exportAndConflict() async throws {
        let s = session()
        s.settings.destination = try freshFolder()
        await s.open(Fixtures.url("landscape-4x3.jpg"))
        #expect(s.canExport)
        await s.export()
        #expect(s.lastExport?.files.count == 2)                                  // print and screen
        await s.export()
        #expect(s.conflict?.count == 2)
        await s.resolveConflict(nil)                                             // Cancel
        #expect(s.conflict == nil)
        await s.export()
        await s.resolveConflict(.keepBoth)
        #expect(s.lastExport?.files.first?.path == "Print Files/landscape-4x3 2.pict")
    }

    @Test func exportNeedsAFolder() async {
        let s = session()
        await s.open(Fixtures.url("landscape-4x3.jpg"))
        #expect(!s.canExport)
        await s.export()
        #expect(s.message?.title == "Nothing to export yet.")
    }

    @Test func settingsAreRemembered() {
        let suite = "MacPhotoTests-\(UUID().uuidString)"
        let a = EditorSession(defaults: UserDefaults(suiteName: suite)!)
        a.settings.resolution = .ppi300
        a.settings.outputs = [.macPaint]
        a.settings.destination = URL(fileURLWithPath: "/tmp/somewhere")
        let b = EditorSession(defaults: UserDefaults(suiteName: suite)!)
        #expect(b.settings == a.settings)
    }

    @Test func fractionsForDrawing() {
        var c = Composition(uprightWidth: 4000, height: 3000)
        let f = c.fractions(.print, uprightWidth: 4000, height: 3000)
        #expect(f.x == 0 && f.width == 1 && abs(f.height - 2857.142857 / 3000) < 1e-6)
        c.setZoom(.print, 2, uprightWidth: 4000, height: 3000)
        let g = c.fractions(.print, uprightWidth: 4000, height: 3000)
        #expect(abs(g.x - 0.25) < 1e-9 && abs(g.width - 0.5) < 1e-9)
        c.setZoom(.print, 99, uprightWidth: 4000, height: 3000)
        #expect(c.printCrop.zoom == Crop.maxZoom)
    }
}
