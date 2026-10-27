#!/usr/bin/env python3
"""Bake the book's bookmark sheets: assets/ui/book/tabs/1.png (no bookmark raised) and one sheet
per chapter with its bookmark raised (2.png for the first chapter, and so on).

    python3 tools/bake_tabs.py [chapters]

The BookUI book has six bookmarks 48 px apart. Hellfare has seven chapters, so this redraws the
bookmarks down the spine 41 px apart, from the art already in the sheets: the first bookmark
(always at y 280), its raised tip (from 2.png) and a plain stretch of spine between bookmarks.
It can be run again: those three pieces are where it left them.
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "assets", "ui", "book", "tabs")
TOP = 280      # first bookmark's top row
HEIGHT = 37    # a bookmark's height
PITCH = 41     # top to top
X0, X1 = 84, 127          # the strip the bookmarks are drawn in (tip included)
TAB_X1 = 110              # a lowered bookmark ends here; the raised tip runs to X1
STRIP = (276, 563)        # rows repainted (matches TAB_STRIP_REGION in book_shell.gd)
GAP_ROW = 318             # a row of bare spine between the first two bookmarks


def main(chapters: int) -> None:
    base = Image.open(os.path.join(DIR, "1.png")).convert("RGBA")
    raised = Image.open(os.path.join(DIR, "2.png")).convert("RGBA")
    tab = base.crop((X0, TOP, TAB_X1, TOP + HEIGHT))
    tip = raised.crop((TAB_X1, TOP, X1, TOP + HEIGHT))
    gap = base.crop((X0, GAP_ROW, X1, GAP_ROW + 1))
    assert TOP + (chapters - 1) * PITCH + HEIGHT <= STRIP[1], "too many chapters for the spine"
    plain = base.copy()
    for y in range(STRIP[0], STRIP[1]):
        plain.paste(gap, (X0, y))
    for i in range(chapters):
        plain.paste(tab, (X0, TOP + i * PITCH), tab)
    plain.save(os.path.join(DIR, "1.png"))
    for i in range(chapters):
        sheet = plain.copy()
        sheet.paste(tip, (TAB_X1, TOP + i * PITCH))
        sheet.save(os.path.join(DIR, "%d.png" % (i + 2)))
    print("baked", chapters + 1, "sheets,", chapters, "bookmarks", PITCH, "px apart")


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 7)
