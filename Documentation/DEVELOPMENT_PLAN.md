# Development plan: status and checklist

The phases are SPECIFICATION.md §12's. Each is planned, built, tested and
documented before the next; nothing is committed until Jack approves.
**First milestone** (§15): one photograph imported, cropped and exported
as a correctly sized print master and a 512 × 342 Atkinson screen image,
both validated. The batch interface comes only after that works.

| Phase | Status |
|---|---|
| 0 Inspect and specify | **Done, 26 Oct 2026.** PQ1, PQ2, PQ7 answered; PQ8 (the 8-bit editable files) open (`PHASE-0-REPORT.md`) |
| 1 Conversion engine | Next |
| 2 File exporters | — |
| 3 Single-image app | — |
| 4 Batch processing | — |
| 5 Saved projects | — |
| 6 Compatibility and release | — |

## Checklist from the specification

Ticked only when built **and** tested; "Plus" items only with Jack's
evidence from the real machine.

### Phase 0
- [x] Repository and build environment inspected (new repository; Swift 6.3.3, macOS 26 SDK, Swift Testing)
- [x] Fixed print profiles defined and tested (§2; PH2)
- [x] Print master format specified (`FILE_FORMATS.md` §1; PH3)
- [x] PICT and MacPaint requirements researched (§2, §3; PH4, PH5)
- [x] Test images and expected sizes established (`TESTING.md` §2)
- [x] Buildable skeleton: engine, harness, app, tests
- [x] Technical-risk report (`PHASE-0-REPORT.md`)

### Phase 1: conversion engine
- [ ] Import JPEG, HEIC/HEIF, PNG, TIFF; dimensions and metadata (§3)
- [ ] EXIF orientation applied (all eight)
- [ ] Greyscale working image from colour or grey sources (PH9)
- [ ] Corrupt, unsupported and missing files reported clearly
- [ ] Originals never written (checked by hash before and after)
- [ ] Composition geometry: crop, zoom, position, 90° rotation, reset (§5), independent of the window
- [ ] Composition unchanged by 300 ↔ 360 PPI
- [ ] Print renderer: exact sizes, 8-bit, no stretching (§6)
- [ ] Screen crop per photograph, forced to 512:342 (PH13); screen renderer from it, not from the print (§7)
- [ ] Small-photograph warning (PH14)
- [ ] Deterministic Atkinson (PH10), matched against a hand-checked case
- [ ] `mpu convert`: one photograph to both canonical images

### Phase 2: exporters
- [ ] Print master writer and validator (`FILE_FORMATS.md` §1)
- [ ] PICT writer and validator (§2)
- [ ] MacPaint writer and validator (§3)
- [ ] Manifest (§4)
- [ ] Safe names; never overwrite silently
- [ ] Handoff fixtures for the Transfer Utility (§5)
- [ ] Plus: PICT and MacPaint files open (Jack)
- [ ] FILE_FORMATS.md frozen as 1.0

### Phases 3–6
- [ ] Window: import, composition controls, print and screen previews, output and destination, progress, errors (§4, §5)
- [ ] Batch: folder import, thumbnails, per-photo crops kept, shared profile, carry on after a failure, conflict choice (§8)
- [ ] Projects: save and reopen, relink missing sources, export history (§9)
- [ ] Plus checks (§11 real-hardware tests 1–6); user guide; clean build from a fresh checkout (§12 Phase 6)
