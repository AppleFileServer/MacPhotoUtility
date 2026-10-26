import Testing
@testable import MacPhotoKit
import MacPhotoTestSupport

/// The renderers (PH28, PH30). Checked on size, placement, tone and
/// warnings, not byte for byte: vImage's output may change between macOS
/// versions. The ditherer underneath is checked exactly in DitherTests.
struct RendererTests {
    static let landscape = try! Importer.load(Fixtures.url("landscape-4x3.jpg")).image
    static let square = try! Importer.load(Fixtures.url("square.png")).image

    @Test(arguments: [(Orientation.landscape, PrintResolution.ppi300, 1050, 750),
                      (.portrait, .ppi300, 750, 1050), (.landscape, .ppi360, 1260, 900),
                      (.portrait, .ppi360, 900, 1260)])
    func exactPrintSizes(o: Orientation, r: PrintResolution, w: Int, h: Int) {
        var c = Composition(uprightWidth: 4000, height: 3000)
        c.setOrientation(o)
        let p = PrintRenderer.render(Self.landscape, c, resolution: r)
        #expect(p.image.width == w && p.image.height == h)
        #expect(p.image.pixels.count == w * h)                    // 8-bit: one byte a pixel
        #expect(p.profile == PrintProfile(orientation: o, resolution: r))
    }

    @Test func ppiDoesNotChangeTheFraming() {
        var c = Composition(uprightWidth: 4000, height: 3000)
        c.printCrop = Crop(centreX: 0.4, centreY: 0.55, zoom: 1.6)
        let a = PrintRenderer.render(Self.landscape, c, resolution: .ppi300)
        let b = PrintRenderer.render(Self.landscape, c, resolution: .ppi360)
        #expect(a.source == b.source)
        // The same place in the picture: the centre square's edge lies at
        // the same fraction of the width in both.
        func firstBlack(_ g: GreyImage) -> Double {
            let y = g.height / 2
            let x = (0..<g.width).first { g[$0, y] < 128 && g[$0 + 1, y] < 128 && g[$0 + 2, y] < 128 }!
            return Double(x) / Double(g.width)
        }
        #expect(abs(firstBlack(a.image) - firstBlack(b.image)) < 0.002)
    }

    @Test func printShowsTheCrop() {
        // Square, portrait by default: columns 429–2571 of the photograph,
        // so the centre square is in the middle of the print, and photo
        // point (1687, 2062), halfway between grid lines both ways, lands
        // at print (529, 866) and is white.
        let p = PrintRenderer.render(Self.square, Composition(uprightWidth: 3000, height: 3000))
        #expect(p.image[450, 630] < 10)
        #expect(p.image[529, 866] > 245)
    }

    @Test func flatGreyStaysFlat() {
        let flat = GreyImage(width: 2000, height: 1500, grey: 137)
        let p = PrintRenderer.render(flat, Composition(uprightWidth: 2000, height: 1500))
        #expect(p.image.pixels.allSatisfy { abs(Int($0) - 137) <= 1 })
    }

    @Test func turnedPhotograph() {
        // Turned a quarter: the landscape becomes portrait, and the F (top
        // left upright) moves to the top right.
        var c = Composition(uprightWidth: 3000, height: 3000)
        c.turn()
        c.printCrop = Crop(centreX: 0.9, centreY: 0.1, zoom: 4)
        let p = PrintRenderer.render(Self.square, c)
        #expect(c.orientation == .landscape)
        #expect(p.image.width == 1260 && p.image.height == 900)
        let blacks = p.image.pixels.filter { $0 < 64 }.count
        #expect(blacks > 1000)                                      // the F is in the crop
    }

    @Test func screenImage() {
        let s = ScreenRenderer.render(Self.landscape, Composition(uprightWidth: 4000, height: 3000))
        #expect(s.bits.width == 512 && s.bits.height == 342 && s.bits.rowBytes == 64)
        #expect(s.grey.width == 512 && s.grey.height == 342)
        #expect(s.bits[256, 171])                                   // the centre square
        #expect(s.source == PixelRect(x: 0, y: 164, width: 4000, height: 2672))
        #expect(s.warnings.isEmpty)
    }

    @Test func screenIgnoresThePrintCrop() {
        var c = Composition(uprightWidth: 4000, height: 3000)
        let a = ScreenRenderer.render(Self.landscape, c)
        c.printCrop = Crop(centreX: 0.2, centreY: 0.3, zoom: 5)
        c.setOrientation(.portrait)
        #expect(ScreenRenderer.render(Self.landscape, c).bits == a.bits)
    }

    @Test func ditherOptionsReachTheScreen() {
        let c = Composition(uprightWidth: 1050, height: 750)
        let ramp = try! Importer.load(Fixtures.url("ramp.png")).image
        let plain = ScreenRenderer.render(ramp, c)
        let fs = ScreenRenderer.render(ramp, c, dither: DitherOptions(method: .floydSteinberg))
        #expect(plain.grey == fs.grey && plain.bits != fs.bits)
    }

    @Test func smallPhotographWarnings() throws {
        let small = try Importer.load(Fixtures.url("small.jpg")).image        // 640 × 480
        let c = Composition(uprightWidth: 640, height: 480)
        let p = PrintRenderer.render(small, c)                                 // 360 PPI: 1260 × 900
        #expect(p.warnings == [.smallForPrint(source: p.source, needed: (1260, 900))])
        #expect(ScreenRenderer.render(small, c).warnings.isEmpty)              // 640 × 427 ≥ 512 × 342

        var zoomed = Composition(uprightWidth: 4000, height: 3000)
        zoomed.printCrop.zoom = 4                                               // 1000 × 714
        zoomed.screenCrop.zoom = 8                                              // 500 × 334
        #expect(PrintRenderer.render(Self.landscape, zoomed, resolution: .ppi300).warnings.count == 1)
        #expect(ScreenRenderer.render(Self.landscape, zoomed).warnings.count == 1)
        zoomed.printCrop.zoom = 3                                               // 1333 × 952
        #expect(PrintRenderer.render(Self.landscape, zoomed).warnings.isEmpty)
    }
}
