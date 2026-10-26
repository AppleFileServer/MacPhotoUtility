# Testing

## 1. Automated tests

    tools/test.sh          # swift test, naming the SDK

Phase 0: `ProfileTests`. The four print sizes, 360 PPI by default (PH19),
exactly 2.5 × 3.5 in and 5:7 at both resolutions, orientation swapping
the sides only, only two resolutions, the screen and MacPaint sizes.

Phase 1 (45 tests in all):
- `DitherTests`: hand-worked cases for Atkinson, rounding towards zero,
  Floyd–Steinberg, serpentine, the error reaching later rows, the tone
  table and the sharpening, each worked out in the test's comment; flat
  white and black; same input, same bits.
- `ImporterTests`: every kind; all eight EXIF orientations against the
  generator's own definitions; colour to grey; transparency; 16-bit; each
  error; a cut-off JPEG and PNG; the sources' SHA-256 and dates unchanged;
  exact turns and mirrors.
- `CompositionTests`: default orientation and crops, the shape within a
  pixel, clamping, turning, and rectangles mapped back through turns.
- `RendererTests`: the four print sizes, the same framing at 300 and
  360 PPI, placement, flat grey, turned photographs, the screen image
  independent of the print crop, the warnings. Not byte for byte (vImage
  may change between macOS versions); the ditherer underneath is.

Phase 2 (70 tests in all):
- `PackBitsTests`: Apple's example byte for byte (TN 1023); long runs;
  random round trips; strict unpacking; CRC-32 against zlib.
- `ScreenPICTTests`, `MacPaintTests`, `PrintPICTTests`: round trips
  (all four print sizes), the layout byte by byte where it's fixed, the
  MacPaint placement, a noisy 360 PPI print's size, and damage refused.
- `ExporterTests`: the three files and the manifest; only some kinds;
  stop, keep both and replace; a failed check leaving nothing; a damaged
  manifest stopping the export; warnings per file; Mac-safe names.
- `FixtureTests`: every file in `Fixtures/handoff/` is in its README with
  the right SHA-256; the good ones pass, the bad ones fail.

The harness: `swift build`, then `.build/debug/mpu profiles`, `convert`,
`compare`, `export`, `validate`, `fixtures`, `testimages` (usage: `mpu`
with no arguments).

**Cross-check (once, 26 Oct, recorded in `PHASE-1-REPORT.md`):** the
Atkinson output on three photographs matched an integer version of
`../image-tools/atkinson.py`'s loop pixel for pixel.

## 2. Test images (PH31)

Synthetic, drawn by `MacPhotoTestSupport` into a temporary folder when
the tests run (`mpu testimages DIR` writes them for looking at), so
they're reproducible and nobody's photographs go into the repository.
Each pattern has a grid in eighths, a centre square and an "F" so crop,
flips and rotation are visible.

| Image | Size | Tests |
|---|---|---|
| landscape-4x3.jpg | 4000 × 3000 | landscape; crop to 7:5 |
| portrait-3x4.jpg | 3000 × 4000 | portrait; crop to 5:7 |
| square.png | 3000 × 3000 | both orientations crop |
| panorama.jpg | 6000 × 2000 | extreme aspect |
| exif-1.jpg … exif-8.jpg | 600 × 400 upright, four grey quarters | every EXIF orientation |
| colour.heic | 4032 × 3024 | HEIC; colour to grey |
| grey-16bit.tiff | 2000 × 1500 | TIFF; 16-bit grey source |
| ramp.png | 1050 × 750 | a grey ramp: tone and dithering |
| small.jpg | 640 × 480 | smaller than the output (PQ7) |
| transparent.png | 400 × 300 | transparency onto white |
| unsupported.gif | 200 × 150 | a kind refused |
| bad-truncated.jpg, bad-empty.png, bad-text.jpg | — | clear errors |

Expected outputs: print 750 × 1050 / 1050 × 750 (300 PPI) and
900 × 1260 / 1260 × 900 (360 PPI), 8-bit; screen 512 × 342, 1-bit.

## 3. Real-hardware tests (Jack, on the Plus)

Specification §11's list (opening a screen PICT, a MacPaint file,
appearance, portrait and landscape, the screensaver, and later the 8-bit
print PICT in MacPhoto). The files go over with the Macintosh Transfer
Utility. Each run is recorded in `COMPATIBILITY.md` with the date and what was seen.
None has run yet.
