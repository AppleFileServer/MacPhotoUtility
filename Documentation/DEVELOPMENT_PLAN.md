# Development plan: status and checklist

The phases are SPECIFICATION.md §12's. Each is planned, built, tested and
documented before the next; nothing is committed until Jack approves.
**First milestone** (§15): one photograph imported, cropped and exported
as a correctly sized 8-bit print image and a 512 × 342 Atkinson screen image,
both validated. The batch interface comes only after that works.

| Phase | Status |
|---|---|
| 0 Inspect and specify | **Done, 26 Oct 2026.** PQ1–PQ3, PQ7, PQ8 answered; PQ4–PQ6 wait for Plus checks (`PHASE-0-REPORT.md`) |
| 1 Conversion engine | **Done, 26 Oct 2026** (D-0.0.2, `PHASE-1-REPORT.md`). Jack chose Atkinson (PH33) after seeing ten of his photographs |
| 2 File exporters | **Built and tested, 26 Oct 2026** (D-0.0.3, `PHASE-2-PLAN.md`, `PHASE-2-REPORT.md`). Emulator check passed. Waiting for: the Plus checks (PH44, PQ10), then the freeze (PH45) |
| 3 Single-image app | — |
| 4 Batch processing | — |
| 5 Saved projects | — |
| 6 Compatibility and release | — |

## Checklist from the specification

Ticked only when built **and** tested; "Plus" items only with Jack's
evidence from the real machine.

### Phase 0
- [x] Repository and build environment inspected (new repository; Swift 6.3.3, macOS 26 SDK, Swift Testing)
- [x] Fixed print profiles defined and tested (§2; PH2); 360 PPI the default (PH19)
- [x] Print image format specified: 8-bit PICT (`FILE_FORMATS.md` §1; PH16)
- [x] PICT and MacPaint requirements researched (§2, §3; PH4, PH5)
- [x] Test images and expected sizes established (`TESTING.md` §2)
- [x] Buildable skeleton: engine, harness, app, tests
- [x] Technical-risk report (`PHASE-0-REPORT.md`)

### Phase 1: conversion engine
- [x] Import JPEG, HEIC/HEIF, PNG, TIFF, by content; dimensions and orientation (§3; PH21)
- [x] EXIF orientation applied (all eight; PH23)
- [x] Greyscale working image from colour, 16-bit grey and transparent sources (PH9, PH22)
- [x] Corrupt, truncated, unsupported, empty and missing files reported clearly
- [x] Originals never written (checked by hash and date before and after)
- [x] Composition geometry: crop, zoom, position, 90° rotation, reset (§5), independent of the window (PH24–PH27)
- [x] Composition unchanged by 300 ↔ 360 PPI; new photographs start at 360 PPI (PH19)
- [x] Print renderer: exact sizes, 8-bit, no stretching (§6; PH28)
- [x] Screen crop per photograph, forced to 512:342 (PH13); screen renderer from it, not from the print (§7)
- [x] Small-photograph warning (PH14, PH30)
- [x] Deterministic Atkinson (PH10, PH29), matched against hand-worked cases and, exactly, against an independent integer version of `../image-tools/atkinson.py`
- [x] Dither options and `mpu compare` (PH32)
- [x] **Jack:** previews of ten of his own photographs; Atkinson chosen (PH33)
- [x] `mpu convert`: one photograph to both canonical images

### Phase 2: exporters
- [x] 8-bit print PICT writer and validator (`FILE_FORMATS.md` §1; PH35, PH36)
- [x] 1-bit screen PICT writer and validator (§2)
- [x] MacPaint writer and validator (§3)
- [x] Manifest (§4; PH41)
- [x] Safe names; never overwrite silently; write, check, rename (PH38–PH40)
- [x] Handoff fixtures for the Transfer Utility (§5; PH42), checked by a test
- [x] Second reader: netpbm, pixel for pixel (ImageIO can't read our PICTs; PH37); the emulator check (PH43): MacPaint, SuperPaint, Photoshop 1.0
- [x] Transfer test pack from Jack's ten photographs, with `PLUS-CHECKS.md` (PH44)
- [ ] Plus: screen PICT and MacPaint files open (Jack); whether anything opens the 8-bit PICT (PQ6)
- [ ] FILE_FORMATS.md frozen as 1.0

### Phases 3–6
- [ ] Window: import, composition controls, print and screen previews, output and destination, progress, errors (§4, §5)
- [ ] Batch: folder import, thumbnails, per-photo crops kept, shared profile, carry on after a failure, conflict choice (§8)
- [ ] Projects: save and reopen, relink missing sources, export history (§9)
- [ ] Plus checks (§11 real-hardware tests 1–6); user guide; clean build from a fresh checkout (§12 Phase 6)
