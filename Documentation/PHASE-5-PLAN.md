# Phase 5 plan: saved projects

**Status: approved by Jack, 26 October 2026.** PH70–PH79 are in
`DECISIONS.md` as Provisional until Jack has saved and reopened a project.

**Deliverable** (specification §12): work can be paused and resumed
without losing composition choices. A project remembers the queue,
every photograph's framing, the output settings and what was exported;
it never holds the photographs themselves (specification §9).

## Decisions proposed

| Code | Decision |
|---|---|
| PH70 | **A project file, `Name.macphoto`:** JSON, readable in a text editor, versioned (`projectVersion` 1), written field by field like every other format here and documented as `FILE_FORMATS.md` §6. It's for this Mac only; it never goes to the Plus. It holds: the app version and dates; the settings (PPI, files, folder); the photographs in queue order, each with its location, its fingerprint (size and SHA-256), its framing and screen tone, whether it's been looked at, and its export history. **No photograph is copied into it.** |
| PH71 | **One project per window, one window,** as now. The File menu becomes: **New Project** (⌘N), **Open Project…** (⌘O), **Open Recent**, **Save** (⌘S), **Save As…** (⇧⌘S); adding photographs moves to **Add Photographs…** (⌘I) and **Add Folder…** (⇧⌘I). The window's title is the project's name ("Untitled" until saved) with the usual edited mark. Double-clicking a `.macphoto` file opens it. |
| PH72 | **Saving is yours to choose, as in other Mac apps:** Save writes the file (to a temporary name, then renamed, like the exports); closing, quitting, New or Open with unsaved changes asks **Save**, **Don't Save** or **Cancel**. This replaces Phase 4's quit question. No autosave, so a project only changes when you say. |
| PH73 | **Finding the photographs again** (specification §9). On opening, each photograph is looked for by a Finder bookmark first (which follows a file moved or renamed on the same disk), then at its saved path, and is accepted only if its size and SHA-256 match the fingerprint. One that moved is updated and listed ("3 photographs had moved; found by their content"). One that can't be found stays in the queue as **Missing**, its framing kept, until you relink it. |
| PH74 | **Relinking, never substituting:** **Locate…** on a missing photograph chooses its file; **Locate in Folder…** searches one folder for every missing photograph, by name and then by fingerprint. A file whose fingerprint doesn't match is never used silently: "This isn't the same photograph (its content is different). Use it anyway, keeping the framing?", and the answer is recorded. |
| PH75 | **Fingerprints are taken when a photograph is added,** in the background with the thumbnail (a 3 MB HEIC takes a few milliseconds), so saving is quick and a project opened later can tell a moved photograph from a different one. |
| PH76 | **Export history** per photograph: each export's date, folder, files (with their SHA-256s), PPI and warnings, from the same records as the manifest; the details panel shows "Exported 3 times; last 27 Oct 10:41 to MacPhoto Files" and the list. It says "exported and checked", never "transferred" or "printed" (specification §9). |
| PH77 | **Errors and warnings kept:** a photograph that couldn't be read keeps its reason in the project; warnings are worked out again when it's opened, since they depend on the settings. |
| PH78 | **Settings:** a project carries its own PPI, files and folder; a new project starts from the ones last used (Phase 3's remembered settings). A project whose folder no longer exists opens with the folder shown as missing, and Export asks for one. |
| PH79 | **Older and newer files:** a project from a newer version of the app is refused with a message rather than half-read; unknown fields are ignored; a damaged file is reported in words and nothing is changed. **Checked** by tests (a round trip of everything, a moved photograph, a renamed one, a missing one relinked, a wrong file refused unless confirmed, a damaged project, a newer version), screenshots, and **you** saving a project, quitting, moving a photograph and reopening it. Version **D-0.0.6**. |

## Steps

1. **Fingerprints** taken on adding (PH75); `Project` (the file's
   contents) with writing, reading and its version rules (PH70, PH79);
   `FILE_FORMATS.md` §6. Tests.
2. **Opening a project:** bookmarks, paths, fingerprints, moved and
   missing photographs (PH73); the export history recorded on every
   export (PH76). Tests.
3. **Relinking** (PH74). Tests.
4. **The window:** the File menu, the title and edited mark, Save /
   Don't Save / Cancel (PH71, PH72), opening by double-click, Missing
   rows with Locate…, the history in the details panel.
5. **Checks and documents:** screenshots, `ARCHITECTURE.md`,
   `TESTING.md`, `CHANGELOG.md`, `PHASE-5-REPORT.md`.
6. **You try it:** save, quit, move a photograph, reopen.

## Not in Phase 5

The icon, user guide, example files and release (Phase 6).
