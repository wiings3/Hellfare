"""Paint the Hellfare site and crypt banners (246x126, opaque pixel art).

Hell is ash greys, ember reds and black, lit by one warm source; each layer of hell has its
own sky and ground colours (LAYERS). The farms stay above and keep their parchment ink art
(tools/paint_trade_sites.py). Run from the project root:

    python3 tools/paint_hell_sites.py            # writes the banners
    python3 tools/paint_hell_sites.py sheet.png  # and a contact sheet

The page shows a banner cropped to its middle (the frame is wider than 246:126), so keep
what matters between y=18 and y=108."""
import math
import random
from PIL import Image, ImageDraw

W, H = 246, 126


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


## Per layer: sky (top -> horizon), far / mid / near ground, ash, glow (the one warm light).
LAYERS = {
    1: dict(sky=["#1e100e", "#2c1612", "#3e1c14", "#562416", "#743018", "#94401c"], far="#4a2218", mid="#2e1610",
            near="#180c0a", ash="#bba898", glow="#f0882e", hot="#f6c25a"),
    2: dict(sky=["#160c10", "#200e14", "#2c1018", "#3c121c", "#521620", "#6a1c24"], far="#3a141a", mid="#240c12",
            near="#12080a", ash="#a88a8a", glow="#d0342e", hot="#f07a4a"),
    3: dict(sky=["#200c06", "#36140a", "#54200c", "#7a2e0e", "#a8420e", "#d05e14"], far="#5a2410", mid="#34140a",
            near="#1a0a06", ash="#d8b898", glow="#f6a02a", hot="#fbe07a"),
    4: dict(sky=["#0e1016", "#141822", "#1c2230", "#283040", "#384254", "#4c586c"], far="#2e3646", mid="#1c2230",
            near="#0e1118", ash="#c8d0dc", glow="#9fb4d0", hot="#e4ecf6"),
    5: dict(sky=["#040408", "#08080e", "#0e0c16", "#16101e", "#1e1428", "#2a1834"], far="#1a1222", mid="#100c16",
            near="#06050a", ash="#8a7aa0", glow="#9a6ad8", hot="#d6c2f6"),
}


class Canvas:
    def __init__(self, layer, seed):
        self.p = {k: (rgb(v) if isinstance(v, str) else [rgb(c) for c in v]) for k, v in LAYERS[layer].items()}
        self.img = Image.new("RGBA", (W, H), self.p["near"])
        self.d = ImageDraw.Draw(self.img)
        self.rnd = random.Random(seed)

    # --- sky and light ---------------------------------------------------------------
    def sky(self, horizon=84):
        """Banded sky from the top down to the horizon, with a 2x2 dither between bands."""
        bands = self.p["sky"]
        n = len(bands)
        for y in range(horizon):
            f = y / max(1, horizon - 1) * (n - 1)
            i = int(f)
            frac = f - i
            for x in range(W):
                pick = i + (1 if frac > [0.2, 0.6, 0.8, 0.4][(x % 2) + 2 * (y % 2)] else 0)
                self.img.putpixel((x, y), bands[min(n - 1, pick)])
        self.d.rectangle([0, horizon, W, H], fill=bands[-1])

    def glow(self, cx, cy, r, colour=None, steps=7, strength=90):
        """A stepped round glow: rings of the light colour at rising opacity (pixel-art friendly)."""
        colour = colour or self.p["glow"]
        over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        od = ImageDraw.Draw(over)
        for k in range(steps):
            rr = r * (1 - k / steps)
            a = int(strength * (k + 1) / steps / steps * 1.6)
            od.ellipse([cx - rr, cy - rr * 0.7, cx + rr, cy + rr * 0.7], fill=colour[:3] + (min(255, a),))
        self.img.alpha_composite(over)

    def ash(self, n=60, colour=None, y0=0, y1=H):
        colour = colour or self.p["ash"]
        for _ in range(n):
            x, y = self.rnd.randrange(W), self.rnd.randrange(y0, y1)
            self.d.point((x, y), fill=colour)
            if self.rnd.random() < 0.25:
                self.d.point((x + 1, y + 1), fill=colour)

    def embers(self, n=18, y0=20, y1=100):
        for _ in range(n):
            x, y = self.rnd.randrange(W), self.rnd.randrange(y0, y1)
            self.d.point((x, y), fill=self.p["hot"] if self.rnd.random() < 0.4 else self.p["glow"])

    # --- ground -----------------------------------------------------------------------
    def ridge(self, top, spread, fill, step=18, bottom=H):
        pts = [(0, bottom)]
        ys = [top + self.rnd.randint(-spread, spread) for _ in range(W // step + 3)]
        for i in range(len(ys) - 1):
            for t in range(step):
                k = t / step
                y = ys[i] + (ys[i + 1] - ys[i]) * (1 - math.cos(k * math.pi)) / 2
                pts.append((i * step + t, int(y)))
        pts.append((W, bottom))
        self.d.polygon(pts, fill=fill)

    def jagged(self, top, spread, fill, step=10, bottom=H):
        pts = [(0, bottom)] + [(x, top + self.rnd.randint(-spread, spread)) for x in range(0, W + step, step)] + [(W, bottom)]
        self.d.polygon(pts, fill=fill)

    def flat(self, y, fill):
        self.d.rectangle([0, y, W, H], fill=fill)

    # --- things -----------------------------------------------------------------------
    def dead_tree(self, x, base, h, fill, ember=None, lean=0):
        d = self.d
        w = max(2, h // 14)
        d.polygon([(x - w, base), (x + lean - 1, base - h), (x + lean + 1, base - h), (x + w, base)], fill=fill)
        rnd = self.rnd
        for i in range(3 + h // 14):
            y = base - h * (0.35 + 0.6 * rnd.random())
            sx = x + lean * (base - y) / h
            side = -1 if i % 2 else 1
            length = h * (0.18 + 0.2 * rnd.random())
            ex, ey = sx + side * length, y - length * (0.5 + 0.5 * rnd.random())
            d.line([(sx, y), (ex, ey)], fill=fill, width=1 if h < 40 else 2)
            if rnd.random() < 0.6:
                d.line([(ex, ey), (ex + side * length * 0.4, ey - length * 0.5)], fill=fill, width=1)
        if ember:
            for k in range(2 + h // 20):
                yy = int(base - h * (0.15 + 0.6 * rnd.random()))
                d.rectangle([x - 1 + int(lean * (base - yy) / h), yy, x + int(lean * (base - yy) / h), yy + 2 + rnd.randint(0, 3)], fill=ember)

    def weeping_tree(self, x, base, h, fill, sap):
        d = self.d
        d.polygon([(x - 3, base), (x - 1, base - h * 0.55), (x + 1, base - h * 0.55), (x + 3, base)], fill=fill)
        cx, cy = x, base - h * 0.62
        for k in range(9):
            a = math.pi * (0.1 + 0.8 * k / 8)
            ex, ey = cx + math.cos(a) * h * 0.5, cy - math.sin(a) * h * 0.38
            d.line([(cx, cy), (ex, ey)], fill=fill, width=2)
            # hanging fronds
            for j in range(3):
                fx = ex + (j - 1) * 3
                d.line([(fx, ey), (fx + self.rnd.randint(-1, 1), ey + h * (0.2 + 0.25 * self.rnd.random()))], fill=fill)
            if self.rnd.random() < 0.5:
                d.rectangle([ex, ey + 4, ex, ey + 4 + self.rnd.randint(2, 7)], fill=sap)
        for k in range(3):
            yy = int(base - h * 0.5 * self.rnd.random())
            d.rectangle([x, yy, x, yy + self.rnd.randint(3, 8)], fill=sap)

    def eyes(self, x, y, colour=None):
        c = colour or self.p["hot"]
        self.d.point((x, y), fill=c)
        self.d.point((x + 3, y), fill=c)

    def hound(self, x, y, fill, right=True, eye=None):
        """A lean hound in profile, about 22 px long, standing at ground y."""
        s = 1 if right else -1
        d = self.d
        body = [(x, y - 8), (x + s * 14, y - 9), (x + s * 17, y - 12), (x + s * 21, y - 11), (x + s * 22, y - 8),
                (x + s * 18, y - 7), (x + s * 16, y - 5), (x + s * 3, y - 5), (x - s * 4, y - 9)]
        d.polygon(body, fill=fill)
        for lx in (2, 5, 13, 16):
            d.line([(x + s * lx, y - 5), (x + s * (lx + (1 if lx < 10 else -1)), y)], fill=fill, width=1)
        d.polygon([(x + s * 17, y - 12), (x + s * 18, y - 15), (x + s * 19, y - 12)], fill=fill)
        d.point((x + s * 19, y - 10), fill=eye or self.p["hot"])

    def horned_beast(self, x, y, fill, eye=None):
        d = self.d
        d.polygon([(x, y - 14), (x + 30, y - 16), (x + 36, y - 22), (x + 42, y - 18), (x + 40, y - 12), (x + 34, y - 10),
                   (x + 30, y - 6), (x + 4, y - 6), (x - 4, y - 12)], fill=fill)
        for lx in (4, 9, 24, 29):
            d.line([(x + lx, y - 6), (x + lx, y)], fill=fill, width=2)
        d.line([(x + 37, y - 21), (x + 34, y - 30), (x + 30, y - 33)], fill=fill, width=2)
        d.line([(x + 40, y - 20), (x + 44, y - 29), (x + 49, y - 31)], fill=fill, width=2)
        d.point((x + 39, y - 17), fill=eye or self.p["hot"])

    def bear(self, x, y, fill, eye=None):
        d = self.d
        d.polygon([(x, y), (x, y - 14), (x + 8, y - 24), (x + 30, y - 26), (x + 40, y - 20), (x + 48, y - 21), (x + 52, y - 16),
                   (x + 48, y - 12), (x + 42, y - 10), (x + 40, y), (x + 33, y), (x + 32, y - 8), (x + 14, y - 8), (x + 12, y)], fill=fill)
        d.point((x + 47, y - 18), fill=eye or self.p["hot"])

    def crow(self, x, y, fill):
        self.d.line([(x - 3, y - 1), (x, y + 1), (x + 3, y - 1)], fill=fill)

    def water(self, top, fill, line, step=5):
        self.d.rectangle([0, top, W, H], fill=fill)
        for y in range(top + 2, H, step):
            for x in range(self.rnd.randrange(8), W, self.rnd.randint(14, 30)):
                self.d.line([(x, y), (x + self.rnd.randint(4, 12), y)], fill=line)

    def reeds(self, x0, x1, base, fill, n=14):
        for _ in range(n):
            x = self.rnd.randint(x0, x1)
            h = self.rnd.randint(8, 18)
            self.d.line([(x, base), (x + self.rnd.randint(-2, 2), base - h)], fill=fill)

    def rock(self, x, y, w, h, fill, light=None):
        self.d.polygon([(x, y), (x + w * 0.2, y - h), (x + w * 0.7, y - h * 1.1), (x + w, y)], fill=fill)
        if light:
            self.d.line([(x + w * 0.2, y - h), (x + w * 0.7, y - h * 1.1)], fill=light)

    def done(self):
        return self.img


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


# =============================================================== layer 1: the Ashen Verge
def cinderwood():
    c = Canvas(1, 11)
    c.sky(86)
    c.glow(130, 92, 120, strength=70)
    c.ridge(70, 6, c.p["far"])
    for x in range(-4, W, 13):
        c.dead_tree(x + c.rnd.randint(0, 5), 92, c.rnd.randint(26, 40), c.p["mid"])
    c.flat(98, c.p["near"])
    for x, h in [(22, 74), (64, 62), (188, 80), (226, 58)]:
        c.dead_tree(x, 104, h, c.p["near"], ember=c.p["glow"], lean=c.rnd.randint(-3, 3))
    # a felled trunk and a stump, still glowing at the cut
    c.d.rectangle([96, 96, 150, 101], fill=c.p["near"])
    c.d.ellipse([146, 95, 153, 102], fill=c.p["glow"])
    c.d.point((149, 98), fill=c.p["hot"])
    c.d.rectangle([118, 88, 126, 98], fill=c.p["near"])
    c.d.line([(118, 88), (126, 88)], fill=c.p["glow"])
    c.d.line([(121, 76), (125, 89)], fill=c.p["near"], width=1)  # axe in the stump
    c.d.polygon([(118, 76), (123, 74), (123, 80)], fill=c.p["near"])
    c.ash(90)
    c.embers(16)
    return c.done()


def gatepit():
    c = Canvas(1, 12)
    c.sky(80)
    c.ridge(52, 8, c.p["far"], step=22)
    c.jagged(66, 6, c.p["mid"], step=12)
    # a rock face with a timbered adit, lit from inside
    c.d.polygon([(70, H), (78, 40), (110, 30), (150, 34), (182, 46), (190, H)], fill=c.p["near"])
    c.glow(130, 84, 34, strength=150)
    c.d.rectangle([116, 66, 144, 104], fill=rgb("#2a0e08"))
    c.d.rectangle([118, 70, 142, 104], fill=c.p["glow"])
    c.d.rectangle([122, 76, 138, 104], fill=c.p["hot"])
    c.d.rectangle([112, 62, 148, 66], fill=c.p["near"])
    c.d.rectangle([112, 62, 116, 104], fill=c.p["near"])
    c.d.rectangle([144, 62, 148, 104], fill=c.p["near"])
    # rails and a cart
    c.d.line([(130, 104), (60, 120)], fill=c.p["mid"])
    c.d.line([(138, 104), (80, 124)], fill=c.p["mid"])
    c.d.polygon([(70, 106), (94, 106), (91, 116), (73, 116)], fill=rgb("#120806"))
    c.d.rectangle([74, 103, 90, 106], fill=rgb("#a25a2a"))  # copper in the cart
    for x in (76, 88):
        c.d.ellipse([x - 2, 115, x + 2, 119], fill=c.p["mid"])
    c.flat(118, c.p["near"])
    c.ash(70)
    return c.done()


def ashmeadow():
    c = Canvas(1, 13)
    c.sky(78)
    c.glow(40, 82, 70, strength=60)
    c.ridge(66, 4, c.p["far"], step=30)
    c.ridge(78, 3, rgb("#3a2a26"), step=26)
    grass = [rgb("#5a4a44"), rgb("#7a6a62"), rgb("#4a3a34")]
    c.flat(88, rgb("#2e221e"))
    for _ in range(420):
        x, y = c.rnd.randrange(W), c.rnd.randint(84, H)
        h = 2 + (y - 80) // 9
        c.d.line([(x, y), (x + c.rnd.randint(-1, 1), y - h)], fill=c.rnd.choice(grass))
    for _ in range(40):  # ashleaf, pale and grey
        x, y = c.rnd.randrange(W), c.rnd.randint(90, H - 4)
        c.d.point((x, y), fill=rgb("#cfc2b6"))
        c.d.point((x + 1, y), fill=rgb("#9a8c82"))
    for _ in range(22):  # cinderberries
        x, y = c.rnd.randrange(W), c.rnd.randint(94, H - 4)
        c.d.rectangle([x, y, x + 1, y + 1], fill=c.p["glow"])
    c.ash(110)
    return c.done()


def cinder_pool():
    c = Canvas(1, 14)
    c.sky(74)
    c.glow(170, 74, 80, strength=70)
    c.ridge(62, 6, c.p["far"])
    c.ridge(72, 4, c.p["mid"], step=14)
    c.water(80, rgb("#2a2220"), rgb("#4a3a34"))
    for y in range(82, 100, 3):  # the glow on the water
        c.d.line([(150 + c.rnd.randint(-8, 8), y), (190 + c.rnd.randint(-8, 8), y)], fill=c.p["glow"])
    # a small jetty and a fisher's rod
    c.d.rectangle([20, 96, 86, 99], fill=c.p["near"])
    for x in (24, 46, 68, 84):
        c.d.rectangle([x, 99, x + 1, 112], fill=c.p["near"])
    c.d.rectangle([70, 86, 74, 96], fill=c.p["near"])
    c.d.line([(74, 88), (110, 70)], fill=c.p["near"])
    c.d.line([(110, 70), (112, 92)], fill=rgb("#6a5048"))
    c.rock(200, 112, 40, 14, c.p["near"])
    c.rock(0, 116, 26, 10, c.p["near"])
    c.ash(70)
    return c.done()


def hollow_fields():
    c = Canvas(1, 15)
    c.sky(80)
    c.glow(200, 84, 60, strength=60)
    c.ridge(74, 3, c.p["far"], step=34)
    c.flat(84, rgb("#2c201c"))
    for y in range(86, H, 4):  # furrows of thin grey grass
        for x in range(0, W, 3):
            if c.rnd.random() < 0.6:
                c.d.line([(x, y), (x, y - 1 - (y - 84) // 14)], fill=rgb("#4e403a") if c.rnd.random() < 0.6 else rgb("#6a5a52"))
    # a bone scarecrow
    x0 = 70
    c.d.rectangle([x0, 54, x0 + 2, 104], fill=c.p["near"])
    c.d.rectangle([x0 - 14, 62, x0 + 16, 64], fill=c.p["near"])
    c.d.ellipse([x0 - 4, 46, x0 + 6, 56], fill=rgb("#bba898"))
    c.d.point((x0 - 1, 50), fill=c.p["near"])
    c.d.point((x0 + 3, 50), fill=c.p["near"])
    c.d.polygon([(x0 - 10, 64), (x0 + 12, 64), (x0 + 8, 82), (x0 - 6, 82)], fill=rgb("#2a1612"))
    for _ in range(9):
        c.crow(c.rnd.randint(110, 236), c.rnd.randint(24, 60), c.p["near"])
    c.crow(x0 + 15, 61, c.p["near"])
    # an ashhare
    c.d.ellipse([170, 100, 180, 106], fill=c.p["near"])
    c.d.line([(178, 100), (179, 95)], fill=c.p["near"])
    c.d.line([(180, 100), (182, 95)], fill=c.p["near"])
    c.ash(60)
    return c.done()


def fallen_keep():
    c = Canvas(1, 16)
    c.sky(90)
    c.glow(123, 70, 110, strength=80)
    c.ridge(84, 5, c.p["far"])
    # the crag and the keep that fell with it
    c.d.polygon([(60, H), (78, 92), (96, 86), (150, 84), (172, 92), (190, H)], fill=c.p["mid"])
    k = c.p["near"]
    c.d.rectangle([94, 46, 152, 90], fill=k)              # curtain wall
    c.d.rectangle([108, 22, 132, 90], fill=k)             # the tower
    for x in range(108, 133, 6):
        c.d.rectangle([x, 18, x + 3, 22], fill=k)
    for x in range(94, 153, 6):
        c.d.rectangle([x, 42, x + 3, 46], fill=k)
    c.d.polygon([(152, 46), (160, 52), (156, 90), (152, 90)], fill=k)  # broken corner
    c.d.polygon([(132, 22), (138, 30), (132, 34)], fill=c.p["mid"])     # a bite out of the tower
    for x, y in [(116, 32), (122, 46), (102, 60), (140, 58), (116, 64)]:
        c.d.rectangle([x, y, x + 2, y + 4], fill=c.p["glow"])
    c.d.rectangle([119, 76, 125, 90], fill=c.p["glow"])  # the door, lit
    c.d.rectangle([120, 80, 124, 90], fill=c.p["hot"])
    for x in (30, 214):
        c.dead_tree(x, 112, 46, c.p["near"])
    c.flat(110, c.p["near"])
    c.ash(90)
    c.embers(10, 30, 90)
    return c.done()


# =============================================================== layer 2: the Weeping Fens
def weepingwood():
    c = Canvas(2, 21)
    c.sky(84)
    c.glow(120, 90, 110, strength=60)
    c.ridge(80, 4, c.p["far"], step=30)
    for x in range(4, W, 34):
        c.weeping_tree(x + c.rnd.randint(0, 10), 94, c.rnd.randint(30, 42), c.p["mid"], c.p["far"])
    c.flat(96, c.p["near"])
    for x, h in [(30, 84), (206, 92)]:
        c.weeping_tree(x, 112, h, c.p["near"], c.p["glow"])
    for x, y in [(92, 90), (150, 86), (176, 92), (120, 94)]:  # hounds watching from the dark
        c.eyes(x, y)
    c.hound(96, 110, c.p["near"])
    c.ash(40)
    return c.done()


def sulphur_deeps():
    c = Canvas(2, 22)
    yellow = [rgb("#1a1406"), rgb("#3a2c0a"), rgb("#6a5010"), rgb("#a88a1a"), rgb("#d8c04a"), rgb("#f2e48a")]
    c.img.paste(rgb("#120c06"), (0, 0, W, H))
    # galleries going back, each lit a little less
    for i, (w, h, col) in enumerate([(200, 96, yellow[1]), (150, 74, yellow[2]), (100, 54, yellow[3]), (60, 36, yellow[4])]):
        x0, y0 = (W - w) // 2, 104 - h
        c.d.rectangle([x0, y0 + 10, x0 + w, 104], fill=col)
        c.d.ellipse([x0, y0, x0 + w, y0 + 20], fill=col)
        c.d.rectangle([x0 - 4, y0 + 8, x0 + 2, 104], fill=rgb("#2a1c0a"))     # timber props
        c.d.rectangle([x0 + w - 2, y0 + 8, x0 + w + 4, 104], fill=rgb("#2a1c0a"))
        c.d.rectangle([x0 - 4, y0 + 6, x0 + w + 4, y0 + 10], fill=rgb("#2a1c0a"))
    c.d.rectangle([108, 60, 138, 104], fill=yellow[5])
    c.d.polygon([(0, 0), (W, 0), (W, 18), (200, 10), (150, 16), (100, 8), (40, 18), (0, 10)], fill=rgb("#0a0604"))
    c.d.polygon([(0, H), (0, 104), (W, 104), (W, H)], fill=rgb("#1a1206"))
    for _ in range(26):  # sulphur crystals
        x, y = c.rnd.randrange(W), c.rnd.randint(104, H - 3)
        c.d.polygon([(x, y + 3), (x + 1, y - 2), (x + 3, y + 3)], fill=yellow[4])
    # a crawler on the wall
    cx, cy = 52, 46
    c.d.ellipse([cx, cy, cx + 10, cy + 6], fill=rgb("#0a0604"))
    for k in range(4):
        c.d.line([(cx + 2 + k * 2, cy + 5), (cx - 2 + k * 4, cy + 10)], fill=rgb("#0a0604"))
        c.d.line([(cx + 2 + k * 2, cy + 1), (cx - 2 + k * 4, cy - 4)], fill=rgb("#0a0604"))
    c.eyes(cx + 8, cy + 2, rgb("#d0342e"))
    for _ in range(30):
        c.d.point((c.rnd.randrange(W), c.rnd.randrange(20, 100)), fill=yellow[4])
    return c.done()


def bloodfen():
    c = Canvas(2, 23)
    c.sky(76)
    c.glow(180, 78, 80, strength=60)
    c.ridge(66, 4, c.p["far"], step=24)
    for x in range(10, W, 40):
        c.dead_tree(x + c.rnd.randint(0, 16), 80, c.rnd.randint(18, 30), c.p["mid"])
    c.water(80, rgb("#3a0c12"), rgb("#6a1a22"), step=6)
    for _ in range(7):  # hummocks with reeds
        x, y = c.rnd.randint(0, W - 30), c.rnd.randint(88, 116)
        c.d.ellipse([x, y, x + c.rnd.randint(20, 40), y + 8], fill=c.p["near"])
        c.reeds(x + 2, x + 20, y + 2, c.p["near"], n=6)
    for _ in range(14):  # gravecaps, pale on the hummocks
        x, y = c.rnd.randrange(W), c.rnd.randint(88, H - 6)
        c.d.rectangle([x, y + 1, x, y + 3], fill=rgb("#a89888"))
        c.d.line([(x - 1, y), (x + 1, y)], fill=rgb("#d8c8b8"))
    c.d.line([(60, 106), (72, 104), (80, 107), (92, 105)], fill=rgb("#120608"), width=2)  # a bog adder
    c.ash(40)
    return c.done()


def styx_shallows():
    c = Canvas(2, 24)
    c.sky(70)
    c.glow(60, 74, 70, strength=70)
    c.ridge(58, 6, c.p["far"])
    c.ridge(68, 4, c.p["mid"], step=16)
    # the river: black, fast, with pale things turning in it
    c.water(74, rgb("#0c0608"), rgb("#2c1016"), step=4)
    for y in range(76, H, 3):
        x = c.rnd.randrange(W)
        c.d.line([(x, y), (x + 20, y)], fill=rgb("#4a1a20"))
    for _ in range(12):
        x, y = c.rnd.randrange(W), c.rnd.randint(84, H - 4)
        c.d.line([(x, y), (x + c.rnd.randint(4, 8), y + c.rnd.choice([-1, 0, 1]))], fill=rgb("#c8b8a8"))  # bones and eels
    # the near bank with a wading angler
    c.d.polygon([(0, H), (0, 100), (40, 104), (70, 114), (90, H)], fill=c.p["near"])
    c.d.rectangle([48, 90, 52, 108], fill=c.p["near"])
    c.d.ellipse([47, 85, 53, 91], fill=c.p["near"])
    c.d.line([(52, 94), (100, 72)], fill=c.p["near"])
    c.d.line([(100, 72), (104, 96)], fill=rgb("#6a3a3a"))
    c.ash(40)
    return c.done()


def houndfang_hills():
    c = Canvas(2, 25)
    c.sky(70)
    c.glow(150, 66, 90, strength=70)
    c.ridge(52, 10, c.p["far"], step=26)
    c.ridge(70, 8, rgb("#4a1418"), step=20)
    # the pack on the near ridge, against the light
    c.d.polygon([(0, H), (0, 96), (40, 84), (90, 78), (150, 78), (200, 86), (W, 92), (W, H)], fill=c.p["near"])
    for x, r in [(62, True), (92, True), (122, False), (150, True)]:
        c.hound(x, 79 + (2 if x < 70 else 0), c.p["near"], right=r)
    # a hellboar below
    c.d.ellipse([196, 106, 222, 118], fill=rgb("#1a080a"))
    c.d.polygon([(220, 108), (230, 112), (222, 116)], fill=rgb("#1a080a"))
    c.d.line([(226, 112), (232, 108)], fill=rgb("#d8c8b8"))
    c.ash(40)
    return c.done()


def drowned_abbey():
    c = Canvas(2, 26)
    c.sky(78)
    c.glow(123, 60, 100, strength=60)
    k = c.p["near"]
    # bell tower and nave, half under black water
    c.d.rectangle([104, 18, 130, 86], fill=k)
    c.d.polygon([(100, 20), (117, 2), (134, 20)], fill=k)
    c.d.rectangle([112, 26, 122, 40], fill=c.p["glow"])
    c.d.ellipse([113, 28, 121, 38], fill=rgb("#2a0c10"))   # the bell
    c.d.rectangle([116, 36, 118, 39], fill=c.p["hot"])
    c.d.polygon([(130, 86), (130, 48), (190, 48), (200, 60), (200, 86)], fill=k)
    c.d.polygon([(40, 86), (50, 58), (104, 58), (104, 86)], fill=k)
    for x in range(140, 196, 12):
        c.d.rectangle([x, 58, x + 4, 72], fill=c.p["glow"])
    for x in range(56, 100, 12):
        c.d.rectangle([x, 66, x + 3, 78], fill=c.p["mid"])
    c.water(84, rgb("#0e0608"), rgb("#2a0e14"), step=4)
    for y in range(86, 110, 3):  # reflections of the windows
        for x in range(140, 196, 12):
            c.d.line([(x + c.rnd.randint(-1, 1), y), (x + 4 + c.rnd.randint(-1, 1), y)], fill=c.p["glow"])
    for _ in range(5):  # the drowned, just under the surface
        x, y = c.rnd.randint(10, 230), c.rnd.randint(98, 118)
        c.d.ellipse([x, y, x + 4, y + 3], fill=rgb("#5a4a50"))
    c.ash(40)
    return c.done()


# =============================================================== layer 3: the Brimstone Reach
def ember_slopes():
    c = Canvas(3, 31)
    c.sky(64)
    c.glow(170, 60, 90, strength=90)
    c.d.polygon([(0, 70), (60, 40), (120, 56), (190, 30), (W, 50), (W, H), (0, H)], fill=c.p["far"])
    c.d.polygon([(0, 92), (50, 70), (110, 82), (170, 62), (W, 80), (W, H), (0, H)], fill=c.p["mid"])
    for x0, y0 in [(66, 74), (178, 66)]:  # lava running down
        x, y = x0, y0
        while y < H:
            nx, ny = x + c.rnd.randint(-4, 4), y + 6
            c.d.line([(x, y), (nx, ny)], fill=c.p["glow"], width=2)
            c.d.line([(x, y), (nx, ny)], fill=c.p["hot"])
            x, y = nx, ny
    for vx in (30, 130, 214):  # vents
        c.d.polygon([(vx - 7, 101), (vx - 2, 93), (vx + 2, 93), (vx + 7, 101)], fill=c.p["near"])
        c.d.polygon([(vx - 3, 93), (vx - 1, 82), (vx, 87), (vx + 2, 78), (vx + 3, 93)], fill=c.p["glow"])
        c.d.polygon([(vx - 1, 93), (vx + 1, 85), (vx + 2, 93)], fill=c.p["hot"])
    c.d.polygon([(0, H), (0, 104), (80, 100), (160, 108), (W, 102), (W, H)], fill=c.p["near"])
    for _ in range(20):  # nightshade and emberbloom
        x, y = c.rnd.randrange(W), c.rnd.randint(106, H - 3)
        c.d.point((x, y), fill=c.p["hot"] if c.rnd.random() < 0.5 else rgb("#7a3aa0"))
        c.d.point((x, y + 1), fill=rgb("#2a3a14"))
    c.embers(30, 10, 100)
    return c.done()


def lake_of_glass():
    c = Canvas(3, 32)
    c.sky(60)
    c.glow(123, 58, 100, strength=80)
    c.ridge(48, 6, c.p["far"], step=22)
    c.ridge(58, 3, c.p["mid"], step=18)
    # the lake: a perfect mirror of the sky
    sky = c.p["sky"]
    for y in range(62, 108):
        t = (y - 62) / 46
        band = sky[max(0, min(len(sky) - 1, int((1 - t) * (len(sky) - 1))))]
        c.d.line([(0, y), (W, y)], fill=band)
    c.d.line([(0, 62), (W, 62)], fill=c.p["hot"])
    for _ in range(6):
        x, y = c.rnd.randrange(W), c.rnd.randint(66, 104)
        c.d.line([(x, y), (x + 14, y)], fill=c.p["glow"])
    # glass shore
    c.d.polygon([(0, H), (0, 106), (W, 110), (W, H)], fill=c.p["near"])
    for _ in range(26):
        x, y = c.rnd.randrange(W), c.rnd.randint(108, H - 2)
        c.d.polygon([(x, y + 3), (x + 2, y - 3), (x + 4, y + 3)], fill=rgb("#c89a6a") if c.rnd.random() < 0.5 else rgb("#f6d8a0"))
    # a great pike breaking the glass
    c.d.polygon([(150, 78), (170, 72), (184, 76), (172, 80)], fill=c.p["near"])
    c.d.polygon([(150, 78), (144, 72), (146, 80)], fill=c.p["near"])
    c.d.ellipse([162, 80, 186, 84], outline=c.p["hot"])
    c.embers(14, 10, 60)
    return c.done()


def gorehorn_moor():
    c = Canvas(3, 33)
    c.sky(72)
    c.glow(60, 70, 90, strength=80)
    c.ridge(62, 5, c.p["far"], step=30)
    c.flat(78, c.p["mid"])
    for x in range(0, W, 7):  # the moor burns in low lines
        if c.rnd.random() < 0.5:
            y = c.rnd.randint(78, 92)
            c.d.line([(x, y), (x + c.rnd.randint(3, 10), y)], fill=c.p["glow"])
    c.d.polygon([(0, H), (0, 98), (W, 94), (W, H)], fill=c.p["near"])
    for x in range(0, W, 3):
        c.d.line([(x, 96 + c.rnd.randint(-2, 2)), (x, 92 + c.rnd.randint(-3, 1))], fill=c.p["near"])
    c.d.polygon([(70, 98), (100, 74), (150, 72), (180, 96)], fill=c.p["near"])
    c.horned_beast(104, 74, c.p["near"])
    c.horned_beast(186, 80, c.p["mid"])
    c.embers(30, 20, 100)
    c.ash(30)
    return c.done()


# =============================================================== layer 4: the Frozen Lament
def ice_spikes(c, top, fill, light, count=14):
    for _ in range(count):
        x = c.rnd.randrange(-10, W)
        h = c.rnd.randint(10, 30)
        w = c.rnd.randint(4, 9)
        c.d.polygon([(x, top + 8), (x + w // 2, top + 8 - h), (x + w, top + 8)], fill=fill)
        c.d.line([(x + w // 2, top + 8 - h), (x + w // 2, top + 8)], fill=light)


def laments_edge():
    c = Canvas(4, 41)
    c.sky(70)
    c.glow(123, 66, 90, strength=50)
    c.ridge(56, 8, c.p["far"], step=24)
    ice_spikes(c, 64, c.p["mid"], c.p["far"], 18)
    c.flat(76, rgb("#3a4456"))
    for y in range(78, H, 4):
        c.d.line([(c.rnd.randrange(W), y), (c.rnd.randrange(W), y + 1)], fill=rgb("#4c586c"))
    # faces held in the ice
    for x, y in [(40, 92), (120, 100), (196, 90)]:
        c.d.ellipse([x, y, x + 10, y + 13], fill=rgb("#5a6478"))
        c.d.point((x + 3, y + 4), fill=c.p["near"])
        c.d.point((x + 6, y + 4), fill=c.p["near"])
        c.d.ellipse([x + 3, y + 8, x + 6, y + 11], fill=c.p["near"])
    for _ in range(12):  # lament lilies
        x, y = c.rnd.randrange(W), c.rnd.randint(84, H - 4)
        c.d.line([(x, y), (x, y + 4)], fill=rgb("#6a7a8a"))
        c.d.polygon([(x - 2, y), (x, y - 3), (x + 2, y)], fill=c.p["hot"])
    c.hound(200, 82, c.p["near"], right=False, eye=rgb("#d0342e"))
    c.ash(90, colour=c.p["hot"])
    return c.done()


def shore_of_tears():
    c = Canvas(4, 42)
    c.sky(64)
    c.glow(190, 60, 70, strength=50)
    c.water(64, rgb("#1c2230"), rgb("#384254"), step=4)
    for y in range(70, 96, 7):  # waves rolling in
        pts = [(x, y + int(2 * math.sin(x / 9 + y))) for x in range(0, W + 6, 6)]
        c.d.line(pts, fill=rgb("#7a8698"))
    c.d.polygon([(0, H), (0, 96), (70, 92), (150, 100), (W, 94), (W, H)], fill=rgb("#262c38"))
    for x, y, w, h in [(10, 104, 40, 18), (150, 108, 30, 12), (200, 100, 46, 24)]:
        c.rock(x, y, w, h, c.p["near"], light=rgb("#5a6478"))
    # a crab and an upturned boat
    c.d.ellipse([110, 110, 118, 115], fill=rgb("#7a2a24"))
    c.d.line([(108, 110), (110, 112)], fill=rgb("#7a2a24"))
    c.d.line([(120, 110), (118, 112)], fill=rgb("#7a2a24"))
    c.d.chord([60, 98, 100, 112], 180, 360, fill=c.p["near"])
    for _ in range(80):  # the rain that never stops
        x, y = c.rnd.randrange(W), c.rnd.randrange(0, 100)
        c.d.line([(x, y), (x - 1, y + 3)], fill=rgb("#6a7688"))
    return c.done()


def bleakridge():
    c = Canvas(4, 43)
    c.sky(80)
    c.glow(80, 70, 80, strength=50)
    c.d.polygon([(0, 80), (40, 50), (70, 60), (120, 26), (160, 48), (200, 38), (W, 60), (W, H), (0, H)], fill=c.p["far"])
    c.d.polygon([(120, 26), (112, 40), (124, 36), (130, 44), (138, 38)], fill=rgb("#c8d0dc"))
    c.d.polygon([(0, 104), (60, 86), (130, 92), (200, 80), (W, 88), (W, H), (0, H)], fill=c.p["mid"])
    ice_spikes(c, 88, rgb("#2e3646"), rgb("#4c586c"), 8)
    c.d.polygon([(0, H), (0, 110), (W, 106), (W, H)], fill=c.p["near"])
    c.bear(150, 92, c.p["near"], eye=rgb("#d0342e"))
    for _ in range(70):  # wind-driven snow
        x, y = c.rnd.randrange(W), c.rnd.randrange(H)
        c.d.line([(x, y), (x + 3, y + 1)], fill=rgb("#aab4c4"))
    return c.done()


# =============================================================== layer 5: the Abyss
def drowned_deep():
    c = Canvas(5, 51)
    c.sky(56)
    c.water(56, rgb("#06060c"), rgb("#141224"), step=5)
    c.glow(150, 100, 60, strength=120)
    c.glow(150, 100, 14, colour=c.p["hot"], strength=200)
    # something vast under the boat
    for k in range(3):
        x0 = 110 + k * 26
        pts = [(x0 + int(8 * math.sin(t / 3 + k)), H - t * 3) for t in range(0, 22)]
        c.d.line(pts, fill=rgb("#1e1428"), width=3)
    # the boat, a lantern, a line
    c.d.polygon([(40, 52), (90, 52), (84, 60), (46, 60)], fill=rgb("#120e18"))
    c.d.rectangle([62, 38, 64, 52], fill=rgb("#120e18"))
    c.d.rectangle([60, 34, 66, 38], fill=c.p["hot"])
    c.glow(63, 36, 16, colour=rgb("#f0c060"), strength=120)
    c.d.line([(64, 40), (120, 30)], fill=rgb("#120e18"))
    c.d.line([(120, 30), (124, 90)], fill=rgb("#3a3050"))
    for _ in range(6):  # voidpearls
        x, y = c.rnd.randint(130, 180), c.rnd.randint(90, 118)
        c.d.point((x, y), fill=c.p["hot"])
    c.ash(30, y0=0, y1=56)
    return c.done()


SITES = {
    "forest_copse": cinderwood, "forest_oakwood": weepingwood, "harlow_site": gatepit, "mine_deepdelve": sulphur_deeps,
    "site_mossward_meadows": ashmeadow, "site_fenmire": bloodfen, "site_sunreach": ember_slopes, "site_frostvale": laments_edge,
    "site_millbrook_pond": cinder_pool, "site_silverrun": styx_shallows, "site_glasswater": lake_of_glass,
    "site_greywater_coast": shore_of_tears, "site_drowned_deep": drowned_deep, "site_hollow_fields": hollow_fields,
    "site_greyfang_hills": houndfang_hills, "site_elkmoor": gorehorn_moor, "site_bleakridge": bleakridge,
    "dungeon_calder_keep": fallen_keep, "dungeon_sunken_abbey": drowned_abbey,
}

if __name__ == "__main__":
    import sys
    for name, fn in SITES.items():
        fn().save("assets/ui/art/%s.png" % name)
    if len(sys.argv) > 1:
        cols = 4
        sheet = Image.new("RGBA", (cols * 252, ((len(SITES) + cols - 1) // cols) * 132), (232, 215, 184, 255))
        for i, name in enumerate(SITES):
            sheet.alpha_composite(Image.open("assets/ui/art/%s.png" % name), ((i % cols) * 252 + 3, (i // cols) * 132 + 3))
        sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(sys.argv[1])
    print("painted %d hell banners" % len(SITES))
