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
| 3 Single-image app | **Built, 26 Oct 2026** (D-0.0.4, `PHASE-3-PLAN.md`, `PHASE-3-REPORT.md`). Waiting for Jack to use it on his own photographs (PH56) |
| 4 Batch processing | **Built, 26 Oct 2026** (D-0.0.5, `PHASE-4-PLAN.md`, `PHASE-4-REPORT.md`). Waiting for Jack to export a folder of his own (PH69) |
| 5 Saved projects | **Built, 26 Oct 2026** (D-0.0.6, `PHASE-5-PLAN.md`, `PHASE-5-REPORT.md`). Waiting for Jack to save, quit, move a photograph and reopen (PH79) |
| 6 Compatibility and release | **Under way** (D-0.0.7, `PHASE-6-PLAN.md`): icon, user guide, release tools and dark appearance done; waiting for the Plus checks, then the freeze and 1.0 (PH89) |

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

### Phase 3: the single-image app
- [x] `EditorSession`: the window's model, tested without a window (PH46)
- [x] The window: photograph, composition editor, previews, output and export (PH47)
- [x] Opening by ⌘O, drag-and-drop onto the window or the Dock icon, and Open With; errors in words (PH52)
- [x] Editor: dimmed outside the crop, Print/Screen crops, drag, zoom (slider, pinch, scroll), turns, orientation, reset, arrow keys (PH48)
- [x] Previews from the real renderers, debounced and cancellable; small-photograph warnings live (PH50, PH52)
- [x] Output: PPI, files, remembered folder; Export; Keep Both (default) / Replace / Cancel; what was written, Show in Finder (PH51, PH53)
- [x] `tools/build-app.sh`: `build/MacPhoto Utility.app`, signed ad hoc (PH55)
- [x] Screenshots of each state; timings (PHASE-3-REPORT.md)
- [x] Brightness and contrast for the screen image (PH57, Jack's request)
- [x] Resizing a crop by its corners (PH58, Jack's request)
- [ ] Dark appearance seen (not yet: the window uses system colours)
- [ ] **Jack:** exports one of his photographs without the command line and is happy with it (PH56)

### Phase 4: batch processing
- [x] `PhotoQueue`, tested without a window (PH59)
- [x] Adding files and folders, by content, no duplicates, Finder order, other files skipped and listed (PH60)
- [x] Quick adding: header and thumbnail only (PH61)
- [x] The queue panel: thumbnails, P/L, status, ↑ ↓, remove (PH62)
- [x] Shared settings; each photograph's own framing kept (PH63)
- [x] Export All one at a time, progress, Stop, failures recorded, summary (PH64)
- [x] Names for the batch first; Keep Both / Replace / Skip / Cancel (PH65)
- [x] Unseen photographs asked about (PH66)
- [x] Memory flat over 200 photographs (PH67)
- [x] Quitting with unexported changes asks (PH68)
- [x] Specification §11's batch tests; screenshots (PHASE-4-REPORT.md)
- [ ] **Jack:** exports a folder of his own photographs (PH69)

### Phase 5: saved projects
- [x] The `.macphoto` project file, versioned, documented (FILE_FORMATS.md §6; PH70)
- [x] File menu, title and edited mark, double-click to open, Open Recent (PH71)
- [x] Save / Don't Save / Cancel on closing, quitting, New and Open (PH72)
- [x] Moved photographs found by bookmark and fingerprint; missing ones kept with their framing (PH73)
- [x] Locate… and Locate in Folder…; a different file only after asking (PH74)
- [x] Fingerprints on adding (PH75); export history per photograph (PH76)
- [x] Newer and damaged projects refused in words (PH79)
- [ ] **Jack:** saves, quits, moves a photograph and reopens it (PH79)

### Phase 6: compatibility and release
- [x] Version names put right: 1.0, no B- for beta (PH80)
- [x] The icon (PH84): `tools/make-icon.swift`, `make-icon.sh`, in the bundle
- [x] `USER-GUIDE.md` and draft `RELEASE-NOTES.md` (PH85)
- [x] `tools/check-fresh-checkout.sh` (PH87): a clone builds, tests and builds the app (66 s)
- [x] `tools/make-release.sh` (PH88), with examples (PH86)
- [x] Dark appearance looked at (the app alone, `-MPUAppearance dark`)
- [x] VoiceOver labels read silently through the accessibility interface (Jack can't play sound at the office): every control of the app's own labelled
- [ ] **Jack:** the Plus checks (`PLUS-CHECKS.md` on `Photo Test.hda`), recorded in COMPATIBILITY.md (PH81)
- [ ] FILE_FORMATS.md 1.0 (PH82); the Transfer session told
- [ ] **Jack:** acceptance of Phases 3–5
- [ ] Version 1.0, the release candidate tried, `v1.0`, the release, the catalogue (PH89)
