# File formats

**Status: draft 0.3 (Phase 0, 26 October 2026). PROVISIONAL throughout.**
**Approved by Jack on 26 October 2026 as the working contract** for both
apps' writers and validators; still provisional in its details.
Frozen as version 1.0 at the end of Phase 2, once the exporters and their
validators agree and the files have been checked on the real Plus. After
that, any change is a new format version recorded in `DECISIONS.md`, never
a silent edit (SPECIFICATION.md §15).

Draft 0.3 replaces draft 0.2's native print format (`.mppi`) with an
**8-bit PICT** (PH16): MacPhoto on the Plus edits PICTs.

These are also the files the Macintosh Transfer Utility receives: §5 is
the handoff contract between the two apps.

Conventions for every format here:
- **Big-endian** multi-byte fields (the 68000's own order). Every field
  is written byte by byte; no Swift structure goes to disk as it is.
- **Data fork only.** No resource fork. The Mac file type and creator are
  set when the file is put on an HFS volume (the Transfer Utility does it);
  macOS doesn't carry them reliably.
- PICT files start with a **512-byte header of zeros**, as every PICT file
  does; the picture follows at offset 512.
- PackBits is Apple's (Inside Macintosh I, `PackBits`). Every row is packed
  on its own; no run crosses a row.

| Output | Use | Format | Section |
|---|---|---|---|
| Print image | Edited in MacPhoto on the Plus; printed | 8-bit grey PICT, version 2 | §1 |
| Screen image | Shown on the Plus as it is | 1-bit PICT, version 1 | §2 |
| Screen image (rarely) | Shown or touched up in MacPaint | MacPaint document | §3 |

## 1. Print image: 8-bit greyscale PICT (`.pict`)

The 2.5 × 3.5-inch image MacPhoto edits: 750 × 1050, 1050 × 750,
900 × 1260 or 1260 × 900 pixels, 256 greys.

| | |
|---|---|
| Extension | `.pict` |
| Mac type / creator | `PICT` / `MPho` (MacPhoto, PH17) |
| Size | about 0.8–1.2 MB (PackBits rarely saves much on photographs) |

**Who can read it.** The Plus has no Color QuickDraw, so its own
`DrawPicture` can't draw an 8-bit PixMap. **MacPhoto decodes the file
itself**, a row at a time, and never needs it whole in memory (the rows
come in order, each with its own length). Whether any other program on the
Plus (SuperPaint 2.0, Photoshop 1.0, the Scrapbook) opens it is untested
(PQ6); nothing depends on it. On a colour Mac it is an ordinary
version 2 picture.

The layout is one fixed subset of version 2. A reader may refuse anything
else. Version 2 opcodes are 2 bytes, and every opcode starts on an even
offset from the start of the picture.

| Bytes | Content |
|---|---|
| 512 | file header: zeros |
| 2 | picSize: the picture's length **modulo 65,536** (meaningless for pictures this big; readers use the file's length) |
| 8 | picFrame: top 0, left 0, bottom = height, right = width |
| 2 + 2 | `0011` VersionOp, `02FF` version 2 |
| 2 + 24 | `0C00` HeaderOp, **extended** form: version −2 (`FFFE`), reserved 0 (2), hRes and vRes as Fixed = PPI (`012C0000` for 300, `01680000` for 360), srcRect = picFrame (8), reserved 0 (4) |
| 2 + 10 | `0001` Clip: region size 10, bounding box = picFrame |
| 2 + 2 + 2 + 20 | `00A1` LongComment: kind **100** (application comment), size 20, then MacPhoto's record below |
| 2 | `0098` PackBitsRect |
| 2 | rowBytes = width, with the top bit set (PixMap): `0x8000 | width` |
| 8 | bounds = picFrame |
| 2, 2, 4 | pmVersion 0, packType 0 (PackBits by row), packSize 0 |
| 4, 4 | hRes, vRes: Fixed PPI, as in the header |
| 2, 2, 2, 2 | pixelType 0 (chunky), pixelSize 8, cmpCount 1, cmpSize 8 |
| 4, 4, 4 | planeBytes 0, pmTable 0, pmReserved 0 |
| 4, 2, 2 | colour table: ctSeed 0, ctFlags 0, ctSize 255 (256 entries) |
| 256 × 8 | entry *i*: value *i*, then red = green = blue = (255 − *i*) × 257: **index 0 white, 255 black**, the Mac's grey convention |
| 8, 8, 2 | srcRect = picFrame, dstRect = picFrame, mode 0 (srcCopy) |
| … | *height* rows, top to bottom: a **2-byte** count (rowBytes > 250), then that row packed. A pixel's value is 255 − grey, where grey is 0 black … 255 white, gamma-encoded (Gray Gamma 2.2, PH9) |
| 0 or 1 | a zero byte if needed so the next opcode is at an even offset |
| 2 | `00FF` OpEndPic |

**MacPhoto's record** (in the LongComment, 20 bytes):

| Offset | Size | Field | Value |
|---:|---:|---|---|
| 0 | 4 | signature | `MPho` |
| 4 | 2 | recordVersion | 1 (a reader ignores a record whose version it doesn't know) |
| 6 | 2 | ppi | 300 or 360 |
| 8 | 2 | printWidth | hundredths of an inch: 250 or 350 |
| 10 | 2 | printHeight | 350 or 250 |
| 12 | 2 | orientation | 0 portrait, 1 landscape |
| 14 | 2 | checksumType | 1: CRC-32 of the unpacked pixel values, row by row |
| 16 | 4 | pixelChecksum | CRC-32 (IEEE 802.3, reflected, polynomial 0xEDB88320, initial and final XOR 0xFFFFFFFF: zlib's `crc32`) |

**Valid when:** the 512-byte header is zeros; the opcodes are exactly the
ones above, in that order; (width, height) and the record's ppi, print
size and orientation are one of the four allowed profiles and agree
(width × 100 = printWidth × ppi, likewise height); hRes and vRes equal
the PPI; the colour table is exactly as above; every row unpacks to
exactly rowBytes bytes; the CRC matches; the file ends at OpEndPic.

## 2. Screen image: 1-bit PICT (`.pict`)

| | |
|---|---|
| Extension | `.pict` |
| Mac type / creator | `PICT` / `MPho` (PH17) |
| Picture | **version 1** (PH5), one 1-bit 512 × 342 bitmap; 1 = black |

Version 1 so the Plus's own QuickDraw draws it: any application that
opens PICTs can show it. This is also the screensaver format: After Dark
2.0's Slide Show module shows PICT files from its Slide Show Folder
(DECISIONS.md PQ4). An 8-bit print PICT must not go there.

| Bytes | Content |
|---|---|
| 512 | file header: zeros |
| 2 | picSize: the picture's length, from picSize to the end opcode inclusive |
| 8 | picFrame: top 0, left 0, bottom 342, right 512 |
| 2 | `11 01`: picVersion, version 1 |
| 1 + 10 | `01` clipRgn: region size 10, bounding box = picFrame |
| 1 | `98` PackBitsRect |
| 2 | rowBytes: 64 |
| 8 | bounds: 0, 0, 342, 512 |
| 8 | srcRect: 0, 0, 342, 512 |
| 8 | dstRect: 0, 0, 342, 512 |
| 2 | mode: 0 (srcCopy) |
| … | 342 rows, each: a 1-byte count (rowBytes ≤ 250) then that row packed |
| 1 | `FF`: end of picture |

Version 1 opcodes are one byte with no word alignment. The largest
possible picture is about 22.6 KB, so picSize always holds the true
length.

## 3. MacPaint document (`.MAC`)

Rarely used (PH15), but supported.

| | |
|---|---|
| Extension | `.MAC` |
| Mac type / creator | `PNTG` / `MPNT` (MacPaint's own) |

From Apple Technical Note #86 and **MacPaint 1.3's source**
(`../MacPaintClipboardFix/source/…/MacPaint.p`, `ReadWrite`):

| Bytes | Content |
|---|---|
| 4 | version: **0** (PH4). MacPaint treats any version below 2 as "no patterns" and keeps the user's own palette (MacPaint.p lines 1366–1378). Version 2 would replace the palette with whatever the file holds. |
| 304 | patterns: zeros (ignored at version 0) |
| 204 | unused: zeros |
| … | 720 rows of 72 bytes, **each row packed separately** with PackBits; no run crosses a row. MacPaint unpacks row by row and beeps, blanking the rest, if a row doesn't come to exactly 72 bytes (MacPaint.p lines 1266–1276). |
| 0–511 | zeros, padding the file to a whole multiple of 512 bytes, as MacPaint itself does when saving (MacPaint.p line 1489). MacPaint reads a shorter file without complaint. |

**Placement (PH12, Jack's choice):** the 512 × 342 image **centred on the
page**: rows 189–530, bytes 4–67 of each row (x 32, a whole 4 bytes).
The rest of the page is white (0).

## 4. Export manifest (`manifest.json`)

To be specified in Phase 2: one JSON file per export folder listing each
output, its source photograph, the profile, sizes, SHA-256 and the
validation result. For the user's record, not for the Plus.

## 5. Handoff contract with the Macintosh Transfer Utility

| Kind | Extension | Type / creator | Folder on the transfer volume (proposed) | Recognised by |
|---|---|---|---|---|
| Print image (8-bit PICT) | `.pict` | `PICT` / `MPho` | `Print Files` | §1's rules |
| Screen image (1-bit PICT) | `.pict` | `PICT` / `MPho` | `PICT Files` | §2's rules |
| MacPaint | `.MAC` | `PNTG` / `MPNT` | `MacPaint Files` | §3's rules |

The two PICT kinds share an extension and type; the content tells them
apart (version 2 with an 8-bit PixMap and MacPhoto's record, or version 1
with a 512 × 342 bitmap). The folder names are the Transfer Utility's;
whether the print images keep the "Print Files" folder is for that session
to put to Jack. Each file's Mac name keeps its extension and fits in 31
characters.

The Transfer Utility recognises a file **by its content**, with its own
validators written from these rules and the public specifications,
independently of MacPhoto's writers. The extension is a hint only.

**Fixtures:** at the end of Phase 2, in `Fixtures/handoff/` in this
repository: good files of each kind from the real exporters (portrait and
landscape, 300 and 360 PPI), and deliberately bad ones (named
`bad-<what>.<ext>`), with a `README.md` listing what each tests and its
SHA-256. The Transfer Utility copies them into its own tests; it never
writes here.
