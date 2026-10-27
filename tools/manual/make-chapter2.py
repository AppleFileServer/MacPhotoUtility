#!/usr/bin/env python3
"""Writes Documentation/manual/chapter2.html, Chapter 2 of the MacPhoto
Utility User's Guide, "Using MacPhoto Utility" (outline.md): the opener,
the chapter's contents listing every task, and the task pages in the wide
column (the utilities addendum), topic after topic.

Build it with tools/manual/build-pdf.sh Documentation/manual/chapter2.html <pdf>."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from book import anchor, img, draft_title, opener, page

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "Documentation", "manual", "chapter2.html")

CHECK = '<span class="check">CHECK</span>'


def fig(name, width):
    return '<figure class="window">%s</figure>' % img(name, width, "screen modern")


# Each topic: (heading, introduction, [tasks]); each task: (heading, body HTML).
TOPICS = [
    ("Adding Photographs",
     "MacPhoto Utility works on a list of photographs, the <b>queue</b>. "
     "Photographs stay where they are on your Mac; the queue only lists them.",
     [("To Add Photographs",
       '<p class="step">Choose Add Photographs from the File menu (or press Command-I), '
       'select one or more photographs, and click Open.</p>'
       '<p class="or">OR</p><p>Click the + button above the list.</p>'
       '<p>JPEG, HEIC, PNG and TIFF photographs are added, in the order the Finder '
       'shows them. A photograph already in the queue isn&rsquo;t added twice.</p>'),
      ("To Add a Folder of Photographs",
       '<p class="step">Choose Add Folder from the File menu (or press Shift-Command-I), '
       'select the folder, and click Add.</p>'
       '<p>The photographs directly inside it are added; folders inside it are '
       'left alone.</p>'),
      ("To Add by Dragging",
       '<p class="step">Drag photographs, or a folder, from the Finder onto the '
       'window, or onto MacPhoto Utility&rsquo;s icon in the Dock.</p>'),
      ("If Some Files Are Skipped",
       '<p>Anything that isn&rsquo;t a photograph MacPhoto Utility reads is left '
       'out, and the foot of the list says how many.</p>'
       '<p class="step">Click &ldquo;skipped: not photographs&rdquo; to see which, '
       'and why.</p>' + fig("p-skipped", 200)),
      ("If a Photograph Can&rsquo;t Be Read",
       '<p>A photograph that&rsquo;s damaged, or too large (more than 250 '
       'megapixels), stays in the list with a red ✕. Click it to see why.</p>'
       + fig("p-cant-read", 200)
       + '<p class="grey">Try another copy of the photograph: from your Photos '
       'library, say, exported again.</p>')]),

    ("The Queue",
     "Each photograph in the list shows a small picture of itself, its name, "
     "how its print will stand, and how far you&rsquo;ve got with it.",
     [("What the Marks Mean",
       '<p>Beside each name, on the right:</p>'
       '<figure class="beside">' + img("p-queue", 118, "screen modern") + '</figure>'
       '<ul class="boxes">'
       '<li><b>P</b> or <b>L</b>: its print is portrait or landscape.</li>'
       '<li><b>○ Not looked at yet</b>: it hasn&rsquo;t been opened, so its frames '
       'are as they started, in the middle at full size.</li>'
       '<li><b>⚠ Small for its output</b>: see &ldquo;Small Photographs.&rdquo;</li>'
       '<li><b>✕ Can&rsquo;t be read</b>: damaged, or not a photograph.</li>'
       '<li><b>✓ Exported</b>: exported since it was last changed.</li>'
       '<li><b>Missing</b>: a project&rsquo;s photograph that isn&rsquo;t where it '
       'was (see &ldquo;Projects&rdquo;).</li></ul>'),
      ("To Work on a Photograph",
       '<p class="step">Click it in the list, or move to it with the Up and Down '
       'Arrow keys.</p>'
       '<p>It opens with its frames just as you left them. Every photograph keeps '
       'its own.</p>'),
      ("To Take Photographs Out of the Queue",
       '<p class="step">Select them, and click Remove (or press Delete).</p>'
       '<p>Remove All empties the queue. Either way, the photographs themselves '
       'stay on your Mac: nothing is deleted.</p>')]),

    ("Framing",
     "Each photograph has two frames: the print&rsquo;s and the screen&rsquo;s. "
     "Print Crop and Screen Crop, above the picture, choose which you&rsquo;re "
     "setting; the other shows as a dashed line.",
     [("To Move a Frame",
       '<p class="step">Drag inside it.</p>'
       '<p>It stops at the edges of the photograph: a frame never goes beyond it. '
       'The arrow keys move it a little at a time.</p>'),
      ("To Make a Frame Smaller or Larger",
       '<p class="step">Drag one of its corners.</p>'
       '<p class="or">OR</p><p>Drag the zoom slider; or pinch on a trackpad, or '
       'turn the scroll wheel, over the picture.</p>'
       '<p>The frame keeps its shape. It can be as large as the photograph allows, '
       'and as small as an eighth of that.</p>' + fig("p-editor", 300)),
      ("To Turn a Photograph",
       '<p class="step">Click a turn button, above the picture (or press Command-[ '
       'or Command-]).</p>'
       '<p>It turns a quarter at a time, frames and all.</p>'),
      ("To Turn the Print",
       '<p class="step">With Print Crop chosen, click Portrait or Landscape.</p>'
       '<p>A new photograph starts as landscape if it&rsquo;s wider than it is '
       'tall, and as portrait otherwise.</p>'),
      ("To Start Again",
       '<p class="step">Click Reset (or press Command-0).</p>'
       '<p>The frame you&rsquo;re setting goes back to the middle, at full size. '
       'The other is left as it is.</p>')]),

    ("The Screen Image",
     "The screen image is the Plus&rsquo;s whole screen, 512 dots by 342, in "
     "black and white. The Mac Plus screen preview shows it dot for dot.",
     [("To Make It Lighter, Darker or Crisper",
       '<p class="step">Drag Brightness or Contrast, under the preview.</p>'
       '<p>Each goes from &minus;100 to +100. They change the screen image only, '
       'never the print, and each photograph keeps its own. Normal puts both '
       'back to 0.</p>' + fig("p-screen-preview", 300)
       + '<p class="grey">Greys become patterns of black and white dots, in the way '
       'Bill Atkinson devised for the first Macintosh. It keeps edges crisp but '
       'can lose detail in the lightest and darkest parts; a little more '
       'contrast or brightness often helps.</p>'),
      ("To See It Larger",
       '<p class="step">Click Larger, above the preview.</p>'
       '<p>It&rsquo;s shown twice the size. Click Done to put it away.</p>')]),

    ("Small Photographs",
     "A frame needs enough of the photograph to fill its picture. When it "
     "hasn&rsquo;t, MacPhoto Utility still makes the picture, enlarged, but "
     "says so.",
     [("If a Photograph Is Small for Its Output",
       '<p>A warning appears under the preview it affects, and the photograph is '
       'marked ⚠ in the list.</p>' + fig("p-small-warning", 160)
       + '<p>A print at 360 dots an inch needs a frame of at least 900 by 1260 of '
       'the photograph&rsquo;s own pixels (750 by 1050 at 300). The screen image '
       'needs 512 by 342.</p>'
       '<p class="step">Make the frame larger, or choose 300 PPI for the '
       'print.</p>'
       '<p class="grey">A photograph from any recent phone is large enough unless '
       'you zoom in a long way.</p>')]),

    ("The Output",
     "The settings under Output are shared by every photograph in the queue, "
     "and remembered.",
     [("To Choose the Print&rsquo;s Resolution",
       '<p class="step">Click 360 PPI or 300 PPI.</p>'
       '<p>360 dots an inch gives more detail; the framing is the same either '
       'way.</p>'),
      ("To Choose Which Files Are Made",
       '<p class="step">Turn on Print PICT, Screen PICT or MacPaint.</p>'
       '<p>The first two are on to start with. A MacPaint document holds the '
       'screen image too, in the middle of a MacPaint page.</p>'),
      ("To Choose the Folder",
       '<p class="step">Click Choose, select a folder (or make a new one), and '
       'click Choose.</p>'
       '<p>The files go into folders inside it, named as they&rsquo;ll be on the '
       'Plus: Print Files, PICT Files and MacPaint Files.</p>'
       + fig("p-output", 170))]),

    ("Exporting",
     "Exporting makes the files. Each one is read back and checked after "
     "it&rsquo;s written; a file that fails isn&rsquo;t kept.",
     [("To Export One Photograph",
       '<p class="step">Click Export This Photograph (or press Command-E).</p>'
       '<p>The files made are listed under the button. Click Show in Finder to '
       'see them.</p>' + fig("p-exported", 170)),
      ("To Export Every Photograph",
       '<p class="step">Click Export All (or press Shift-Command-E).</p>'
       '<p>The photographs are exported one at a time, in the order of the list. '
       'The panel shows which one it&rsquo;s on. A photograph that fails is '
       'marked, and the rest carry on.</p>'),
      ("If Some Haven&rsquo;t Been Looked At",
       '<p>Export All asks first, and lists them: they&rsquo;d be exported with '
       'the frames they started with, in the middle at full size.</p>'
       + fig("a-unseen", 140)
       + '<p class="step">Click Export All to go ahead, or Cancel to look at them '
       'first.</p>'),
      ("If Files Are Already There",
       '<p>When the folder already has files of the same names, MacPhoto Utility '
       'asks once, for all of them:</p>'
       '<ul class="boxes"><li><b>Keep Both</b> saves the new files under the next '
       'free name: IMG_8691 2.pict, say.</li>'
       '<li><b>Replace</b> puts the new files in place of the old ones.</li>'
       '<li><b>Skip Those Photographs</b> leaves them out.</li>'
       '<li><b>Cancel</b> exports nothing.</li></ul>' + fig("a-taken", 140)
       + '<p class="grey">Two photographs in the queue with the same name (from '
       'different folders) are numbered automatically.</p>'),
      ("To Stop",
       '<p class="step">Click Stop, under the progress bar.</p>'
       '<p>The photograph in hand is finished, so every file written is complete '
       'and checked; the rest are left for another time.</p>'),
      ("When It&rsquo;s Finished",
       '<p>A summary says how many photographs were exported, any warnings, and '
       'any that couldn&rsquo;t be, with the reason.</p>' + fig("f-summary", 240))]),

    ("Projects",
     "A <b>project</b> keeps your work: the queue, every photograph&rsquo;s "
     "frames and screen settings, the output settings, and what was exported "
     "when. It doesn&rsquo;t copy the photographs; it remembers where they "
     "are.",
     [("To Save Your Work",
       '<p class="step">Choose Save from the File menu (or press Command-S), '
       'name the project, and click Save.</p>'
       '<p>The window&rsquo;s title becomes the project&rsquo;s name. Save As '
       'saves a copy under another name.</p>' + fig("a-save", 200)
       + '<p class="grey">If you close the window or quit with changes unsaved, '
       'MacPhoto Utility asks whether to save them.</p>'),
      ("To Open a Project",
       '<p class="step">Choose Open Project from the File menu (or press '
       'Command-O), or choose one from Open Recent.</p>'
       '<p class="or">OR</p><p>Double-click the project in the Finder.</p>'),
      ("If Photographs Have Moved",
       '<p>MacPhoto Utility finds them again by their content, even moved to '
       'another folder or renamed, and says so. Save the project to remember '
       'the new places.</p>' + fig("a-opened", 140)),
      ("If a Photograph Is Missing",
       '<p>It stays in the list, marked Missing, with its frames kept.</p>'
       + fig("p-missing", 170)
       + '<p class="step">Select it, and click Locate in the panel below the list; '
       'find the photograph and click Open.</p>'
       '<p class="or">OR</p><p>Click Locate in Folder to look in one folder for '
       'every missing photograph at once.</p>'
       '<p class="grey">If the file you choose isn&rsquo;t the same photograph '
       '(its content is different), MacPhoto Utility asks before using it.</p>'),
      ("To Start a New Project",
       '<p class="step">Choose New Project from the File menu (or press '
       'Command-N).</p>'
       '<p>The queue is emptied; the output settings stay as they were.</p>')]),
]


def body():
    out, toc = [], []
    for i, (head, intro, tasks) in enumerate(TOPICS):
        toc.append('<li class="part"><a href="#%s">%s</a></li>' % (anchor(head), head))
        toc += ['<li class="lesson"><a href="#%s">%s</a></li>' % (anchor(t), t) for t, _ in tasks]
        # Each task: its head kept with its first paragraph (the series');
        # a topic's head and introduction kept with its first task's.
        parts = []
        for t_, b in tasks:
            first_end = b.find("</p>") + 4 if b.startswith("<p") else 0
            task_head = ('<div class="margin"><h3 class="task-head" id="%s">%s</h3></div>%s'
                         % (anchor(t_), t_, b[:first_end]))
            parts.append((task_head, b[first_end:]))
        blocks = ['<div class="entry task"><div class="keep">%s</div>%s</div>' % pr for pr in parts[1:]]
        h0, r0 = parts[0]
        topic_head = ('<div class="margin"><h2 class="margin-head" id="%s">%s</h2></div><p>%s</p>'
                      % (anchor(head), head, intro))
        out.append('<div class="topic-block"><div class="entry task"><div class="keep">%s%s</div>%s</div>%s</div>'
                   % (topic_head, h0, r0, "".join(blocks)))
    contents = ('<div class="chapter chapter-contents"><div class="flow">'
                '<div class="margin"><h2 class="contents-head">Contents</h2></div>'
                '<ul class="toc">%s</ul></div></div>' % "\n".join(toc))
    return (opener(2, "Using MacPhoto Utility", "c2-opener") + contents
            + '<div class="chapter tasks-wide page-break"><div class="flow">%s</div></div>'
            % "".join(out))


DRAFT = draft_title(
    "Chapter 2: Using MacPhoto Utility",
    "A draft for review, 27 October 2026, written against MacPhoto Utility "
    "B-0.9.0. Every task, topic by topic; Chapter 1 is the tutorial, "
    "Chapter 3 the reference.")

PART = body()
TOPICS_TOC = [(anchor(h), h) for h, _, _ in TOPICS]

if __name__ == "__main__":
    open(OUT, "w").write(page("MacPhoto Utility User&rsquo;s Guide: Chapter 2", DRAFT + PART))
    print("wrote", os.path.normpath(OUT))
