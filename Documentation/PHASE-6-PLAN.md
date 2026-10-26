# Phase 6 plan: compatibility and release

**Status: approved by Jack, 26 October 2026** ("please continue"); PQ11
taken as suggested, (a). PH80–PH89 are in `DECISIONS.md`.

**Deliverable** (specification §12): a tested, documented initial
release, **MacPhoto Utility 1.0**, made from committed source, with what
has been seen on the real Plus written down, and nothing claimed that
hasn't been.

Much of this phase waits on the Plus: the `Photo Test.hda` checks
(Phase 2, step 10) decide whether `FILE_FORMATS.md` can be frozen as 1.0,
and the release follows the freeze. The steps that don't need the Plus
come first.

## Decisions proposed

| Code | Decision |
|---|---|
| PH80 | **Version names:** the release is **1.0**. PH11's "B-x.y.z for a beta" is withdrawn, because the programme's P22 gives "B-" another meaning (the British edition). Before 1.0, builds stay D-0.0.x; a release candidate is the 1.0 build before it's tagged. |
| PH81 | **Compatibility written from evidence only** (specification §15): `COMPATIBILITY.md` records each Plus check from `PLUS-CHECKS.md` with its date and what you saw, separately from the Mini vMac and netpbm results. Anything unchecked is listed as unchecked in the release notes. |
| PH82 | **The format freeze (PH45):** when the Plus checks pass, `FILE_FORMATS.md` becomes **1.0** (§1–§5; §6, the project file, is versioned on its own and isn't part of the handoff). A Plus problem is fixed first, and the fixtures and the test pack are made again. The Transfer session is told the moment it's frozen. |
| PH83 | **The print PICT and MacPhoto:** specification §12 asks for the print format to be checked "with the MacPhoto importer when available". MacPhoto on the Plus doesn't exist yet, so 1.0 records that this check is **outstanding**, says what does confirm the format (our validator, netpbm pixel for pixel, Photoshop 1.0 on the Plus if your check passes), and leaves it to MacPhoto's own development. |
| PH84 | **An icon of its own:** a small print with a Mac Plus-style screen beside it, drawn as SVG and made into `AppIcon.icns` the way the Transfer Utility does (`tools/make-icon.sh`). I'll show you a preview before it goes in. |
| PH85 | **A user guide** (PQ11 decides its form): what the app does and doesn't do, installing it, a walk through one photograph and a whole folder, projects, the files and where they go on the Plus (`Print Files`, `PICT Files`, `MacPaint Files`; After Dark's Slide Show folder for screen PICTs only), the warnings and messages, and the PH14/PH57 notes on small photographs and screen tone. |
| PH86 | **Example files:** the release carries the handoff fixtures' good files and a small set exported from the generated test images (never your photographs), with a note of what each is. |
| PH87 | **A clean build from a fresh checkout** (specification §12): `tools/check-fresh-checkout.sh` clones the repository into a temporary folder, builds, runs the tests and builds the app there, and keeps the log. Nothing outside the repository is needed but Xcode's toolchain and, for one optional test, netpbm. |
| PH88 | **The release** as the Transfer Utility's (`tools/make-release.sh`): refuses uncommitted changes, runs the tests, builds the app, and writes `~/MacPlusProjects/releases/MacPhoto-Utility-1.0/` with the zipped app, `RELEASE-NOTES.md`, the user guide, the examples, `SHA256SUMS`, the source as a git bundle with its tags, and `checks/` (tests, fresh-checkout log, what it was made from). Signed ad hoc, not notarised. For your own use, like the rest of the suite; nothing is published (Q19, the licence, stays open). |
| PH89 | **What 1.0 needs:** your Plus checks passed and recorded; the formats frozen; your acceptance of Phases 3, 4 and 5 (exporting one photograph, a folder, and a saved project reopened); a look at dark appearance and VoiceOver; the release candidate tried by you; then the `v1.0` tag, the release folder, the Programme catalogue set to Released, and the Transfer session told. |

## Steps

**Without the Plus:**
1. PH80: the version names put right in `DECISIONS.md`.
2. The icon (PH84): the SVG, a preview for you, then `make-icon.sh` and
   the bundle.
3. The user guide (PH85), in the form you choose (PQ11).
4. `check-fresh-checkout.sh` (PH87) and `make-release.sh` (PH88), tried
   on a D-0.0.7 build into a scratch folder (not `releases/`).
5. Dark appearance and VoiceOver: with your permission I switch this
   Mac to dark appearance for a few minutes and back, and turn VoiceOver
   on briefly to listen to the window; or you look yourself.

**With the Plus:**
6. Your checks from `PLUS-CHECKS.md` (on `Photo Test.hda`); I write them
   into `COMPATIBILITY.md` (PH81).
7. Anything they find, fixed and checked again.
8. The freeze (PH82), the message to the Transfer session.

**Release:**
9. Version 1.0, the release candidate, your look at it.
10. The tag, the release folder, the catalogue, the Transfer session
    (PH89).

## Open questions

| Code | Question |
|---|---|
| PQ11 | **Answered: (a)**, as suggested (Jack, 26 Oct). **The user guide's form.** (a) A short guide in the release notes and a `USER-GUIDE.md`, as the Transfer Utility does; or (b) a printed manual like the MacLife family's, 7½ × 9 in (P24), made from HTML with headless Chrome as the MacMusic manual is. (a) is quick; (b) matches the shelf. My suggestion: (a) for 1.0, (b) later if you want it in print. |
