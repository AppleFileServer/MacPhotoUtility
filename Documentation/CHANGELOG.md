# Changelog

## D-0.0.7 (26 October 2026, not released)

Phase 6, before the Plus checks.
- An icon of its own, in the style of the MacMusic Converter, Macintosh
  Transfer and Macintosh Backup Utilities.
- A user guide (`USER-GUIDE.md`) and draft release notes.
- `tools/check-fresh-checkout.sh` and `tools/make-release.sh`.
- `-MPUAppearance dark` at launch shows the app alone in dark appearance,
  for checking it.
- Fixed: launched by a file (a folder or photograph dropped on the icon,
  Open With, a double-clicked project), the app could start with no
  window; and a project sent to the running app could still quit it.

## D-0.0.6 (26 October 2026, not released)

Phase 5: projects.
- Save the queue as a project (`.macphoto`): every photograph's framing
  and screen settings, the output settings and each photograph's export
  history; never the photographs themselves.
- New, Open, Open Recent, Save, Save As; double-click a project to open
  it; asked to save before closing, quitting, New or Open.
- Photographs moved or renamed since are found again by their content;
  ones that can't be found stay in the project with their framing, to be
  located (one at a time or a folder at once). A different file is only
  used if you say so.
- Adding photographs is now ⌘I (⇧⌘I for a folder); ⌘O opens a project.
- Fixed: sending a file to the app while it was running (the Dock icon,
  Open With) closed its window and quit it.

## D-0.0.5 (26 October 2026, not released)

Phase 4: many photographs at once.
- A queue: add photographs or folders (menu, buttons, dragging onto the
  window or the Dock icon); thumbnails, print orientation and status for
  each; anything that isn't a photograph is skipped and listed.
- Each photograph keeps its own framing and screen settings; the PPI,
  files and folder are shared.
- Export All, one photograph at a time, with progress and Stop; a
  photograph that fails doesn't stop the rest; a summary at the end.
- Asked once about names already in the folder (Keep Both, Replace, Skip
  Those Photographs, Cancel), and about photographs not looked at yet.
- Asked before quitting with framing changed and not exported.

## D-0.0.4 (26 October 2026, not released)

Phase 3: the app's window, for one photograph at a time.
- Open a photograph from the File menu, by dragging it onto the window or
  the Dock icon, or with Open With.
- Frame the print and the screen image separately: drag, zoom, turn,
  portrait or landscape, reset; what's left out is dimmed.
- See the real print image and the real 1-bit screen image as you go,
  with a warning when a photograph is too small.
- Choose 360 or 300 PPI, the files and the folder; Export; asked before
  anything is replaced.
- Brightness and contrast for the screen image, never the print.
- Resize a crop by dragging its corners; its shape stays the same.

## D-0.0.3 (26 October 2026, not released)

Phase 2: the files for the Plus, made from the harness.
- Writes the 8-bit print PICT, the 1-bit screen PICT and the MacPaint
  document, each checked by reading it back before it counts.
- Exports into `Print Files`, `PICT Files` and `MacPaint Files`, with
  names that work on the Plus; never overwrites without being asked.
- `manifest.json` records what was exported, from what, and how.
- `mpu export`, `mpu validate`, `mpu fixtures`; handoff fixtures for the
  Macintosh Transfer Utility in `Fixtures/handoff/`.

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
