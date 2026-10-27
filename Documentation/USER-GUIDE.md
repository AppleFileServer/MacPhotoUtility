# MacPhoto Utility: user guide

MacPhoto Utility prepares photographs for a Macintosh Plus. From each
photograph it makes:

- a **print image**: 2.5 × 3.5 inches, 8-bit greyscale, for MacPhoto on
  the Plus to edit and for printing;
- a **screen image**: the Plus's whole screen, 512 × 342 dots in black and
  white, to look at on the Plus or use in After Dark's Slide Show;
- if you want it, the screen image as a **MacPaint** document.

It never changes your photographs. It doesn't put files on the Plus (the
Macintosh Transfer Utility does that), and it doesn't print.

## Installing

Unzip `MacPhoto-Utility-B-0.9.0.zip` (or the version you have) and drag **MacPhoto Utility** to
Applications. It needs an Apple silicon Mac with macOS 26.

It's signed for its owner's own use, not notarised. If macOS won't open it
the first time, open System Settings ▸ Privacy & Security and click
**Open Anyway** beside its name.

## One photograph

1. **Add it:** File ▸ Add Photographs… (⌘I), the + button, or drag it onto
   the window or the Dock icon. JPEG, HEIC, PNG and TIFF photographs are
   read; the picture is turned the right way up from the camera's own
   record.
2. **Frame the print.** With **Print crop** chosen above the picture, the
   white frame is what will be printed; everything outside it is dimmed.
   Drag inside to move it; drag a corner to make it bigger or smaller
   (it keeps the print's shape); or use the zoom slider, a pinch or the
   scroll wheel. Turn the photograph with the turn buttons (⌘[ and ⌘]);
   choose **Portrait** or **Landscape** for the print. **Reset** (⌘0) puts
   the frame back to centred and full size.
3. **Frame the screen image.** Choose **Screen crop** (or press Tab). The
   screen has its own frame, the Plus screen's shape, set the same way;
   the print's frame shows as a yellow outline.
4. **Look at the previews.** Underneath: the print as it will be, and the
   Plus screen exactly as it will look, one Plus dot per point (**Larger…**
   shows it twice the size). They follow your changes within a moment.
5. **Brightness and contrast** under the screen preview change the screen
   image only, never the print. **Normal** puts them back.
6. **Choose the output** on the right: **360 PPI** (the default) or 300 PPI
   for the print (the framing doesn't change); which files; and the
   **folder** they go into (**Choose…**).
7. **Export This Photograph** (⌘E). Each file is checked after it's
   written; the list shows what was made.

## Many photographs

- **Add a folder** (File ▸ Add Folder…, ⇧⌘I): the photographs directly in
  it are added, in the Finder's order. Anything else in the folder is left
  out and listed ("3 skipped: not photographs…").
- Each photograph keeps **its own** framing, turns and screen settings.
  The PPI, the files and the folder are shared by all of them.
- Each row shows the print's orientation (**P** or **L**) and a status:
  not looked at yet (○), small (⚠), can't be read (✕, with the reason),
  exported (✓).
- **Export All** (⇧⌘E) exports them one at a time, with progress and a
  **Stop** button (it finishes the photograph in hand). A photograph that
  fails is marked and the others carry on; a summary says what happened.
- Before it starts, Export All asks if some photographs haven't been
  looked at (they'd be exported framed centred), and, if files of the
  same names are already in the folder, whether to **Keep Both** (the new
  files get a number), **Replace** them, or **Skip Those Photographs**.
  Two photographs with the same name in the queue are numbered
  automatically.
- **Remove** (⌫) takes photographs out of the queue, never off the disk.

## Projects

- **File ▸ Save** (⌘S) keeps the queue as a project (`.macphoto`): every
  photograph's framing and screen settings, the output settings, and what
  was exported when. The photographs themselves aren't copied into it.
- **File ▸ Open Project…** (⌘O), **Open Recent**, or double-click a
  project. If photographs have been moved or renamed since, they're found
  again by their content and you're told. Any that can't be found stay in
  the project, marked missing, with their framing kept: select one and use
  **Locate…**, or **Locate in Folder…** to search a folder for all of
  them. A file that isn't the same photograph is only used if you say so.
- Closing, quitting, New and Open ask **Save**, **Don't Save** or
  **Cancel** if anything is unsaved.

## The files, and where they go on the Plus

Inside the folder you chose:

| Folder | File | What it is | On the Plus |
|---|---|---|---|
| `Print Files` | `name.pict` | the 8-bit print image, about 1 MB | for MacPhoto (when it exists); Photoshop 1.0 may open it |
| `PICT Files` | `name.pict` | the screen image, 1 bit | opens in any PICT program, e.g. SuperPaint; for the screensaver, copy into `System Folder:After Dark Files:Slide Show Folder` |
| `MacPaint Files` | `name.MAC` | the screen image on a MacPaint page, centred | MacPaint (your patterns are left alone) |

`manifest.json` in the folder lists every file exported there, from which
photograph, how framed, and its checksum. It's for your records; the Plus
doesn't need it.

**Keep the print images out of the Slide Show folder:** the Plus's own
QuickDraw can't draw 8-bit pictures, so Slide Show can't show them.

The Macintosh Transfer Utility puts the files on the Plus's disk in the
same three folders, with each file's type and creator set.

## Messages and warnings

- **⚠ Small for its output:** the frame covers fewer pixels of the
  photograph than the image needs, so it will be enlarged and may look
  soft. It still exports. Zooming out, or 300 PPI instead of 360, helps
  the print.
- **✕ Can't be read:** the file is damaged or isn't a photograph this app
  reads; the reason is shown.
- **Missing:** a project's photograph that isn't where it was (see
  Projects).
- An export that fails leaves **nothing** half-written in the folder.

## Good to know

- 360 PPI gives the print more detail; the framing is the same at 300.
- The screen image is dithered with Atkinson's method, the classic Mac
  look. Brightness and contrast can help a dark or flat photograph.
- The window can be checked in dark appearance without changing the Mac:
  `open -a "MacPhoto Utility" --args -MPUAppearance dark`.
