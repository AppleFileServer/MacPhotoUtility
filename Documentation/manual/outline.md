# MacPhoto Utility User's Guide: outline

Step 2 of `Documentation/MANUAL-PLAN.md`. The book in the series' shape
(the MacMusic style guide §5: learning, using, reference, appendixes,
glossary, index), with the utilities addendum's rules for a modern Mac
program. Each section names its figures (codes from `figures.md`) and
its sources:

- **[A]** MacPhoto Utility B-0.9.0 as it is (the app, `USER-GUIDE.md`,
  `FILE_FORMATS.md`, `DECISIONS.md`);
- **[E]** the Mini vMac check (`COMPATIBILITY.md`);
- **[P]** to be seen on the real Plus: marked CHECK until then (MG8).

Page counts are estimates for the 7½ × 9 in page. **About 52 pages.**

## Front matter (about 6 pages)

| Page | Contents | Figures |
|---|---|---|
| Cover | Own-use: the series' MacDraw composition, the Plus's screen showing a MacPhoto screen image, tinted pale blue. Plain: the title, MacPhoto's icon, the screen image | cover-screen |
| Inside front cover | Copyright page: © 2026 Jack McAteer; the trademark lines; "Written by … Program by …" and a playful line; the not-affiliated statement; the edition line ("MacPhoto Utility B-1.0.0") in place of a part number | |
| i | Title page: the title top left, the icon (own-use: the logo) top right | icon |
| ii | Contents | |
| iii–iv | **About This Manual** | |

**About This Manual** [A]: what MacPhoto Utility is for (a print and a
screen image from each photograph; the Plus's MacPhoto edits the print;
the screen image is to look at, or for After Dark); the two computers
("your Mac", "the Macintosh Plus"); what you need (an Apple silicon Mac
with macOS 26; the Macintosh Transfer Utility to carry the files; a Plus
with System 6.0.7 and a BlueSCSI); what you should know already (the
Finder; the *Macintosh Owner's Guide* for the Plus); how to use the
book; conventions; **Important** (the ruled note): your photographs are
never changed, but a file you choose to replace is gone.

## Chapter 1: Learning MacPhoto Utility (about 13 pages)

Opener spread (MQ2), the chapter's contents, an introduction, lessons,
What Now?

**Introduction: What MacPhoto Utility Does** (2 pages): one photograph
becomes two pictures, a print the size of a playing card in 256 greys,
and the Plus's whole screen in black and white; why they're framed
separately (the shapes differ); the journey from your Mac to the Plus,
drawn as a row of boxes (photograph → MacPhoto Utility → Transfer
Utility → Plus: MacPhoto, SuperPaint, After Dark). Figures: d-journey,
d-two-shapes. [A]

| No. | Lesson | Covers | Figures | Sources |
|---|---|---|---|---|
| 1 | Installing MacPhoto Utility | Unzip, drag to Applications, Open Anyway the first time | f-zip, f-open-anyway | [A] |
| 2 | Adding a Photograph | Add Photographs (⌘I), the + button, or drag; the queue's row; the photograph upright; the details | w-main (labelled, across the page), p-queue | [A] |
| 3 | Framing the Print | Print crop, drag, the slider and the corners, Reset, Portrait and Landscape; the preview follows (in the sample) | p-editor | [A] |
| 4 | Framing the Screen Image | Screen crop, its own frame, the yellow outline of the other; the Mac Plus preview at one dot a point; Larger | p-editor-screen, p-screen-preview | [A] |
| 5 | Exporting | 360 or 300 PPI, the files, Choose a folder, Export This Photograph; what's written, Show in Finder | p-output, p-exported | [A] |
| 6 | Seeing It on the Macintosh Plus | The Transfer Utility; on the Plus, a screen PICT in SuperPaint and in After Dark's Slide Show, the MacPaint file; the print image waits for MacPhoto | plus-superpaint, plus-macpaint | [E], [P] CHECK |

**What Now?**: try a folder of photographs (Chapter 2), save your work
as a project, and keep the print images for MacPhoto.

## Chapter 2: Using MacPhoto Utility (about 14 pages)

Opener spread, the chapter's contents (every task listed), task pages in
the wide column (the addendum), one topic after another:

| Topic | Tasks | Figures |
|---|---|---|
| Adding Photographs | To add photographs; to add a folder; to add by dragging (the window, the Dock icon); what's skipped and why; if a photograph can't be read | p-queue, a-skipped, p-cant-read |
| The Queue | What the marks mean (○, ⚠, ✕, ✓, P and L); to remove photographs; to look at another | p-queue-marks |
| Framing | To move a frame; to resize it by its corners; to zoom (slider, pinch, scroll wheel); to turn a photograph; portrait or landscape; to start again | p-editor, p-handles |
| The Screen Image | To make it lighter or darker, or more contrasty; to see it larger; why it looks the way it does (Atkinson, in two lines) | p-tone, f-larger |
| Small Photographs | What the warning means; what to do (zoom out, 300 PPI) | p-small-warning |
| The Output | To choose 360 or 300 PPI; to choose the files; to choose the folder | p-output |
| Exporting | To export one photograph; to export every photograph (in the sample); if some haven't been looked at; if a file is already there (in the sample); to stop; the summary | p-output, a-unseen, a-taken, f-summary |
| Projects | To save your work; to open a project; if photographs have moved; if a photograph is missing (Locate, Locate in Folder); if a different file is chosen | a-save, a-opened, p-missing |

## Chapter 3: Reference (about 9 pages)

Opener spread, then:

- **The window** (2 pages): w-main across the page, labelled on both
  sides: the queue, the details, the editor and its toolbar, the
  previews, Brightness and Contrast, Output.
- **Each part:** the queue and its rows; the editor's controls; the two
  previews; the output panel.
- **The menus:** MacPhoto Utility, File (New Project … Export All),
  Edit, Photograph (Turn Left … Reset Crop), Window, Help; each command
  with its keys. Figures: m-file, m-photograph.
- **The files it makes:** the three kinds and where they go, the
  manifest, the project file; names on the Plus (31 characters).
- **Limits and settings:** sizes, PPI, zoom 1–8, brightness and contrast
  −100 to +100, what's remembered between launches.

## Appendixes (about 6 pages)

- **A, Messages:** every alert and message, what it means, what to do. [A]
- **B, The Files on the Macintosh Plus:** the three folders; type and
  creator; SuperPaint and other PICT programs; After Dark's Slide Show
  (screen PICTs only); MacPaint (centred, your patterns kept); Photoshop
  1.0 and the print PICT; MacPhoto when it comes. [E], [P] CHECK
- **C, Troubleshooting:** won't open the first time; a photograph won't
  add; it looks too dark on the Plus; a project's photographs are
  missing. [A]
- **D, Specifications:** the print image (sizes, PPI, 8-bit grey PICT,
  about 1.1 MB), the screen image (512 × 342, 1-bit, Atkinson), MacPaint;
  the formats in brief (`FILE_FORMATS.md`); requirements. [A]

## Back matter (about 4 pages)

Glossary (about 30 terms: Atkinson dithering, crop, export, frame,
MacPaint document, manifest, PICT, PPI, print image, project, queue,
screen image, …); index; back cover with an "at a glance" panel (the
window's parts and the main keys).
