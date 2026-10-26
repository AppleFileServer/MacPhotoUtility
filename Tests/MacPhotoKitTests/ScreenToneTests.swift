import Foundation
import Testing
@testable import MacPhotoKit

/// Brightness and contrast for the screen image only (PH57).
struct ScreenToneTests {
    @Test func neutralChangesNothing() {
        #expect(ScreenTone.neutral.table == (0...255).map { UInt8($0) })
    }

    @Test func byHand() {
        // contrast 50: (200 − 128) × 150 / 100 + 128 = 108 + 128 = 236.
        #expect(ScreenTone(brightness: 0, contrast: 50).table[200] == 236)
        // contrast 50 below mid-grey: (60 − 128) × 150 / 100 = −102 → 26.
        #expect(ScreenTone(brightness: 0, contrast: 50).table[60] == 26)
        // brightness 25: 25 × 128 / 100 = 32 levels lighter.
        #expect(ScreenTone(brightness: 25, contrast: 0).table[100] == 132)
        // brightness −100 and contrast −100: everything 128 − 128 = 0.
        #expect(ScreenTone(brightness: -100, contrast: -100).table.allSatisfy { $0 == 0 })
        // contrast 100 doubles about 128 and clips: 10 → 0, 250 → 255.
        let t = ScreenTone(brightness: 0, contrast: 100).table
        #expect(t[10] == 0 && t[250] == 255 && t[128] == 128 && t[140] == 152)
        // Out of range is held to ±100.
        #expect(ScreenTone(brightness: 500, contrast: -500) == ScreenTone(brightness: 100, contrast: -100))
    }

    @Test func alwaysInOrder() {
        for b in stride(from: -100, through: 100, by: 25) {
            for c in stride(from: -100, through: 100, by: 25) {
                let t = ScreenTone(brightness: b, contrast: c).table
                #expect(zip(t, t.dropFirst()).allSatisfy { $0 <= $1 }, "b \(b), c \(c)")
            }
        }
    }

    @Test func screenChangesPrintDoesNot() throws {
        let photo = try Importer.load(Fixtures.url("ramp.png")).image
        var c = Composition(uprightWidth: 1050, height: 750)
        let print0 = PrintRenderer.render(photo, c).image
        let screen0 = ScreenRenderer.render(photo, c)
        c.screenTone = ScreenTone(brightness: 30, contrast: 40)
        #expect(PrintRenderer.render(photo, c).image == print0)               // never the print
        let screen1 = ScreenRenderer.render(photo, c)
        #expect(screen1.bits != screen0.bits)
        #expect(screen1.bits.blackCount < screen0.bits.blackCount)              // lighter
        #expect(screen1.grey == c.screenTone.apply(screen0.grey))
    }

    @Test func savedWithTheCompositionAndOldManifestsStillRead() throws {
        var c = Composition(uprightWidth: 4000, height: 3000)
        c.screenTone = ScreenTone(brightness: -10, contrast: 20)
        let back = try JSONDecoder().decode(Composition.self, from: JSONEncoder().encode(c))
        #expect(back == c)
        // A composition as Phase 2 wrote it, with no screenTone.
        let old = #"{"quarterTurns":1,"orientation":"portrait","printCrop":{"centreX":0.5,"centreY":0.5,"zoom":1},"screenCrop":{"centreX":0.5,"centreY":0.5,"zoom":2}}"#
        let decoded = try JSONDecoder().decode(Composition.self, from: Data(old.utf8))
        #expect(decoded.screenTone == .neutral && decoded.quarterTurns == 1 && decoded.screenCrop.zoom == 2)
    }

    @MainActor @Test func theSessionAppliesIt() async {
        let s = EditorSession(defaults: UserDefaults(suiteName: "MacPhotoTests-\(UUID().uuidString)")!,
                              previewDelay: .zero)
        await s.open(Fixtures.url("ramp.png"))
        await s.previewsSettled()
        let before = s.screenPreview!.bits.blackCount, print = s.printPreview!.image
        s.setScreenTone(ScreenTone(brightness: 40, contrast: 0))
        await s.previewsSettled()
        #expect(s.screenPreview!.bits.blackCount < before)
        #expect(s.printPreview!.image == print)
    }
}
