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
        │                                   ├─ PICTWriter     → .pict
        ▼ PrintMasterWriter                 └─ MacPaintWriter → .MAC
    .mppi
        │  each output checked by its validator before it counts as done
        ▼
    export folder (+ manifest.json)  →  Macintosh Transfer Utility  →  Plus

The two renderers share only the photograph and its rotation: a change
to the dithering can't touch the print (specification §10).

## Package

| Target / file | What | Phase |
|---|---|---|
| `MacPhotoKit/PrintProfile` | the four print sizes; nothing else expressible | 0 |
| `MacPhotoKit/ScreenSpec` | the screen and MacPaint page sizes | 0 |
| `MacPhotoKit/Version` | the version | 0 |
| `MacPhotoKit` importer, composition, renderers, Atkinson | the engine | 1 |
| `MacPhotoKit` writers and validators, manifest | the exporters | 2 |
| `MacPhotoKit` project, queue | saving, batches | 4–5 |
| `mpu` | the harness: runs the engine without the window | 0 → |
| `MacPhotoUtility` | the SwiftUI app; a placeholder until Phase 3 | 0, 3 → |
| `MacPhotoKitTests` | the tests | 0 → |
