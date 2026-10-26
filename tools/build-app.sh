#!/bin/sh
# Builds "MacPhoto Utility.app" in build/ (Phase 3; PH55), as the Transfer
# Utility builds its own: the release build of the app in a bundle with its
# Info.plist (the version from Version.swift) and icon (PH84), signed ad hoc.
#
# Usage: tools/build-app.sh

set -eu
cd "$(dirname "$0")/.."
SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
export SDKROOT
VERSION=$(sed -n 's/.*static let string = "\(.*\)".*/\1/p' Sources/MacPhotoKit/Version.swift)
swift build -c release --product MacPhotoUtility
BIN=$(swift build -c release --show-bin-path)/MacPhotoUtility
APP="build/MacPhoto Utility.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/MacPhotoUtility"
sed "s/@VERSION@/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
echo "built $APP ($VERSION)"
