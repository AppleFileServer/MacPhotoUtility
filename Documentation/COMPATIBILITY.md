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

## In Mini vMac (26 Oct 2026; an emulated Plus, so this confirms nothing)

System 6.0.7, with MacPaint, SuperPaint 2.0 and Photoshop 1.0 copied from
the backups onto a test disk, and one of Jack's photographs exported by
D-0.0.3 (PH43). Screenshots: `../MacPhotoUtility-Samples/emulator-check-2026-10-26/`
(private: they show the photograph).

| File | Application | Seen in the emulator |
|---|---|---|
| MacPaint `.MAC` | MacPaint | Opened with no beep or blank rows; Show Page puts the picture centred (10/11 and 64/61 at a third of the size); the pattern palette identical before and after (PH4) |
| Screen PICT | SuperPaint 2.0 | Opened and drawn correctly by QuickDraw |
| Print PICT, 8-bit, 1.1 MB | **Photoshop 1.0** | Photoshop 1.0 runs on the emulated Plus, lists the file as a PICT File of 1095K, and opens it as **Gray Scale**, 900 × 1260, shown at 1:5 (PQ6) |

The Finder couldn't open a document by double-click on the freshly made
test disk (its desktop database didn't yet know the applications);
opening from inside each application worked. Not a fault in the files.

## On this Mac

netpbm's `picttoppm` (installed 26 Oct 2026) decodes all six PICT fixtures
exactly as MacPhoto's validators do, pixel for pixel (`NetpbmTests`), and
draws After Dark's sample PICT correctly.

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
