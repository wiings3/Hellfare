"""Bake the BookUI close animation for the pause menu.
The pack's Style 1 close shuts the book onto its front cover. Mirrored, it shuts onto the
back cover (spine on the right, clasps on the left), which is where the pause menu lives.
Frames are recoloured to oxblood like the rest of the book (see recolor.py).

Usage: python3 tools/bake_close.py
"""
import os, sys
from PIL import Image, ImageOps
sys.path.insert(0, os.path.dirname(__file__))
from recolor import recolor

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/Sprites/Inventory Book/Open & Close/Style 1/Close")
DST = os.path.join(ROOT, "assets/ui/book/close")

for i in range(1, 7):
    out = os.path.join(DST, f"{i}.png")
    recolor(os.path.join(SRC, f"{i}.png"), out)
    ImageOps.mirror(Image.open(out)).save(out)
print("baked", DST)
