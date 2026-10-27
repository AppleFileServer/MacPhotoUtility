#!/usr/bin/env python3
"""Makes the MacPhoto Utility User's Guide's figures (MANUAL-PLAN.md, MG4,
MG7) into Documentation/manual/figures/png:

- **windows and their parts**, from window captures of the real app
  (`screencapture -o -l`, which leaves the area outside a window's rounded
  corners transparent): put on the page's white, a 2-pixel grey outline
  just inside the window's own edge (a white window needs an edge on a
  white page), greyscale, as *MacMusic Utilities* prints macOS windows; a
  part of a window is cut square, with a thin grey rule round it;
- **chapter openers**: one of Jack's photographs as MacPhoto's own screen
  image (`mpu dither`, plain Atkinson, 342 dots high and as wide as the
  spread), each dot four pixels, black made pale grey, cut into the
  spread's two pages.

The captures and the openers' photographs are private, in
~/MacPlusProjects/manual-assets-private/ (macphoto-screenshots/,
macphoto/openers/); only these figures are in the repository (MQ1).

Usage (with Pillow, as the series' tools): make-figures.py
"""
import os, subprocess, tempfile
from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "Documentation", "manual", "figures", "png")
PRIVATE = os.environ.get("MANUAL_ASSETS", os.path.expanduser("~/MacPlusProjects/manual-assets-private"))
SHOTS = os.path.join(PRIVATE, "macphoto-screenshots")
OPENER_PHOTOS = os.path.join(PRIVATE, "macphoto", "openers")
MPU = os.path.join(ROOT, ".build", "release", "mpu")

OUTLINE = 2     # the window's outline, in the capture's pixels
GREY = 150      # and its tone
RULE = 2        # a part's rule
SCALE = 2       # capture pixels per point (a Retina screen)

# Windows: code -> capture. Parts: code -> (capture, (left, top, right, bottom) in points).
WINDOWS = {"w-main": "s01-window"}
PARTS = {
    "p-editor": ("s01-window", (241, 31, 1109, 396)),
    "p-output": ("s01-window", (1110, 31, 1402, 478)),
}

# Openers: code -> (photograph, width in dots, centre or None), Jack's
# choices (27 October 2026) from his photographs of this summer.
OPENERS = {
    "c1-opener": ("IMG_6710.jpeg", 570, None),      # horses on the steppe
    "c2-opener": ("IMG_8179.jpeg", 570, None),      # the road to the mesa
    "c3-opener": ("IMG_6406.jpeg", 570, None),      # the Flame Towers, Baku
}
OPENER_DOT = 4          # pixels per dot: 342 dots make 1368, the page's 9 in at 152 per inch
OPENER_GREY = 196       # a black dot's tone (the series' openers)


def capture(name):
    return Image.open(os.path.join(SHOTS, name + ".png")).convert("RGBA")


def on_white(im):
    """The window on the page's white, with a grey outline just inside
    its own (rounded) edge, greyscale."""
    alpha = im.split()[3]
    white = Image.new("RGBA", im.size, (255, 255, 255, 255))
    flat = Image.alpha_composite(white, im).convert("L")
    solid = alpha.point(lambda a: 255 if a > 128 else 0)
    inner = solid.filter(ImageFilter.MinFilter(2 * OUTLINE + 1))
    ring = ImageChops.subtract(solid, inner)
    flat.paste(GREY, mask=ring)
    return flat


def part(im, box):
    l, t, r, b = (v * SCALE for v in box)
    cut = Image.alpha_composite(Image.new("RGBA", im.size, "white"), im).convert("L").crop((l, t, r, b))
    d = ImageDraw.Draw(cut)
    w, h = cut.size
    d.rectangle((0, 0, w - 1, h - 1), outline=GREY, width=RULE)
    return cut


def opener(code, photo, width, centre):
    with tempfile.TemporaryDirectory() as tmp:
        dots = os.path.join(tmp, "dots.png")
        cmd = [MPU, "dither", os.path.join(OPENER_PHOTOS, photo), "--out", dots, "--width", str(width)]
        if centre:
            cmd += ["--centre", "%s,%s" % centre]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
        im = Image.open(dots).convert("L")
    im = im.resize((im.size[0] * OPENER_DOT, im.size[1] * OPENER_DOT), Image.NEAREST)
    im = im.point(lambda v: OPENER_GREY if v < 128 else 255)
    half = im.size[0] // 2
    im.crop((0, 0, half, im.size[1])).save(os.path.join(OUT, code + "-l.png"))
    im.crop((half, 0, im.size[0], im.size[1])).save(os.path.join(OUT, code + "-r.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    for code, name in WINDOWS.items():
        on_white(capture(name)).save(os.path.join(OUT, code + ".png"))
    for code, (name, box) in PARTS.items():
        part(capture(name), box).save(os.path.join(OUT, code + ".png"))
    for code, (photo, width, centre) in OPENERS.items():
        opener(code, photo, width, centre)
    print("figures:", ", ".join(sorted(os.listdir(OUT))))


if __name__ == "__main__":
    main()
