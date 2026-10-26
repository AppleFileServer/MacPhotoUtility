# Phase 1 report (26 October 2026)

**D-0.0.2.** The conversion engine, as planned in `PHASE-1-PLAN.md`
(PH20–PH32). `mpu convert` turns one photograph into the 8-bit print
image and the 1-bit 512 × 342 screen image, in memory, with PNG previews.
45 tests pass (`tools/test.sh`).

## What was built

| Step | Result |
|---|---|
| 1 Images and dithering | `GreyImage`, `BitImage`; one ditherer: Atkinson by default, Floyd–Steinberg, serpentine, linear tone, sharpening (PH29, PH32) |
| 2 Test images | `MacPhotoTestSupport` and `mpu testimages`: 21 images, generated |
| 3 Importer | by content, four kinds; grey; EXIF; seven clear errors |
| 4 Composition | print and screen crops as centre and zoom; turns; pixel rectangles |
| 5 Renderers | print at the four exact sizes, screen at 512 × 342; warnings |
| 6 Harness | `mpu convert`, `mpu compare` |

## Found while building

- **ImageIO decodes a cut-off JPEG without complaint**, reporting it
  complete and filling the missing part with grey. The importer now also
  checks that a JPEG ends with its end-of-image marker and a PNG with its
  `IEND` chunk. TIFF and HEIC rely on ImageIO's own checks.
- **vImage's rotation constants mean what they say** (a first draft
  assumed the opposite; the hand-worked turn test caught it, and the eight
  EXIF tests, built from independent definitions, confirm the fix).
- **Turning a photograph by a quarter swaps portrait and landscape**,
  so the framing keeps its shape on the picture (added to PH26).
- **The cross-check:** on the owl, zebra and dandelion from
  `/Library/User Pictures` (Apple's, 512 × 512), the Atkinson output
  differs from `../image-tools/atkinson.py` in 14–31% of pixels but has
  the same share of black within 0.5%: that script carries the error in
  floating point, so dots land in different places. With its loop run in
  integers rounded towards zero (PH29), the two match **pixel for pixel**
  on all three.

## The dither comparison (PH32)

`mpu compare` sheets for the three photographs are in the session's
scratchpad (not the repository). First impressions on a Retina screen, not
on the Plus:
- **Linear tone** (4, 6, 8) is much too dark on every photograph.
  Physically correct for dot coverage, but not what the eye expects here.
- **Floyd–Steinberg** (7) keeps the mid-tones and the grey background
  closest to the original, and more texture in dark areas; grainier.
- **Plain Atkinson** (2) is the crispest, with brighter highlights and
  deeper shadows; it loses detail at both ends, as expected.
- Serpentine and sharpening make small differences at this size.

Then ten of Jack's own photographs (exported as copies from his Photos
library into the scratchpad, read only; nothing in the repository), with
plain Atkinson beside Floyd–Steinberg (`mpu compare --set pair`). **Jack
chose Atkinson (PH33).** To be confirmed on the Plus in Phase 2.

## Not verified

Nothing has been on the Plus. The renderers are tested on size, placement
and tone, not byte for byte. Jack's ten photographs all imported and
rendered, including two shot sideways (EXIF 6 and 8).
