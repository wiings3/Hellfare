"""Paint the site banners for Greyvein Quarry and Deepdelve (246x126, three ink tones on
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


def quarry():
    img, d = base()
    rnd = random.Random(3)
    # Distant hills.
    d.polygon([(0, 70), (40, 52), (80, 62), (130, 44), (180, 58), (246, 40), (246, GROUND), (0, GROUND)], fill=FAINT)
    # Terraced cut: a stepped cliff rising to the right, with strata and ledges.
    profile = [(84, GROUND), (84, 94), (106, 94), (106, 78), (128, 78), (128, 62), (150, 62), (150, 46), (172, 46), (172, 30), (246, 30), (246, GROUND)]
    d.polygon(profile, fill=SOFT)
    for y in range(34, GROUND, 5):
        x0 = next(px for (px, py) in profile[1:-1:2] if py <= y) if any(py <= y for (px, py) in profile[1:-1:2]) else 84
        d.line([(x0 + 2, y), (246, y + rnd.randint(-1, 1))], fill=FAINT)
    for (xa, ya), (xb, yb) in zip(profile[1:-1], profile[2:-1]):
        if ya == yb:
            d.line([(xa, ya), (xb, yb)], fill=FAINT)
        else:
            d.line([(xa, ya), (xb, yb)], fill=INK, width=2)
    for x in range(176, 246, 9):
        d.line([(x, 31), (x + 4, 44)], fill=INK)
    # Derrick: an A-frame with a boom and a hanging bucket.
    d.line([(46, GROUND), (62, 34)], fill=INK, width=3)
    d.line([(78, GROUND), (62, 34)], fill=INK, width=3)
    d.line([(52, 80), (72, 80)], fill=INK, width=2)
    d.line([(62, 34), (112, 28)], fill=INK, width=2)
    d.line([(108, 29), (108, 70)], fill=SOFT, width=1)
    d.rectangle([103, 70, 113, 78], fill=INK)
    d.line([(62, 34), (40, GROUND - 4)], fill=SOFT, width=1)
    # Rubble piles and a cart.
    for cx, cy, r in [(20, GROUND, 14), (36, GROUND, 9), (140, GROUND, 10), (204, GROUND, 13)]:
        d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=INK)
        for k in range(5):
            a = math.radians(200 + k * 30)
            d.point((cx + int(r * 0.6 * math.cos(a)), cy + int(r * 0.6 * math.sin(a))), fill=FAINT)
    d.rectangle([84, GROUND - 14, 106, GROUND - 4], fill=INK)
    d.ellipse([86, GROUND - 6, 92, GROUND], fill=SOFT)
    d.ellipse([98, GROUND - 6, 104, GROUND], fill=SOFT)
    for x in range(86, 105, 4):
        d.point((x, GROUND - 16), fill=SOFT)
    # Ground line and pebbles.
    d.line([(0, GROUND), (W, GROUND)], fill=INK)
    for _ in range(40):
        x, y = rnd.randrange(0, W), rnd.randrange(GROUND + 2, H - 4)
        d.point((x, y), fill=FAINT)
    img.save("assets/ui/art/quarry_greyvein.png")


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


quarry()
deepdelve()
print("painted quarry_greyvein.png, mine_deepdelve.png")
