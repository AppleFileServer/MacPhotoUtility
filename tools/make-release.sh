#!/bin/sh
# Makes a release of MacPhoto Utility (PH88), from the committed source, as
# the Macintosh Transfer Utility's does, into
#   ~/MacPlusProjects/releases/MacPhoto-Utility-<version>/
# holding:
#   MacPhoto-Utility-<version>.zip   the app (unzip, drag to Applications)
#   RELEASE-NOTES.md, USER-GUIDE.md, SHA256SUMS
#   examples/                        files made from the generated test images (PH86)
#   source/MacPhotoUtility.bundle    the whole repository (git bundle, with tags)
#   checks/tests.txt                 the tests, run for this release
#   checks/fresh-checkout.txt        the clean build from a fresh clone (PH87)
#   checks/made.txt                  from what, on what
#
# For its owner's own use, like the rest of the suite; not published.
# It refuses a dirty working tree or an existing release folder.
#
# Usage: tools/make-release.sh            a release (candidate)
#        tools/make-release.sh --bundle   after tagging: refresh the source bundle
#                                         (and SHA256SUMS) in the existing release
#        MPU_RELEASES=DIR tools/make-release.sh    somewhere else (a trial)

set -eu
cd "$(dirname "$0")/.."
VERSION=$(sed -n 's/.*static let string = "\(.*\)".*/\1/p' Sources/MacPhotoKit/Version.swift)
OUT=${MPU_RELEASES:-$HOME/MacPlusProjects/releases}/MacPhoto-Utility-$VERSION
NAME="MacPhoto Utility"
SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
export SDKROOT

# Names have spaces in them (Print Files): passed with NULs, not split.
sums() { (cd "$OUT" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 shasum -a 256 > SHA256SUMS); }

if [ "${1:-}" = "--bundle" ]; then
    [ -d "$OUT" ] || { echo "no release at $OUT" >&2; exit 1; }
    git bundle create "$OUT/source/MacPhotoUtility.bundle" --all 2> /dev/null
    git bundle verify "$OUT/source/MacPhotoUtility.bundle" > /dev/null 2>&1
    sums
    echo "refreshed the source bundle: $(git describe --tags --always)"
    exit 0
fi

[ -z "$(git status --porcelain)" ] || { echo "commit (or stash) your changes first: a release is made from committed source" >&2; exit 1; }
[ -e "$OUT" ] && { echo "$OUT already exists: remove it, or change the version" >&2; exit 1; }
mkdir -p "$OUT/source" "$OUT/checks" "$OUT/examples"

echo "tests…"
tools/test.sh > "$OUT/checks/tests.txt" 2>&1 || { echo "the tests failed: $OUT/checks/tests.txt" >&2; exit 1; }
grep -q "^✘" "$OUT/checks/tests.txt" && { echo "the tests failed: $OUT/checks/tests.txt" >&2; exit 1; }
echo "fresh checkout…"
tools/check-fresh-checkout.sh "$OUT/checks/fresh-checkout.txt" > /dev/null

echo "the app…"
tools/build-app.sh > /dev/null
(cd build && ditto -c -k --keepParent "$NAME.app" "$OUT/MacPhoto-Utility-$VERSION.zip")

echo "examples…"
swift build -c release --product mpu > /dev/null
MPU=$(swift build -c release --show-bin-path)/mpu
WORK=$(mktemp -d)
"$MPU" testimages "$WORK/photos" > /dev/null
for f in landscape-4x3.jpg portrait-3x4.jpg; do
    "$MPU" export "$WORK/photos/$f" --to "$OUT/examples" --only print,screen,macpaint > /dev/null
done
rm -r "$WORK"
mkdir -p "$OUT/examples/handoff"
for f in Fixtures/handoff/*; do
    case "$(basename "$f")" in bad-*) ;; *) cp "$f" "$OUT/examples/handoff/" ;; esac
done
cat > "$OUT/examples/README.md" <<EOT
# Examples

Made by MacPhoto Utility $VERSION from its generated test images (a grid,
a centre square and an "F"; nobody's photographs):

- \`Print Files/\`, \`PICT Files/\`, \`MacPaint Files/\`, \`manifest.json\`:
  a landscape and a portrait test image exported with the default
  framing, as the app exports.
- \`handoff/\`: the good files of the Macintosh Transfer Utility's test set
  (all four print sizes, screen PICTs and MacPaint files) with their
  README; the deliberately broken ones are left out.
EOT

cp Documentation/RELEASE-NOTES.md Documentation/USER-GUIDE.md "$OUT/"
git bundle create "$OUT/source/MacPhotoUtility.bundle" --all 2> /dev/null
git bundle verify "$OUT/source/MacPhotoUtility.bundle" > /dev/null 2>&1
{
    echo "MacPhoto Utility $VERSION"
    echo "commit $(git rev-parse HEAD) ($(git describe --tags --always))"
    echo "made $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    sw_vers | tr '\n' ' '; echo
    swift --version 2>&1 | head -1
    sysctl -n machdep.cpu.brand_string
} > "$OUT/checks/made.txt"
sums
echo "released into $OUT"
