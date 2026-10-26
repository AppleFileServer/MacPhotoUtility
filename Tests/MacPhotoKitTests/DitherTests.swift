import Testing
@testable import MacPhotoKit

/// The ditherer (PH29, PH32). The hand-worked cases are the proof; each is
/// worked out step by step in its comment.
struct DitherTests {
    /// "B" black, "W" white, one string per row.
    func rows(_ b: BitImage) -> [String] {
        (0..<b.height).map { y in String((0..<b.width).map { b[$0, y] ? "B" : "W" }) }
    }

    func row(_ values: [UInt8]) -> GreyImage {
        GreyImage(width: values.count, height: 1, pixels: values)
    }

    @Test func atkinsonByHand() {
        // 100 → black, error 100, 12 each to x1, x2 (112, 112).
        // 112 → black, error 112, 14 each to x2, x3 (126, 114).
        // 126 → black, error 126, 15 to x3 (129).
        // 129 → white.
        #expect(rows(Dither.dither(row([100, 100, 100, 100]))) == ["BBBW"])
    }

    @Test func atkinsonNegativeErrorRoundsTowardsZero() {
        // 140 → white, error −115, share −14 (rounding down would give −15)
        // to x1 and x2: x1 126, x2 113. x1: 126 → black, 15 to x2: 128 →
        // white. Rounding down, x2 would end at 127 and go black.
        #expect(rows(Dither.dither(row([140, 140, 127]))) == ["WBW"])
    }

    @Test func floydSteinbergByHand() {
        // 100 → black, error 100, 700/16 = 43 to x1 (143).
        // 143 → white, error −112, −784/16 = −49 to x2 (51).
        // 51 → black, error 51, 357/16 = 22 to x3 (122).
        // 122 → black.
        let b = Dither.dither(row([100, 100, 100, 100]),
                              options: DitherOptions(method: .floydSteinberg))
        #expect(rows(b) == ["BWBB"])
    }

    @Test func serpentineRunsOddRowsBackwards() {
        // Row 0 is white (no error). Row 1 run right to left gives the
        // mirror of atkinsonByHand's row.
        let image = GreyImage(width: 4, height: 2, pixels: [255, 255, 255, 255, 100, 100, 100, 100])
        #expect(rows(Dither.dither(image, options: DitherOptions(serpentine: true)))
                == ["WWWW", "WBBB"])
        #expect(rows(Dither.dither(image)) == ["WWWW", "BBBW"])
    }

    @Test func errorReachesTheNextRows() {
        // 2 × 3, all 100: (0,0) → black, 12 each to (1,0), (0,1), (1,1) and
        // (0,2). (1,0): 112 → black, 14 each to (0,1), (1,1): (0,1) is
        // 126, (1,1) 126; and 14 to (1,2): 114. (0,1): 126 → black, 15
        // each to (1,1) 141, (0,2) 127, (1,2) 129. (1,1): 141 → white,
        // −14 each to (0,2) 113, (1,2) 115. Row 2: 113 → black, 14 to
        // (1,2) 129 → white.
        let image = GreyImage(width: 2, height: 3, grey: 100)
        #expect(rows(Dither.dither(image)) == ["BB", "BW", "BW"])
    }

    @Test(arguments: DitherOptions.Method.allCases)
    func flatWhiteAndBlack(method: DitherOptions.Method) {
        let o = DitherOptions(method: method, serpentine: true)
        #expect(Dither.dither(GreyImage(width: 512, height: 342, grey: 255), options: o).blackCount == 0)
        #expect(Dither.dither(GreyImage(width: 512, height: 342, grey: 0), options: o).blackCount
                == 512 * 342)
    }

    @Test func midGreyIsAboutHalfBlack() {
        // Floyd–Steinberg keeps all the error, so a flat grey comes out at
        // very nearly its own share of black: 1 − 128/255 = 49.8%.
        let grey = GreyImage(width: 512, height: 342, grey: 128)
        let total = Double(512 * 342)
        let fs = Double(Dither.dither(grey, options: DitherOptions(method: .floydSteinberg)).blackCount)
        #expect(abs(fs / total - 0.498) < 0.01)
        // Atkinson drops a quarter of the error but stays near half on a
        // flat mid-grey.
        let at = Double(Dither.dither(grey).blackCount)
        #expect(abs(at / total - 0.5) < 0.05)
    }

    @Test func sameInputSameBits() {
        var g = GreyImage(width: 512, height: 342, grey: 0)
        for y in 0..<342 { for x in 0..<512 { g[x, y] = UInt8((x + y) % 256) } }
        for o in [DitherOptions(), DitherOptions(method: .floydSteinberg, serpentine: true,
                                                 linearTone: true, sharpen: true)] {
            #expect(Dither.dither(g, options: o) == Dither.dither(g, options: o))
        }
    }

    @Test func linearToneTable() {
        let t = Dither.linearToneTable
        #expect(t[0] == 0 && t[255] == 255)
        #expect(t[128] == 56)          // (128/255)^2.2 × 255 = 55.98
        #expect(zip(t, t.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test func linearToneDarkensMidGrey() {
        // 128 becomes 56 before dithering, so about 78% of dots are black.
        let grey = GreyImage(width: 512, height: 342, grey: 128)
        let b = Dither.dither(grey, options: DitherOptions(method: .floydSteinberg, linearTone: true))
        #expect(abs(Double(b.blackCount) / Double(512 * 342) - (1 - 56.0 / 255)) < 0.01)
    }

    @Test func sharpenByHand() {
        // One row, so every 3 × 3 neighbourhood is its row three times over.
        // x0: mean of 100,100,100 = 100 → 100.  x1: (100+100+150)×3/9 = 116
        // → 100 + (100−116)/2 = 92.  x2: (100+150+150)×3/9 = 133 → 150 +
        // 17/2 = 158.  x3: 150 → 150.
        #expect(Dither.sharpened(row([100, 100, 150, 150])).pixels == [100, 92, 158, 150])
        #expect(Dither.sharpened(GreyImage(width: 5, height: 5, grey: 77))
                == GreyImage(width: 5, height: 5, grey: 77))
    }

    @Test func bitImageLayout() {
        var b = BitImage(width: 512, height: 342)
        #expect(b.rowBytes == 64 && b.bytes.count == 64 * 342)
        b[0, 0] = true
        b[9, 1] = true
        #expect(b.bytes[0] == 0x80 && b.bytes[64 + 1] == 0x40)
        #expect(BitImage(width: 20, height: 1).rowBytes == 4)    // padded to even
    }
}
