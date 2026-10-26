# Phase 5 report (26 October 2026)

**D-0.0.6.** Saved projects, as planned in `PHASE-5-PLAN.md` (PH70–PH79).
Built and checked by tests and the running app; done when Jack has saved
a project, quit, moved a photograph and reopened it (PH79). 115 tests
pass.

## What was built

- **`ProjectFile`**: the `.macphoto` JSON file (FILE_FORMATS.md §6),
  versioned; a newer version refused before anything else is read;
  written to a temporary name and renamed.
- **Fingerprints** (size and SHA-256) and Finder bookmarks taken when a
  photograph is added, with its thumbnail.
- **The queue as a project**: save, open, new; unsaved changes tracked
  (adding, removing, framing, settings, exports; not merely looking);
  on opening, each photograph found by bookmark, then path, and accepted
  only if its fingerprint matches; moved ones updated and listed, the
  rest kept as Missing with their framing; Locate… and Locate in
  Folder…; a different file used only after an explicit question, and
  the choice recorded.
- **Export history** per photograph, from every export (Export This and
  Export All), shown in the details panel as "Exported and checked …".
- **The window**: the File menu (New ⌘N, Open… ⌘O, Open Recent, Save ⌘S,
  Save As… ⇧⌘S; Add Photographs… ⌘I, Add Folder… ⇧⌘I), the project's name
  and edited mark in the title bar, Save / Don't Save / Cancel on
  closing, quitting, New and Open, double-clicking a project to open it.

## Found while building

- **Sending a file to the running app closed its window and quit it.**
  macOS delivers a file opened with the app (Dock icon, Open With, a
  double-clicked project) as an "open documents" event; SwiftUI's own
  handling of it closed the app's only window to "activate" one for the
  file, and with no window left the app quit. Telling SwiftUI the window
  handles all such events didn't stop it. Traced with the call stack at
  the window's closing; fixed by taking the event directly once the app
  is running (files sent while it's starting still go through SwiftUI,
  which then makes the window). Phase 4's drag-onto-the-Dock check had
  passed only because the app wasn't yet declaring a document type of
  its own.
- **The Finder sends files as bookmarks**, which the first version of
  that event handler didn't read; it now resolves them.
- **A relinked photograph stayed blank in the editor** while still
  selected; it's now shown as soon as it's found.
- The zoom slider's VoiceOver value used a mismatched number format
  (logged by the system); fixed.

## Checked by running the app

In scratch folders, with three test images and a copy of one of Jack's
photographs: added by sending the folder to the running app; one framed;
⌘S, the Save panel, "Phase Five Test": the title and edited mark right;
quit without being asked. Then one photograph moved to another folder,
another deleted after copying it to a backup folder; the project opened
by double-click: "Found where they had moved to, by their content:
square.png … Not found: portrait-3x4.jpg"; the missing row with its
framing and Locate buttons; Locate in Folder… on the backup: "Found 1.
Nothing is missing now."; IMG_8691 with the same framing it was saved
with; quitting asked Save / Don't Save / Cancel, and Save recorded the
new places in the file.

Afterwards the app's remembered folder was set back to Jack's own and
the test project taken out of Open Recent.

## Not checked

- Close button with unsaved changes (the same question as quitting, by
  the same code; quitting was checked).
- Locate… for a single file with a different photograph (the question;
  tested without the window).
- Dark appearance, VoiceOver, pinch and scroll wheel, as before.
- Jack's own project (PH79).
