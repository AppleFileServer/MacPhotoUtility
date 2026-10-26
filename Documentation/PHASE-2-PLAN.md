# Phase 2 plan: the file exporters

**Status: approved by Jack, 26 October 2026.** PH34–PH45 are in
`DECISIONS.md` as Provisional until Phase 2's tests and the Plus confirm them.

**Deliverable** (specification §12): validated output files and a
documented transfer test pack. `mpu export` turns one photograph into the
three files of `FILE_FORMATS.md` (8-bit print PICT, 1-bit screen PICT,
MacPaint), checks each one, and records them in a manifest. At the end,
`FILE_FORMATS.md` is frozen as **1.0**, once the files have been seen on
the Plus.

## Decisions proposed

| Code | Decision |
|---|---|
| PH34 | **One PackBits encoder and one strict decoder**, Apple's algorithm (Inside Macintosh I; Technical Note 1023): runs of 3 or more equal bytes become a repeat, everything else literal, at most 128 bytes a run, each row packed on its own. Tested against Apple's published example byte for byte, and by round trips on random rows. The decoder refuses a row that doesn't come to exactly the row's length, which is what MacPaint does (it beeps and blanks the rest). |
| PH35 | **Three writers, each making bytes in memory**: `PrintPICTWriter` (§1), `ScreenPICTWriter` (§2), `MacPaintWriter` (§3). Every field written byte by byte, big-endian; no Swift structure goes to disk (specification §6). |
| PH36 | **Three validators, written separately from the writers**, from `FILE_FORMATS.md` alone: each parses the whole file, checks every rule in its "valid when" list, unpacks every row, and returns the decoded image. A writer's output counts only if its validator passes **and** the decoded image is identical to what was written (the print's CRC-32 included). The validators report what's wrong in words ("row 211 unpacks to 71 bytes, not 72"). |
| PH37 | **Apple's own reader as a second opinion:** macOS's ImageIO still reads PICT. Each test decodes our PICTs with it and compares with the source image (exactly for the 1-bit PICT; within a level or two for the 8-bit one, in case ImageIO colour-manages it). If ImageIO turns out not to read one of the two forms, that's recorded and the test is dropped, not faked. Nothing on macOS reads MacPaint; its second opinion is MacPaint itself (PH43). |
| PH38 | **Export is write, check, then rename:** each file is written to a hidden temporary name in the destination folder, read back from disk and validated, and only then renamed to its real name. A failure leaves no half-written or invalid file. Success is reported only after that (specification §9). |
| PH39 | **Folders and names.** In the chosen export folder, three subfolders named as on the transfer volume: `Print Files`, `PICT Files`, `MacPaint Files` (`FILE_FORMATS.md` §5), so both PICTs keep the photograph's own name: `IMG_8691.pict` in each, and `IMG_8691.MAC`. The name is made Mac-safe: accents removed, anything outside printable ASCII or a colon becomes `_`, and the whole name cut to fit **31 characters** with its extension. |
| PH40 | **Never overwrite silently** (specification §8): if a name is taken, the export stops and says so, unless asked to **replace** or to **keep both** (`IMG_8691 2.pict`, then 3, …, still within 31 characters). The harness takes `--if-exists stop|replace|keep-both`; the window (Phase 3) will ask. |
| PH41 | **The manifest** (`FILE_FORMATS.md` §4): `manifest.json` in the export folder, one entry per output file, updated (not replaced) by later exports to the same folder: format version 1, the app's version, the date; per file: the kind, its path, size and SHA-256, its pixel size, and the validation result; with the source photograph's path, size and SHA-256, the composition (turns, orientation, both crops), the PPI and any warnings. Written by the same write-check-rename. For Jack's records only; the Plus never sees it. |
| PH42 | **Handoff fixtures** in `Fixtures/handoff/` (`FILE_FORMATS.md` §5), made by the real exporters from the generated test images (so nothing private): print PICTs in all four sizes, a screen PICT, a MacPaint file, and deliberately broken ones named `bad-<what>.<ext>` (cut short, a row of the wrong length, a wrong checksum, a size not allowed, a wrong colour table, version 1 opcodes in a version 2 file, …). A `README.md` lists what each tests and its SHA-256; a test checks the folder still matches. The Transfer session is told when they're there. |
| PH43 | **A short emulator check before the Plus:** on a scratchpad copy of the boot and applications disks (from the backups, never the card), a small HFS image with one file of each kind, typed with hfsutils under a private `HOME`. Then a run of a minute or two in Mini vMac, only if no one else is using it: MacPaint opens the `.MAC` (centred, patterns untouched), SuperPaint opens the screen PICT. Screenshots in the report. It catches gross mistakes; it **confirms nothing** about the Plus (COMPATIBILITY.md). |
| PH44 | **The transfer test pack** for Jack, from his ten sample photographs into a scratchpad folder (never the repository): for each, the print PICT at 360 PPI, the screen PICT and the MacPaint file, plus `PLUS-CHECKS.md`: what to open in what, and what to look for. The checks: the screen PICT in MacPhoto-to-be's stand-in (SuperPaint) and in After Dark's Slide Show; the MacPaint file; whether Photoshop 1.0 opens a print PICT (PQ6); and **Atkinson on the Plus's own screen** (PH33). |
| PH45 | **The freeze:** `FILE_FORMATS.md` becomes 1.0 when the validators, the ImageIO check, the fixtures and the Plus checks of PH44 all agree. If the Plus check finds a problem, the fix is made before 1.0, so 1.0 is what the Plus accepts. |

## Steps

Each step builds and passes its tests before the next.

1. **PackBits** (PH34): encoder, strict decoder, Apple's example, round trips.
2. **Screen PICT** (PH35–PH37): writer and validator; round trip; ImageIO
   reads it back bit for bit. The smallest format, so it shakes out the
   shared parts first.
3. **MacPaint** (PH35, PH36): writer and validator; round trip; the image at
   rows 189–530, bytes 4–67; the file a multiple of 512 bytes; version 0.
4. **Print PICT** (PH35–PH37): writer and validator, the CRC-32, all four
   sizes; round trip; ImageIO's opinion.
5. **Export** (PH38–PH41): names, folders, conflicts, write-check-rename,
   the manifest; tests in a temporary folder, including a failure part way
   leaving nothing behind.
6. **Harness:** `mpu export PHOTO --to DIR [--ppi …] [--orientation …]
   [--turns …] [--print-crop …] [--screen-crop …] [--only print,screen,macpaint]
   [--if-exists stop|replace|keep-both]` and `mpu validate FILE…` (any of
   the three kinds, recognised by content, as the Transfer Utility will).
7. **Fixtures** (PH42), and a message to the Transfer session.
8. **Emulator check** (PH43), short, with your go-ahead at the time.
9. **Test pack** (PH44) and documents: `FILE_FORMATS.md` (still draft until
   the Plus), `ARCHITECTURE.md`, `TESTING.md`, `COMPATIBILITY.md`,
   `CHANGELOG.md` (D-0.0.3), `PHASE-2-REPORT.md`.
10. **Plus checks** (Jack), then the freeze (PH45).

## Files

| New | What |
|---|---|
| `MacPhotoKit/PackBits.swift` | PH34 |
| `MacPhotoKit/ScreenPICT.swift`, `MacPaint.swift`, `PrintPICT.swift` | each format's writer and validator, side by side but sharing nothing but PackBits and a byte reader/writer |
| `MacPhotoKit/CRC32.swift` | zlib's CRC-32, checked against zlib itself |
| `MacPhotoKit/Exporter.swift`, `Manifest.swift`, `MacNames.swift` | PH38–PH41 |
| `Fixtures/handoff/` | PH42 |
| `Tests/MacPhotoKitTests/…` | one file per step |

## Not in Phase 2

The window (Phase 3), batches (Phase 4), projects (Phase 5). No writing
to the SD card, ever: the files reach the Plus through the Macintosh
Transfer Utility.

## Open question

| Code | Question |
|---|---|
| PQ10 | **How does the test pack reach the Plus?** The Macintosh Transfer Utility is adding picture support alongside this phase. If it's ready when the test pack is, that's the route (and a test of it too). If not: wait for it, or have the Transfer session put the files on the card by its existing routine (backup, rehearse, compare). It's your choice when we get there; nothing in Phase 2 waits on it until step 10. |
