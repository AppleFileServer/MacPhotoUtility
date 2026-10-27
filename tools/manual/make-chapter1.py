#!/usr/bin/env python3
"""Writes Documentation/manual/chapter1.html, Chapter 1 of the MacPhoto
Utility User's Guide, "Learning MacPhoto Utility" (outline.md), for review
on its own: a title page for the draft, the opener spread, the chapter's
contents, the introduction, six lessons and "What Now?". Made as the Bulk
Formatter's make-chapter1.py.

Build it with tools/manual/build-pdf.sh Documentation/manual/chapter1.html <pdf>."""
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from book import img, draft_title, opener, page, png_size
from drawings import journey, two_shapes

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "Documentation", "manual", "chapter1.html")

# CHECK: not yet seen on the real Plus, or not yet built (MG8).
CHECK = '<span class="check">CHECK</span>'


def modern(name, width):
    """A macOS figure, `width` points wide, smoothed."""
    return img(name, width, "screen modern")


def plus(name, width=300):
    """A Plus screen, 1-bit, square pixels."""
    return img(name, width, "screen")


def window_labelled():
    """w-main across the whole text block (448pt), labelled from above in
    red, each label centred over its part with a straight leader down to
    it (the window is too wide to leave room for margin labels). Points
    are in the window's own points (1402 x 851)."""
    W = 448.0
    k = W / 1402
    top = 44.0                                    # room for the labels
    h = 851 * k
    # (text, point x, point y, row): two rows, so no label meets another
    # and no leader crosses a label.
    labels = [("The queue", 120, 330, 0),
              ("The picture and its frame", 675, 200, 0),
              ("Output and export", 1250, 300, 0),
              ("The print", 380, 520, 1),
              ("The Mac Plus screen", 900, 520, 1)]
    parts = ['<svg class="callouts" width="%dpt" height="%.0fpt" viewBox="0 0 %d %.0f">'
             % (W, top + h, W, top + h),
             '<rect x="0" y="0" width="%g" height="%.1f" fill="white"/>' % (W, top + h),
             '<image href="figures/w-main.png" x="0" y="%g" width="%g" height="%.1f" '
             'style="image-rendering: auto"/>' % (top, W, h)]
    for text, tx, ty, row in labels:
        x, y = tx * k, top + ty * k
        base = 12 + row * 16
        parts.append('<text x="%.1f" y="%g" text-anchor="middle">%s</text>' % (x, base, text))
        parts.append('<polyline class="leader" points="%.1f,%g %.1f,%.1f"/>' % (x, base + 4, x, y))
    parts.append("</svg>")
    return "".join(parts)


def lesson(number, title, anchor):
    return ('<div class="margin"><div class="lesson-head" id="%s">'
            '<span class="number">%d</span><span class="title">%s</span></div></div>'
            % (anchor, number, title))


LESSONS = [
    (1, "Installing MacPhoto Utility", "l1"),
    (2, "Adding a Photograph", "l2"),
    (3, "Framing the Print", "l3"),
    (4, "Framing the Screen Image", "l4"),
    (5, "Exporting", "l5"),
    (6, "Seeing It on the Macintosh Plus", "l6"),
]

CONTENTS = "\n".join(
    ['<li class="part"><a href="#intro">Introduction: What MacPhoto Utility Does</a></li>',
     '<li class="part"><a href="#lessons">Lessons</a></li>']
    + ['<li class="lesson"><span class="n">%d</span><a href="#%s">%s</a></li>' % (n, a, t)
       for n, t, a in LESSONS]
    + ['<li class="part"><a href="#whatnow">What Now?</a></li>'])

BODY = """
OPENER

<div class="chapter chapter-contents">
 <div class="flow">
  <div class="margin"><h2 class="contents-head">Contents</h2></div>
  <ul class="toc">
CONTENTS
  </ul>
 </div>
</div>

<div class="chapter page-break">
 <div class="flow">

  <div class="margin"><h2 class="margin-head" id="intro">What MacPhoto Utility Does</h2></div>
  <p>A photograph on your Mac holds millions of colours. The Macintosh
  Plus shows two: black and white, on a screen 512 dots wide and 342
  high. MacPhoto Utility bridges the gap. From each photograph it makes
  two pictures:</p>
  <ul class="boxes">
   <li>a <b class="term">print image</b>, the size of a playing card
   (2.5 by 3.5 inches) in 256 shades of grey, for MacPhoto on the Plus to
   edit, and for printing;</li>
   <li>a <b class="term">screen image</b>, the Plus&rsquo;s whole screen
   in black and white, to look at on the Plus as it is, or to show in
   After Dark&rsquo;s slide show.</li>
  </ul>
  <p>Your photograph itself is never changed. MacPhoto Utility only reads
  it.</p>

  <div class="margin"><h3 class="margin-sub">Two frames</h3></div>
  <p>The print and the screen are different shapes. A print standing
  upright is tall and narrow; the screen is wide. No single frame suits
  both, so each photograph has two: a <b class="term">print crop</b> and
  a <b class="term">screen crop</b>, which you set separately.</p>
  <figure class="wide">IMG_SHAPES</figure>

  <div class="margin"><h3 class="margin-sub">From your Mac to the Plus</h3></div>
  <p>MacPhoto Utility works on your Mac, a modern one. The files it makes
  travel to the Plus on a disk made by the Macintosh Transfer Utility,
  its companion:</p>
  <div class="wide">IMG_JOURNEY</div>

  <div class="margin"><h3 class="margin-sub">What you&rsquo;ll learn</h3></div>
  <p>The lessons that follow take about a quarter of an hour, with one
  of your own photographs. You&rsquo;ll install MacPhoto Utility, add a
  photograph, frame it twice, export it, and see it on the Plus.</p>
  <p>You should already know your way round your Mac and the Finder. For
  the Plus, the <i>Macintosh Owner&rsquo;s Guide</i> covers the
  basics.</p>

  <div class="margin"><h2 class="margin-head" id="lessons">Lessons</h2></div>
  <p class="lessons-intro">Do the lessons in order; each one picks up
  where the last one left off. Each step is shown like this:</p>
  <p class="step">A step tells you what to do.</p>
  <p>The plain text after it tells you what happens.</p>

LESSON_1
  <p>MacPhoto Utility comes as a single file, MacPhoto-Utility-B-0.9.0.zip
  (or the version you have).</p>
  <p class="step">Double-click the zip file.</p>
  <p>The Finder unpacks it beside the zip: the MacPhoto Utility
  program.</p>
  <p class="step">Drag MacPhoto Utility to the Applications folder, in
  the sidebar of a Finder window.</p>
  <p class="step">Open the Applications folder, and double-click
  MacPhoto Utility.</p>
  <p>Its window opens, empty for now. It needs an Apple silicon Mac with
  macOS 26.</p>
  <p class="grey">If macOS won&rsquo;t open it the first time, open
  System Settings, click Privacy &amp; Security, and click Open Anyway
  beside its name. It&rsquo;s signed for its owner&rsquo;s own use, not
  by Apple.</p>

LESSON_2
  <p class="step">Choose Add Photographs from the File menu (or press
  Command-I), select a photograph, and click Open.</p>
  <p class="or">OR</p>
  <p>Drag a photograph from the Finder onto the window.</p>
  <p>MacPhoto Utility reads JPEG, HEIC, PNG and TIFF photographs: the
  kinds a phone or a camera makes. The photograph appears in the list on
  the left, with a small picture of it.</p>
  <p class="step">Click the photograph in the list.</p>
  <p>It opens in the middle of the window, the right way up whichever way
  the camera was held. Underneath are two previews: the print, and the
  Plus&rsquo;s screen.</p>
  <figure class="window wide">IMG_WINDOW</figure>
  <p>The panel at the bottom left gives the photograph&rsquo;s details:
  what kind of file it is, its size, and whether it was turned to stand
  upright.</p>

LESSON_3
  <p>The print is 2.5 by 3.5 inches, so it can&rsquo;t always show the
  whole photograph. You choose the part it shows, and everything else is
  left out of the print, but never out of your photograph.</p>
  <p class="step">Click Print Crop, above the picture, if it isn&rsquo;t
  already chosen.</p>
  <p>A white frame shows what will be printed. Everything outside it is
  dimmed. The frame keeps the print&rsquo;s shape however you change
  it.</p>
  <figure class="window wide">IMG_EDITOR</figure>
  <p class="step">Drag inside the frame to move it.</p>
  <p>The print preview, below the picture, follows a moment later.
  It&rsquo;s the print itself, made from the whole photograph, not a
  sketch.</p>
  <p class="step">Drag the zoom slider to the right, or drag one of the
  frame&rsquo;s corners towards the middle.</p>
  <p>The frame gets smaller, so the print shows less of the photograph,
  larger. To start again, click Reset.</p>
  <p class="margin margin-note grey">A frame that&rsquo;s too small for
  the print gets a warning: see &ldquo;Small Photographs&rdquo; in
  Chapter 2.</p>
  <p class="step">Click Portrait or Landscape to turn the print the other
  way.</p>
  <p>The frame changes shape, and keeps its place on the picture.</p>

LESSON_4
  <p class="step">Click Screen Crop (or press the Tab key).</p>
  <p>Now the frame is the Plus&rsquo;s screen: wide, and always filled
  edge to edge. The print&rsquo;s frame stays, as a thin dashed line, so
  you can see both.</p>
  <figure class="window wide">IMG_EDITOR_SCREEN</figure>
  <p class="step">Move and size the frame as you did the print&rsquo;s.</p>
  <p>The Mac Plus screen preview shows the screen image exactly as it
  will look on the Plus: one dot of the Plus&rsquo;s screen for each dot
  here, in black and white.</p>
  <figure class="window">IMG_PREVIEW</figure>
  <p>Shades of grey become patterns of black and white dots, in the
  way Bill Atkinson devised for the first Macintosh. If a photograph looks
  too dark or too flat, drag Brightness or Contrast under the preview;
  they change the screen image, never the print. Normal puts them
  back.</p>
  <p class="step">Click Larger to see the screen image twice the size.</p>
  <p>Click Done to put it away.</p>

LESSON_5
  <p>The files go into a folder you choose, on your Mac.</p>
  <p class="step">Under Output, click Choose, select a folder (or make a
  new one), and click Choose.</p>
  <p>MacPhoto Utility remembers it for next time. Leave the other
  settings as they are: a print at 360 dots an inch, and two files, the
  print PICT and the screen PICT.</p>
  <figure class="beside">IMG_OUTPUT</figure>
  <p class="step">Click Export This Photograph (or press Command-E).</p>
  <p>MacPhoto Utility makes the two files, checks each one by reading it
  back, and lists them: the print image in a folder called Print Files,
  the screen image in PICT Files.</p>
  <figure class="beside">IMG_EXPORTED</figure>
  <p class="step">Click Show in Finder to see them.</p>
  <p>They&rsquo;re ready for the Plus, but not on it yet.</p>

LESSON_6
  <p>The Macintosh Transfer Utility puts the files on a disk for the
  Plus, in folders of the same names, with each file marked as a picture
  for the Plus to recognise. {CHECK}</p>
  <p class="step">On the Plus, open the PICT Files folder, then open the
  screen image in SuperPaint (or another program that opens PICT
  files).</p>
  <p>Your photograph fills the Plus&rsquo;s screen, just as the preview
  showed it.</p>
  <figure class="plus">IMG_SUPERPAINT</figure>
  <p class="grey">This picture, and the MacPaint one below, are from an
  emulated Macintosh Plus. {CHECK}</p>
  <p class="step">To use the screen image in After Dark&rsquo;s slide
  show, copy it into the Slide Show Folder in the After Dark Files folder,
  in the System Folder. {CHECK}</p>
  <p>Only screen images belong there. The print images are in 256 greys,
  which the Plus&rsquo;s own drawing can&rsquo;t show.</p>
  <p>The print image waits in Print Files for MacPhoto, the Plus&rsquo;s
  photograph editor. Photoshop 1.0 can open it too. {CHECK}</p>
  <figure class="plus">IMG_MACPAINT</figure>
  <p class="grey">If you also export a MacPaint document, MacPaint shows
  the screen image in the middle of its page. Your patterns are left as
  they were.</p>

  <div class="margin"><h2 class="margin-head" id="whatnow">What Now?</h2></div>
  <p>That&rsquo;s the whole journey: add, frame twice, export, and carry
  the files to the Plus.</p>
  <p>Chapter 2, &ldquo;Using MacPhoto Utility,&rdquo; covers each task in
  turn: a folder of photographs at once, the queue, the screen
  image&rsquo;s brightness, small photographs, and saving your work as a
  project to come back to. Chapter 3 describes every part of the window
  and every menu command.</p>
 </div>
</div>
"""

PICTURES = {
    "IMG_SHAPES": two_shapes(),
    "IMG_JOURNEY": journey(),
    "IMG_WINDOW": window_labelled(),
    "IMG_EDITOR_SCREEN": modern("p-editor-screen", 448),
    "IMG_EDITOR": modern("p-editor", 448),
    "IMG_PREVIEW": modern("p-screen-preview", 300),
    "IMG_OUTPUT": modern("p-output", 150),
    "IMG_EXPORTED": modern("p-exported", 150),
    "IMG_SUPERPAINT": plus("plus-superpaint"),
    "IMG_MACPAINT": plus("plus-macpaint-page"),
}

DRAFT = draft_title(
    "Chapter 1: Learning MacPhoto Utility",
    "A draft for review, 27 October 2026, written against MacPhoto Utility "
    "B-0.9.0. In the finished book this chapter follows About This Manual, "
    "and its pages are numbered on from there. CHECK marks what is still to "
    "be seen on the Macintosh Plus, or isn&rsquo;t built yet (the Transfer "
    "Utility&rsquo;s picture support).")
body = BODY.replace("{CHECK}", CHECK)
body = body.replace("OPENER", opener(1, "Learning MacPhoto Utility", "c1-opener"))
body = body.replace("CONTENTS", CONTENTS)
for key in sorted(PICTURES, key=len, reverse=True):
    body = body.replace(key, PICTURES[key])
for n, title, anchor in reversed(LESSONS):
    body = body.replace("LESSON_%d\n" % n, lesson(n, title, anchor) + "\n")
# Each margin head stays on the page with what follows it (as the series').
body = re.sub(r'(<div class="margin">(?:(?!</div>).)*</div>(?:</div>)?)(\s*<figure class="beside">.*?</figure>)?'
              r'(\s*<p.*?</p>)(\s*<figure class="wide">.*?</figure>)?',
              r'<div class="keep">\1\2\3\4</div>', body, flags=re.S)
PART = body

if __name__ == "__main__":
    open(OUT, "w").write(page("MacPhoto Utility User&rsquo;s Guide: Chapter 1", DRAFT + PART))
    print("wrote", os.path.normpath(OUT))
