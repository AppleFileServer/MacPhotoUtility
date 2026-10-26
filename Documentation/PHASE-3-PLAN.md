# Phase 3 plan: the single-image app

**Status: approved by Jack, 26 October 2026.** PH46–PH56 are in
`DECISIONS.md` as Provisional until Jack has used the window.

**Deliverable** (specification §12): you can import, compose and export
one photograph **without the command line**. The window has what
specification §4–§5 ask for, for one photograph at a time; the queue of
many comes in Phase 4, and the window is laid out so it can be added
without starting again.

Phase 2's Plus checks and the freeze of `FILE_FORMATS.md` can happen at
any point during this phase; nothing here changes the files.

## Decisions proposed

| Code | Decision |
|---|---|
| PH46 | **A thin window over a tested model.** The SwiftUI views only draw and pass on gestures. Everything they show or do goes through an `EditorSession` (the photograph, its composition, the settings, the latest previews, the export) in the engine, where the tests can reach it without a window. Slow work (opening a photograph, rendering previews, exporting) runs off the main thread and never freezes the window. |
| PH47 | **One window, three areas** (specification §4): on the left the **photograph** (its name, size as stored and upright, EXIF orientation, kind, status; the place where Phase 4's queue goes); in the middle the **composition editor**; on the right **output and export**. Open with ⌘O, the toolbar or by dragging a file onto the window. |
| PH48 | **The composition editor** shows the whole turned photograph with the crop as a rectangle; what the crop leaves out is dimmed, so nothing is removed silently (specification §5). A switch chooses which crop you're editing, **Print** (5:7 or 7:5) or **Screen** (512:342, PH13); the other shows as a thin outline. Drag inside the crop to move it; zoom with a slider, a pinch or the scroll wheel (1× to 8×); turn left or right a quarter; Portrait/Landscape for the print; **Reset** puts that crop back to centred, full size. The arithmetic stays in `Composition` (new tested helpers: move by a fraction, zoom about the centre); the view only converts points to fractions. |
| PH49 | **The editor draws from a working copy**, the upright photograph reduced once on import to at most 2,000 pixels on its long side, so moving the crop is instant even for a 48-megapixel photograph. The previews never use it. |
| PH50 | **Two previews, from the real renderers** (specification §5, §7): **Print**, the actual 8-bit print image at the chosen PPI, scaled to fit and labelled "2.5 × 3.5 in, 900 × 1260 px, 360 PPI"; **Mac Plus screen**, the actual 1-bit Atkinson image at exactly 1:1 or 2× with square pixels, labelled "512 × 342, as on the Plus". They re-render about a fifth of a second after you stop changing something; a newer change cancels an older render. The two are clearly separate (specification §4: print versus screen). |
| PH51 | **Output and export:** PPI (360, or 300); which files, Print PICT and Screen PICT ticked, MacPaint not (rarely used, PH15); the destination folder, chosen with a folder panel and remembered. **Export** writes through Phase 2's `Exporter`; if a name is taken it asks **Replace**, **Keep Both** or **Cancel** (PH40); then it lists what was written and checked, with **Show in Finder**. It never says "transferred" or "printed" (specification §9). |
| PH52 | **Warnings and errors in words**: an import error as a message naming the file and the reason (Phase 1's texts); the small-photograph warning (PH14) shown under the preview it affects as soon as it applies, not only at export; an export failure says nothing was written. |
| PH53 | **Remembered between launches:** only the destination folder, the PPI and the output choices. The composition isn't saved yet (projects are Phase 5), so closing the photograph simply closes it. |
| PH54 | **Keyboard and appearance:** ⌘O open, ⌘E export, ⌘[ and ⌘] turn, ⌘0 reset the crop, Tab between Print and Screen crops, the arrow keys nudge the crop; light and dark appearance; VoiceOver labels on every control. |
| PH55 | **The app bundle** as the Transfer Utility's: `tools/build-app.sh` makes `build/MacPhoto Utility.app` (release build, Info.plist with the version, signed ad hoc). A placeholder icon until Phase 6. Version **D-0.0.4**. |
| PH56 | **How it's checked:** the session and the new `Composition` helpers by tests; the window by running the real app and taking screenshots of each state (opening, editing each crop, turning, previews, a conflict, an error, a small photograph); then **you** use it on two or three of your own photographs, and Phase 3 is done when you've exported one without the command line and are happy with how it works. |

## Steps

1. **Engine** (PH46, PH48, PH49): `Composition` helpers (move, zoom about
   the centre, reset one crop); the working copy; `EditorSession` with
   its debounced, cancellable previews and the export flow, including the
   conflict question. Tests.
2. **Window skeleton** (PH47, PH52): the three areas, opening by panel,
   menu and drag-and-drop, the photograph's details, error messages.
3. **Composition editor** (PH48): the dimmed photograph, both crops,
   dragging, zooming, turning, orientation, reset, the keyboard.
4. **Previews** (PH50): print and screen, labelled, with warnings.
5. **Output and export** (PH51, PH53): settings, folder, export, the
   conflict question, the result.
6. **Finish** (PH54, PH55): shortcuts, menus, appearance, VoiceOver
   labels, `tools/build-app.sh`.
7. **Checks** (PH56): the screenshots, timings with a large photograph
   (open, preview, export), the documents (`ARCHITECTURE.md`, `TESTING.md`
   with a manual checklist, `CHANGELOG.md`, `PHASE-3-REPORT.md`).
8. **You try it**, and we adjust what doesn't feel right.

## Added after Jack tried it

PH57: brightness and contrast for the screen image; PH58: resizing a crop
by its corners (see DECISIONS.md).

## Not in Phase 3

The photo queue, folders and batch export (Phase 4); saving and reopening
projects (Phase 5); the icon, user guide and release (Phase 6).
