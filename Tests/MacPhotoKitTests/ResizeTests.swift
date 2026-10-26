import Testing
@testable import MacPhotoKit

/// Resizing a crop by a corner, its shape kept (PH58).
struct ResizeTests {
    // 4000 × 3000, landscape print (7:5): full width at zoom 1, 4000 × 2857.1.
    let w = 4000, h = 3000

    func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }

    @Test func oppositeCornerStays() {
        var c = Composition(uprightWidth: w, height: h)
        c.setZoom(.print, 2, uprightWidth: w, height: h)                 // 2000 × 1428.6, centred
        let before = c.fractions(.print, uprightWidth: w, height: h)
        // Drag the bottom-right corner inwards to x = 0.6: 400 px narrower.
        c.resize(.print, corner: .bottomRight, to: (0.6, 0.5), uprightWidth: w, height: h)
        let after = c.fractions(.print, uprightWidth: w, height: h)
        #expect(near(after.x, before.x) && near(after.y, before.y))      // top-left unchanged
        #expect(near(after.width * 4000, 1400))                           // 0.6 × 4000 − 1000
        #expect(near(after.width * 4000 / (after.height * 3000), 1.4))    // still 7:5
        #expect(near(c.printCrop.zoom, 4000 / 1400))
    }

    @Test func followsTheLargerMovement() {
        var c = Composition(uprightWidth: w, height: h)
        c.setZoom(.print, 4, uprightWidth: w, height: h)                 // 1000 × 714.3
        let f = c.fractions(.print, uprightWidth: w, height: h)
        // Top-left corner dragged a little left but a long way up: height wins.
        let anchorY = (f.y + f.height) * 3000
        c.resize(.print, corner: .topLeft, to: (f.x - 0.01, (anchorY - 1000) / 3000), uprightWidth: w, height: h)
        let g = c.fractions(.print, uprightWidth: w, height: h)
        #expect(near(g.height * 3000, 1000) && near((g.y + g.height) * 3000, anchorY))
    }

    @Test func limits() {
        var c = Composition(uprightWidth: w, height: h)
        c.setZoom(.print, 2, uprightWidth: w, height: h)
        // Far outwards: no bigger than the room to the edge from the anchor.
        c.resize(.print, corner: .bottomRight, to: (5, 5), uprightWidth: w, height: h)
        let f = c.fractions(.print, uprightWidth: w, height: h)
        #expect(f.x + f.width <= 1 + 1e-9 && f.y + f.height <= 1 + 1e-9)
        #expect(c.printCrop.zoom >= 1)
        // Past the anchor: no smaller than zoom 8.
        c.resize(.print, corner: .bottomRight, to: (-1, -1), uprightWidth: w, height: h)
        #expect(near(c.printCrop.zoom, Crop.maxZoom))
    }

    @Test func screenCropKeepsItsShape() {
        var c = Composition(uprightWidth: w, height: h)
        c.resize(.screen, corner: .topRight, to: (0.7, 0.4), uprightWidth: w, height: h)
        let f = c.fractions(.screen, uprightWidth: w, height: h)
        #expect(near(f.width * 4000 / (f.height * 3000), 512.0 / 342.0))
        #expect(c.printCrop == .centred)                                 // the other crop untouched
    }

    @MainActor @Test func theSessionResizesTheCropBeingEdited() async {
        let s = EditorSession(defaults: .init(suiteName: "MacPhotoTests-resize")!, previewDelay: .zero)
        await s.open(Fixtures.url("landscape-4x3.jpg"))
        s.editing = .screen
        s.resize(corner: .bottomLeft, to: (0.5, 0.5))
        #expect(s.composition!.screenCrop.zoom > 1 && s.composition!.printCrop == .centred)
    }
}
