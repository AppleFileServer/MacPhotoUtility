# Phase 6 report (in progress, 27 October 2026)

**D-0.0.7.** Compatibility and release, as planned in `PHASE-6-PLAN.md`
(PH80–PH89). Everything that doesn't need the Plus is done; 1.0 waits for
the Plus checks, the freeze and Jack's acceptance (PH89). 115 tests pass.

## Done

- **Version names** (PH80): the release is 1.0; PH11's B- for beta
  withdrawn in favour of the programme's P22.
- **The icon** (PH84): drawn by `tools/make-icon.swift`; `make-icon.sh`
  makes `Resources/AppIcon.icns`, which the app bundle carries.
- **`USER-GUIDE.md`** and draft **`RELEASE-NOTES.md`** (PH85).
- **`tools/check-fresh-checkout.sh`** (PH87): a clone of the last commit
  built, passed every test and built the signed app in 66 s.
- **`tools/make-release.sh`** (PH88): a trial into the scratchpad made the
  zipped app, the notes and guide, six example files (all valid), the
  source bundle (verified), the checks and `SHA256SUMS` (24 files, all
  verified); the unzipped app's signature verified.
- **Dark appearance** checked with `-MPUAppearance dark`, without
  changing the Mac's own setting.
- **VoiceOver labels** read silently through the accessibility interface
  (Jack is in an office and can't play sound): the app's 26 controls all
  labelled; the window's title-bar buttons are named by their role.

## Found and fixed

- **The release's checksums skipped files** in folders with spaces in
  their names (`Print Files`); fixed (9cefbf1).
- **Launched by a file, the app could have no window.** Dropping a folder
  or photograph on the icon with the app not running, or double-clicking
  a project, started it with menus but no window; and with Phase 5's
  workaround in place a project sent to the running app could still quit
  it. SwiftUI's own handling of files sent to the app is the cause in
  both directions: it closes this window when a file arrives while it's
  running, and doesn't present it when the app is launched by one;
  neither `defaultLaunchBehavior(.presented)` nor
  `handlesExternalEvents(matching: ["*"])` changed that. Now the app
  takes every incoming file itself from launch, and opens its window
  with SwiftUI's own `openWindow` action when there isn't one. Checked:
  cold with a folder, warm with a photograph, cold with a project, warm
  with a photograph, a plain launch, warm with a project: one window
  each time, with the files in it.

## Waiting for

- The Plus checks (`PLUS-CHECKS.md` on `Photo Test.hda`), then
  `COMPATIBILITY.md`, the freeze (PH82) and the Transfer session.
- Jack's acceptance of Phases 3, 4 and 5.
- Version 1.0, the release candidate, the tag, the release, the
  catalogue (PH89).
