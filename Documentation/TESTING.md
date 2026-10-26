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
- `NetpbmTests`: netpbm's `picttoppm` decodes every PICT fixture exactly as
  our validators do (skipped without netpbm: `brew install netpbm`).
- `FixtureTests`: every file in `Fixtures/handoff/` is in its README with
  the right SHA-256; the good ones pass, the bad ones fail.

Phase 3 (93 tests in all):
- `ResizeTests` (PH58): the opposite corner stays, the larger movement
  wins, the limits, the screen crop's shape, the session.
- `ScreenToneTests` (PH57): the table by hand, always in order, the print
  unchanged, saved with the composition, old manifests still read.
- `EditorSessionTests`: opening (working copy, previews), an open error
  as a message, editing the right crop and stopping at the edges, turning
  and orientation, a PPI change keeping the crop, the live small-photo
  warning, export with the conflict question (cancel, keep both), export
  without a folder, remembered settings, the crop fractions for drawing.

Phase 4 (107 tests in all):
- `PhotoQueueTests`: adding a mixed folder (order, skipped files, the
  damaged one marked, thumbnails), no file twice, each photograph keeping
  its framing through selection and a shared PPI change, a file damaged
  after adding, Export All asking about unseen photographs and exporting
  each as framed, the same name twice numbered, the taken-names question
  (cancel, skip, keep both, replace), one failure not stopping the rest,
  Stop, sources unchanged, removing, unexported changes counted, small
  worked out without rendering.
- `memoryStaysFlat`: 200 twelve-megapixel photographs exported; run on its
  own, as it's slow and other tests move the footprint:
  `MPU_MEMORY_TEST=1 tools/test.sh --filter memoryStaysFlat`.

Phase 5 (115 tests in all):
- `ProjectTests`: fingerprints on adding; a round trip of everything
  (order, framing, seen, settings, history, nothing photographic in the
  file); a photograph moved and one renamed found by bookmark; one
  deleted, kept as missing with its framing, found in a backup folder and
  shown in the editor; a different file of the same name refused unless
  confirmed, and the choice remembered; damaged, newer and absent project
  files refused with the open project untouched; unknown fields ignored;
  what counts as unsaved.

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

## 4. The window, by hand (Phase 3)

`tools/build-app.sh`, then open `build/MacPhoto Utility.app`. Check:
1. Empty window: the three areas, "No photograph open", Export disabled.
2. Open a landscape and a portrait photograph (⌘O, drag onto the window,
   drag onto the Dock icon): upright, details right, previews appear.
3. Print crop: drag, zoom (slider, pinch, scroll wheel), Reset; the print
   preview follows, the screen preview doesn't.
4. Screen crop (Tab or the switch): the same; the print preview doesn't
   change.
5. Turn left and right; Portrait/Landscape.
6. 300 ↔ 360 PPI: the print preview's size changes, its framing doesn't.
7. A small photograph: the warning under the print preview at once.
8. A damaged file: a message naming it; the open photograph stays.
9. Export to a chosen folder; export again: Keep Both is the default,
   Replace is red; Cancel leaves the folder alone.
10. Quit and reopen: the folder, PPI and files are remembered.
11. Brightness and contrast: the screen preview changes, the print
    doesn't; Normal puts both back to 0.
12. Drag each corner handle: the crop keeps its shape, the opposite
    corner stays, the zoom slider follows; it stops at the edges.
13. (Phase 4) Add a folder with photographs and other files: the others
    are listed as skipped; a damaged photograph is marked ✕.
14. Select several in turn and frame each differently; come back: each as
    left. Change the PPI: nobody's framing changes.
15. Export All with some not looked at: asked first. Again: asked about
    names already there; Keep Both is the default.
16. Export All on a long queue and press Stop: it finishes the photograph
    in hand and says so.
17. Change a photograph's framing and quit: asked first.
18. (Phase 5) Add photographs, frame one, ⌘S: the title shows the name,
    the edited mark goes. Quit: not asked.
19. Move one photograph, delete another (keeping a copy), double-click the
    project: told which moved and which is missing; the missing one keeps
    its framing; Locate in Folder… finds the copy and shows it.
20. Quit: Save / Don't Save / Cancel; Save keeps the new places.
21. With the app running, drag a photograph onto its Dock icon: it's
    added; the window stays.
22. (Phase 6) Dark appearance without changing the Mac:
    `open -a "build/MacPhoto Utility.app" --args -MPUAppearance dark`.
    Checked 26 Oct 2026: panels, lists, controls and captions follow it;
    the previews stay true grey and black and white.

## 5. Before a release (Phase 6)

    tools/check-fresh-checkout.sh     # a clone builds, tests, builds the app
    tools/make-release.sh             # refuses uncommitted changes

