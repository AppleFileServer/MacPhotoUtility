# MacPhoto Utility

A macOS app for the Macintosh Plus: it turns photographs into a
2.5 × 3.5-inch 8-bit greyscale print image (a PICT that MacPhoto on the
Plus edits) and a 512 × 342 1-bit Atkinson-dithered screen image (PICT,
or MacPaint). The files reach the Plus through the Macintosh Transfer
Utility.

**Status: Phase 0 done** (D-0.0.1): the skeleton, the print profiles and
the draft file formats. No conversion yet.

    tools/test.sh                                  # the tests
    swift build && .build/debug/mpu profiles       # the harness

| Document | |
|---|---|
| `Documentation/SPECIFICATION.md` | the brief, unedited |
| `Documentation/DEVELOPMENT_PLAN.md` | phase status and the checklist |
| `Documentation/PHASE-0-REPORT.md` | what was found, the risks, the questions |
| `Documentation/ARCHITECTURE.md` | modules and data flow |
| `Documentation/FILE_FORMATS.md` | 8-bit and 1-bit PICT, MacPaint, manifest; the handoff contract |
| `Documentation/COMPATIBILITY.md` | what has been seen on the Plus |
| `Documentation/TESTING.md` | automated and real-hardware tests |
| `Documentation/CHANGELOG.md` | changes by version |
| `Documentation/DECISIONS.md` | PH decisions, PQ questions |

Copyright © 2026 Jack McAteer. Not affiliated with Apple.
