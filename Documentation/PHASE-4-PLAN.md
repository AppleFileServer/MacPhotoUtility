# Phase 4 plan: batch processing

**Status: approved by Jack, 26 October 2026.** PH59–PH69 are in
`DECISIONS.md` as Provisional until Jack has exported a folder with it.

**Deliverable** (specification §12): a mixed set of photographs, portrait
and landscape, each framed on its own, exported reliably in one
operation. The window keeps Phase 3's editor and previews; the left-hand
panel becomes the queue.

```
┌────────────────────┬──────────────────────────────┬──────────────────┐
│ + Photos  + Folder │  editor (the selected photo)  │ Output           │
│ ▣ IMG_0419    L ✓  │                               │  360 / 300 PPI   │
│ ▣ IMG_2973    L    │                               │  files, folder   │
│ ▣ IMG_5474    P ⚠  │                               │                  │
│ ▣ cbf18d32…   L ✕  │  previews                     │ [Export This]    │
│ 12 photographs,    │                               │ [Export All (11)]│
│ 1 can't be read    │                               │  3 of 11 ▓▓░░    │
└────────────────────┴──────────────────────────────┴──────────────────┘
```

## Decisions proposed

| Code | Decision |
|---|---|
| PH59 | **A queue over the editor.** A `PhotoQueue` in the engine holds the photographs in order, each with its own composition and screen tone, its status and a thumbnail, plus the shared settings (PPI, files, folder). The `EditorSession` edits the selected photograph and writes every change back to its entry. As in Phase 3, the window only draws this and passes on gestures, and the tests drive it without a window. |
| PH60 | **Adding photographs:** Add Photographs… (several files), Add Folder… (the photographs directly in it, not in its subfolders), or dragging files and folders onto the window. Photographs are recognised by content (PH21); anything else in a folder is skipped and counted ("12 added; 3 skipped: not photographs", with the list). A file already in the queue isn't added twice. New ones are added in name order (IMG_2 before IMG_10, as the Finder sorts) after those already there. |
| PH61 | **Quick to add, slow work later.** Adding reads only each file's header and a small thumbnail with the EXIF orientation applied (ImageIO's thumbnail, about 160 px), in the background, two at a time; so a folder of hundreds appears in seconds. That's enough for the default composition (PH26) and the list. The full photograph is decoded only when it's selected or exported. Damage found then marks that entry, never the whole queue. |
| PH62 | **The queue panel:** each row a thumbnail, the name, P or L for the print's orientation, and a status: not yet seen, seen, ⚠ small (PH14), ✕ can't be read (with the reason on hover and below), ✓ exported. Select with the mouse or ↑ ↓; ⌫ removes the selected photographs from the queue (never from the disk); Remove All. Under the list, the count and the selected photograph's details (Phase 3's panel). |
| PH63 | **Shared and individual settings** (specification §8): the PPI, the files and the folder are shared by the whole queue; framing, turns, orientation and screen tone belong to each photograph and nothing shared ever changes them. Switching 300 ↔ 360 PPI keeps every photograph's framing (PH24). |
| PH64 | **Export All, one photograph at a time** (specification §8: predictable memory): each is decoded, rendered, written and checked (Phase 2's all-or-nothing per photograph), then let go before the next. Progress shows "3 of 11: IMG_5474" with **Stop**, which finishes the photograph in hand and stops; files already written stay. A photograph that fails is marked with the reason and the batch carries on. At the end, a summary: exported, failed (each with its reason), warnings, with Show in Finder. **Export This** exports only the selected photograph, as in Phase 3. |
| PH65 | **Names and conflicts for the whole batch, decided before anything is written.** First, two photographs in the queue that would get the same name (IMG_0001.HEIC from two folders) get " 2", " 3" automatically, listed in the summary. Then, if any name is already taken in the folder, one question for the batch: **Keep Both** (the default), **Replace**, **Skip Those Photographs** or **Cancel**. Nothing is ever overwritten without that answer. |
| PH66 | **Photographs you haven't looked at:** a photograph never selected would be exported with the default framing, centred. Export All says so first ("4 photographs haven't been looked at; export them framed centred?"): **Export All** or **Cancel**, with their names. |
| PH67 | **Memory stays flat:** thumbnails for the queue, the selected photograph's full image and working copy, and at most one photograph being exported. Tested with a queue of 200 generated photographs. |
| PH68 | **Nothing is saved between launches yet** (projects are Phase 5): quitting with photographs whose framing was changed and not exported asks first ("Quit and lose the framing of 5 photographs?"). |
| PH69 | **How it's checked:** the queue by tests, including specification §11's batch list (mixed orientations, individual crops surviving the batch, shared PPI not changing framing, one failure not stopping the rest, no silent overwrite, sources unchanged); a generated test folder with portrait, landscape, square, a damaged file, a text file and two photographs of the same name; screenshots of the running app; then **you** export a folder of your own photographs in one go. Version **D-0.0.5**. |

## Steps

1. **Engine:** the quick probe and thumbnail (PH61); `PhotoQueue` with
   adding, removing, selection, status and the shared settings (PH59,
   PH60, PH63); the `EditorSession` editing a queue entry. Tests.
2. **Batch export:** names planned for the batch, the conflict question,
   the unseen question, one at a time, progress, Stop, failures, the
   summary (PH64–PH66). Tests, including the 200-photograph memory check
   (PH67).
3. **The queue panel** (PH62): rows, thumbnails, status, keyboard, adding
   by menu, button and drag, removing.
4. **Output panel:** Export This, Export All, progress and Stop, the
   questions, the summary.
5. **Quitting** with unexported changes (PH68).
6. **Checks and documents** (PH69): screenshots, timings for adding a
   folder and exporting it, `ARCHITECTURE.md`, `TESTING.md` (with the
   manual checklist extended), `CHANGELOG.md`, `PHASE-4-REPORT.md`.
7. **You try it** on a folder of your photographs.

## Not in Phase 4

Saving and reopening the queue as a project, relinking moved photographs
and the export history (Phase 5); the icon, user guide and release
(Phase 6).
