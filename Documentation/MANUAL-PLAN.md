# Plan: the MacPhoto Utility User's Guide

**Status: proposed, 27 October 2026. Waiting for Jack's approval.**

A printed-style user's guide (PDF) for MacPhoto Utility, in the series'
own style: the *MacMusic User's Guide*'s style guide
(`~/MacPlusProjects/MacMusicPlayer/docs/manual/style-guide.md`) for the
page, the type, the red, the lessons, task pages, reference, glossary and
index; and *MacMusic Utilities*' style addendum
(`MacMusicPlayer/docs/utilities-manual/style-addendum.md`) for what a
book about a **modern Mac program** needs: two computers, macOS
screenshots in greyscale with their rounded corners, tasks in the wide
column. Built as the *Bulk Formatter Utility User's Guide* was
(`~/MacPlusProjects/FloppyFormatter/docs/plans/manual.md`): its tools
copied here, never changed where they came from. MacMusicPlayer is only
read (programme P20).

## Decisions proposed

| Code | Decision |
|---|---|
| MG1 | **The page: 7½ × 9 in** (programme P24), printed double-sided on colour laser and wire bound. |
| MG2 | **The title:** *MacPhoto Utility User's Guide*. |
| MG3 | **The design:** the style guide's design B (EB Garamond text, bold Helvetica headings, the red-orange second colour, the left margin column and its rule, numbered lessons in red squares, ■ steps, the ruled Important note), with the utilities addendum's rules for modern screens and wide task pages. British spelling; the plain Apple voice; "your Mac" for the modern one and "the Macintosh Plus" (then "the Plus") for the old one. |
| MG4 | **Chapter openers with the red-bordered title** (your choice for *MacMusic Utilities* and the Bulk Formatter's guide): each chapter opens on a two-page spread with a picture bleeding off both pages, its "Chapter n" and title in a white panel framed by a thin red rule (0.75 pt) in the right-hand page's margin column (`utilities.css`, `.opener-title`). The pictures (MQ2): one of Jack's recent landscape photographs per chapter, Atkinson-dithered at 342 pixels high and as wide as the spread needs, in flat pale-grey pixels. |
| MG5 | **Two editions, as the Bulk Formatter's** (BF3): an **own-use** edition with the MacDraw cover's hand, mouse and cable and the rainbow logo, from `~/MacPlusProjects/manual-assets-private/` and never copied into the repository; and a **plain** edition with MacPhoto's icon in the logo's place and a drawn cover. |
| MG6 | **The cover:** the series' MacDraw composition, the Plus's screen showing a MacPhoto screen image (a photograph, dithered by the app), tinted pale blue as the others are. |
| MG7 | **Figures from the real app.** Screens of the window, its dialogs and menus taken from MacPhoto Utility B-0.9.0 itself (window only, never the desktop), greyscale, rounded corners masked and a 2-pixel grey edge (the addendum's rules, its `make-figures.py` copied); callouts in red in the margin. Screens of the Plus from Mini vMac at 1×, short runs only. Kept as figures in `Documentation/manual/figures/`. |
| MG8 | **Accuracy:** every statement checked against B-0.9.0 and its documents; anything not yet seen on the real Plus (SuperPaint, Slide Show, MacPaint, Photoshop 1.0, the Transfer Utility's picture support) marked **CHECK** in the drafts, not guessed, until the Plus checks settle it (as BF6). |
| MG9 | **The shape, about 50 pages:** front matter (cover, copyright, title page, contents, About This Manual); **Chapter 1, Learning MacPhoto Utility** (what it makes and a photograph's journey to the Plus, then lessons: installing, adding a photograph, framing the print, framing the screen image, exporting, seeing it on the Plus; What Now?); **Chapter 2, Using MacPhoto Utility** (task pages: adding photographs, framing, the screen image, the output, exporting one or many, the queue, projects and missing photographs); **Chapter 3, Reference** (the window's parts with callouts, every control and menu, the files and folders, limits); **Appendixes** A messages, B the files on the Plus (where each goes, After Dark's Slide Show, MacPaint, Photoshop 1.0), C troubleshooting, D specifications; glossary; index; back cover with an "at a glance" panel (no separate reference card, as BF4). |
| MG10 | **Files:** this plan; `Documentation/manual/` (outline, figure list, style notes, generated pages, figures); `tools/manual/` (the generators and the PDF build: Paged.js in headless Chrome, with the fonts in `~/MacPlusProjects/manual-tools/`); `build-manual/` (draft PDFs, not committed). When done, both PDFs go into the B-1.0.0 release folder. |
| MG11 | **Order, with your approval at each step:** (1) this plan; (2) the outline with its figure list, and a two-page sample spread showing the opener with its red-bordered title and a task page; (3) the figures; (4) Chapters 1–3, each as a draft PDF; (5) appendixes, glossary, index, covers, the whole book, both editions; (6) proofing after the Plus checks, CHECK items settled, into the B-1.0.0 release. Committed only with your approval. |

## Questions for you (answered by Jack, 27 October 2026)

- **MQ1: (a), his ten sample photographs** in the screenshots.
- **MQ2: Atkinson-dithered photographs from his Photos library** on the
  openers: **landscape** photographs **from the last six months**
  (since late April 2026), **visually appealing**; dithered at **342
  pixels high**, as the Plus's screen, and **wider than 512 where the
  spread needs it** (the 15 × 9 in spread wants about 570 × 342). From a
  shortlist of twelve, **Jack chose** the horses on the steppe
  (Chapter 1), the road to the mesa (Chapter 2) and the Flame Towers in
  Baku (Chapter 3), 27 October 2026. **For this manual only, the
  openers' dots are black, not the series' pale grey** (Jack, 27 October
  2026); the series' style guide is unchanged.
- **MQ3: now**, against B-0.9.0, the Plus-side parts marked CHECK,
  finished for B-1.0.0.

| Code | Question | My suggestion |
|---|---|---|
| MQ1 | **Whose photographs in the figures?** Screens of the app need photographs in them. (a) Your ten samples (kept in the repository's figures, which is private, as *MacMusic Utilities* shows your folders), or (b) the generated test images (grids and an "F"), or (c) Apple's sample pictures from `/Library/User Pictures` (Apple's, so kept in the private assets only). | **(a)**: a book about photographs reads best with real ones, and yours are the ones you'll use. |
| MQ2 | **The openers' pictures:** (a) one of your photographs per chapter, as the app's own 1-bit screen image, enlarged in flat pale-grey pixels across the spread (MacPhoto's own artwork, as MacMusic's openers show its own screen); or (b) scenes from macOS's Macintosh wallpaper, as *MacMusic Utilities*. | **(a)**: it shows what the app does, and needs nothing from Apple. |
| MQ3 | **Timing:** write it now against B-0.9.0, with the Plus-side parts marked CHECK, and finish it for B-1.0.0; or wait until after the Plus checks. | **Now**: the app is complete; only the Plus parts wait. |
