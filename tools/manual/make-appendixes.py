#!/usr/bin/env python3
"""Writes Documentation/manual/appendixes.html, the appendixes of the
MacPhoto Utility User's Guide (outline.md), made as the Bulk Formatter's:
  A  Messages: every message MacPhoto Utility shows, quoted from the
     B-0.9.0 source (Importer, Exporter, Project, the app), with what it
     means and what to do;
  B  The Files on the Macintosh Plus;
  C  Troubleshooting;
  D  Specifications (FILE_FORMATS.md, DECISIONS.md).

Build it with tools/manual/build-pdf.sh Documentation/manual/appendixes.html <pdf>."""
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from book import img, draft_title, page, anchor

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "Documentation", "manual", "appendixes.html")
CHECK = '<span class="check">CHECK</span>'


def appendix(letter, name, body, first=False):
    return ('<div class="chapter%s"><div class="appendix-title" id="appendix-%s" '
            'data-foot="Appendix %s: %s">'
            '<p class="ch">Appendix %s</p><h1 class="name">%s</h1></div>'
            '<div class="flow">%s</div></div>\n'
            % ("" if first else " page-break", letter.lower(), letter, name, letter, name, body))


def sub(title):
    return '<h3 class="ref-head loose" id="a-%s">%s</h3>' % (anchor(title), title)


def msg(text, meaning):
    return ('<div class="msg"><p class="msg-text">%s</p><p>%s</p></div>' % (text, meaning))


def trouble(problem, *paras):
    return ('<div class="entry"><div class="margin"><h4 class="cmd" id="t-%s">%s</h4></div>%s</div>'
            % (anchor(problem), problem, "".join("<p>%s</p>" % p for p in paras)))


def table(rows, cls="ref spec"):
    r = "".join("<tr>%s</tr>" % "".join("<td>%s</td>" % c for c in row) for row in rows)
    return '<table class="%s"><thead><tr><th></th><th></th></tr></thead><tbody>%s</tbody></table>' % (cls, r)


# ---- Appendix A ---------------------------------------------------------

A = "".join([
    "<p>This appendix lists the messages MacPhoto Utility shows, with what "
    "they mean and what to do. <i>name</i> stands for a file&rsquo;s name.</p>",

    sub("Adding and Opening Photographs"),
    "<p>These appear beside a photograph in the queue, or in a message when "
    "it&rsquo;s opened.</p>",
    msg("<i>name</i>: the file isn&rsquo;t there.",
        "It has been moved or deleted since it was added. In a project, see "
        "&ldquo;If a Photograph Is Missing&rdquo; in Chapter 2."),
    msg("<i>name</i>: the file is empty.", "The file has nothing in it. Use another copy."),
    msg("<i>name</i>: not a picture this app can read.",
        "It isn&rsquo;t a picture at all, or not one MacPhoto Utility understands."),
    msg("<i>name</i>: a <i>kind</i> picture. Only JPEG, HEIC, PNG and TIFF "
        "photographs are accepted.",
        "A GIF, say. Save the picture as one of those four (Preview can) and add it again."),
    msg("<i>name</i>: the file is damaged (it ends before the picture does).",
        "Part of the file is missing: it was cut short when it was copied or "
        "downloaded. Use another copy."),
    msg("<i>name</i>: the file is damaged (it can&rsquo;t be decoded).",
        "The file is spoilt inside. Use another copy."),
    msg("<i>name</i>: <i>n</i> megapixels is more than the 250 this app accepts.",
        "The picture is enormous. Make a smaller copy (Preview&rsquo;s Adjust "
        "Size will do it) and add that."),

    sub("Warnings"),
    "<p>These appear under the preview they affect. The picture is still made.</p>",
    msg("The print crop is <i>w</i> &times; <i>h</i> photo pixels but the print "
        "needs <i>w</i> &times; <i>h</i>: it will be enlarged and may look soft.",
        "See &ldquo;Small Photographs&rdquo; in Chapter 2."),
    msg("The screen crop is <i>w</i> &times; <i>h</i> photo pixels, less than "
        "the screen&rsquo;s 512 &times; 342: it will be enlarged.",
        "Make the screen frame larger."),

    sub("Exporting"),
    msg("Nothing to export yet.",
        "There&rsquo;s no photograph, no file is ticked under Output, or no "
        "folder has been chosen."),
    msg("Some of these files are already there.",
        "Export This Photograph: Keep Both, Replace or Cancel."),
    msg("<i>n</i> photographs haven&rsquo;t been looked at.",
        "Export All: they&rsquo;d be exported framed in the middle, at full size."),
    msg("Files for some photographs are already in the folder.",
        "Export All: Keep Both, Replace, Skip Those Photographs or Cancel."),
    msg("Nothing was exported. The <i>kind</i> file failed its check, so nothing "
        "was exported.",
        "A file didn&rsquo;t read back as it should. Nothing half-made is left "
        "in the folder. Try again; if it happens again, try another folder."),
    msg("Nothing was exported. The folder&rsquo;s manifest.json can&rsquo;t be "
        "read, so nothing was exported rather than overwrite it.",
        "The record of exports in that folder is damaged. Move it aside, or "
        "choose another folder."),

    sub("Projects"),
    msg("Do you want to save the changes to &ldquo;<i>project</i>&rdquo;?",
        "On closing, quitting, New Project or Open Project. Save, Don&rsquo;t "
        "Save, or Cancel."),
    msg("&ldquo;<i>project</i>&rdquo; is open. Found where they had moved to, "
        "by their content&hellip; Not found&hellip;",
        "Some photographs had moved and were found; any not found are marked "
        "Missing. Save the project to remember the new places."),
    msg("The project couldn&rsquo;t be opened. The project can&rsquo;t be read: "
        "it isn&rsquo;t a MacPhoto project.",
        "Or it&rsquo;s damaged, or part of it is missing. The project that was "
        "open is left as it was."),
    msg("The project was saved by a newer MacPhoto Utility&hellip; Nothing was changed.",
        "Use the newer MacPhoto Utility to open it."),
    msg("The project wasn&rsquo;t saved.",
        "The disk may be full or locked. Try Save As, somewhere else."),
    msg("This isn&rsquo;t the same photograph.",
        "Locate: the file you chose has different content. Cancel, or Use It "
        "Anyway to keep the frames with this file."),
    msg("That file can&rsquo;t be used.", "Locate: the file can&rsquo;t be read."),
    msg("None of the missing photographs are there. Found <i>n</i>.",
        "Locate in Folder: how many it found, and how many are still missing."),
])
A = re.sub(r'(<h3 class="ref-head loose"[^>]*>.*?</h3>)(<p>.*?</p>)?(<div class="msg">.*?</div>)',
           r'<div class="keep">\1\2\3</div>', A, flags=re.S)

# ---- Appendix B ---------------------------------------------------------

B = "".join([
    "<p>The Macintosh Transfer Utility puts MacPhoto Utility&rsquo;s files on a "
    "disk for the Plus, in the same three folders, and marks each one so the "
    "Plus knows what it is. %s</p>" % CHECK,
    sub("The Three Folders"),
    table([("Print Files", "Print images: PICT files in 256 greys, for MacPhoto. "
                           "Type PICT, creator MPho."),
           ("PICT Files", "Screen images: black-and-white PICT files, 512 &times; 342. "
                          "Type PICT, creator MPho."),
           ("MacPaint Files", "Screen images on MacPaint pages. Type PNTG, creator MPNT.")]),
    "<p>Files made by MacPhoto Utility open in MacPhoto when you double-click "
    "them (once MacPhoto exists). Until then, open them from inside a program.</p>",
    sub("Screen Images"),
    "<p>Any program that opens PICT files shows a screen image: SuperPaint, for "
    "instance, or the Scrapbook. In an emulated Plus, SuperPaint 2.0 opened one "
    "and showed it exactly. %s</p>" % CHECK,
    sub("After Dark&rsquo;s Slide Show"),
    "<p>After Dark&rsquo;s Slide Show shows the PICT files in the Slide Show "
    "Folder, in After Dark Files in the System Folder. Copy screen images there, "
    "and choose Slide Show in the After Dark control panel. %s</p>"
    "<p>Keep print images out of it: the Plus&rsquo;s own drawing can&rsquo;t "
    "show pictures in 256 greys.</p>" % CHECK,
    sub("MacPaint"),
    "<p>A MacPaint document holds the screen image in the middle of a MacPaint "
    "page: 32 dots in from the left and 189 down. MacPaint opens it like any "
    "of its own documents, and leaves your patterns as they were. In an "
    "emulated Plus it opened without trouble. %s</p>" % CHECK,
    sub("Print Images"),
    "<p>A print image is for MacPhoto, the Plus&rsquo;s photograph editor, "
    "which reads it a strip at a time, so it never needs the whole megabyte "
    "in memory. Photoshop 1.0 can open one, as a grey picture: it did in an "
    "emulated Plus. %s</p>" % CHECK,
])
B = re.sub(r'(<h3 class="ref-head loose"[^>]*>.*?</h3>)(<p>.*?</p>|<table.*?</table>)',
           r'<div class="keep">\1\2</div>', B, flags=re.S)

# ---- Appendix C ---------------------------------------------------------

C = "".join([
    "<p>If something doesn&rsquo;t go as you expect, look for it here.</p>",
    trouble("macOS won&rsquo;t open MacPhoto Utility",
            "It&rsquo;s signed for its owner&rsquo;s own use, not by Apple. Open "
            "System Settings, click Privacy &amp; Security, and click Open "
            "Anyway beside its name. You need do it only once."),
    trouble("A photograph won&rsquo;t add",
            "If nothing appears, it may not be a photograph MacPhoto Utility "
            "reads: click the &ldquo;skipped&rdquo; line under the list to see "
            "why. A photograph marked ✕ is damaged; its reason is shown when "
            "you select it (Appendix A).",
            "A photograph in your Photos library can be added once it&rsquo;s "
            "exported: in Photos, choose Export from the File menu."),
    trouble("A photograph is on its side",
            "MacPhoto Utility turns photographs upright from the camera&rsquo;s "
            "own record. If a photograph was saved without one, turn it with "
            "Command-[ or Command-]."),
    trouble("The screen image looks too dark, or too flat",
            "Drag Brightness or Contrast under the Mac Plus screen preview. "
            "Detail in deep shadow is often brought back by a little more "
            "brightness."),
    trouble("The print warns it&rsquo;s small",
            "Make the frame larger, or choose 300 PPI (Chapter 2, &ldquo;Small "
            "Photographs&rdquo;)."),
    trouble("Export All skipped some photographs",
            "Photographs that can&rsquo;t be read are left out, and the summary "
            "says why. So are those you chose to skip because their files were "
            "already there."),
    trouble("A project&rsquo;s photographs are missing",
            "They&rsquo;ve been deleted, or moved to another disk. Select one, "
            "and click Locate, or Locate in Folder to search a folder for all "
            "of them."),
    trouble("Nothing shows in After Dark&rsquo;s Slide Show",
            "Make sure the Slide Show Folder holds screen images (from PICT "
            "Files), not print images. %s" % CHECK),
])

# ---- Appendix D ---------------------------------------------------------

D = "".join([
    sub("The Print Image"),
    table([("Size", "2.5 &times; 3.5 inches, portrait or landscape"),
           ("Pixels", "900 &times; 1260 at 360 PPI; 750 &times; 1050 at 300 PPI (or turned)"),
           ("Greys", "256 (8 bits a pixel), Gray Gamma 2.2"),
           ("File", "PICT version 2, one picture packed row by row, with MacPhoto&rsquo;s "
                    "record of the print size and a checksum; about 1 MB at 360 PPI")]),
    sub("The Screen Image"),
    table([("Size", "512 &times; 342 dots: the Macintosh Plus&rsquo;s whole screen"),
           ("Colours", "Black and white, Atkinson dithering"),
           ("File", "PICT version 1, packed row by row; under 23 KB"),
           ("MacPaint", "576 &times; 720 page, the image 32 dots in and 189 down; under 52 KB")]),
    sub("Photographs"),
    table([("Kinds", "JPEG, HEIC, PNG, TIFF"),
           ("Largest", "250 megapixels"),
           ("Colour", "Made grey by the Mac&rsquo;s own colour matching; transparency becomes white")]),
    sub("What You Need"),
    table([("To run it", "An Apple silicon Mac with macOS 26"),
           ("To carry the files", "The Macintosh Transfer Utility %s" % CHECK),
           ("To use them", "A Macintosh Plus with System 6.0.7 and a BlueSCSI")]),
    "<p>The file formats are set out in full in MacPhoto Utility&rsquo;s "
    "FILE_FORMATS document.</p>",
])
D = re.sub(r'(<h3 class="ref-head loose"[^>]*>.*?</h3>)(<table.*?</table>)',
           r'<div class="keep">\1\2</div>', D, flags=re.S)

PART = (appendix("A", "Messages", A)
        + appendix("B", "The Files on the Macintosh Plus", B)
        + appendix("C", "Troubleshooting", C)
        + appendix("D", "Specifications", D))

DRAFT = draft_title("Appendixes A&ndash;D",
                    "A draft for review, 27 October 2026, written against MacPhoto "
                    "Utility B-0.9.0.")

if __name__ == "__main__":
    open(OUT, "w").write(page("MacPhoto Utility User&rsquo;s Guide: Appendixes", DRAFT + PART))
    print("wrote", os.path.normpath(OUT))
