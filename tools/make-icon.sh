#!/bin/sh
# Remakes Resources/AppIcon.icns from tools/make-icon.swift (PH84): the
# icon drawn at every size macOS wants, then iconutil. The .icns is kept in
# the repository, so building the app doesn't need this.
set -eu
cd "$(dirname "$0")/.."
SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
export SDKROOT
WORK=$(mktemp -d)
SET="$WORK/AppIcon.iconset"
mkdir -p "$SET"
for n in 16 32 128 256 512; do
    swift tools/make-icon.swift "$SET/icon_${n}x${n}.png" $n > /dev/null
    swift tools/make-icon.swift "$SET/icon_${n}x${n}@2x.png" $((n * 2)) > /dev/null
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
rm -r "$WORK"
echo "made Resources/AppIcon.icns"
