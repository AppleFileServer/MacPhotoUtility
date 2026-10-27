#!/bin/sh
# Builds a PDF from one of the manual's HTML files (copied from the
# Bulk Formatter Utility User's Guide's, which are the MacMusic User's Guide's): copies it,
# Documentation/manual/manual.css, the figures and the fonts into build-manual/,
# then prints it with headless Chrome (tools/manual/print-pdf.py), Paged.js
# laying out the pages.
# The tools live outside the project (as MacMusic's):
#   MANUAL_TOOLS   default ~/MacPlusProjects/manual-tools
#
# The own-use edition's private assets (MG5), if there, are copied into
# build-manual/private/ (never into the project's docs):
#   MANUAL_ASSETS  default ~/MacPlusProjects/manual-assets-private
#
# Usage: tools/manual/build-pdf.sh <html file> <out.pdf> [<anchors.json>]

set -eu
cd "$(dirname "$0")/../.."
TOOLS=${MANUAL_TOOLS:-$HOME/MacPlusProjects/manual-tools}
ASSETS=${MANUAL_ASSETS:-$HOME/MacPlusProjects/manual-assets-private}
CHROME=$TOOLS/chrome-headless-shell-mac-arm64/chrome-headless-shell
SRC=$1
OUT=$2
B=build-manual
# Clear only what's copied in, so the other parts' PDFs are kept.
rm -rf "$B/fonts" "$B/figures" "$B/private" "$B/page.html"; mkdir -p "$B/fonts" "$B/figures"
if [ -d "$ASSETS" ]; then
    mkdir -p "$B/private"
    cp "$ASSETS"/rainbow-logo.png "$B/private/" 2>/dev/null || true
    cp "$ASSETS"/cover-macphoto.jpg "$B/private/" 2>/dev/null || true
fi
cp "$SRC" "$B/page.html"
cp Documentation/manual/manual.css "$TOOLS/paged.polyfill.js" "$B/"
cp Documentation/manual/figures/png/*.png "$B/figures/"
cp "$TOOLS"/fonts/built/*.ttf "$B/fonts/"
"$TOOLS/venv/bin/python" tools/manual/print-pdf.py "$CHROME" "$B/page.html" "$OUT" ${3:+"$3"}
