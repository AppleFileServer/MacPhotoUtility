#!/usr/bin/env python3
"""Writes Documentation/manual/sample/sample.html, the sample pages (step 2
of MANUAL-PLAN.md, MG11): Chapter 1's opener spread with its red-bordered
title (MG4), Lesson 3, "Framing the Print", and a task page in the wide
column, "Exporting Your Photographs" (the utilities addendum's style).

Build it with tools/manual/build-pdf.sh Documentation/manual/sample/sample.html <pdf>."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from book import img, opener, page

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "Documentation", "manual", "sample", "sample.html")

# CHECK: not yet seen on the real Plus (MG8).
CHECK = '<span class="check">CHECK</span>'

EDITOR = img("p-editor", 448, "screen modern")       # the whole text area's width
OUTPUT = img("p-output", 210, "screen modern")

BODY = opener(1, "Learning MacPhoto Utility", "c1-opener") + f'''
<div class="lesson100 w100 page-break">
 <div class="flow">
  <div class="margin">
   <div class="lesson-head"><span class="number">3</span><span class="title">Framing the Print</span></div>
  </div>
   <p class="lessons-intro">The print is 2.5 by 3.5 inches, so it can&rsquo;t
   always show the whole photograph. You choose the part it shows, and
   everything else is left out of the print, but never out of your
   photograph.</p>
   <p class="step">Click Print Crop, above the picture, if it isn&rsquo;t
   already chosen.</p>
   <p>A white frame shows what will be printed. Everything outside it is
   dimmed. The frame keeps the print&rsquo;s shape however you change
   it.</p>
   <figure class="window wide">{EDITOR}</figure>
   <p class="step">Drag inside the frame to move it.</p>
   <p>The print preview, below the picture, follows a moment later. It&rsquo;s
   the print itself, made from the whole photograph, not a sketch.</p>
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
 </div>
</div>

<div class="task100 tasks-wide page-break w100">
 <div class="flow">
  <div class="topic-block">
   <div class="keep">
    <div class="margin"><h2 class="margin-head">Exporting Your Photographs</h2></div>
    <p>MacPhoto Utility makes its files in a folder you choose: the print
    image, the screen image and, if you want it, a MacPaint document.
    Each file is checked after it&rsquo;s written.</p>
   </div>
   <div class="entry task">
    <div class="keep">
     <div class="margin"><h3 class="task-head">To Export Every Photograph</h3></div>
     <p class="step">Click Export All, under Output.</p>
    </div>
    <p>The photographs are exported one at a time, in the order of the
    list. The panel shows which one it&rsquo;s on; click Stop to stop after
    that one.</p>
    <figure class="window">{OUTPUT}</figure>
    <p class="grey">If you haven&rsquo;t looked at some of the photographs,
    MacPhoto Utility asks first: they&rsquo;d be exported framed in the
    middle, at full size.</p>
   </div>
   <div class="entry task">
    <div class="keep">
     <div class="margin"><h3 class="task-head">If a File Is Already There</h3></div>
     <p>When the folder already has files of the same names, MacPhoto
     Utility asks once, for all of them:</p>
    </div>
    <ul class="boxes">
     <li><b>Keep Both</b> saves the new files under the next free name:
     IMG_8691 2.pict, say.</li>
     <li><b>Replace</b> puts the new files in place of the old ones.</li>
     <li><b>Skip Those Photographs</b> leaves them out.</li>
     <li><b>Cancel</b> exports nothing.</li>
    </ul>
   </div>
   <div class="entry task">
    <div class="keep">
     <div class="margin"><h3 class="task-head">To Put the Files on the Macintosh Plus</h3></div>
     <p>The Macintosh Transfer Utility puts them on a disk for the Plus,
     in folders of the same names. {CHECK}</p>
    </div>
   </div>
  </div>
 </div>
</div>
'''

os.makedirs(os.path.dirname(OUT), exist_ok=True)
html = page("MacPhoto Utility User&rsquo;s Guide: sample pages", BODY)
open(OUT, "w").write(html)
print("wrote", os.path.normpath(OUT))
