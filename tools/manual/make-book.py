#!/usr/bin/env python3
"""Builds the whole MacPhoto Utility User's Guide (copied from the Bulk
Formatter Utility User's Guide's, which is MacMusic's): the front matter, Chapters 1 to 3 and the
appendixes (from make-chapter1.py ... make-appendixes.py), the glossary,
the index and the back matter, as Documentation/manual/book.html, printed to
build-manual/MacPhoto-Utility-Users-Guide.pdf.

The contents and the index give page numbers, so the book is laid out
twice: the first time to find which page each part, task and command
fell on (print-pdf.py's anchors), the second with the numbers filled in.

The own-use edition (MG5) uses the private cover and the rainbow logo
when ~/MacPlusProjects/manual-assets-private (MANUAL_ASSETS) holds them
(make-cover.py makes the cover); otherwise, or with
MANUAL_ASSETS=/nonexistent, the plain edition is built, with the
program's own icon.

Usage: make-book.py"""
import importlib.util
import json
import os
import re
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from book import BOOK, img, page

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "Documentation", "manual", "book.html")
ANCHORS = os.path.join(ROOT, "build-manual", "anchors.json")
PRIVATE = os.environ.get("MANUAL_ASSETS",
                         os.path.expanduser("~/MacPlusProjects/manual-assets-private"))
OWN_USE = all(os.path.exists(os.path.join(PRIVATE, f))
              for f in ("cover-macphoto.jpg", "rainbow-logo.png"))
PDF = os.path.join(ROOT, "build-manual", "MacPhoto-Utility-Users-Guide%s.pdf"
                   % ("" if OWN_USE else "-plain"))
EDITION = "MacPhoto Utility B-0.9.0 &middot; Draft edition, October 2026"


def part(name):
    """A chapter's or the appendixes' body, from its generator."""
    path = os.path.join(HERE, "make-%s.py" % name)
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def logo(width):
    if OWN_USE:     # the rainbow logo is 314 x 295 pixels
        return ('<img class="logo" src="private/rainbow-logo.png" style="width:%spt; height:%.1fpt">'
                % (width, width * 295 / 314))
    return img("mp-icon", width, "logo")


def boxes(*items):
    return '<ul class="boxes">%s</ul>' % "".join("<li>%s</li>" % i for i in items)


def margin_head(title, ident):
    return '<div class="margin"><h2 class="margin-head" id="%s">%s</h2></div>' % (ident, title)


def margin_sub(title):
    return '<div class="margin"><h3 class="margin-sub">%s</h3></div>' % title


# ---- Front matter ---------------------------------------------------------

def cover():
    if OWN_USE:
        return '<div class="cover"><img src="private/cover-macphoto.jpg"></div>\n'
    return ('<div class="cover plain"><div class="cover-logo">%s</div>'
            '<p class="cover-title">%s</p>%s</div>\n'
            % (img("mp-icon", 40), BOOK, img("c0-cover-screen", 400)))


COPYRIGHT = """
<div class="copyright"><div class="copy-columns">
 <div class="copy-left">
  <p class="copy-head">Copyright</p>
  <p>This manual and the software it describes are copyrighted, with all
  rights reserved.</p>
  <p>&copy; 2026 Jack McAteer.</p>
  <p>MacPhoto Utility is an independent project, and is not affiliated
  with, endorsed by, sponsored by or produced by Apple Inc.</p>
  <p>Apple, Macintosh, Mac, macOS and Finder are trademarks of Apple Inc.
  Other names and trademarks belong to their respective owners.</p>
  <p>Program and manual by Jack McAteer.<br>
  The photographs are the author&rsquo;s own, from a summer on the road:
  horses on the steppe, a road to a mesa, and Baku&rsquo;s Flame Towers,
  in 342 lines of black and white.</p>
  <p>%s</p>
 </div>
 <div class="copy-right">
  <p class="copy-head">Disclaimer</p>
  <p>MacPhoto Utility is provided without any representation that it is
  suitable for a particular purpose.</p>
  <p>MacPhoto Utility only reads your photographs; it never changes them.
  A file you choose to replace when exporting is gone, so keep copies of
  anything you want to keep.</p>
  <p class="caps">The developer accepts no responsibility for loss or
  corruption of data, photographs or equipment arising from the use of the
  software, except to the extent that such liability cannot lawfully be
  excluded or limited.</p>
 </div>
</div></div>
""" % EDITION


def title_page():
    return ('<div class="title-page" id="title-page">'
            '<div class="title-logo">%s</div><p class="title-name">%s</p></div>\n'
            % (logo(36), BOOK))


ABOUT = "".join([
    '<div class="front"><div class="flow">',
    margin_head("About This Manual", "about"),
    "<p>MacPhoto Utility turns your photographs into pictures for a "
    "Macintosh Plus: from each one, a print image, the size of a playing "
    "card in 256 greys, for MacPhoto on the Plus to edit and for printing; "
    "and a screen image, the Plus&rsquo;s whole screen in black and white. "
    "This manual shows you how.</p>",

    margin_sub("Two computers"),
    "<p>MacPhoto Utility runs on a modern Mac: this manual calls it "
    "&ldquo;your Mac.&rdquo; The pictures it makes are for the Macintosh "
    "Plus (&ldquo;the Plus&rdquo;), and travel there on a disk made by its "
    "companion, the Macintosh Transfer Utility.</p>",

    margin_sub("What you need"),
    boxes("an Apple silicon Mac with macOS 26;",
          "your photographs: JPEG, HEIC, PNG or TIFF;",
          "the Macintosh Transfer Utility, to carry the files to the Plus;",
          "a Macintosh Plus with System 6.0.7 and a BlueSCSI."),

    margin_sub("What you should know"),
    "<p>This manual assumes you know your way round your Mac and the Finder. "
    "For the Plus, the <i>Macintosh Owner&rsquo;s Guide</i> covers the "
    "basics.</p>",

    margin_sub("How to use this manual"),
    boxes("<b>Learn it:</b> Chapter 1, &ldquo;Learning MacPhoto Utility,&rdquo; "
          "takes one photograph from your Mac to the Plus, in six short lessons.",
          "<b>Look it up:</b> Chapter 2, &ldquo;Using MacPhoto Utility,&rdquo; "
          "shows how to do each task. Chapter 3 is the reference. The "
          "appendixes list the messages, the files on the Plus, what to do "
          "when something goes wrong, and the specifications.",
          "<b>Just start:</b> add a photograph and try it."),

    '<div class="important">'
    '<p class="margin important-head">Important</p>'
    "<p>MacPhoto Utility never changes your photographs. But if you choose "
    "to replace files when exporting, the old ones are gone.</p></div>",

    margin_sub("Conventions"),
    '<p class="step">A step tells you what to do.</p>',
    '<p class="grey">Grey text adds a remark you can skip.</p>',
    '<p><span class="check">CHECK</span> marks what is still to be seen on the '
    'Macintosh Plus in this draft.</p>',
    "</div></div>\n",
])


# ---- The contents ----------------------------------------------------------

def book_contents(ch2_topics, ch3_sections):
    rows = [("about", "About This Manual", "part")]
    rows += [("chapter-1", "Chapter 1: Learning MacPhoto Utility", "ch"),
             ("intro", "Introduction: What MacPhoto Utility Does", "sec"),
             ("lessons", "Lessons", "sec"), ("whatnow", "What Now?", "sec")]
    rows += [("chapter-2", "Chapter 2: Using MacPhoto Utility", "ch")]
    rows += [(a, t, "sec") for a, t in ch2_topics]
    rows += [("chapter-3", "Chapter 3: Reference", "ch")]
    rows += [(a, t, "sec") for a, t in ch3_sections]
    rows += [("appendix-a", "Appendix A: Messages", "part"),
             ("appendix-b", "Appendix B: The Files on the Macintosh Plus", "part"),
             ("appendix-c", "Appendix C: Troubleshooting", "part"),
             ("appendix-d", "Appendix D: Specifications", "part"),
             ("glossary", "Glossary", "part"), ("index", "Index", "part"),
             ("comments", "Tell Us What You Think", "part")]
    items = "".join('<li class="toc-%s"><span class="t">%s</span><span class="pg">%s</span></li>'
                    % (cls, t, "{{%s}}" % a) for a, t, cls in rows)
    return ('<div class="front"><div class="flow">'
            '<div class="margin"><h2 class="contents-head" id="book-contents">Contents</h2></div>'
            '<ul class="toc book-toc">%s</ul></div></div>\n' % items)


# ---- Back matter ------------------------------------------------------------

GLOSSARY = [
    ("Atkinson dithering", "The way MacPhoto Utility turns greys into black and "
     "white dots, devised by Bill Atkinson for the first Macintosh: crisp, with "
     "clean whites and blacks."),
    ("brightness, contrast", "Settings for the screen image only, from &minus;100 "
     "to +100, under the Mac Plus screen preview."),
    ("click", "To position the pointer on something, and press and quickly "
     "release the mouse or trackpad button."),
    ("crop", "To leave part of a photograph out of a picture. Each photograph has "
     "a print crop and a screen crop."),
    ("dither", "To show shades of grey with patterns of black and white dots."),
    ("export", "To make the files: the print image, the screen image and, if "
     "chosen, a MacPaint document."),
    ("Finder", "The program that shows your disks, folders and files, on your Mac "
     "and on the Plus."),
    ("frame", "The rectangle drawn on the photograph, showing what a picture will "
     "hold."),
    ("HEIC", "The kind of photograph an iPhone makes."),
    ("Macintosh Plus", "The 1986 Macintosh the pictures are for, with a black and "
     "white screen 512 dots by 342."),
    ("Macintosh Transfer Utility", "MacPhoto Utility&rsquo;s companion, which puts "
     "files on a disk for the Plus."),
    ("MacPaint document", "A picture MacPaint opens: 576 by 720 dots, black and "
     "white. MacPhoto Utility puts the screen image in the middle."),
    ("MacPhoto", "The Plus&rsquo;s photograph editor, which opens the print "
     "images."),
    ("manifest", "The record, manifest.json, that MacPhoto Utility keeps in the "
     "export folder, of every file it made there."),
    ("missing", "Of a photograph in a project: not where it was when the project "
     "was saved, and not found by its content."),
    ("opener", "The picture across two pages at the start of each chapter."),
    ("PICT", "The Macintosh&rsquo;s picture file. The print image and the screen "
     "image are both PICT files."),
    ("pixel", "One dot of a picture."),
    ("PPI", "Pixels per inch: how many dots the print has to each inch. 360 or "
     "300."),
    ("print crop", "The frame that chooses what the print shows: 2.5 by 3.5 "
     "inches, portrait or landscape."),
    ("print image", "The picture for printing and for MacPhoto: 2.5 by 3.5 "
     "inches, in 256 greys."),
    ("project", "A file (.macphoto) that keeps the queue, every photograph&rsquo;s "
     "frames and settings, and what was exported; never the photographs."),
    ("queue", "The list of photographs on the left of the window."),
    ("relink", "To tell a project where a missing photograph is now (Locate)."),
    ("screen crop", "The frame that chooses what the screen image shows: the "
     "shape of the Plus&rsquo;s screen."),
    ("screen image", "The picture for the Plus&rsquo;s screen: 512 by 342 dots, "
     "black and white."),
    ("Slide Show", "After Dark&rsquo;s screen saver that shows the PICT files in "
     "its folder, one after another."),
    ("System 6", "The Plus&rsquo;s system software. MacPhoto Utility&rsquo;s "
     "pictures are for System 6.0.7."),
    ("turn", "To rotate a photograph a quarter at a time."),
    ("warning", "A note under a preview that a frame is too small for its "
     "picture, which will be enlarged."),
    ("zoom", "To make a frame smaller, so the picture shows less of the "
     "photograph, larger."),
]


def glossary():
    entries = "".join('<div class="gloss"><p class="term">%s</p><p>%s</p></div>' % e
                      for e in GLOSSARY)
    return ('<div class="chapter page-break"><div class="appendix-title" id="glossary" '
            'data-foot="Glossary"><h1 class="name">Glossary</h1></div>'
            '<div class="flow">%s</div></div>\n' % entries)


# The index: each subject, and the ids it points to (its pages come from
# the first layout). A "see" entry points to another subject instead.
INDEX = [
    ("adding photographs", ["l2", "adding-photographs", "to-add-photographs",
                            "to-add-a-folder-of-photographs", "to-add-by-dragging"]),
    ("After Dark", ["l6", "a-after-darks-slide-show", "t-nothing-shows-in-after-darks-slide-show"]),
    ("Atkinson dithering", ["l4", "to-make-it-lighter-darker-or-crisper"]),
    ("brightness and contrast", ["l4", "to-make-it-lighter-darker-or-crisper", "r-the-previews"]),
    ("can&rsquo;t be read", ["if-a-photograph-cant-be-read", "a-adding-and-opening-photographs"]),
    ("dragging photographs", ["l2", "to-add-by-dragging"]),
    ("exporting", ["l5", "exporting", "to-export-one-photograph", "to-export-every-photograph",
                   "a-exporting"]),
    ("Export All", ["to-export-every-photograph", "if-some-havent-been-looked-at",
                    "if-files-are-already-there", "to-stop", "when-its-finished"]),
    ("files made", ["l5", "r-the-files-it-makes", "appendix-b"]),
    ("File menu", ["r-the-menus"]),
    ("folder, choosing", ["l5", "to-choose-the-folder"]),
    ("frames", ["intro", "l3", "l4", "framing", "r-the-picture-and-its-frame"]),
    ("HEIC", ["l2", "a-photographs"]),
    ("installing", ["l1", "t-macos-wont-open-macphoto-utility"]),
    ("Keep Both", ["if-files-are-already-there"]),
    ("keys", ["r-the-menus"]),
    ("Larger", ["l4", "to-see-it-larger"]),
    ("limits", ["r-limits-and-settings", "appendix-d"]),
    ("Locate, Locate in Folder", ["if-a-photograph-is-missing"]),
    ("MacPaint", ["l6", "a-macpaint", "a-the-screen-image"]),
    ("manifest.json", ["r-the-files-it-makes"]),
    ("messages", ["appendix-a"]),
    ("missing photographs", ["if-a-photograph-is-missing", "t-a-projects-photographs-are-missing"]),
    ("moved photographs", ["if-photographs-have-moved"]),
    ("output", ["l5", "the-output", "r-output-and-export"]),
    ("Photograph menu", ["r-the-menus"]),
    ("Photoshop 1.0", ["l6", "a-print-images"]),
    ("Portrait and Landscape", ["l3", "to-turn-the-print"]),
    ("PPI", ["l5", "to-choose-the-prints-resolution", "a-the-print-image"]),
    ("previews", ["l3", "l4", "r-the-previews"]),
    ("print image", ["intro", "l3", "a-the-print-image", "a-print-images"]),
    ("projects", ["projects", "to-save-your-work", "to-open-a-project"]),
    ("queue", ["the-queue", "what-the-marks-mean", "r-the-queue"]),
    ("Remove", ["to-take-photographs-out-of-the-queue"]),
    ("Reset", ["l3", "to-start-again"]),
    ("saving", ["to-save-your-work"]),
    ("screen image", ["intro", "l4", "the-screen-image", "a-the-screen-image", "a-screen-images"]),
    ("skipped files", ["if-some-files-are-skipped"]),
    ("Slide Show", "After Dark"),
    ("small photographs", ["small-photographs", "if-a-photograph-is-small-for-its-output",
                           "t-the-print-warns-its-small"]),
    ("SuperPaint", ["l6", "a-screen-images"]),
    ("Transfer Utility", ["intro", "l6", "appendix-b"]),
    ("troubleshooting", ["appendix-c"]),
    ("turning a photograph", ["to-turn-a-photograph", "t-a-photograph-is-on-its-side"]),
    ("warnings", ["if-a-photograph-is-small-for-its-output", "a-warnings"]),
    ("window", ["l2", "r-the-window"]),
    ("zoom", ["l3", "to-make-a-frame-smaller-or-larger"]),
]


def pages_text(ids, at):
    """The pages for some ids: sorted, each once, runs joined (12&ndash;13)."""
    nums = sorted({int(page_number(at[i], at)) for i in ids if i in at
                   and page_number(at[i], at).isdigit()})
    out, i = [], 0
    while i < len(nums):
        j = i
        while j + 1 < len(nums) and nums[j + 1] == nums[j] + 1:
            j += 1
        out.append(str(nums[i]) if i == j else "%d&ndash;%d" % (nums[i], nums[j]))
        i = j + 1
    return ", ".join(out) or "00"


def index(at):
    groups = {}
    for term, refs in INDEX:
        key = re.sub(r"<[^>]+>|&[a-z]+;", "", term)[0].upper()
        if key.isdigit():
            key = "#"
        groups.setdefault(key, []).append((term, refs))
    html = []
    for letter in ["#"] + list("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):
        if letter == "#" and "#" not in groups:
            continue
        html.append('<h3 class="index-letter">%s</h3>' % ("Numbers" if letter == "#" else letter))
        for term, refs in sorted(groups.get(letter, []),
                                 key=lambda e: re.sub(r"<[^>]+>|&[a-z]+;", "", e[0]).lower()):
            if isinstance(refs, str):
                html.append('<p class="ix">%s. <i>See</i> %s</p>' % (term, refs))
            else:
                html.append('<p class="ix">%s, %s</p>' % (term, pages_text(refs, at)))
    return ('<div class="chapter page-break"><div class="appendix-title" id="index" '
            'data-foot="Index"><h1 class="name">Index</h1></div>'
            '<div class="index-columns">%s</div></div>\n' % "".join(html))


COMMENTS = """
<div class="chapter page-break"><div class="appendix-title" id="comments"
 data-foot="Tell Us What You Think"><h1 class="name">Tell Us What You Think</h1></div>
<div class="flow">
 <p>This manual is meant to help you get the most from MacPhoto Utility.
 Your comments, and the problems you find, make the next edition
 better.</p>
 <div class="form">
  <p>Did MacPhoto Utility do what you expected?
   <span class="tick">&#9744; Always</span><span class="tick">&#9744; Usually</span><span class="tick">&#9744; Rarely</span></p>
  <p>Which parts of the manual did you use?
   <span class="tick">&#9744; Learning</span><span class="tick">&#9744; Using</span><span class="tick">&#9744; Reference</span><span class="tick">&#9744; Appendixes</span></p>
  <p>Which photograph looked best on the Plus?</p>
  <div class="lines"></div>
  <p>Did you find any mistakes? (Please give the page.)</p>
  <div class="lines"></div>
  <p>What would you like MacPhoto Utility to do next?</p>
  <div class="lines"></div>
 </div>
 <p class="grey">Please pass your comments to the MacPhoto Utility project,
 with your name if you&rsquo;d like a reply. Thank you.</p>
</div></div>
"""


def back_cover():
    """The back cover (style guide §12.4), with the "at a glance" panel
    (MG9) in place of a Quick Reference Card."""
    glance = ('<div class="glance"><p class="glance-head">At a glance</p>'
              '<ol>'
              '<li>Add photographs (&#8984;I), or drag them in.</li>'
              '<li>Frame the print: drag, zoom, Portrait or Landscape.</li>'
              '<li>Frame the screen image (Tab), and set its brightness.</li>'
              '<li>Choose 360 PPI, the files and the folder.</li>'
              '<li>Export This Photograph (&#8984;E), or Export All (&#8679;&#8984;E).</li>'
              '</ol>'
              '<p><b>Save</b> (&#8984;S) keeps your work as a project. Screen images '
              'go in After Dark&rsquo;s Slide Show Folder; print images never do.</p></div>')
    return ('<div class="inside-back"></div>\n'
            '<div class="back-cover"><p class="publisher">MacPhoto Utility</p>'
            '%s<div class="back-logo">%s</div></div>\n' % (glance, logo(30)))


# ---- The book ---------------------------------------------------------------

def book(at):
    ch1, ch2, ch3 = part("chapter1"), part("chapter2"), part("chapter3")
    app = part("appendixes")
    c1, c2, c3, ap = ch1.PART, ch2.PART, ch3.PART, app.PART
    topics = ch2.TOPICS_TOC
    # Each chapter's first page, its opener, for the contents.
    c1 = c1.replace('<div class="opener opener-left">',
                    '<div class="opener opener-left" id="chapter-1">', 1)
    c2 = c2.replace('<div class="opener opener-left">',
                    '<div class="opener opener-left" id="chapter-2">', 1)
    c3 = c3.replace('<div class="opener opener-left">',
                    '<div class="opener opener-left" id="chapter-3">', 1)

    # The chapters' own contents pages: page numbers from the layout too.
    def own_contents(text):
        return re.sub(r'<ul class="toc">.*?</ul>', lambda m: re.sub(
            r'<a href="#([^"]+)">(.*?)</a>',
            r'<span class="toc-t">\2</span><span class="toc-pg">{{\1}}</span>', m.group(0)),
            text, flags=re.S)
    c1, c2, c3 = own_contents(c1), own_contents(c2), own_contents(c3)
    body = (cover() + COPYRIGHT + title_page()
            + book_contents(topics, ch3.SECTIONS_TOC) + ABOUT
            + c1 + c2 + c3 + ap
            + glossary() + index(at) + COMMENTS + back_cover())
    body = re.sub(r"\{\{([a-z0-9-]+)\}\}",
                  lambda m: page_number(at[m.group(1)], at) if m.group(1) in at else "00", body)
    return body


FOOT_NAMES = [("chapter-1", "Chapter 1: Learning MacPhoto Utility"),
              ("chapter-2", "Chapter 2: Using MacPhoto Utility"),
              ("chapter-3", "Chapter 3: Reference"),
              ("appendix-a", "Appendix A: Messages"),
              ("appendix-b", "Appendix B: The Files on the Macintosh Plus"),
              ("appendix-c", "Appendix C: Troubleshooting"),
              ("appendix-d", "Appendix D: Specifications"),
              ("glossary", "Glossary"), ("index", "Index"),
              ("comments", "Tell Us What You Think")]


def page_number(p, at):
    """The number printed on the p'th page: roman from the title page,
    arabic from Chapter 1's opener, which is page 2."""
    if p >= at.get("chapter-1", 10 ** 6):
        return str(p - at["chapter-1"] + 2)
    return roman(p - at.get("title-page", 1) + 1)


def feet(at):
    """Each page's number, written into its running foot's number box
    (Paged.js's own page counter doesn't follow resets in its margin
    boxes)."""
    if not at:
        return ""
    parts = sorted((at[i], name) for i, name in FOOT_NAMES if i in at)
    rules = []
    for p in range(at.get("title-page", 1), 200):
        n = page_number(p, at)
        name = ([nm for start, nm in parts if start <= p] or [""])[-1]
        left = n + ("\\2003\\2003 " + name if name and p >= at.get("chapter-1", 10 ** 6) else "")
        for box, text in (("bottom-left", left), ("bottom-right", n)):
            rules.append('.pagedjs_page[data-page-number="%d"] .pagedjs_margin-%s '
                         '> .pagedjs_margin-content::after { content: "%s" !important; }'
                         % (p, box, text))
    return "<style>%s</style>\n" % "\n".join(rules)


def roman(n):
    out = ""
    for value, letters in ((10, "x"), (9, "ix"), (5, "v"), (4, "iv"), (1, "i")):
        while n >= value:
            out += letters
            n -= value
    return out


def build(at, anchors=None):
    html = page(BOOK, book(at)).replace("</head>", feet(at) + "</head>", 1)
    open(OUT, "w").write(html)
    cmd = [os.path.join(HERE, "build-pdf.sh"), OUT, PDF] + ([anchors] if anchors else [])
    subprocess.run(cmd, check=True, cwd=ROOT)


if __name__ == "__main__":
    build({}, ANCHORS)                      # the first layout: where everything fell
    at = json.load(open(ANCHORS))
    for ident in [i for term, refs in INDEX if not isinstance(refs, str) for i in refs]:
        if ident not in at:
            print("index: no such id:", ident)
    ids = re.findall(r'id="([^"]+)"', open(OUT).read())
    for dup in sorted({i for i in ids if ids.count(i) > 1}):
        print("duplicate id:", dup)
    build(at)                               # the second, with the page numbers
    print("edition:", "own use (MG5)" if OWN_USE else "plain")
