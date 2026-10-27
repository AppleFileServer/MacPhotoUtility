# MacPhoto Utility B-0.9.1

**27 October 2026. A release for use before the Plus checks** (PH90,
PH92): installable and complete, but not yet tried on the Macintosh Plus,
and the Macintosh Transfer Utility can't carry its files there yet.
B-1.0.0 follows once both have been done.

## New in B-0.9.1

- **The User's Guide**, 62 pages, in `manual/`: the own-use edition
  (`MacPhoto-Utility-Users-Guide.pdf`) and the plain one
  (`…-plain.pdf`). What is still to be seen on the Plus is marked
  CHECK; those parts are settled for B-1.0.0.
- The crop switch reads **Print Crop** and **Screen Crop**, as the guide
  names them (PH91).

The app is otherwise B-0.9.0's; its files and projects are the same.

A Mac app that prepares photographs for a Macintosh Plus: a 2.5 × 3.5-inch
8-bit greyscale print image (a PICT, for MacPhoto on the Plus and for
printing), and the Plus's screen as a 1-bit Atkinson image (PICT, or
MacPaint). One photograph or a folder of them, each framed on its own,
saved as a project. See `USER-GUIDE.md`.

## Installing

Unzip `MacPhoto-Utility-B-0.9.1.zip` and drag **MacPhoto Utility** to
Applications. It needs an Apple silicon Mac with macOS 26. It's signed ad
hoc for its owner's own use, not notarised: if macOS won't open it the
first time, open System Settings ▸ Privacy & Security and click **Open
Anyway** beside its name.

## What's in it

- Photographs: JPEG, HEIC, PNG and TIFF, turned upright from the camera's
  record, never changed.
- Framing: a print crop (5:7 or 7:5) and a screen crop (512:342) for each
  photograph: drag, resize by the corners, zoom, turn, portrait or
  landscape; the real print and screen images previewed as you go;
  brightness and contrast for the screen image only.
- Output: 360 PPI (default) or 300 PPI; the print PICT, the screen PICT
  and MacPaint; `Print Files`, `PICT Files`, `MacPaint Files` and a
  manifest; every file checked after it's written; nothing replaced
  without asking.
- Many photographs: a queue, Export All one at a time with progress and
  Stop, a summary, one question about names already there.
- Projects (`.macphoto`): the queue, the framing, the settings and the
  export history; moved photographs found again by their content, missing
  ones kept until located.

## What's been checked

- **Automatically:** 115 tests (`checks/tests.txt`): the file formats byte
  by byte (and Apple's PackBits example), the framing arithmetic, the
  importer, the queue, projects and the specification's batch rules. A
  fresh clone builds and passes them (`checks/fresh-checkout.txt`).
  netpbm, written outside Apple, reads both PICT kinds exactly as the
  app's own checks do.
- **In Mini vMac** (an emulated Plus: this confirms nothing about the
  real one): MacPaint opened a `.MAC` centred with the user's patterns
  kept; SuperPaint 2.0 drew a screen PICT; Photoshop 1.0 opened a print
  PICT as Gray Scale.
- **By hand on this Mac:** the window with Jack's own photographs and
  generated ones, light and dark appearance, every control's VoiceOver
  label (read silently).

## Not yet checked

- **Anything on the real Macintosh Plus** (`PLUS-CHECKS.md`).
- **Getting the files there:** the Macintosh Transfer Utility's picture
  support isn't built yet.
- **The print PICT in MacPhoto:** MacPhoto on the Plus doesn't exist yet.
- **Printing** through the print bridge, and whether 360 PPI shows.

## The file formats

`FILE_FORMATS.md` is **draft 0.3**: the formats may still change before
B-1.0.0 if the Plus finds a problem. Files made by B-0.9.x can then be
made again from their project.
