#!/usr/bin/env python3
"""Bring the Duskwarden sprites the crawl uses into the game.

    python3 tools/import_duskwarden.py /path/to/Duskwarden/outputs/duskwarden

Writes horizontal animation strips to assets/ui/crawl/dusk/<key>_<anim>.png (square cells; the
frame count is width / height) and still portraits for the hero cards to assets/ui/crawl/<cls>.png.
Only what the game shows is copied: the Duskwarden license allows the art inside the game but not
the raw pack on its own, so the pack itself never goes in the repository.

Animations kept per fighter: idle, attack (Strike), skill (the class skill, or a boss's second
attack), hurt and death. Some fighters are recoloured from the pack's 32-colour palette:
  aldren      the knight in polished steel and brass (Ser Aldren Vane, before)
  first_blade the Fallen Knight as it comes (Aldren, after: Death's First Blade)
  gatekeeper  the Fallen Knight with ember light for teal (the Ember Gate's warden)
  cultist     the pack's cultist with ember light for teal (the Brimstone Reach's cultists)
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "crawl", "dusk")

WINE = ["#4b233b", "#79374a", "#ab5361", "#d67f79"]
BRASS = ["#73533f", "#aa7950", "#dbb477", "#eee0ae"]
SLATE = ["#273c4b", "#3d5b69", "#5b8190", "#8eb1b5"]
STEEL = ["#3d5b69", "#5b8190", "#8eb1b5", "#d4cad0"]
TEAL = ["#16434b", "#22676c", "#38a096", "#87d9ba"]
EMBER = ["#a64836", "#df793d", "#f8bc65", "#eee0ae"]


def _rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def remap(*pairs):
    table = {}
    for src, dst in pairs:
        for a, b in zip(src, dst):
            table[_rgb(a)] = _rgb(b)
    return table


# key: (folder, pack name, {our anim: pack anim}, recolour)
HERO = {"idle": "idle", "attack": "attack", "skill": "secondary_attack", "hurt": "hurt", "death": "death"}
FOE = {"idle": "idle", "attack": "attack", "skill": "attack", "hurt": "hurt", "death": "death"}
BOSS = {"idle": "idle", "attack": "attack_1", "skill": "attack_2", "hurt": "hurt", "death": "death"}
FIGHTERS = {
    "knight": ("characters/knight", "knight", HERO, None),
    "rogue": ("characters/rogue", "rogue", HERO, None),
    "aldren": ("characters/knight", "knight", HERO, remap((WINE, BRASS), (SLATE, STEEL))),
    "first_blade": ("boss/fallen_knight", "fallen_knight", BOSS, None),
    "gatekeeper": ("boss/fallen_knight", "fallen_knight", BOSS, remap((TEAL, EMBER))),
    "bat": ("enemies/bat", "bat", FOE, None),
    "skeleton": ("enemies/skeleton", "skeleton", FOE, None),
    "armored_undead": ("enemies/armored_undead", "armored_undead", FOE, None),
    "cultist": ("enemies/cultist", "cultist", FOE, remap((TEAL, EMBER))),
    "slime": ("enemies/slime", "slime", FOE, None),
}


def recolour(img, table):
    if not table:
        return img
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in table:
                px[x, y] = table[(r, g, b)] + (a,)
    return img


def main(src):
    os.makedirs(OUT, exist_ok=True)
    for key, (folder, name, anims, table) in FIGHTERS.items():
        for ours, theirs in anims.items():
            path = os.path.join(src, "assets", folder, "spritesheets", "%s_%s_spritesheet.png" % (name, theirs))
            img = recolour(Image.open(path).convert("RGBA"), table)
            img.save(os.path.join(OUT, "%s_%s.png" % (key, ours)))
    # Still portraits for the hero cards and the prologue's choice: the first idle frame,
    # trimmed to the figure.
    for cls in ["knight", "rogue"]:
        strip = Image.open(os.path.join(OUT, "%s_idle.png" % cls))
        cell = strip.crop((0, 0, strip.height, strip.height))
        box = cell.getbbox()
        pad = 2
        cell.crop((box[0] - pad, box[1] - pad, box[2] + pad, box[3] + pad)).save(
            os.path.join(ROOT, "assets", "ui", "crawl", "%s.png" % cls))
    print("imported", len(FIGHTERS), "fighters to", OUT)


if __name__ == "__main__":
    main(sys.argv[1])
