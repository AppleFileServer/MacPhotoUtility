# Phase 3 report (26 October 2026)

**D-0.0.4.** The window, as planned in `PHASE-3-PLAN.md` (PH46–PH56).
Built and checked by tests and by running the real app; Phase 3 is done
when Jack has used it on his own photographs (PH56). 93 tests pass.

## What was built

- **`EditorSession`** (engine): the photograph, a working copy of at most
  2,000 px, the composition, settings remembered between launches,
  previews rendered off the main thread about 0.2 s after a change (older
  renders cancelled), and the export with its conflict question.
- **`Composition` helpers**: move, zoom about the centre, reset one crop,
  clamp after a turn, and the crop as fractions for drawing.
- **The window**: the photograph's details on the left; the editor with
  the Print/Screen crop switch, turns, orientation, zoom and Reset, the
  photograph dimmed outside the crop and the other crop as a yellow
  outline; the print and screen previews beneath it; output and export
  on the right.
- **Opening** by ⌘O, dragging onto the window, dragging onto the Dock
  icon or Open With (the app declares JPEG, HEIC, PNG and TIFF as a
  viewer, at the lowest rank, so it never becomes their default app).
- **`tools/build-app.sh`** → `build/MacPhoto Utility.app`, signed ad hoc.

## Changed from the plan

- **Brightness and contrast for the screen image** (PH57, Jack's request
  after trying the window): two sliders and Normal under the Mac Plus
  preview, per photograph, never touching the print. Checked by hand-worked
  values, the print staying byte for byte the same, compositions from
  Phase 2 manifests still reading, and in the running app.
- **Resizing a crop by its corners** (PH58, Jack's request): handles on the
  crop being edited; its shape kept, the opposite corner fixed; checked by
  tests (the anchor, the larger movement, the limits, the screen shape)
  and by dragging a handle in the running app.

- **The previews sit under the editor**, not in the right-hand column as
  the plan's sketch had them: that way the screen preview fits at exactly
  one Plus pixel per point on a 13-inch screen.
- **Keep Both is the conflict dialog's default** and Replace is marked
  destructive, so pressing Return never overwrites a file. The first
  build had Replace as the default; the screenshots caught it.

## Checked by running the app

Screenshots (in the session's scratchpad; they show Jack's photographs,
so not in the repository) of: the empty window; a portrait photograph
with EXIF orientation 6 coming up upright; a landscape photograph;
zooming with the slider and dragging the print crop (the print preview
follows, the screen preview doesn't); the screen crop; export (two files
written and checked, listed with Show in Finder; both pass `mpu
validate`); export again (the question; Cancel; Keep Both making
`IMG_8691 2.pict`); a damaged file (the message, the open photograph
kept); a 640 × 480 photograph (the print warning at once, none for the
screen); a quarter turn (portrait print, "Turned 90° clockwise").

The test folder the app remembered was removed from its settings
afterwards, so the app starts with no folder chosen.

**Timings** (release build, this MacBook): opening and rendering both
images takes 0.45 s for a 12 MP HEIC and 0.28 s for a 48 MP JPEG; a full
export of the 48 MP photograph 0.27 s.

## Not checked

- **Dark appearance:** the launch option didn't switch the app, and the
  system setting wasn't changed for a test. The window uses system
  colours, apart from the deliberate dimming and crop lines over the
  photograph.
- **VoiceOver:** labels are set on the controls, the crop and the
  previews, but nobody has listened to them.
- **The pinch and the scroll wheel** were built but not driven by the
  automatic checks (only the slider was).
- **Jack's use** (PH56).
