# Phase 1 plan: the conversion engine

**Status: approved by Jack, 26 October 2026, with the dither comparison
added (PH32).** PH20–PH32 are in `DECISIONS.md` as Provisional, until
Phase 1's tests and Jack's look at the results confirm them.

**Deliverable** (specification §12): `mpu convert` turns one photograph
into both canonical images in memory: the 8-bit print image at the
selected size, and the 1-bit 512 × 342 Atkinson screen image. No file
formats yet (that's Phase 2). The harness writes PNG previews so the
results can be looked at; they are diagnostics, not a product.

## Decisions proposed

| Code | Decision |
|---|---|
| PH20 | **Two in-memory images.** `GreyImage`: width, height, one byte per pixel, **0 black … 255 white** (Gray Gamma 2.2), rows without padding. `BitImage`: 512 × 342, 64 bytes per row, **1 = black**, as QuickDraw and the screen PICT. The Mac's "0 = white" for the 8-bit PICT is applied only by the Phase 2 writer, in one place. |
| PH21 | **Import by content, four kinds only.** ImageIO identifies the file from its bytes; JPEG, HEIC/HEIF, PNG and TIFF are accepted, anything else is refused with its type named (even if ImageIO could read it). The extension is ignored. The first image in the file is used (a HEIC's primary image). The file is opened read-only and never written. |
| PH22 | **Greyscale as PH9**, plus: transparency is flattened onto **white**; 16-bit sources are reduced to 8-bit by CoreGraphics; a colour photograph uses its own embedded profile (Display P3, sRGB, …), or sRGB when it has none. |
| PH23 | **Orientation by exact pixel moves.** The image is decoded as stored and converted to grey; then the EXIF orientation (all eight cases) and the user's quarter turns are applied as exact moves of whole pixels (vImage rotate and mirror), never by resampling. The result is the **upright image**, which everything below refers to. |
| PH24 | **Composition stored independently of window and PPI.** Per photograph: the quarter turns (0–3), the print orientation, and two crops, **print** (5:7 or 7:5) and **screen** (256:171, i.e. 512:342), each held as a **centre** (fractions 0–1 of the upright image's width and height) and a **zoom** (1 = the largest crop of that shape that fits in the image; up to 8). PPI appears nowhere in it, so switching 300 ↔ 360 can't change the framing. |
| PH25 | **Crops stay inside the photograph.** Zoom can't go below 1 and the centre is clamped, so neither output ever gets margins or invented pixels (PH13 for the screen; specification §2 "do not stretch" for the print). What the crop leaves out is visible in the editor (Phase 3) as the crop boundary. |
| PH26 | **Defaults for a new photograph:** print orientation **landscape if the upright image is wider than tall, otherwise portrait** (a square one is portrait); both crops centred at zoom 1. Changing orientation or turning the photograph keeps each crop's centre (turned with it) and zoom, then clamps. |
| PH27 | **Crop to pixels:** each crop's edges are rounded to whole source pixels before resampling, so the output's shape can be off by **less than one source pixel** across the whole photograph: invisible, but documented, since it's the only departure from an exact 5:7. |
| PH28 | **Resampling as PH10:** vImage Lanczos (high-quality) from the cropped pixels straight to the output size, separately for print and screen, on the gamma-encoded values (as Photoshop does by default). The screen image is never made from the print image (specification §7). |
| PH29 | **Atkinson exactly as PH10**, in integers: the error is `old − new` and each of the six neighbours gets `error / 8`, rounded **towards zero** (Swift's `/`). No tone change before dithering in this phase (the specification has no brightness or contrast controls; see PQ9). |
| PH30 | **Small-photograph warning (PH14) per output:** the print crop is fewer source pixels than 750 × 1050 / 900 × 1260 (at the selected PPI) in either direction, or the screen crop fewer than 512 × 342. A warning on the result, never a refusal. At the 360 PPI default a portrait print crop needs at least 900 × 1260 source pixels: any phone photo of the last decade has that, unless zoomed in a long way. |
| PH32 | **A dither comparison before the method is settled.** Atkinson stays the default (specification §7). Alongside it, as options of one ditherer: **Floyd–Steinberg** (7, 3, 5, 1 sixteenths, integers rounded towards zero), **serpentine** scanning (odd rows right to left, the kernel mirrored), a **linear-light tone curve** (the gamma-encoded grey converted to linear light by a fixed 256-entry table before dithering, since dot coverage on a 1-bit screen is linear) and **light sharpening** (an integer unsharp mask on the 512 × 342 grey image: a 3 × 3 box blur, amount ½). Every option is deterministic. `mpu compare` makes a labelled sheet of eight versions of one photograph; Jack chooses by eye, ideally after seeing a couple on the Plus. Anything other than plain Atkinson then becomes a recorded decision departing from the specification. |
| PH31 | **Test images are generated, not stored.** A small library target, `MacPhotoTestSupport`, draws `TESTING.md` §2's images with CoreGraphics (grid, centre mark, an "F" made of rectangles so no font is involved) and writes them with ImageIO, including the eight EXIF orientations, into a temporary folder for the tests. `mpu testimages DIR` writes the same set for looking at. No one's photographs go into the repository. |

## Steps

Each step builds and passes its tests before the next.

1. **Images and dithering.** `GreyImage`, `BitImage`, the ditherer with
   PH32's options (Atkinson by default). Floyd–Steinberg, serpentine, the
   tone table and the sharpening each get a hand-worked case too.
   Tests: a hand-worked 4 × 3 case written out in the test file; all-white
   and all-black give no dots and all dots; 50% grey gives close to half
   black (Atkinson drops a quarter of the error, so mid-greys come out a
   little lighter or darker; the test states the expected count exactly);
   the same input twice gives identical bytes. Once, as a diagnostic in
   the scratchpad: compare with `../image-tools/atkinson.py`, which uses
   floating-point error, so the two should agree on almost every pixel but
   not all; the figure goes in the report.
2. **Test images** (PH31) and `mpu testimages`.
3. **Importer** (PH21–PH23). Errors, each a clear message: file missing;
   empty; not an image; an image of another kind (named); damaged or
   truncated (ImageIO's status checked, since a cut-off JPEG can decode
   with a grey bottom and no error); larger than 250 megapixels. Tests:
   every kind and every EXIF orientation comes out upright (the F's
   position checked pixel by pixel); colour to grey on known colours;
   transparency on white; the source files' SHA-256 and modification
   dates the same before and after.
4. **Composition** (PH24–PH27). Pure arithmetic, no images. Tests: the
   default crops for landscape, portrait, square and panorama; clamping;
   zoom limits; turning four times returns the same composition; the pixel
   rectangle's shape within one pixel of 5:7; **the same crop rectangle at
   300 and 360 PPI**.
5. **Renderers** (PH28, PH30). `PrintRenderer`: crop, Lanczos, exact size,
   8-bit. `ScreenRenderer`: its own crop, Lanczos to 512 × 342, Atkinson.
   Tests: the four sizes exactly; the grid lines and F where the crop puts
   them; a flat grey stays that grey (within one level) in the print; the
   warnings appear when they should and only then. The renderers aren't
   tested byte for byte (vImage may change between macOS versions);
   Atkinson is.
6. **Harness.** `mpu convert PHOTO [--ppi 300|360] [--orientation
   portrait|landscape] [--turns N] [--print-crop X,Y,ZOOM] [--screen-crop
   X,Y,ZOOM] [--preview DIR]`: prints the source, the composition, both
   pixel rectangles, the output sizes and any warnings; with `--preview`,
   writes `print.png` (8-bit grey, PPI recorded) and `screen.png` (1-bit).
   `mpu compare PHOTO --out DIR` (PH32): the screen crop's grey image and
   seven dithered versions, each shown at 2× with square pixels (as on a
   Retina screen) and labelled, on one sheet; also each version as its
   own 512 × 342 PNG.
7. **Documents and report.** `ARCHITECTURE.md`, `TESTING.md`,
   `DEVELOPMENT_PLAN.md`, `CHANGELOG.md` (D-0.0.2), `PHASE-1-REPORT.md`.
   Then you look at the previews from a few of your own photographs
   (read only, nothing copied into the repository) before Phase 1 counts
   as done.

## Files

| New | What |
|---|---|
| `MacPhotoKit/GreyImage.swift`, `BitImage.swift` | PH20 |
| `MacPhotoKit/Dither.swift` | PH29, PH32 |
| `MacPhotoKit/Importer.swift` | PH21–PH23, the errors |
| `MacPhotoKit/Composition.swift` | PH24–PH27 |
| `MacPhotoKit/PrintRenderer.swift`, `ScreenRenderer.swift` | PH28, PH30 |
| `MacPhotoTestSupport/TestImages.swift` | PH31 |
| `Tests/MacPhotoKitTests/…` | one file per step |

Frameworks: ImageIO, CoreGraphics, Accelerate (vImage), UniformTypeIdentifiers.
All are part of macOS; no packages are added.

## Not in Phase 1

File writers and validators, the manifest, safe names (Phase 2); the
window (Phase 3); batches (Phase 4); projects (Phase 5). Nothing goes near
the Plus, the SD card or Mini vMac in this phase.

## Open question

| Code | Question |
|---|---|
| PQ9 | **Folded into PH32's comparison.** Atkinson discards a quarter of each error, so it lightens highlights and darkens shadows: the classic Mac look, but photographs can lose detail at both ends. Would you want a simple brightness and contrast control for the **screen** image (never touching the print)? It isn't in the specification. Not needed for Phase 1; the previews will show whether it's worth it. |
