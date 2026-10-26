# MacPhoto Utility

## Project

A native macOS app that turns photographs into a 2.5 × 3.5-inch 8-bit
greyscale PICT (edited by MacPhoto on the Plus) and a 512 × 342 1-bit
Atkinson screen image (PICT, MacPaint) for a Macintosh Plus (4 MB,
System 6.0.7). The requirements:
`Documentation/SPECIFICATION.md` (Jack's brief, unedited); decisions in
`Documentation/DECISIONS.md` (PH, PQ). Start with `README.md` and
`Documentation/DEVELOPMENT_PLAN.md`.

Related projects (don't change them):
- `~/MacPlusProjects/MacintoshTransfer/` (formerly `MacMusicTransfer`):
  the Macintosh Transfer Utility, developed alongside in its own session.
  It reads this app's files; the contract is `FILE_FORMATS.md` §5. Agree
  changes with that session (SendMessage) and Jack; never write there.
- `~/MacPlusProjects/Programme/`: the suite's framework (P25 for this).

## Build and test

    tools/test.sh

## Working rules

- **Phase by phase** (specification §12): the smallest coherent step,
  tests, documents, report; plan with numbered decisions first.
- **Never commit until Jack approves.**
- **Never change the source photographs.**
- **No other print sizes**, and no silent change to a file format:
  a new format version, recorded.
- **Never claim compatibility not seen on the real Plus.**
- **Never write to the BlueSCSI SD card.** Disk images for tests: copies
  in the scratchpad, hfsutils with a private HOME (`~/.hcwd` is shared).
- **Mini vMac is shared:** short runs only.
- Throwaway diagnostics in the scratchpad, not the project.
