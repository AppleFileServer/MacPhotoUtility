#!/bin/sh
# A clean build from a fresh checkout (PH87; specification §12): clones the
# committed repository into a temporary folder, builds everything, runs
# the tests and builds the app there, and keeps the log.
#
# Usage: tools/check-fresh-checkout.sh [LOG]     (default: build/fresh-checkout.log)

set -eu
cd "$(dirname "$0")/.."
REPO=$(pwd)
LOG=${1:-$REPO/build/fresh-checkout.log}
mkdir -p "$(dirname "$LOG")"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
export SDKROOT

{
    echo "Fresh checkout of $(git rev-parse --short HEAD) ($(git describe --tags --always)), $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Uncommitted changes in the working tree are not included."
    sw_vers | tr '\n' ' '; echo
    swift --version 2>&1 | head -1
    git clone --quiet "$REPO" "$WORK/MacPhotoUtility"
    cd "$WORK/MacPhotoUtility"
    echo "--- swift build"
    swift build 2>&1 | tail -3
    echo "--- tools/test.sh"
    tools/test.sh 2>&1 | grep -E "^✘|Test run with" || true
    echo "--- tools/build-app.sh"
    tools/build-app.sh 2>&1 | tail -1
    codesign --verify --strict "build/MacPhoto Utility.app" && echo "signature verified"
} > "$LOG" 2>&1

cat "$LOG"
grep -q "^✘" "$LOG" && { echo "FAILED: see $LOG" >&2; exit 1; }
grep -q "signature verified" "$LOG" || { echo "FAILED: see $LOG" >&2; exit 1; }
echo "fresh checkout: built, tested and app built ($LOG)"
