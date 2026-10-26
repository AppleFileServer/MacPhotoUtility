# Phase 2 report (26 October 2026, in progress)

**D-0.0.3.** The exporters, as planned in `PHASE-2-PLAN.md` (PH34–PH45).
Steps 1–9 are done; the Plus checks (step 10) wait for a way to reach
the Plus (PQ10). 72 tests pass (with netpbm installed).

## What was built

| Step | Result |
|---|---|
| 1 PackBits | encoder matching Apple's example byte for byte; strict decoder; CRC-32 equal to zlib's |
| 2 Screen PICT | writer and validator; 12–23 KB |
| 3 MacPaint | writer and validator; image at rows 189–530, bytes 4–67; 14–24 KB, a multiple of 512 |
| 4 Print PICT | writer and validator, CRC-32, the four sizes; a photograph at 360 PPI is about 1.1 MB |
| 5 Export | three subfolders, Mac-safe names, stop / replace / keep both, all-or-nothing write-check-rename, `manifest.json` |
| 6 Harness | `mpu export`, `mpu validate` (recognises the kind by content) |
| 7 Fixtures | `Fixtures/handoff/`: 8 good, 17 bad, README with SHA-256s, checked by a test (1.2 MB) |
| 9 Test pack | Jack's ten photographs, 30 files with a manifest and `PLUS-CHECKS.md`, in `~/MacPlusProjects/MacPhotoUtility-Samples/test-pack/` (private; never committed) |

## Found while building

- **macOS can't judge PICT files (PH37).** ImageIO lists PICT as a type it
  reads, and opens our files at the right size, but draws both the 1-bit
  and the 8-bit PICT as blank white. It draws After Dark's own sample
  picture (a 1990 version 2 PICT, read from a copy of the boot disk) as
  solid black. macOS can't write PICT, so there's no round trip either.
  As PH37 said, the comparison was dropped rather than faked.
- **netpbm is the second reader instead.** With Jack's go-ahead, netpbm
  (Homebrew) was installed; its `picttoppm` draws After Dark's PICT
  correctly and decodes every PICT fixture exactly as our validators do,
  pixel for pixel, including the 8-bit print PICTs, which the Plus's own
  QuickDraw can't draw (`NetpbmTests`, skipped where netpbm is missing).
- **The emulator check (PH43) passed.** In Mini vMac: MacPaint opened the
  `.MAC` with no beep, centred, the user's patterns untouched; SuperPaint
  drew the screen PICT; and **Photoshop 1.0 runs on the emulated Plus and
  opened the 8-bit print PICT as Gray Scale** (PQ6). Details in
  COMPATIBILITY.md; it took about twelve minutes of emulator time, more
  than planned, because of preference-file dialogs.
- **After Dark's sample PICT has data in its 512-byte header.** Ours are
  zeros, as FILE_FORMATS.md says; other people's PICTs needn't be. Told
  the Transfer session, whose validators may meet both.
- **All or nothing:** every file is written and checked under a temporary
  name before any is renamed, so a failure on the last file leaves the
  folder exactly as it was (a test tampers with the MacPaint file to
  prove it).

## Still to do

- Step 10: the Plus checks (`PLUS-CHECKS.md`), then the freeze (PH45). The
  Macintosh Transfer Utility won't read pictures until after its rename
  and generic file kinds (its T1, T2), so PQ10 needs an answer.
- Tell the Transfer session about the fixtures once they're committed.
