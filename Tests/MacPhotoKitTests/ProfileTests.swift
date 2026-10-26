import Testing
@testable import MacPhotoKit

/// The fixed print profiles (SPECIFICATION.md §2, §11 "Print tests") and
/// the screen and MacPaint sizes (§7).
struct ProfileTests {
    @Test(arguments: [
        (Orientation.portrait, PrintResolution.ppi300, 750, 1050),
        (.landscape, .ppi300, 1050, 750),
        (.portrait, .ppi360, 900, 1260),
        (.landscape, .ppi360, 1260, 900),
    ])
    func pixels(_ o: Orientation, _ r: PrintResolution, _ w: Int, _ h: Int) {
        let p = PrintProfile(orientation: o, resolution: r).pixels
        #expect(p.width == w && p.height == h)
    }

    @Test func defaultIs300() {
        #expect(PrintProfile(orientation: .portrait).resolution == .ppi300)
    }

    @Test(arguments: Orientation.allCases, PrintResolution.allCases)
    func physicalSizeAndAspect(_ o: Orientation, _ r: PrintResolution) {
        let p = PrintProfile(orientation: o, resolution: r)
        let (w, h) = p.pixels
        // Exactly 2.5 x 3.5 in at the stated PPI, and exactly 5:7 (or 7:5).
        #expect(w * 100 == p.hundredths.width * r.ppi)
        #expect(h * 100 == p.hundredths.height * r.ppi)
        #expect(o == .portrait ? w * 7 == h * 5 : w * 5 == h * 7)
    }

    @Test func orientationSwapsSidesOnly() {
        for r in PrintResolution.allCases {
            let p = PrintProfile(orientation: .portrait, resolution: r).pixels
            let l = PrintProfile(orientation: .landscape, resolution: r).pixels
            #expect(p.width == l.height && p.height == l.width)
        }
    }

    @Test func onlyTwoResolutions() {
        #expect(PrintResolution.allCases.map(\.ppi) == [300, 360])
    }

    @Test func screenAndPage() {
        #expect(ScreenImage.width == 512 && ScreenImage.height == 342 && ScreenImage.rowBytes == 64)
        #expect(MacPaintPage.width == 576 && MacPaintPage.height == 720 && MacPaintPage.rowBytes == 72)
        #expect(ScreenImage.width <= MacPaintPage.width && ScreenImage.height <= MacPaintPage.height)
    }

    @Test func macPaintPlacementIsCentred() {
        let o = MacPaintPage.screenOrigin
        #expect(o.x == 32 && o.y == 189)
        #expect(o.x % 8 == 0)                                   // byte-aligned
        #expect(o.x * 2 + ScreenImage.width == MacPaintPage.width)
        #expect(o.y * 2 + ScreenImage.height == MacPaintPage.height)
    }
}
