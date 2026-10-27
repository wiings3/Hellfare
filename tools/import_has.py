#!/usr/bin/env python3
"""Bring the crawl's fighters in from the Heroic Asset Series: Creature Pack (Aleksandr Makarov).

    python3 tools/import_has.py /path/to/HAS_Creature_Pack

Each unit's sheet is 16x16 cells, four frames a row: idle, walk, attack, damage taken, death,
and on some units a sixth "special" row. This writes horizontal strips to
assets/ui/crawl/has/<key>_<anim>.png (idle, attack, skill, hurt, death; skill is the special row
when there is one, else the attack) and still portraits for the hero cards to
assets/ui/crawl/<cls>.png. Only the units the game shows are copied: the pack's license allows
the art in the game but not redistributing the pack. Credit: Aleksandr Makarov (CREDITS.md).
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "crawl", "has")
CELL = 16

# Our key: (faction folder, unit, variant 0 or 1)
FIGHTERS = {
    "knight": ("castle", "swordsman", 0),
    "rogue": ("castle", "archer", 0),
    "aldren": ("castle", "paladin", 0),
    "first_blade": ("castle", "paladin", 1),
    "mira": ("castle", "archer", 1),
    "skeleton": ("necropolis", "skeleton", 0),
    "spider": ("necropolis", "spider", 1),
    "death_knight": ("necropolis", "death knight", 0),
    "imp": ("dark bastion", "imp", 0),
    "devil": ("dark bastion", "devil", 0),
}
ROWS = {"idle": 0, "attack": 2, "hurt": 3, "death": 4}


def main(src):
    os.makedirs(OUT, exist_ok=True)
    for key, (faction, unit, variant) in FIGHTERS.items():
        path = glob.glob(os.path.join(glob.escape(os.path.join(src, faction, unit)), "sprite_sheet_*_%d_16x16.png" % variant))[0]
        sheet = Image.open(path).convert("RGBA")
        rows = sheet.height // CELL
        anims = dict(ROWS)
        anims["skill"] = 5 if rows > 5 else 2
        for name, row in anims.items():
            sheet.crop((0, row * CELL, sheet.width, (row + 1) * CELL)).save(os.path.join(OUT, "%s_%s.png" % (key, name)))
    for cls in ["knight", "rogue"]:
        frame = Image.open(os.path.join(OUT, "%s_idle.png" % cls)).crop((0, 0, CELL, CELL))
        box = frame.getbbox()
        frame.crop((box[0] - 1, box[1] - 1, box[2] + 1, box[3] + 1)).save(os.path.join(ROOT, "assets", "ui", "crawl", "%s.png" % cls))
    print("imported", len(FIGHTERS), "fighters to", OUT)


if __name__ == "__main__":
    main(sys.argv[1])
