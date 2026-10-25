"""Paint the site banner for Deepdelve (246x126, three ink tones on
transparent parchment, like forest_copse.png). Run from the project root."""
import math, random
from PIL import Image, ImageDraw

INK = (61, 40, 36, 255)
SOFT = (122, 88, 74, 255)
FAINT = (176, 141, 117, 255)
W, H = 246, 126
GROUND = 108


def base():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def deepdelve():
    img, d = base()
    rnd = random.Random(9)
    # Mountain face.
    d.polygon([(0, GROUND), (0, 60), (30, 34), (60, 46), (100, 8), (150, 30), (190, 14), (246, 52), (246, GROUND)], fill=SOFT)
    d.polygon([(100, 8), (150, 30), (120, 60), (90, 40)], fill=INK)
    for _ in range(14):
        x, y = rnd.randrange(10, 236), rnd.randrange(40, 100)
        d.line([(x, y), (x + rnd.randint(6, 14), y + rnd.randint(-3, 3))], fill=FAINT)
    # Dwarven gate: square pillars, a lintel with carved runes, a dark arch.
    gx0, gx1, top = 92, 156, 48
    d.rectangle([gx0 - 8, top, gx1 + 8, GROUND], fill=FAINT)
    d.rectangle([gx0 - 10, top - 6, gx1 + 10, top + 2], fill=INK)
    for x in range(gx0, gx1, 8):
        d.line([(x, top - 4), (x + 3, top - 1)], fill=FAINT)
        d.point((x + 5, top - 3), fill=FAINT)
    d.rectangle([gx0 - 8, top + 2, gx0 + 2, GROUND], fill=INK)
    d.rectangle([gx1 - 2, top + 2, gx1 + 8, GROUND], fill=INK)
    d.pieslice([gx0 + 6, top + 10, gx1 - 6, top + 70], 180, 360, fill=INK)
    d.rectangle([gx0 + 6, top + 40, gx1 - 6, GROUND], fill=INK)
    # Rails running into the dark.
    for k, (x0, x1) in enumerate([(104, 118), (144, 130)]):
        d.line([(x0, GROUND + 16), (x1, top + 56)], fill=SOFT, width=2)
    for y in range(top + 60, GROUND + 16, 6):
        d.line([(110 - (y - top - 60) // 4, y), (138 + (y - top - 60) // 4, y)], fill=SOFT)
    # Lanterns on the pillars.
    for x in (gx0 - 4, gx1 + 3):
        d.rectangle([x - 2, top + 16, x + 2, top + 22], fill=(214, 160, 62, 255))
        d.point((x, top + 14), fill=INK)
    # Stalagmite stones and a broken cart.
    for x, h in [(20, 18), (34, 10), (196, 16), (214, 22), (230, 12)]:
        d.polygon([(x - 5, GROUND), (x, GROUND - h), (x + 5, GROUND)], fill=INK)
    d.polygon([(54, GROUND), (60, GROUND - 12), (80, GROUND - 10), (78, GROUND)], fill=INK)
    d.ellipse([58, GROUND - 4, 64, GROUND + 2], fill=SOFT)
    d.line([(0, GROUND), (W, GROUND)], fill=INK)
    img.save("assets/ui/art/mine_deepdelve.png")


deepdelve()
print("painted mine_deepdelve.png")
