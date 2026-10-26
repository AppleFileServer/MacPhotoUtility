# Architecture

## Data flow

    photograph (JPEG, HEIC, PNG, TIFF)        never written
        │ Importer: decode, EXIF orientation, greyscale (PH9)
        ▼
    working greyscale image  +  Composition (print crop, screen crop (PH13),
                                             zoom, position, rotation)
        │                                   │
        ▼ PrintRenderer (PH10)              ▼ ScreenRenderer (PH10)
    8-bit print image                    8-bit 512 × 342 → Atkinson → 1-bit
    750 × 1050 … 1260 × 900                 │
        │                                   ├─ PICT1Writer    → .pict (1-bit)
        ▼ PICT2Writer (PH16)                └─ MacPaintWriter → .MAC
    .pict (8-bit, for MacPhoto to edit)
        │  each output checked by its validator before it counts as done
        ▼
    export folder (+ manifest.json)  →  Macintosh Transfer Utility  →  Plus

The two renderers share only the photograph, its turns and the
resampler: a change to the dithering can't touch the print
(specification §10). Only the crop is turned, never the whole
photograph, and turns are exact moves of pixels (PH23).

## Package

| Target / file | What | Phase |
|---|---|---|
| `MacPhotoKit/PrintProfile` | the four print sizes; nothing else expressible | 0 |
| `MacPhotoKit/ScreenSpec` | the screen and MacPaint page sizes | 0 |
| `MacPhotoKit/Version` | the version | 0 |
| `MacPhotoKit/Images` | `GreyImage` (0 black … 255 white), `BitImage` (1 = black) (PH20) | 1 |
| `MacPhotoKit/Importer` | decode by content, grey, EXIF orientation; exact turns and mirrors; the errors (PH21–PH23) | 1 |
| `MacPhotoKit/Composition` | the two crops, turns, orientation; pixel rectangles (PH24–PH27) | 1 |
| `MacPhotoKit/Renderers` | `PrintRenderer`, `ScreenRenderer`, and `Resampler` (crop, turn, Lanczos), the one thing they share (PH28, PH30) | 1 |
| `MacPhotoKit/Dither` | Atkinson and the comparison's options (PH29, PH32) | 1 |
| `MacPhotoTestSupport` | the synthetic test images (PH31) | 1 |
| `MacPhotoKit` writers and validators, manifest | the exporters | 2 |
| `MacPhotoKit` project, queue | saving, batches | 4–5 |
| `mpu` | the harness: runs the engine without the window | 0 → |
| `MacPhotoUtility` | the SwiftUI app; a placeholder until Phase 3 | 0, 3 → |
| `MacPhotoKitTests` | the tests | 0 → |
