#!/usr/bin/env python3
"""Writes Documentation/manual/chapter3.html, Chapter 3 of the MacPhoto
Utility User's Guide, "Reference" (outline.md): the opener, the chapter's
contents, the window labelled, each part, the menus, the files it makes,
and the limits and settings. Every fact checked against B-0.9.0 and its
documents (DECISIONS.md, FILE_FORMATS.md).

Build it with tools/manual/build-pdf.sh Documentation/manual/chapter3.html <pdf>."""
import importlib.util
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from book import anchor, img, draft_title, opener, page

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "Documentation", "manual", "chapter3.html")

# The labelled window, as Chapter 1 draws it.
spec = importlib.util.spec_from_file_location("ch1", os.path.join(HERE, "make-chapter1.py"))
ch1 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ch1)


def modern(name, width, cls="window"):
    return '<figure class="%s">%s</figure>' % (cls, img(name, width, "screen modern"))


def table(rows, head=("", ""), cls="ref controls"):
    h = "".join("<th>%s</th>" % c for c in head)
    r = "".join("<tr>%s</tr>" % "".join("<td>%s</td>" % c for c in row) for row in rows)
    return '<table class="%s"><thead><tr>%s</tr></thead><tbody>%s</tbody></table>' % (cls, h, r)


SECTIONS = [
    ("The Window",
     "<p>Everything happens in one window. On the left, the queue of "
     "photographs and the details of the one you&rsquo;re working on; in the "
     "middle, the photograph with its frame, and the two previews; on the "
     "right, the output settings and the export buttons.</p>"
     '<figure class="window wide">' + ch1.window_labelled() + "</figure>"
     "<p>The window&rsquo;s title is the project&rsquo;s name, or Untitled. "
     "Closing the window quits MacPhoto Utility, asking first if there are "
     "unsaved changes.</p>"),

    ("The Queue",
     "<p>The list of photographs you&rsquo;re working on, and the details of "
     "the one selected.</p>"
     + table([
         ("+ button", "Adds photographs (as Add Photographs)."),
         ("Folder button", "Adds the photographs in a folder (as Add Folder)."),
         ("A row", "A small picture, the name, the print&rsquo;s orientation (P or L) and its state: "
                   "not looked at yet, looked at, small for its output, can&rsquo;t be read, exported, missing."),
         ("The count", "How many photographs, how many can&rsquo;t be read, and how many files were "
                       "skipped as not photographs (click it to see which)."),
         ("Remove", "Takes the selected photographs out of the queue (Delete does the same)."),
         ("Remove All", "Empties the queue."),
         ("The details", "The selected photograph&rsquo;s kind, its size as stored and upright, how the camera "
                         "turned it, any turns you&rsquo;ve made, and when it was last exported. For a missing "
                         "photograph, where it was, with Locate and Locate in Folder."),
     ], ("Part", "What it does"))
     + modern("p-queue", 118)),

    ("The Picture and Its Frame",
     "<p>The photograph, turned the right way up, with the frame you&rsquo;re "
     "setting drawn on it and everything outside the frame dimmed.</p>"
     + modern("p-editor", 448, "window wide")
     + table([
         ("Print Crop, Screen Crop", "Which frame you&rsquo;re setting (Command-1, Command-2, or Tab). The other shows as a dashed line."),
         ("Turn buttons", "Turn the photograph a quarter to the left or right (Command-[, Command-])."),
         ("Portrait, Landscape", "Which way the print stands. Shown only with Print Crop chosen."),
         ("Zoom slider", "Makes the frame smaller (to the right) or larger, keeping its shape: from the largest "
                         "the photograph allows to an eighth of that. A pinch or the scroll wheel does the same."),
         ("Reset", "The frame back to the middle at full size (Command-0)."),
         ("The frame", "Drag inside it to move it, or a corner to size it. The arrow keys move it a little at a time."),
     ], ("Control", "What it does"))),

    ("The Previews",
     "<p>Both are made from the whole photograph, a moment after each change: "
     "they&rsquo;re the pictures themselves, not sketches.</p>"
     + table([
         ("Print", "The print image, scaled to fit: its size in pixels, its resolution, and any warning."),
         ("Mac Plus screen", "The screen image, one dot of the Plus&rsquo;s screen to each point, in black and white."),
         ("Larger", "The screen image twice the size."),
         ("Brightness, Contrast", "&minus;100 to +100 each, for the screen image only. Each photograph keeps its own."),
         ("Normal", "Brightness and contrast back to 0."),
     ], ("Part", "What it shows or does"))),

    ("Output and Export",
     "<p>What to make, where, and the buttons that make it.</p>"
     + table([
         ("360 PPI, 300 PPI", "The print&rsquo;s resolution. The framing is the same either way."),
         ("Print PICT", "The print image: 8-bit grey, for MacPhoto."),
         ("Screen PICT", "The screen image: 1-bit, 512 by 342."),
         ("MacPaint", "The screen image on a MacPaint page, in the middle."),
         ("Folder, Choose", "Where the files go, in folders inside it named for the Plus."),
         ("Export All", "Every photograph that can be read, one at a time (Shift-Command-E), with progress and Stop."),
         ("Export This Photograph", "The selected one (Command-E)."),
     ], ("Control", "What it does"))
     + "<p>These settings are shared by every photograph, kept in a project, and "
     "remembered between times you use MacPhoto Utility.</p>"
     + modern("p-output", 150)),

    ("The Menus",
     "<p>The File and Photograph menus hold MacPhoto Utility&rsquo;s own "
     "commands.</p>"
     + '<figure class="row">%s%s</figure>' % (img("m-file", 180, "screen modern"), img("m-photograph", 140, "screen modern"))
     + table([
         ("New Project", "&#8984;N", "Empties the queue, asking first to save any changes."),
         ("Open Project&hellip;", "&#8984;O", "Opens a saved project."),
         ("Open Recent", "", "The projects opened lately."),
         ("Add Photographs&hellip;", "&#8984;I", "Adds photographs to the queue."),
         ("Add Folder&hellip;", "&#8679;&#8984;I", "Adds the photographs in a folder."),
         ("Save, Save As&hellip;", "&#8984;S, &#8679;&#8984;S", "Saves the project."),
         ("Export This Photograph", "&#8984;E", "Exports the selected photograph."),
         ("Export All", "&#8679;&#8984;E", "Exports every photograph."),
     ], ("File menu", "Keys", ""), "ref narrow")
     + table([
         ("Turn Left, Turn Right", "&#8984;[, &#8984;]", "Turns the photograph a quarter."),
         ("Edit Print Crop, Edit Screen Crop", "&#8984;1, &#8984;2", "Chooses which frame you&rsquo;re setting."),
         ("Reset Crop", "&#8984;0", "That frame back to the middle at full size."),
     ], ("Photograph menu", "Keys", ""), "ref narrow")
     + "<p>The MacPhoto Utility, Edit, Window and Help menus are the ones every "
     "Mac program has: About MacPhoto Utility and Quit are in the first.</p>"),

    ("The Files It Makes",
     "<p>In the folder you choose, MacPhoto Utility makes a folder for each "
     "kind of file, named as it will be on the Plus.</p>"
     + table([
         ("Print Files", "<i>name</i>.pict", "The print image: a PICT in 256 greys, at the print&rsquo;s exact size. About 1&nbsp;MB."),
         ("PICT Files", "<i>name</i>.pict", "The screen image: a black-and-white PICT, 512 by 342. Under 23&nbsp;KB."),
         ("MacPaint Files", "<i>name</i>.MAC", "The screen image in the middle of a MacPaint page. Under 52&nbsp;KB."),
         ("", "manifest.json", "A record of every file exported into the folder: from which photograph, framed how, "
                               "and its checksum. For your records; the Plus doesn&rsquo;t need it."),
     ], ("Folder", "File", "What it is"), "ref narrow")
     + "<p>Names are made to suit the Plus: up to 31 characters with the "
     "ending, without colons, and with letters the Plus can&rsquo;t show "
     "changed for the nearest it can. A project, saved where you choose, ends "
     "in .macphoto.</p>"),

    ("Limits and Settings",
     "<p>The figures, for reference.</p>"
     + table([
         ("Photographs", "JPEG, HEIC, PNG and TIFF, up to 250 megapixels"),
         ("Print, 360 PPI", "900 &times; 1260 pixels (portrait) or 1260 &times; 900 (landscape)"),
         ("Print, 300 PPI", "750 &times; 1050 pixels or 1050 &times; 750"),
         ("Print size", "2.5 &times; 3.5 inches; no other size"),
         ("Screen image", "512 &times; 342 dots, black and white, Atkinson dithering"),
         ("MacPaint page", "576 &times; 720 dots; the screen image 32 dots in and 189 down"),
         ("Zoom", "1&times; to 8&times;"),
         ("Brightness, contrast", "&minus;100 to +100"),
         ("File names on the Plus", "31 characters"),
         ("To start with", "360 PPI; Print PICT and Screen PICT; no folder until you choose one"),
     ], ("", ""), "ref spec")),
]


def body():
    toc, parts = [], []
    for head, html in SECTIONS:
        toc.append('<li class="part"><a href="#%s">%s</a></li>' % (anchor(head), head))
        # The heading stays with the section's opening paragraph.
        end = html.index("</p>") + 4
        parts.append('<div class="section"><div class="keep"><div class="margin"><h2 class="margin-head" id="%s">%s</h2>'
                     '</div>%s</div>%s</div>' % (anchor(head), head, html[:end], html[end:]))
    contents = ('<div class="chapter chapter-contents"><div class="flow">'
                '<div class="margin"><h2 class="contents-head">Contents</h2></div>'
                '<ul class="toc">%s</ul></div></div>' % "\n".join(toc))
    return (opener(3, "Reference", "c3-opener") + contents
            + '<div class="chapter page-break"><div class="flow">%s</div></div>' % "".join(parts))


DRAFT = draft_title(
    "Chapter 3: Reference",
    "A draft for review, 27 October 2026, written against MacPhoto Utility "
    "B-0.9.0: every part of the window, every menu command, the files it "
    "makes, and its limits.")

if __name__ == "__main__":
    open(OUT, "w").write(page("MacPhoto Utility User&rsquo;s Guide: Chapter 3", DRAFT + body()))
    print("wrote", os.path.normpath(OUT))
