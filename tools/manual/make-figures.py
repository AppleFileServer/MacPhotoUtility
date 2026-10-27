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

# Captures of windows of their own (with their own rounded corners):
# code -> capture.
WINDOWS = {
    "w-main": "s01-window",
    "a-save": "a-save",
    "m-file": "m-file",
    "m-photograph": "m-photograph",
}
# Parts of the main window, cut square: code -> (capture, (left, top,
# right, bottom) in points from the capture's corner). The details panel
# and the output panel's folder show scratch paths in the later captures,
# so those crops leave them out.
PARTS = {
    "p-editor": ("s01-window", (241, 31, 1109, 396)),
    "p-output": ("s01-window", (1110, 31, 1402, 478)),
    "p-queue": ("s02-queue", (0, 31, 240, 700)),
    "p-editor-screen": ("s04-screen", (241, 31, 1109, 396)),
    "p-screen-preview": ("s05-tone", (515, 405, 1055, 845)),
    "p-exported": ("s06-exported", (1110, 438, 1402, 612)),
    "p-small-warning": ("s07-small", (241, 405, 515, 849)),
    "p-cant-read": ("s08-cant-read", (0, 700, 240, 800)),
    "p-missing": ("s15-missing", (0, 290, 240, 346)),
    "p-skipped": ("s03-skipped", (0, 586, 254, 700)),
}
# Alerts, questions and sheets, cut from their window's capture by the
# bounds macOS reported, rounded as they are on screen: code ->
# (capture, (left, top, right, bottom) in points, corner radius in points).
DIALOGS = {
    "a-unseen": ("s10-unseen", (571, 305, 831, 545), 26),
    "a-taken": ("s11-taken", (571, 270, 831, 580), 26),
    "f-summary": ("s12-summary", (471, 337, 931, 513), 16),
    "a-opened": ("s14-opened-missing", (571, 305, 831, 545), 26),
    "f-larger": ("s09-larger", (173, 49, 1229, 801), 16),
}
# Screens of the Plus, exact 512 x 342 from the Mini vMac check (private):
# code -> file in MacPhotoUtility-Samples/emulator-check-2026-10-26.
PLUS = {"plus-macpaint": "16-open", "plus-macpaint-page": "18-showpage"}
PLUS_DIR = os.path.expanduser("~/MacPlusProjects/MacPhotoUtility-Samples/emulator-check-2026-10-26")

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


def dialog(im, box, radius):
    """A dialog cut from its window, its rounded corners on the page's
    white, a grey outline just inside."""
    l, t, r, b = (v * SCALE for v in box)
    cut = Image.alpha_composite(Image.new("RGBA", im.size, "white"), im).convert("L").crop((l, t, r, b))
    w, h = cut.size
    big = Image.new("L", (w * 4, h * 4), 0)
    ImageDraw.Draw(big).rounded_rectangle((0, 0, w * 4 - 1, h * 4 - 1), radius * SCALE * 4, fill=255)
    mask = big.resize((w, h), Image.LANCZOS)
    page = Image.new("L", (w, h), 255)
    page.paste(cut, mask=mask)
    ring = ImageChops.subtract(mask.point(lambda a: 255 if a > 128 else 0),
                               mask.point(lambda a: 255 if a > 128 else 0).filter(ImageFilter.MinFilter(2 * OUTLINE + 1)))
    page.paste(GREY, mask=ring)
    return page


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
    for code, (name, box, radius) in DIALOGS.items():
        dialog(capture(name), box, radius).save(os.path.join(OUT, code + ".png"))
    for code, name in PLUS.items():
        Image.open(os.path.join(PLUS_DIR, name + ".png")).convert("1").save(os.path.join(OUT, code + ".png"))
    for code, (photo, width, centre) in OPENERS.items():
        opener(code, photo, width, centre)
    print("figures:", ", ".join(sorted(os.listdir(OUT))))


if __name__ == "__main__":
    main()
