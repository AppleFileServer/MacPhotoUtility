# Changelog

## D-0.0.2 (26 October 2026, not released)

Phase 1: the conversion engine, run from the harness. No files for the
Plus yet (Phase 2).
- Reads JPEG, HEIC, PNG and TIFF photographs, the right way up, in grey;
  refuses other kinds and damaged files with a clear message.
- Frames each photograph with its own print crop and screen crop.
- Makes the print image at exactly 750 × 1050 … 1260 × 900, and the
  512 × 342 screen image dithered with Atkinson.
- Warns when a crop is too small for its output.
- `mpu convert` shows what it would make, with PNG previews; `mpu compare`
  sets seven ways of dithering side by side (PH32); `mpu testimages`.

## D-0.0.1 (26 October 2026, not released)

Phase 0: the project's skeleton. Nothing for a user yet.
- The four print sizes, and `mpu profiles` to list them.
- Draft file formats: the 8-bit print PICT, the 1-bit screen PICT, MacPaint.
- A placeholder window.
- The MacPaint page centres the screen image (PH12).
- 360 PPI is the default print resolution; 300 PPI remains (PH19).
