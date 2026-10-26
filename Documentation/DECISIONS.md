# Decisions

Two logs, as the programme's (`../Programme/DECISIONS.md`): decisions
(**PH**-codes), **Firm** (Jack agreed) or **Provisional** (working
assumption until checked); and open questions (**PQ**-codes). Never
renumber or delete an entry; mark it **Superseded by PHn**.

## Decisions

| Code | Decision | Kind | Date |
|---|---|---|---|
| PH1 | **Repository and build:** `~/MacPlusProjects/MacPhotoUtility`, its own git repository (programme P18). A Swift package as the Transfer Utility's: the engine `MacPhotoKit`, the harness `mpu`, the app `MacPhotoUtility`, tests with Swift Testing. Swift 6.3.3, macOS 26 SDK, deployment target macOS 26, Apple silicon. | Firm (Jack, 26 Oct) | 2026-10-26 |
| PH2 | **Print profiles in whole numbers:** the sides held as 250 and 350 hundredths of an inch, so 750 × 1050, 1050 × 750, 900 × 1260 and 1260 × 900 come out exactly. No other size can be expressed. 300 PPI is the default. | Firm (specification §2) | 2026-10-26 |
| PH3 | **Superseded by PH16.** **Print master format** (`FILE_FORMATS.md` §1): `.mppi`, magic `MPPI`, a 64-byte big-endian header with every field at an even offset, uncompressed 8-bit rows without padding, optional CRC-32. Type `MPpi`, creator `MPho`. | Provisional until Phase 2 freezes the format | 2026-10-26 |
| PH4 | **MacPaint header version 0, patterns zeroed.** MacPaint 1.3's source keeps the user's own patterns for any version below 2; version 2 would overwrite them. Every row packed separately; the file padded to a multiple of 512 bytes, as MacPaint saves. | Provisional until opened on the Plus | 2026-10-26 |
| PH5 | **PICT version 1** with one PackBitsRect. It is the oldest form and any System 6 QuickDraw draws it; version 2 adds nothing a 1-bit image needs. | Provisional until opened on the Plus | 2026-10-26 |
| PH6 | **Superseded by PH12.** The screen image at the MacPaint page's top-left corner. | Provisional | 2026-10-26 |
| PH7 | **Superseded by PH17.** **PICT creator `SPNT`** (SuperPaint 2.0, on the Plus), so a double-click opens it there. | Provisional (PQ3) | 2026-10-26 |
| PH8 | **No transfer in MacPhoto Utility.** Its files reach the Plus through the Macintosh Transfer Utility (formerly the MacMusic Transfer Utility), which recognises them by content (`FILE_FORMATS.md` §5). Programme P25. | Firm (Jack, 26 Oct) | 2026-10-26 |
| PH9 | **Greyscale working image:** decode with ImageIO (EXIF orientation applied), then draw into an 8-bit Generic Gray Gamma 2.2 context with CoreGraphics' colour management. The print image stores these gamma-encoded values. | Provisional, Phase 1 | 2026-10-26 |
| PH10 | **Resampling and dithering:** resample with vImage's high-quality (Lanczos) scaling, separately for the print and the screen from the same crop. Atkinson in integer arithmetic: threshold 128, one-eighth of the error to each of (x+1,y), (x+2,y), (x−1,y+1), (x,y+1), (x+1,y+1), (x,y+2), left to right, top to bottom, no serpentine, error past an edge dropped. Same input, same output. | Provisional, Phase 1 | 2026-10-26 |
| PH11 | **Versions:** `D-0.0.x` in development, `B-x.y.z` beta, `1.0` release (as the suite's other apps). | Firm | 2026-10-26 |
| PH12 | **The screen image is centred on the MacPaint page**, both ways: x 32, y 189 (x is a whole 4 bytes); the rest of the page white. Answers PQ2. | Firm (Jack) | 2026-10-26 |
| PH13 | **Screen images are force-cropped in the utility:** each photograph has its own screen crop at exactly 512:342 that always fills the screen, with no bars and no stretching, set in MacPhoto Utility. The result goes to the Plus ready to view, not for editing there. Answers PQ1. | Firm (Jack) | 2026-10-26 |
| PH14 | **A small photograph gets a warning:** when the crop has fewer source pixels than the output in either direction (so it would be enlarged), the photograph is marked and the export says so; it still exports. Answers PQ7. | Firm (Jack) | 2026-10-26 |
| PH15 | **MacPhoto on the Plus is the editor**, a separate program. Its input will mostly be this utility's PICT output; MacPaint output will be rare. MacPhoto shows a landscape image fitted to the screen with black bars and lets a portrait image scroll. Recorded here because it decides what the editable files must be (PQ8). | Firm (Jack) | 2026-10-26 |
| PH16 | **The print image is an 8-bit greyscale PICT** (version 2, one PackBitsRect with an 8-bit grey PixMap, the extended header carrying the PPI, and MacPhoto's record in an application comment for the print size, orientation and a CRC-32), **replacing `.mppi`**. One fixed subset, `FILE_FORMATS.md` §1. MacPhoto decodes it itself, row by row; the Plus's QuickDraw can't draw it. Departs from the specification's "native MacPhoto print-image format" (§6) on Jack's instruction. Answers PQ8. | Firm (Jack) | 2026-10-26 |
| PH17 | **Every PICT gets MacPhoto's creator `MPho`**, so a double-click opens MacPhoto (once it exists). Answers PQ3. | Firm (Jack) | 2026-10-26 |
| PH18 | **Screen images stay 1-bit Atkinson** (PICT version 1 or MacPaint), shown on the Plus as they are. | Firm (Jack; specification §7) | 2026-10-26 |

## Open questions

| Code | Question | Status |
|---|---|---|
| PQ1 | **Answered by PH13.** **Screen framing.** The print is 5:7 (or 7:5); the screen is 512:342 (about 3:2). The same crop can't fill both. Options: (a) **fit**: the whole print crop on the screen with margins (landscape 479 × 342 with 16–17 px bars each side; portrait about 244 × 342); (b) **fill**: widen or trim the crop for the screen; (c) a **separate screen crop** per photograph, starting from the print crop. Margin colour white or black? | Answered (PH13) |
| PQ2 | MacPaint placement: top-left (PH6) or centred across (x 32)? | Answered: centred (PH12) |
| PQ3 | **Answered by PH17 (MacPhoto).** Which application should open a PICT on the Plus: SuperPaint 2.0 (`SPNT`), Photoshop 1.0 (`8BIM`) or another? Checked on the Plus in Phase 2. | Answered (PH17) |
| PQ4 | Which screensaver will show screen images (specification §11, test 6), and does it read PICT, MacPaint or something else? | Open, Jack |
| PQ5 | How will print images be printed in the end (a future MacPhoto on the Plus, a printer bridge)? It decides whether 360 PPI is worth keeping. | Open |
| PQ6 | Can anything already on the Plus (Photoshop 1.0, SuperPaint 2.0, the Scrapbook) open an 8-bit PICT (PH16)? Nothing depends on it, but it would show a print image before MacPhoto exists. | Open, a Plus check |
| PQ7 | A photograph smaller than the output (say 640 × 480 for a 1050 × 750 print): upscale silently, warn, or refuse? | Answered: warn (PH14) |
| PQ8 | **Answered by PH16–PH18.** **What are the 8-bit editable files for MacPhoto?** Jack: "the PICT/MAC output will be 8-bit editable images on the Mac Plus". A MacPaint document can only be 1-bit. An 8-bit PICT is possible (a version 2 PICT with an 8-bit grey PixMap), but the Plus's own QuickDraw can't draw one: only MacPhoto, reading it itself, could use it (perhaps not SuperPaint or Photoshop 1.0). To settle: is the editable file the print-size image as an 8-bit PICT (instead of, or as well as, `.mppi`)? Are the screen images still 1-bit Atkinson? Should PICTs carry MacPhoto's creator `MPho` instead of `SPNT` (PQ3)? | Answered (PH16–PH18) |
