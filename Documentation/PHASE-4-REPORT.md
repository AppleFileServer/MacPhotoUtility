# Phase 4 report (26 October 2026)

**D-0.0.5.** Batch processing, as planned in `PHASE-4-PLAN.md`
(PH59–PH69). Built and checked by tests and the running app; done when
Jack has exported a folder of his own (PH69). 107 tests pass (the memory
check runs separately).

## What was built

- **`PhotoQueue`** (engine): adding files and folders, a quick probe and
  thumbnail for each, selection opening a photograph in the editor with
  its own framing, every edit written back, removing, the shared
  settings, and Export All: the unseen question, names planned for the
  batch, the taken-names question, one photograph at a time, progress,
  Stop, failures recorded, the summary.
- **`Importer.probe`**: the header and a 160 px thumbnail with the EXIF
  orientation applied, from ImageIO's thumbnail, without decoding the
  photograph.
- **The window**: the queue panel on the left (thumbnails, P/L, status,
  Remove, Remove All, the skipped list, the selected photograph's
  details); Export All and Export This on the right with progress and
  Stop; the two Export All questions; the summary sheet; adding by menu,
  buttons and dragging onto the window or the Dock icon; the quit guard.

## Found while building

- **A dialog answered twice.** SwiftUI reports a confirmation dialog's
  dismissal as well as the button pressed, and the first build treated
  the dismissal as Cancel. After "Export All" in the unseen question, that
  stray Cancel cleared the next question (names already taken) before it
  could appear. The tests drive the queue without dialogs, so only the
  running app showed it. The dialogs are now answered by their buttons
  only (Escape presses Cancel).
- **Asked twice about the same photographs.** Photographs exported once,
  framed centred with your agreement, were asked about again on the next
  Export All. Now only photographs neither looked at nor exported are.
- **The window was too wide** for this MacBook's 1,408-point screen once
  the queue was added (1,420 at its minimum); the middle column's minimum
  came down to 830, which the previews still fit.
- **Measuring memory needs a quiet process.** Run alongside the other
  tests the footprint fell by 268 MB during the batch (others finishing).
  Run alone and sampled through the batch: 127 MB before, a 229 MB peak,
  74 MB after, for 200 twelve-megapixel photographs: one photograph's
  worth, not 2.4 GB.

## Checked by running the app

A generated folder (landscape, portrait, square, panorama, two small
photographs IMG_2 and IMG_10, a damaged JPEG, a text file, a GIF): the
queue in Finder order, the damaged one ✕ with its reason, the two small
⚠, "2 skipped: not photographs"; selecting one; Export All asking about
the five not looked at; the summary (6 exported, 12 files, 2 warnings);
every row ✓. Export All again: asked about names already there, Keep
Both the default, Replace red; Skip Those Photographs. Then Jack's ten
sample photographs (copies, in the session's scratchpad export folder):
thumbnails right way up, P and L right, "3 of 10: IMG_0419.JPG" with
Stop, 10 exported (20 files, checked; one validated again with `mpu
validate`). Changing one photograph's framing and quitting: "Quit and
lose the framing of 1 photograph?", Cancel the default.

The app's remembered folder was pointed at a scratch folder for these
checks and put back to Jack's own (`~/Macintosh/MacPhoto Files`) after.

## Not checked

- Stop pressed by hand mid-batch: ten photographs export in about three
  seconds, too quickly to press it; the test drives it.
- Pinch and scroll-wheel zoom, dark appearance and VoiceOver, as in
  Phase 3.
- Jack's own folder (PH69).
