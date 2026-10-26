# File formats

**Status: draft 0.2 (Phase 0, 26 October 2026). PROVISIONAL throughout.**
What the editable files for MacPhoto are is still open (DECISIONS.md
PQ8): it may add an 8-bit PICT, or change §1 and §2.
Frozen as version 1.0 at the end of Phase 2, once the exporters and their
validators agree and the screen files have opened on the real Plus. After
that, any change is a new format version recorded in `DECISIONS.md`, never
a silent edit (SPECIFICATION.md §15).

These are also the files the Macintosh Transfer Utility receives: §5 is
the handoff contract between the two apps.

Conventions for every format here:
- **Big-endian** multi-byte fields (the 68000's own order). Every field
  is written byte by byte; no Swift structure goes to disk as it is.
- **Data fork only.** No resource fork. The Mac file type and creator are
  set when the file is put on an HFS volume (the Transfer Utility does it);
  macOS doesn't carry them reliably.
- 1-bit images: **1 = black**, 0 = white (QuickDraw's convention).

## 1. Print master (`.mppi`)

The 2.5 × 3.5-inch print image: 8-bit greyscale, uncompressed, made to be
read by a future 68000 C application one strip of rows at a time.

| | |
|---|---|
| Extension | `.mppi` |
| Mac type / creator | `MPpi` / `MPho` (PROVISIONAL; MacPhoto's creator) |
| Size | 64 + width × height bytes: 787,564 (300 PPI) or 1,134,064 (360 PPI) |

### Header: 64 bytes, every field at an even offset

| Offset | Size | Field | Value |
|---:|---:|---|---|
| 0 | 4 | magic | `MPPI` (0x4D 50 50 49) |
| 4 | 2 | versionMajor | 1. A reader refuses a major version it doesn't know. |
| 6 | 2 | versionMinor | 0. A reader accepts a higher minor version (only additions in reserved space). |
| 8 | 2 | headerLength | 64. A reader seeks to pixelOffset, not to 64. |
| 10 | 2 | flags | 0 (none defined; a reader ignores unknown bits) |
| 12 | 2 | width | pixels: 750, 1050, 900 or 1260 |
| 14 | 2 | height | pixels: 1050, 750, 1260 or 900 |
| 16 | 2 | bitsPerPixel | 8 |
| 18 | 2 | pixelEncoding | 1 = greyscale, 0 black … 255 white, gamma-encoded (Gray Gamma 2.2) |
| 20 | 4 | rowBytes | = width (no padding; every allowed width is even) |
| 24 | 4 | pixelOffset | 64 |
| 28 | 4 | pixelLength | rowBytes × height |
| 32 | 2 | ppi | 300 or 360 |
| 34 | 2 | printWidth | hundredths of an inch: 250 or 350 |
| 36 | 2 | printHeight | hundredths of an inch: 350 or 250 |
| 38 | 2 | orientation | 0 portrait, 1 landscape |
| 40 | 2 | checksumType | 0 none, 1 CRC-32 of the pixel data |
| 42 | 2 | reserved | 0 |
| 44 | 4 | pixelChecksum | CRC-32 (IEEE 802.3, reflected, polynomial 0xEDB88320, initial and final XOR 0xFFFFFFFF: zlib's `crc32`), or 0 |
| 48 | 16 | reserved | 0 |

### Pixels

Rows from top to bottom, each row's pixels from left to right, one byte
each. The file ends exactly at `pixelOffset + pixelLength`.

### Validity (both the writer's check and the Transfer Utility's)

magic; versionMajor 1; headerLength ≥ 64; bitsPerPixel 8;
pixelEncoding 1; (width, height, ppi, printWidth, printHeight,
orientation) one of the four allowed profiles and consistent with each
other (width × 100 = printWidth × ppi, likewise height); rowBytes =
width; pixelOffset ≥ headerLength; pixelLength = rowBytes × height; file
length = pixelOffset + pixelLength; if checksumType 1, the CRC matches;
reserved fields 0.

## 2. PICT screen image (`.pict`)

| | |
|---|---|
| Extension | `.pict` |
| Mac type / creator | `PICT` / `SPNT` (PROVISIONAL: SuperPaint 2.0, on the Plus's Applications disk, owns the only PICT there) |
| Picture | **version 1** (PH5), one 1-bit 512 × 342 bitmap |

Layout:

| Bytes | Content |
|---|---|
| 512 | file header: all zeros (applications skip it) |
| 2 | picSize: the picture's length in bytes, from picSize to the end opcode inclusive |
| 8 | picFrame: top 0, left 0, bottom 342, right 512 |
| 2 | `11 01`: picVersion, version 1 |
| 1 + 10 | `01` clipRgn: region size 10, bounding box = picFrame |
| 1 | `98` PackBitsRect |
| 2 | rowBytes: 64 |
| 8 | bounds: 0, 0, 342, 512 |
| 8 | srcRect: 0, 0, 342, 512 |
| 8 | dstRect: 0, 0, 342, 512 |
| 2 | mode: 0 (srcCopy) |
| … | 342 rows, each: a 1-byte count (rowBytes ≤ 250) then that row packed with PackBits |
| 1 | `FF`: end of picture |

Version 1 opcodes are one byte with no word alignment. The largest
possible picture (every row incompressible) is about 22.6 KB, so picSize
always holds the true length.

## 3. MacPaint document (`.MAC`)

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

| Kind | Extension | Type / creator | Folder on the transfer volume | Recognised by |
|---|---|---|---|---|
| MacPaint | `.MAC` | `PNTG` / `MPNT` | `MacPaint Files` | §3's rules |
| PICT | `.pict` | `PICT` / `SPNT` | `PICT Files` | §2's rules |
| Print master | `.mppi` | `MPpi` / `MPho` | `Print Files` | §1's rules |

(The folder names are the Transfer Utility's, approved by Jack.) Each
file's Mac name keeps its extension and fits in 31 characters.

The Transfer Utility recognises a file **by its content**, with its own
validators written from these rules and the public specifications,
independently of MacPhoto's writers. The extension is a hint only.

**Fixtures:** at the end of Phase 2, in `Fixtures/handoff/` in this
repository: good files of each kind from the real exporters (portrait and
landscape, 300 and 360 PPI), and deliberately bad ones (named
`bad-<what>.<ext>`), with a `README.md` listing what each tests and its
SHA-256. The Transfer Utility copies them into its own tests; it never
writes here.
