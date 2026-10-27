#!/usr/bin/env python3
"""Makes the MacPhoto Utility User's Guide's cover pictures (MG5, MG6), as
the Bulk Formatter's make-cover.py does:

- Documentation/manual/figures/png/mp-icon.png: MacPhoto Utility's icon
  (Resources/AppIcon.icns, 256 pixels), for the plain edition's cover,
  title page and back cover, in place of a logo.
- Documentation/manual/figures/png/c0-cover-screen.png: a screen image of
  Jack's (IMG_2973, made by `mpu dither`, as the app makes it), 6 times
  its size, in the cover's pale blue (the series' colours).
- The own-use edition's cover, only when the private assets are there
  (~/MacPlusProjects/manual-assets-private, or MANUAL_ASSETS): MacDraw's
  cover with its title replaced by the book's and its screen by
  c0-cover-screen, written as cover-macphoto.jpg in that folder, never in
  the project (it holds Apple's artwork).

Usage (with Pillow): make-cover.py"""
import os, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
FIGURES = os.path.join(ROOT, "Documentation", "manual", "figures", "png")
PRIVATE = os.environ.get("MANUAL_ASSETS",
                         os.path.expanduser("~/MacPlusProjects/manual-assets-private"))
TOOLS = os.environ.get("MANUAL_TOOLS", os.path.expanduser("~/MacPlusProjects/manual-tools"))
FONT = os.path.join(TOOLS, "fonts", "built", "MacMusicGaramond100-Regular.ttf")
TITLE_TEXT = "MacPhoto Utility User’s Guide"
PHOTO = os.path.expanduser("~/MacPlusProjects/MacPhotoUtility-Samples/photos/IMG_2973.HEIC")
MPU = os.path.join(ROOT, ".build", "release", "mpu")

# Where things are on the MacDraw cover scan (4489 x 5360), as measured
# for MacMusic's cover.
SCREEN = (1503, 704, 4406, 2652)
TITLE = (1420, 380, 2420, 632)
TITLE_LEFT, TITLE_BASE = 1436, 600
TITLE_CAP = 168
HOLES = 205
PALE, DARK = (191, 218, 225), (30, 40, 50)


def icon():
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["iconutil", "-c", "iconset", os.path.join(ROOT, "Resources", "AppIcon.icns"),
                        "-o", os.path.join(tmp, "i.iconset")], check=True)
        im = Image.open(os.path.join(tmp, "i.iconset", "icon_256x256.png")).convert("RGBA")
    white = Image.new("RGBA", im.size, "white")
    Image.alpha_composite(white, im).convert("RGB").save(os.path.join(FIGURES, "mp-icon.png"), optimize=True)
    print("wrote mp-icon.png")


def screen():
    with tempfile.TemporaryDirectory() as tmp:
        dots = os.path.join(tmp, "dots.png")
        subprocess.run([MPU, "dither", PHOTO, "--out", dots, "--width", "512"],
                       check=True, stdout=subprocess.DEVNULL)
        im = Image.open(dots).convert("L")
    im = im.resize((im.width * 6, im.height * 6), Image.NEAREST)
    im = Image.merge("RGB", [im.point(lambda v, d=d, p=p: p if v > 127 else d)
                             for d, p in zip(DARK, PALE)])
    im.save(os.path.join(FIGURES, "c0-cover-screen.png"), optimize=True)
    print("wrote c0-cover-screen.png")


def cover():
    scan = os.path.join(PRIVATE, "macdraw-cover-4489.png")
    if not os.path.exists(scan):
        print("no private assets: the plain edition's cover will be used")
        return
    im = Image.open(scan).convert("RGB")
    draw = ImageDraw.Draw(im)
    strip = im.crop((HOLES, 0, HOLES + 20, im.height)).resize((1, 1), Image.BOX)
    draw.rectangle((0, 0, HOLES, im.height), fill=strip.getpixel((0, 0)))
    draw.rectangle(TITLE, fill=(255, 255, 255))
    size = 100
    font = ImageFont.truetype(FONT, size)
    cap = font.getbbox("M")[3] - font.getbbox("M")[1]
    size = round(size * TITLE_CAP / cap)
    while True:
        font = ImageFont.truetype(FONT, size)
        if TITLE_LEFT + font.getlength(TITLE_TEXT) <= SCREEN[2]:
            break
        size -= 2
    draw.text((TITLE_LEFT, TITLE_BASE), TITLE_TEXT, font=font, fill=(20, 20, 20), anchor="ls")
    shot = Image.open(os.path.join(FIGURES, "c0-cover-screen.png")).convert("RGB")
    x0, y0, x1, y1 = SCREEN
    im.paste(shot.resize((x1 - x0, y1 - y0), Image.NEAREST), (x0, y0))
    out = os.path.join(PRIVATE, "cover-macphoto.jpg")
    im.resize((2700, round(2700 * im.height / im.width)), Image.LANCZOS).save(out, quality=90)
    print("wrote", out)


icon()
screen()
cover()
