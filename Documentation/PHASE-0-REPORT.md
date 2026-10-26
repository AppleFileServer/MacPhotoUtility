# Phase 0 report (26 October 2026)

## What was there

No MacPhoto Utility repository existed. The programme listed MacPhoto (the
Plus application) as an Idea. Related work found:

- `../image-tools/atkinson.py`: a Python Atkinson ditherer for PNGs. Useful
  to compare against in Phase 1; not reused.
- `../MacPaintClipboardFix/source/`: MacPaint 1.3's Pascal source, the
  authority for what MacPaint accepts (PH4).
- `../MacMusicTransfer`: becoming the Macintosh Transfer Utility (P25),
  which will carry these files to the Plus.

## Environment

Swift 6.3.3 (`swiftlang-6.3.3.1.3`), Xcode's macOS 26 SDK, Swift Testing,
arm64. `swift test` needs `SDKROOT` set (as for the Transfer Utility);
`tools/test.sh` does it. Built and tested: 6 tests (12 cases), all passing.
`mpu profiles` prints the four sizes.

## Technical risks

| Risk | Why it matters | What's planned |
|---|---|---|
| **Print and screen aspects differ** | 5:7 or 7:5 against about 3:2: one crop can't fill both | Settled: each photograph gets its own forced screen crop (PH13) |
| MacPaint acceptance | MacPaint blanks the rest of the page if any row unpacks wrongly | Version 0 header, rows packed separately (PH4); a validator that unpacks as MacPaint does; the Plus check |
| PICT on System 6 | An unusual picture may draw wrongly or not at all | Version 1, the simplest form (PH5); the Plus check; which app opens it (PQ3) |
| Print image size on the Plus | 0.8–1.2 MB, a quarter of the Plus's memory, more than a small partition | Rows in order, each with its own length, so MacPhoto reads in strips (PH16) |
| 8-bit PICT on a Plus | The Plus's QuickDraw can't draw a version 2 PICT with an 8-bit PixMap, so other programs there may not open it | MacPhoto decodes it itself; one fixed subset to read (FILE_FORMATS.md §1); PQ6 checks the others |
| Determinism | vImage or CoreGraphics output may differ between macOS versions | Atkinson tested on fixed 8-bit buffers (exact); renderers tested on size, tone and structure, not byte-for-byte |
| Colour to grey | Uncontrolled conversion gives muddy or contrasty prints | CoreGraphics colour management to Gray Gamma 2.2 (PH9); the ramp test image |
| 360 PPI | May give nothing visible | Kept optional (specification §2); depends on how prints are made (PQ5) |
| Small sources | Upscaling a phone thumbnail gives a soft print | Jack's choice (PQ7) |
| Type and creator lost on macOS | Files on the Plus wouldn't open with a double-click | The Transfer Utility sets them from content (FILE_FORMATS.md §5) |
| Two apps changing together | The formats could drift apart | A versioned contract (FILE_FORMATS.md §5), fixtures from the real exporters, independent validators |

## Not verified

Nothing has been on the real Plus. The MacPaint and PICT layouts come from
Apple's documentation and MacPaint's source, not from trying them. The
8-bit print PICT has no reader on the Plus yet.

## Questions for Jack

PQ1–PQ7 in `DECISIONS.md`. Jack answered PQ1 (forced crop, PH13), PQ2
(centred, PH12) and PQ7 (warn, PH14) on 26 October and described MacPhoto
on the Plus (PH15). That raised PQ8, what the 8-bit editable files are,
which Jack then answered: the print image is an 8-bit PICT replacing
`.mppi` (PH16), every PICT opens in MacPhoto (PH17), screen images stay
1-bit (PH18). Then: the screensaver is After Dark 2.0, whose Slide Show module shows PICT
files, so it takes the 1-bit screen PICTs (PQ4), prints go
to an inkjet through a print bridge (PQ5), and Photoshop 1.0 may open
the 8-bit PICT (PQ6); each still needs a Plus check or a test print.
