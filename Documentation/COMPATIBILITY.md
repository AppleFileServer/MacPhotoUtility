# Compatibility

Only what has been seen on the real Macintosh Plus (4 MB, System 6.0.7)
is recorded as confirmed. Checks on this Mac or in Mini vMac are noted
as such and confirm nothing.

| File | Application on the Plus | Status | Evidence |
|---|---|---|---|
| MacPaint `.MAC` | MacPaint (on the Applications disk) | **Not tested** | — |
| Screen PICT `.pict` (1-bit, v1) | MacPhoto (creator); meanwhile SuperPaint 2.0 or Photoshop 1.0 via Open | **Not tested** | — |
| Print PICT `.pict` (8-bit, v2) | MacPhoto (not yet written); maybe Photoshop 1.0 (PQ6) | **Not tested** | — |
| Screen PICT in the screensaver | After Dark 2.0, Slide Show 2.1 module, from `After Dark Files:Slide Show Folder` (PQ4) | **Not tested** | — |

On this Mac (26 Oct 2026): macOS's ImageIO lists PICT as readable but
draws both of our PICTs as blank white, and After Dark's own 1990 sample
PICT as solid black, so it is no judge of PICT files (PH37). macOS can't
write PICT. Nothing on macOS reads MacPaint documents.

Found on the Plus's disks (from the 21 Oct backup of "Applications
40 MB", read only): MacPaint (`MPNT`), SuperPaint 2.0 (`SPNT`), Adobe
Photoshop 1.0 (`8BIM`), Ofoto 1.1, AppleScan. No MacDraw. On the boot disk (Macintosh Backup Utility snapshot of
25 Oct, read from a copy): After Dark 2.0 with the Flying Toasters,
Randomizer and Slide Show modules; Slide Show's folder holds one sample
picture, a data-fork version 2 PICT.
