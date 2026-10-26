# MacPhoto Utility

A macOS app for the Macintosh Plus: it turns photographs into a
2.5 × 3.5-inch 8-bit greyscale print image (a PICT that MacPhoto on the
Plus edits) and a 512 × 342 1-bit Atkinson-dithered screen image (PICT,
or MacPaint). The files reach the Plus through the Macintosh Transfer
Utility.

**Status: Phase 2 built** (D-0.0.3): the engine and the three file
formats, run from the harness; waiting for the emulator and Plus checks
before the formats are frozen.

    tools/test.sh                                  # the tests
    swift build && .build/debug/mpu                # the harness's commands
    .build/debug/mpu convert PHOTO --preview DIR   # one photograph, both images
    .build/debug/mpu export PHOTO --to DIR         # the three files, checked
    .build/debug/mpu validate FILE…                # check any of the three
    .build/debug/mpu compare PHOTO --out DIR       # ways of dithering

| Document | |
|---|---|
| `Documentation/SPECIFICATION.md` | the brief, unedited |
| `Documentation/DEVELOPMENT_PLAN.md` | phase status and the checklist |
| `Documentation/PHASE-0-REPORT.md` | what was found, the risks, the questions |
| `Documentation/PHASE-1-PLAN.md`, `PHASE-1-REPORT.md` | the engine: plan and result |
| `Documentation/PHASE-2-PLAN.md`, `PHASE-2-REPORT.md` | the exporters: plan and result |
| `Fixtures/handoff/` | files for the Macintosh Transfer Utility's tests |
| `Documentation/ARCHITECTURE.md` | modules and data flow |
| `Documentation/FILE_FORMATS.md` | 8-bit and 1-bit PICT, MacPaint, manifest; the handoff contract |
| `Documentation/COMPATIBILITY.md` | what has been seen on the Plus |
| `Documentation/TESTING.md` | automated and real-hardware tests |
| `Documentation/CHANGELOG.md` | changes by version |
| `Documentation/DECISIONS.md` | PH decisions, PQ questions |

Copyright © 2026 Jack McAteer. Not affiliated with Apple.
