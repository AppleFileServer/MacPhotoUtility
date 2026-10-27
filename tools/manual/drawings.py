"""The manual's line drawings (figures.md, d- codes), as inline SVG and
HTML in the book's black, grey and red (the series' drawings.py): a
photograph's journey to the Plus (d-journey), and the print's and the
screen's shapes over one photograph (d-two-shapes)."""


def journey():
    """d-journey: from the photograph to the Plus, in four red-ruled
    stages (the Bulk Formatter's D-line)."""
    stages = [("1", "Your photograph", "JPEG, HEIC, PNG or TIFF, on your Mac"),
              ("2", "MacPhoto Utility", "framed twice: a print image and a screen image"),
              ("3", "Macintosh Transfer Utility", "puts the files on a disk for the Plus"),
              ("4", "The Macintosh Plus", "MacPhoto, SuperPaint, MacPaint, After Dark")]
    boxes = "".join('<div class="stage"><span class="number">%s</span>'
                    '<b>%s</b><span>%s</span></div>' % s for s in stages)
    return '<div class="stages">%s</div>' % boxes


def two_shapes():
    """d-two-shapes: one landscape photograph (4:3) with a portrait
    print's frame (5:7) and the screen's (512:342), each as large as
    fits, centred: why each needs its own frame. The print's in red, the
    screen's in black, dashed; labels outside the picture."""
    W, H = 240.0, 180.0                       # the photograph, 4:3
    ph, pw = H, H * 5 / 7                     # a portrait print: full height
    sw, sh = W, W * 342 / 512                 # the screen: full width
    x0, y0 = 20.0, 10.0
    px, sy = x0 + (W - pw) / 2, y0 + (H - sh) / 2
    def label(x, y, text, colour="#111", anchor="start"):
        return ('<text x="%g" y="%g" font-family="Helvetica" font-size="8" fill="%s" '
                'text-anchor="%s">%s</text>' % (x, y, colour, anchor, text))
    return ('<svg width="370pt" height="215pt" viewBox="0 0 370 215">'
            '<rect x="%g" y="%g" width="%g" height="%g" fill="#e6e6e6" stroke="#111" stroke-width="0.8"/>'
            '<rect x="%g" y="%g" width="%g" height="%g" fill="none" stroke="#111" stroke-width="1" stroke-dasharray="4 3"/>'
            '<rect x="%g" y="%g" width="%g" height="%g" fill="none" stroke="#e0442b" stroke-width="1.6"/>'
            % (x0, y0, W, H, x0, sy, sw, sh, px, y0, pw, ph)
            + label(x0 + W + 8, y0 + 10, "Print, portrait:", "#e0442b")
            + label(x0 + W + 8, y0 + 20, "2.5 &#215; 3.5 in, 5:7", "#e0442b")
            + label(x0 + W + 8, sy + sh - 12, "Mac Plus screen:")
            + label(x0 + W + 8, sy + sh - 2, "512 &#215; 342, about 3:2")
            + label(x0, y0 + H + 14, "The photograph, 4:3", "#555")
            + '</svg>')
