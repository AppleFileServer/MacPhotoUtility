# MacPhoto Utility 1.0

**Draft (D-0.0.7): completed at the release, after the Plus checks.**

A Mac app that prepares photographs for a Macintosh Plus: a 2.5 × 3.5-inch
8-bit greyscale print image (a PICT, for MacPhoto on the Plus and for
printing), and the Plus's screen as a 1-bit Atkinson image (PICT, or
MacPaint). One photograph or a folder of them, each framed on its own,
saved as a project. The files reach the Plus with the Macintosh Transfer
Utility. See `USER-GUIDE.md`.

## Installing

Unzip `MacPhoto-Utility-1.0.zip` and drag **MacPhoto Utility** to
Applications. It needs an Apple silicon Mac with macOS 26. Signed ad hoc
for its owner's own use, not notarised: if macOS won't open it the first
time, System Settings ▸ Privacy & Security ▸ Open Anyway.

## What's been checked

- **Automatically:** every file is read back and checked after it's
  written; the tests (`checks/tests.txt`) cover the formats byte by byte,
  the framing, the queue, projects and the batch rules of the
  specification; netpbm, written outside Apple, reads both PICT kinds
  exactly as MacPhoto's own checks do.
- **In Mini vMac** (an emulated Plus, so it confirms nothing): MacPaint
  opened a `.MAC` centred, with the user's patterns kept; SuperPaint 2.0
  drew a screen PICT; Photoshop 1.0 opened a print PICT as Gray Scale.
- **On the real Plus:** *(to be written from `PLUS-CHECKS.md`)*.

## Not checked

- **The print PICT in MacPhoto:** MacPhoto on the Plus doesn't exist yet
  (PH83). The format is fixed in `FILE_FORMATS.md` 1.0 for it.
- **Printing** through the print bridge, and whether 360 PPI shows on the
  inkjet printer (PQ5).
- VoiceOver has labels throughout but hasn't been listened to.

## The file formats

`FILE_FORMATS.md` *(1.0 at the release)*: the print PICT, the screen
PICT, MacPaint, the manifest, the handoff to the Macintosh Transfer
Utility, and the project file.
