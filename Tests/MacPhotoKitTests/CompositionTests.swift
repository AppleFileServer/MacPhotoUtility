import Testing
@testable import MacPhotoKit

/// The framing arithmetic (PH24–PH27): no images except for the turns.
struct CompositionTests {
    @Test(arguments: [(4000, 3000, Orientation.landscape), (3000, 4000, .portrait),
                      (3000, 3000, .portrait), (6000, 2000, .landscape), (2000, 6000, .portrait)])
    func defaultOrientation(w: Int, h: Int, o: Orientation) {
        let c = Composition(uprightWidth: w, height: h)
        #expect(c.orientation == o && c.quarterTurns == 0)
        #expect(c.printCrop == .centred && c.screenCrop == .centred)
    }

    @Test func defaultPrintCrops() {
        // 4:3 is wider than 7:5? No (1.333 < 1.4): the crop is the full
        // width, 4000 × 2857.1, centred: rows 71.4–2928.6, rounded.
        #expect(Composition(uprightWidth: 4000, height: 3000).printRect(uprightWidth: 4000, height: 3000)
                == PixelRect(x: 0, y: 71, width: 4000, height: 2858))
        // A panorama: the full height, 2800 × 2000, centred.
        #expect(Composition(uprightWidth: 6000, height: 2000).printRect(uprightWidth: 6000, height: 2000)
                == PixelRect(x: 1600, y: 0, width: 2800, height: 2000))
        // Square, portrait: 2142.9 × 3000, columns 428.6–2571.4.
        #expect(Composition(uprightWidth: 3000, height: 3000).printRect(uprightWidth: 3000, height: 3000)
                == PixelRect(x: 429, y: 0, width: 2142, height: 3000))
    }

    @Test func defaultScreenCrop() {
        // 512:342 is wider than 4:3, so the full width: 4000 × 2671.9.
        let r = Composition(uprightWidth: 4000, height: 3000).screenRect(uprightWidth: 4000, height: 3000)
        #expect(r == PixelRect(x: 0, y: 164, width: 4000, height: 2672))
    }

    @Test(arguments: [(4000, 3000), (3000, 4000), (3000, 3000), (6000, 2000), (641, 479), (1001, 999)])
    func shapeWithinOnePixel(w: Int, h: Int) {
        for o in Orientation.allCases {
            for zoom in [1.0, 1.7, 3.3, 8] {
                var c = Composition(uprightWidth: w, height: h)
                c.setOrientation(o)
                c.printCrop = Crop(centreX: 0.37, centreY: 0.61, zoom: zoom)
                let r = c.printRect(uprightWidth: w, height: h)
                let s = Composition.size(aspect: Composition.printAspect(o), zoom: zoom, in: w, h)
                #expect(abs(Double(r.width) - s.width) <= 1 && abs(Double(r.height) - s.height) <= 1)
                #expect(r.x >= 0 && r.y >= 0 && r.x + r.width <= w && r.y + r.height <= h)
            }
        }
    }

    @Test func cropsStayInside() {
        var c = Composition(uprightWidth: 4000, height: 3000)
        c.printCrop = Crop(centreX: 0, centreY: 1, zoom: 2)            // pushed past the corner
        let r = c.printRect(uprightWidth: 4000, height: 3000)
        #expect(r.x == 0 && r.y + r.height == 3000 && r.width == 2000)
        c.printCrop = Crop(centreX: 0.5, centreY: 0.5, zoom: 0.25)     // zoomed out too far
        #expect(c.printRect(uprightWidth: 4000, height: 3000).width == 4000)
        let clamped = Composition.clamped(Crop(zoom: 50), aspect: 1.4, in: 4000, 3000)
        #expect(clamped.zoom == Crop.maxZoom)
        let nan = Composition.clamped(Crop(centreX: .nan, centreY: .infinity, zoom: .nan),
                                      aspect: 1.4, in: 4000, 3000)
        #expect(nan == .centred)                                       // nonsense falls back to centred
    }

    @Test func turning() {
        var c = Composition(uprightWidth: 4000, height: 3000)
        c.printCrop = Crop(centreX: 0.25, centreY: 0.375, zoom: 2)
        let start = c
        c.turn()
        #expect(c.quarterTurns == 1 && c.orientation == .portrait)
        #expect(c.printCrop == Crop(centreX: 0.625, centreY: 0.25, zoom: 2))
        #expect(c.turnedSize(uprightWidth: 4000, height: 3000) == (3000, 4000))
        c.turn(by: 3)
        #expect(c == start)
        c.turn(by: -1)
        #expect(c.quarterTurns == 3)
    }

    @Test func unturnedRectsPickTheSamePixels() {
        // A 7 × 5 picture with every pixel different.
        let u = GreyImage(width: 7, height: 5, pixels: (0..<35).map { UInt8($0) })
        for q in 0..<4 {
            let t = u.turned(q)
            for r in [PixelRect(x: 1, y: 1, width: 3, height: 2), PixelRect(x: 0, y: 2, width: 2, height: 3),
                      PixelRect(x: 0, y: 0, width: t.width, height: t.height)] {
                let back = r.unturned(q, turnedWidth: t.width, turnedHeight: t.height)
                #expect(u.cropped(back).turned(q) == t.cropped(r), "q \(q), \(r)")
            }
        }
    }
}
