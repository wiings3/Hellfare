"""Paint the site banners for the foraging, fishing, hunting and farming sites
(246x126, three ink tones on transparent parchment, like forest_copse.png).
Run from the project root: writes assets/ui/art/site_<id>.png."""
import math
import random
from PIL import Image, ImageDraw

INK = (61, 40, 36, 255)
SOFT = (122, 88, 74, 255)
FAINT = (176, 141, 117, 255)
GOLD = (214, 160, 62, 255)
W, H = 246, 126
GROUND = 108


def base():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def hills(d, rnd, top, spread, fill, step=18):
    """A rolling ridge line from left to right, filled down to the ground."""
    pts = [(0, GROUND)]
    for x in range(0, W + step, step):
        pts.append((x, top + rnd.randint(-spread, spread)))
    pts.append((W, GROUND))
    smooth = [pts[0]]
    for (x0, y0), (x1, y1) in zip(pts[1:-2], pts[2:-1]):
        for t in range(0, 6):
            k = t / 6
            smooth.append((x0 + (x1 - x0) * k, y0 + (y1 - y0) * (1 - math.cos(k * math.pi)) / 2))
    smooth.append(pts[-2])
    smooth.append(pts[-1])
    d.polygon(smooth, fill=fill)


def peaks(d, xs, base_y, fill, snow=False):
    for x, h, w in xs:
        d.polygon([(x - w, base_y), (x, base_y - h), (x + w, base_y)], fill=fill)
        if snow:
            s = h // 3
            d.polygon([(x - w * s // h, base_y - h + s), (x, base_y - h), (x + w * s // h, base_y - h + s),
                       (x + 2, base_y - h + s - 3), (x - 3, base_y - h + s + 2)], fill=(236, 226, 210, 255))


def pine(d, x, y, h, fill=INK):
    w = h // 3
    for k in range(3):
        top = y - h + k * h // 4
        d.polygon([(x - w + (2 - k) * 2, top + h // 2), (x, top), (x + w - (2 - k) * 2, top + h // 2)], fill=fill)
    d.rectangle([x - 1, y - h // 4, x + 1, y], fill=fill)


def oak(d, x, y, h, fill=INK):
    d.rectangle([x - 2, y - h // 2, x + 2, y], fill=fill)
    r = h // 3
    for dx, dy in [(-r // 2, -h + r), (r // 2, -h + r), (0, -h + r // 2), (-r, -h + r + 4), (r, -h + r + 4)]:
        d.ellipse([x + dx - r // 2 - 3, y + dy - r // 2, x + dx + r // 2 + 3, y + dy + r // 2], fill=fill)


def dead_tree(d, x, y, h, fill=INK):
    d.line([(x, y), (x, y - h)], fill=fill, width=3)
    d.line([(x, y - h * 2 // 3), (x - 8, y - h + 2)], fill=fill, width=2)
    d.line([(x, y - h // 2), (x + 9, y - h * 3 // 4)], fill=fill, width=2)
    d.line([(x + 5, y - h * 5 // 8), (x + 8, y - h * 7 // 8)], fill=fill)


def reeds(d, rnd, x0, x1, y, n, fill=INK):
    for _ in range(n):
        x = rnd.randint(x0, x1)
        h = rnd.randint(8, 16)
        lean = rnd.randint(-3, 3)
        d.line([(x, y), (x + lean, y - h)], fill=fill)
        if rnd.random() < 0.4:
            d.rectangle([x + lean - 1, y - h, x + lean + 1, y - h + 4], fill=fill)


def grass(d, rnd, y0, y1, n, fill=SOFT):
    for _ in range(n):
        x, y = rnd.randint(2, W - 2), rnd.randint(y0, y1)
        d.line([(x, y), (x - 2, y - 4)], fill=fill)
        d.line([(x, y), (x + 2, y - 4)], fill=fill)


def flowers(d, rnd, y0, y1, n, fill=INK, centre=GOLD):
    for _ in range(n):
        x, y = rnd.randint(4, W - 4), rnd.randint(y0, y1)
        d.line([(x, y), (x, y + 5)], fill=SOFT)
        for dx, dy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
            d.point((x + dx, y + dy), fill=fill)
        d.point((x, y), fill=centre)


def water(d, rnd, y0, y1, x0=0, x1=W, fill=FAINT, ripples=SOFT, n=18):
    d.rectangle([x0, y0, x1, y1], fill=fill)
    for _ in range(n):
        x, y = rnd.randint(x0 + 4, x1 - 14), rnd.randint(y0 + 3, y1 - 2)
        d.line([(x, y), (x + rnd.randint(5, 12), y)], fill=ripples)


def ground(d):
    d.line([(0, GROUND), (W, GROUND)], fill=INK)


def rock(d, x, y, w, h, fill=INK):
    d.polygon([(x - w, y), (x - w + 3, y - h + 2), (x, y - h), (x + w - 2, y - h + 4), (x + w, y)], fill=fill)


def basket(d, x, y):
    d.pieslice([x - 9, y - 10, x + 9, y + 6], 0, 180, fill=INK)
    d.arc([x - 7, y - 12, x + 7, y + 2], 180, 360, fill=INK)
    for k in range(-6, 8, 4):
        d.line([(x + k, y - 2), (x + k, y + 4)], fill=SOFT)
    for k in range(3):
        d.ellipse([x - 6 + k * 4, y - 5, x - 2 + k * 4, y - 1], fill=(150, 40, 90, 255))


def jetty(d, x0, x1, y):
    d.rectangle([x0, y - 3, x1, y], fill=INK)
    for x in range(x0 + 2, x1, 8):
        d.line([(x, y), (x, y + 9)], fill=INK, width=2)
        d.line([(x + 3, y - 3), (x + 3, y)], fill=SOFT)


def rod_and_line(d, x, y, length, tip_drop):
    d.line([(x, y), (x + length, y - length // 2)], fill=INK, width=2)
    d.line([(x + length, y - length // 2), (x + length + 6, y - length // 2 + tip_drop)], fill=SOFT)
    d.ellipse([x + length + 4, y - length // 2 + tip_drop - 1, x + length + 8, y - length // 2 + tip_drop + 3], fill=(200, 52, 52, 255))


def elk(d, x, y, s=1.0, fill=INK):
    def P(px, py):
        return (x + px * s, y + py * s)
    d.polygon([P(-14, -14), P(10, -16), P(14, -12), P(12, -4), P(-12, -4), P(-16, -10)], fill=fill)
    for lx in (-11, -6, 6, 10):
        d.line([P(lx, -5), P(lx, 6)], fill=fill, width=max(1, int(2 * s)))
    d.polygon([P(10, -16), P(18, -26), P(24, -24), P(16, -12)], fill=fill)
    d.polygon([P(18, -26), P(26, -22), P(26, -20), P(22, -20)], fill=fill)
    for ax, ay in [(16, -36), (24, -38), (12, -32)]:
        d.line([P(19, -26), P(ax, ay)], fill=fill, width=max(1, int(2 * s)))
    d.line([P(16, -36), P(12, -40)], fill=fill)
    d.line([P(24, -38), P(28, -42)], fill=fill)


def hare(d, x, y):
    d.ellipse([x - 7, y - 6, x + 5, y], fill=INK)
    d.ellipse([x + 2, y - 9, x + 8, y - 4], fill=INK)
    d.line([(x + 5, y - 9), (x + 3, y - 16)], fill=INK, width=2)
    d.line([(x + 7, y - 9), (x + 8, y - 15)], fill=INK, width=2)
    d.point((x - 8, y - 4), fill=FAINT)


def hide_tent(d, x, y):
    """A hunter's lean-to with a hide drying on a frame."""
    d.polygon([(x - 18, y), (x, y - 22), (x + 14, y)], fill=INK)
    d.polygon([(x - 6, y), (x, y - 12), (x + 4, y)], fill=FAINT)
    d.line([(x + 22, y), (x + 22, y - 18)], fill=INK, width=2)
    d.line([(x + 40, y), (x + 40, y - 18)], fill=INK, width=2)
    d.line([(x + 20, y - 18), (x + 42, y - 18)], fill=INK, width=2)
    d.polygon([(x + 24, y - 16), (x + 38, y - 16), (x + 36, y - 4), (x + 31, y - 2), (x + 26, y - 4)], fill=SOFT)


def furrows(d, x0, x1, y0, y1, fill=SOFT, vanish=None, crop=None):
    vx = vanish if vanish is not None else (x0 + x1) // 2
    for k in range(0, 13):
        bx = x0 + (x1 - x0) * k // 12
        tx = vx + (bx - vx) // 4
        d.line([(tx, y0), (bx, y1)], fill=fill)
        if crop:
            for t in range(1, 6):
                px = tx + (bx - tx) * t // 6
                py = y0 + (y1 - y0) * t // 6
                crop(px, py, t)


def farmhouse(d, x, y, w=34, h=18):
    d.rectangle([x, y - h, x + w, y], fill=SOFT)
    d.polygon([(x - 4, y - h), (x + w // 2, y - h - 16), (x + w + 4, y - h)], fill=INK)
    d.rectangle([x + w // 2 - 3, y - 9, x + w // 2 + 3, y], fill=INK)
    d.rectangle([x + 4, y - h + 4, x + 9, y - h + 9], fill=GOLD)
    d.rectangle([x + w - 9, y - h + 4, x + w - 4, y - h + 9], fill=GOLD)
    d.rectangle([x + w - 8, y - h - 14, x + w - 4, y - h - 6], fill=INK)


def fence(d, x0, x1, y):
    d.line([(x0, y - 6), (x1, y - 6)], fill=INK)
    d.line([(x0, y - 2), (x1, y - 2)], fill=INK)
    for x in range(x0, x1 + 1, 10):
        d.rectangle([x - 1, y - 9, x + 1, y], fill=INK)


def skep(d, x, y):
    for k in range(4):
        w = 9 - k * 2
        d.ellipse([x - w, y - 5 - k * 4, x + w, y - k * 4], fill=GOLD if k % 2 == 0 else (176, 120, 32, 255))
        d.arc([x - w, y - 5 - k * 4, x + w, y - k * 4], 0, 180, fill=INK)
    d.rectangle([x - 2, y - 3, x + 2, y], fill=INK)
    d.rectangle([x - 12, y, x + 12, y + 2], fill=INK)


def bees(d, rnd, n, x0, x1, y0, y1):
    for _ in range(n):
        x, y = rnd.randint(x0, x1), rnd.randint(y0, y1)
        d.point((x, y), fill=INK)
        d.point((x + 1, y), fill=GOLD)
        d.point((x, y - 1), fill=FAINT)


def scarecrow(d, x, y):
    d.line([(x, y), (x, y - 30)], fill=INK, width=2)
    d.line([(x - 12, y - 22), (x + 12, y - 22)], fill=INK, width=2)
    d.polygon([(x - 7, y - 23), (x + 7, y - 23), (x + 5, y - 10), (x - 5, y - 10)], fill=SOFT)
    d.ellipse([x - 4, y - 34, x + 4, y - 26], fill=FAINT)
    d.polygon([(x - 8, y - 32), (x + 8, y - 32), (x, y - 40)], fill=INK)


# --- Foraging -------------------------------------------------------------------------

def mossward_meadows():
    img, d = base(); rnd = random.Random(11)
    hills(d, rnd, 70, 8, FAINT)
    hills(d, rnd, 86, 6, SOFT)
    for x in (30, 196, 214):
        oak(d, x, 90, 28, SOFT)
    oak(d, 222, GROUND, 44)
    grass(d, rnd, 92, 106, 50)
    flowers(d, rnd, 90, 104, 26)
    basket(d, 70, GROUND - 4)
    ground(d); return img


def fenmire():
    img, d = base(); rnd = random.Random(12)
    hills(d, rnd, 80, 4, FAINT, step=30)
    for x, h in [(30, 46), (176, 38), (206, 52)]:
        dead_tree(d, x, 96, h, SOFT)
    for x0, x1, y in [(20, 110, 98), (120, 200, 102), (60, 150, 92)]:
        d.ellipse([x0, y - 4, x1, y + 6], fill=FAINT)
        d.line([(x0 + 10, y + 1), (x0 + 24, y + 1)], fill=SOFT)
    reeds(d, rnd, 0, W, GROUND, 60)
    for x in (100, 150):
        d.ellipse([x - 3, 84, x + 3, 90], fill=GOLD)  # will-o'-wisps over the bog
    dead_tree(d, 228, GROUND, 60)
    ground(d); return img


def sunreach():
    img, d = base(); rnd = random.Random(13)
    d.ellipse([170, 10, 206, 46], fill=GOLD)
    for a in range(0, 360, 30):
        r0, r1 = 22, 30
        d.line([(188 + r0 * math.cos(math.radians(a)), 28 + r0 * math.sin(math.radians(a))),
                (188 + r1 * math.cos(math.radians(a)), 28 + r1 * math.sin(math.radians(a)))], fill=GOLD)
    d.polygon([(0, GROUND), (0, 40), (90, 62), (246, 96), (246, GROUND)], fill=SOFT)
    d.polygon([(0, 40), (40, 30), (90, 62)], fill=INK)
    for x, y in [(30, 70), (70, 80), (120, 88), (150, 96)]:
        rock(d, x, y, 8, 6)
    flowers(d, rnd, 70, 104, 30, fill=GOLD, centre=INK)
    ground(d); return img


def frostvale():
    img, d = base(); rnd = random.Random(14)
    peaks(d, [(40, 70, 40), (110, 90, 50), (190, 76, 46)], 96, SOFT, snow=True)
    for x in range(8, W, 22):
        pine(d, x + rnd.randint(-4, 4), GROUND, rnd.randint(26, 40))
    for _ in range(50):
        d.point((rnd.randint(0, W - 1), rnd.randint(0, GROUND - 2)), fill=(236, 226, 210, 255))
    flowers(d, rnd, 100, 106, 10, fill=(150, 200, 230, 255), centre=(236, 226, 210, 255))
    ground(d); return img


# --- Fishing --------------------------------------------------------------------------

def millbrook_pond():
    img, d = base(); rnd = random.Random(21)
    hills(d, rnd, 72, 6, FAINT)
    oak(d, 24, 92, 46, SOFT)
    d.chord([36, 84, 224, 132], 180, 360, fill=FAINT)
    for _ in range(10):
        x = rnd.randint(70, 190); y = rnd.randint(92, 104)
        d.line([(x, y), (x + 8, y)], fill=SOFT)
    reeds(d, rnd, 40, 70, 104, 14)
    reeds(d, rnd, 196, 226, 104, 14)
    jetty(d, 120, 176, 98)
    rod_and_line(d, 160, 94, 22, 14)
    d.ellipse([150, 82, 158, 90], fill=INK)  # the angler's head
    d.rectangle([150, 88, 158, 96], fill=INK)
    ground(d); return img


def silverrun():
    img, d = base(); rnd = random.Random(22)
    hills(d, rnd, 58, 10, FAINT)
    hills(d, rnd, 78, 8, SOFT)
    d.polygon([(100, 60), (120, 60), (190, GROUND), (60, GROUND)], fill=(214, 202, 186, 255))
    for _ in range(14):
        y = rnd.randint(64, 104); w = (y - 60) // 3
        x = 110 + rnd.randint(-w, w)
        d.line([(x, y), (x + 6, y)], fill=FAINT)
    for x, y in [(80, 100), (150, 96), (170, 104), (96, 88)]:
        rock(d, x, y, 7, 5)
    for x in (20, 40, 210, 230):
        pine(d, x, GROUND, 40)
    ground(d); return img


def glasswater():
    img, d = base(); rnd = random.Random(23)
    peaks(d, [(60, 50, 40), (130, 64, 46), (200, 54, 40)], 70, SOFT, snow=True)
    d.rectangle([0, 70, W, GROUND], fill=FAINT)
    for x, h, w in [(60, 50, 40), (130, 64, 46), (200, 54, 40)]:  # reflection
        d.polygon([(x - w, 70), (x, 70 + h // 2), (x + w, 70)], fill=(160, 126, 104, 255))
    for _ in range(12):
        x, y = rnd.randint(0, 230), rnd.randint(74, 104)
        d.line([(x, y), (x + 10, y)], fill=(214, 202, 186, 255))
    d.ellipse([110, 88, 116, 92], fill=(240, 234, 220, 255))  # a pearl's glint
    reeds(d, rnd, 0, 30, GROUND, 10)
    ground(d); return img


def greywater_coast():
    img, d = base(); rnd = random.Random(24)
    d.rectangle([0, 60, W, GROUND], fill=FAINT)
    for row in range(64, GROUND, 8):
        for x in range(rnd.randint(-10, 0), W, 22):
            d.arc([x, row - 3, x + 12, row + 3], 200, 340, fill=SOFT)
    d.polygon([(150, GROUND), (156, 40), (176, 30), (210, 34), (246, 24), (246, GROUND)], fill=INK)
    d.polygon([(156, 40), (176, 30), (184, 50), (160, 64)], fill=SOFT)
    d.rectangle([222, 10, 232, 26], fill=SOFT)  # lighthouse
    d.polygon([(220, 10), (227, 3), (234, 10)], fill=INK)
    d.rectangle([224, 12, 230, 16], fill=GOLD)
    for x in (30, 60, 110):
        rock(d, x, GROUND, 10, 8)
    jetty(d, 100, 150, 96)
    ground(d); return img


def drowned_deep():
    img, d = base(); rnd = random.Random(25)
    d.rectangle([0, 52, W, GROUND], fill=SOFT)
    for row in range(56, GROUND, 7):
        for x in range(rnd.randint(-10, 0), W, 18):
            d.arc([x, row - 3, x + 10, row + 3], 200, 340, fill=INK)
    # A drowned tower leaning out of the deep.
    d.polygon([(96, 70), (102, 18), (124, 14), (128, 70)], fill=INK)
    d.polygon([(98, 18), (112, 2), (128, 14)], fill=INK)
    for y in (28, 44):
        d.rectangle([108, y, 114, y + 8], fill=(90, 60, 140, 255))
    for _ in range(20):
        x, y = rnd.randint(4, W - 4), rnd.randint(60, GROUND - 2)
        d.point((x, y), fill=(170, 130, 220, 255))
    for x in (30, 190, 220):
        rock(d, x, 60, 12, 10)
    ground(d); return img


# --- Hunting --------------------------------------------------------------------------

def hollow_fields():
    img, d = base(); rnd = random.Random(31)
    hills(d, rnd, 76, 6, FAINT)
    for x in range(0, W, 14):  # a hedgerow
        d.ellipse([x - 4, 80 + rnd.randint(-2, 2), x + 12, 94], fill=SOFT)
    grass(d, rnd, 96, 106, 60)
    hare(d, 60, GROUND - 2)
    hare(d, 170, GROUND - 6)
    oak(d, 214, GROUND, 52)
    ground(d); return img


def greyfang_hills():
    img, d = base(); rnd = random.Random(32)
    hills(d, rnd, 44, 14, FAINT, step=30)
    hills(d, rnd, 70, 10, SOFT, step=24)
    for x in (20, 44, 196, 226):
        pine(d, x, 96, 36)
    for x, y in [(90, 98), (140, 104)]:
        rock(d, x, y, 14, 12)
    hide_tent(d, 160, GROUND)
    d.line([(60, GROUND), (60, GROUND - 6)], fill=SOFT)
    ground(d); return img


def elkmoor():
    img, d = base(); rnd = random.Random(33)
    hills(d, rnd, 66, 6, FAINT, step=40)
    hills(d, rnd, 86, 4, SOFT, step=36)
    grass(d, rnd, 88, 106, 70)
    elk(d, 120, 94, 1.3)
    elk(d, 40, 82, 0.6, SOFT)
    for x in (200, 226):
        dead_tree(d, x, GROUND, 40)
    ground(d); return img


def bleakridge():
    img, d = base(); rnd = random.Random(34)
    peaks(d, [(30, 60, 50), (120, 96, 60), (210, 70, 50)], GROUND, SOFT, snow=True)
    d.pieslice([100, 76, 140, 116], 180, 360, fill=INK)  # a cave mouth in the ridge
    d.rectangle([100, 96, 140, GROUND], fill=INK)
    for k in range(6):  # tracks into the dark
        x = 60 + k * 8
        d.ellipse([x, GROUND - 4 + (k % 2) * 2, x + 4, GROUND - 1 + (k % 2) * 2], fill=INK)
    for _ in range(40):
        d.point((rnd.randint(0, W - 1), rnd.randint(0, GROUND - 2)), fill=(236, 226, 210, 255))
    ground(d); return img


# --- Farming --------------------------------------------------------------------------

def wheat_ear(d):
    def crop(x, y, t):
        d.line([(x, y), (x, y - 2 - t)], fill=GOLD)
    return crop


def home_fields():
    img, d = base(); rnd = random.Random(41)
    hills(d, rnd, 64, 4, FAINT, step=40)
    d.polygon([(0, 74), (W, 70), (W, GROUND), (0, GROUND)], fill=SOFT)
    furrows(d, -60, 200, 74, GROUND, fill=INK, vanish=40, crop=wheat_ear(d))
    farmhouse(d, 180, 86)
    oak(d, 228, 90, 34)
    fence(d, 150, 246, GROUND)
    ground(d); return img


def tilled_acres():
    img, d = base(); rnd = random.Random(42)
    hills(d, rnd, 60, 4, FAINT, step=40)
    d.polygon([(0, 70), (W, 68), (W, GROUND), (0, GROUND)], fill=SOFT)

    def potato(x, y, t):
        d.ellipse([x - 1, y - 1 - t // 2, x + 1 + t // 2, y + 1], fill=INK)
    furrows(d, -40, 290, 70, GROUND, fill=INK, vanish=120, crop=potato)
    scarecrow(d, 60, 94)
    fence(d, 0, 100, GROUND)
    d.polygon([(190, 82), (210, 82), (214, 96), (186, 96)], fill=INK)  # a cart
    for x in (192, 208):
        d.ellipse([x - 5, 92, x + 5, 102], fill=SOFT)
        d.ellipse([x - 2, 95, x + 2, 99], fill=INK)
    ground(d); return img


def beehives():
    img, d = base(); rnd = random.Random(43)
    hills(d, rnd, 70, 6, FAINT)
    oak(d, 30, 98, 56, SOFT)
    d.rectangle([60, 96, 200, 100], fill=INK)  # the bench
    for x in (80, 110, 140, 170):
        skep(d, x, 96)
    bees(d, rnd, 40, 60, 200, 50, 90)
    flowers(d, rnd, 100, 106, 24)
    fence(d, 200, 246, GROUND)
    ground(d); return img


def glasshouse():
    img, d = base(); rnd = random.Random(44)
    hills(d, rnd, 70, 6, FAINT)
    x0, x1, top = 52, 194, 40
    d.polygon([(x0, 70), ((x0 + x1) // 2, top), (x1, 70)], fill=(214, 202, 186, 255))
    d.rectangle([x0, 70, x1, GROUND], fill=(214, 202, 186, 255))
    for x in range(x0, x1 + 1, 14):  # glazing bars
        y = 70 - (x1 - x0) // 2 * 0 if False else 70 - (min(x - x0, x1 - x) * (70 - top)) // ((x1 - x0) // 2)
        d.line([(x, y), (x, GROUND)], fill=INK)
    d.line([(x0, 70), (x1, 70)], fill=INK, width=2)
    d.line([(x0, 70), ((x0 + x1) // 2, top), (x1, 70)], fill=INK, width=2)
    d.line([(x0, 88), (x1, 88)], fill=SOFT)
    for x in range(x0 + 8, x1 - 4, 14):  # pepper plants behind the glass
        d.line([(x, GROUND), (x, GROUND - 12)], fill=(60, 110, 50, 255))
        d.ellipse([x - 2, GROUND - 10, x + 2, GROUND - 4], fill=(200, 52, 52, 255))
    d.rectangle([x0, 70, x1, GROUND], outline=INK, width=2)
    pine(d, 220, GROUND, 40)
    pine(d, 22, GROUND, 34)
    ground(d); return img


# --- Dungeons ------------------------------------------------------------------------

def calder_keep():
    img, d = base(); rnd = random.Random(51)
    hills(d, rnd, 72, 6, FAINT)
    # The ruined keep: a broken curtain wall, a tall tower with a collapsed top, a dark gate.
    d.rectangle([60, 56, 190, GROUND], fill=SOFT)
    for x in range(60, 190, 12):
        if rnd.random() < 0.75:
            d.rectangle([x, 50, x + 7, 56], fill=SOFT)
    d.polygon([(150, 56), (162, 40), (175, 52), (190, 46), (190, 56)], fill=FAINT)
    d.rectangle([92, 18, 128, GROUND], fill=INK)
    d.polygon([(92, 18), (98, 10), (106, 16), (114, 6), (122, 14), (128, 12), (128, 18)], fill=INK)
    for y in (30, 52):
        d.rectangle([106, y, 112, y + 8], fill=GOLD)
    d.pieslice([98, 76, 122, 100], 180, 360, fill=(20, 12, 10, 255))
    d.rectangle([98, 88, 122, GROUND], fill=(20, 12, 10, 255))
    for x, y in [(70, 70), (170, 64), (140, 80)]:
        d.line([(x, y), (x + 6, y + 10)], fill=INK)
    for x in (40, 214):
        dead_tree(d, x, GROUND, 40)
    for x, y in [(30, GROUND), (196, GROUND), (226, GROUND)]:
        rock(d, x, y, 9, 7)
    ground(d); return img


DUNGEONS = {"dungeon_calder_keep": calder_keep}

SITES = {
    "mossward_meadows": mossward_meadows, "fenmire": fenmire, "sunreach": sunreach, "frostvale": frostvale,
    "millbrook_pond": millbrook_pond, "silverrun": silverrun, "glasswater": glasswater,
    "greywater_coast": greywater_coast, "drowned_deep": drowned_deep,
    "hollow_fields": hollow_fields, "greyfang_hills": greyfang_hills, "elkmoor": elkmoor, "bleakridge": bleakridge,
    "home_fields": home_fields, "tilled_acres": tilled_acres, "beehives": beehives, "glasshouse": glasshouse,
}

if __name__ == "__main__":
    import sys
    for key, fn in SITES.items():
        fn().save("assets/ui/art/site_%s.png" % key)
    for name, fn in DUNGEONS.items():
        fn().save("assets/ui/art/%s.png" % name)
    if len(sys.argv) > 1:
        sheet = Image.new("RGBA", (3 * 256, ((len(SITES) + 2) // 3) * 136), (232, 220, 196, 255))
        for i, key in enumerate(SITES):
            sheet.alpha_composite(Image.open("assets/ui/art/site_%s.png" % key), ((i % 3) * 256 + 5, (i // 3) * 136 + 5))
        sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(sys.argv[1])
    print("painted %d site banners" % len(SITES))
