"""Paint the expedition banners (246x126 pixel art): every site and crypt in scripts/sites.gd and
scripts/dungeons.gd.

Each banner is built like a stage set, back to front: a sky with smoke, then silhouette layers
that fade into the haze with distance, each lit by the scene's lights (a rim of light on the
edges that face them, a wash of colour on what's near them). Glowing things (embers, windows,
lava) are painted last and light what's around them. The finished picture is reduced to a small
palette with an ordered dither, so it reads as pixel art at the size the book shows it.

    python3 tools/paint_sites.py                 # writes assets/ui/art/<banner>.png
    python3 tools/paint_sites.py sheet.png       # and a contact sheet
    python3 tools/paint_sites.py sheet.png cinderwood weepingwood   # only some

The page crops a banner to its middle, so what matters sits between y=18 and y=108."""
import math
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 246, 126
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], dtype=float) / 16.0 - 0.47


def rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def lerp(a, b, t):
    return a + (b - a) * t


class Scene:
    def __init__(self, seed, haze, ambient=0.22):
        self.rnd = random.Random(seed)
        self.np = np.random.default_rng(seed)
        self.img = np.zeros((H, W, 3))
        self.haze = rgb(haze) if isinstance(haze, str) else haze
        self.ambient = ambient
        self.lights = []          # (x, y, radius, colour, strength)
        self.yy, self.xx = np.mgrid[0:H, 0:W].astype(float)

    # --- noise ------------------------------------------------------------------------
    def noise(self, scale, octaves=4, w=W, h=H):
        """Fractal value noise in 0..1, features about `scale` px across."""
        out = np.zeros((h, w))
        amp, total = 1.0, 0.0
        for o in range(octaves):
            s = max(1.0, scale / (2 ** o))
            gw, gh = int(w / s) + 3, int(h / s) + 3
            grid = self.np.random((gh, gw))
            im = Image.fromarray((grid * 255).astype(np.uint8)).resize((int(gw * s), int(gh * s)), Image.BICUBIC)
            a = np.asarray(im, dtype=float)[:h, :w] / 255.0
            out += a * amp
            total += amp
            amp *= 0.5
        return out / total

    def noise1d(self, scale, octaves=4):
        return self.noise(scale, octaves, W, 1)[0]

    # --- light ------------------------------------------------------------------------
    def light(self, x, y, r, colour, strength=1.0):
        self.lights.append((x, y, r, rgb(colour) if isinstance(colour, str) else colour, strength))

    def lightmap(self):
        """Colour of the light falling on every pixel (sum of the lights)."""
        out = np.zeros((H, W, 3))
        for x, y, r, c, s in self.lights:
            d = np.sqrt((self.xx - x) ** 2 + ((self.yy - y) * 1.25) ** 2) / r
            out += c[None, None, :] * (s * np.clip(1 - d, 0, 1) ** 1.6)[..., None]
        return out

    def light_dir(self):
        """Per pixel, a unit vector pointing to the strongest light."""
        best = np.zeros((H, W))
        dx = np.zeros((H, W))
        dy = np.full((H, W), -1.0)
        for x, y, r, c, s in self.lights:
            d = np.sqrt((self.xx - x) ** 2 + (self.yy - y) ** 2)
            v = s * np.clip(1 - d / r, 0, 1)
            take = v > best
            n = np.maximum(d, 1e-3)
            dx = np.where(take, (x - self.xx) / n, dx)
            dy = np.where(take, (y - self.yy) / n, dy)
            best = np.maximum(best, v)
        return dx, dy

    # --- sky --------------------------------------------------------------------------
    def sky(self, stops, smoke=None, smoke_amount=0.35, smoke_scale=40):
        """A vertical gradient through `stops` [(y, colour)], with drifting smoke."""
        ys = [s[0] for s in stops]
        cs = [rgb(s[1]) for s in stops]
        col = np.zeros((H, 3))
        for y in range(H):
            if y <= ys[0]:
                col[y] = cs[0]
            elif y >= ys[-1]:
                col[y] = cs[-1]
            else:
                i = max(k for k in range(len(ys)) if ys[k] <= y)
                t = (y - ys[i]) / max(1, ys[i + 1] - ys[i])
                col[y] = lerp(cs[i], cs[i + 1], t * t * (3 - 2 * t))
        self.img[:] = col[:, None, :]
        if smoke is not None:
            n = self.noise(smoke_scale, 5)
            stretch = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((W * 3, H)).crop((0, 0, W, H)), float) / 255
            m = np.clip((stretch - 0.45) * 2.4, 0, 1) * smoke_amount
            self.img = lerp(self.img, rgb(smoke)[None, None, :], m[..., None])

    def glow(self, x, y, r, colour, strength=0.6, squash=0.7):
        """A soft bloom of light in the air (sky, haze)."""
        d = np.sqrt((self.xx - x) ** 2 + ((self.yy - y) / squash) ** 2) / r
        a = np.clip(1 - d, 0, 1) ** 2 * strength
        self.img = self.img + rgb(colour)[None, None, :] * a[..., None]

    # --- masks ------------------------------------------------------------------------
    @staticmethod
    def canvas():
        im = Image.new("L", (W, H), 0)
        return im, ImageDraw.Draw(im)

    @staticmethod
    def m(im):
        return np.asarray(im, dtype=float) / 255.0 > 0.5

    def ridge_mask(self, top, amp, scale, sharp=False, bottom=H):
        n = self.noise1d(scale, 5)
        if sharp:
            n = 1 - np.abs(n * 2 - 1)
        h = top - (n - 0.5) * 2 * amp
        return (self.yy >= h[None, :]) & (self.yy < bottom)

    # --- painting a layer -------------------------------------------------------------
    def layer(self, mask, colour, depth, rim=0.9, wash=0.6, texture=0.08, tex_scale=6, haze_k=0.85):
        """Paint `mask` in `colour`, faded into the haze by `depth` (0 near, 1 far), washed by
        the light near it and rimmed on the edges that face the light."""
        if not mask.any():
            return
        base = rgb(colour) if isinstance(colour, str) else colour
        lm = self._lm if hasattr(self, "_lm") else self.lightmap()
        tex = 1 + (self.noise(tex_scale, 3) - 0.5) * 2 * texture
        c = base[None, None, :] * tex[..., None]
        c = c * (self.ambient + 0.4) + lm * wash * (0.25 + 0.6 * base.mean())
        c = lerp(c, self.haze[None, None, :], depth * haze_k)
        if rim > 0:
            dx, dy = self._dir if hasattr(self, "_dir") else self.light_dir()
            edge = np.zeros((H, W), bool)
            for ox, oy in [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)]:
                facing = (dx * ox + dy * oy) > 0.35
                nb = np.roll(np.roll(mask, -oy, 0), -ox, 1)
                edge |= facing & ~nb
            edge &= mask
            rim_c = np.clip(lm * rim * (1 - depth * 0.6), 0, 1.4)
            c = np.where(edge[..., None], c + rim_c, c)
        self.img = np.where(mask[..., None], c, self.img)

    def flat(self, mask, colour):
        c = rgb(colour) if isinstance(colour, str) else colour
        self.img = np.where(mask[..., None], c[None, None, :], self.img)

    def emissive(self, mask, colour, hot=None, bloom=0.0, bloom_r=4):
        """Things that glow: painted at full colour, with an optional hot core and a bloom."""
        c = rgb(colour)
        if bloom > 0:
            b = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(bloom_r)), float) / 255
            self.img = self.img + c[None, None, :] * (b * bloom)[..., None]
        self.img = np.where(mask[..., None], c[None, None, :], self.img)
        if hot is not None:
            core = mask & np.roll(mask, 1, 0) & np.roll(mask, -1, 0) & np.roll(mask, 1, 1) & np.roll(mask, -1, 1)
            self.img = np.where(core[..., None], rgb(hot)[None, None, :], self.img)

    def fog(self, y, thick, colour, amount=0.5, scale=30):
        n = self.noise(scale, 4)
        n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((W * 2, H)).crop((W // 2, 0, W // 2 + W, H)), float) / 255
        band = np.exp(-((self.yy - y) / thick) ** 2)
        a = np.clip(band * (0.5 + n) * amount, 0, 1)
        self.img = lerp(self.img, rgb(colour)[None, None, :], a[..., None])

    def prepare_light(self):
        """Fix the light before painting layers (lights added later only glow, they don't rim)."""
        self._lm = self.lightmap()
        self._dir = self.light_dir()

    # --- shapes -----------------------------------------------------------------------
    def dead_tree(self, d, x, base, h, lean=0.0, spread=1.0, width=None, depth=4, seed=None):
        """A bare, crooked tree drawn into mask draw `d`. Returns the cracks to light (points)."""
        rnd = random.Random(seed if seed is not None else self.rnd.random())
        w = width or max(2.0, h / 11)
        cracks = []

        def branch(x0, y0, ang, length, wid, level):
            pts = [(x0, y0)]
            x1, y1 = x0, y0
            steps = max(2, int(length / 5))
            for i in range(steps):
                ang += rnd.uniform(-0.28, 0.28)
                x1 += math.cos(ang) * length / steps
                y1 -= math.sin(ang) * length / steps
                pts.append((x1, y1))
            for i in range(len(pts) - 1):
                ww = wid * (1 - 0.7 * i / len(pts))
                d.line([pts[i], pts[i + 1]], fill=255, width=max(1, int(round(ww))))
            if level >= depth or length < 5:
                return
            n = 2 if level > 0 else rnd.randint(3, 4)
            for k in range(n):
                at = rnd.uniform(0.45, 0.95)
                i = min(len(pts) - 1, int(at * (len(pts) - 1)))
                side = -1 if k % 2 else 1
                branch(pts[i][0], pts[i][1], ang + side * rnd.uniform(0.35, 0.9) * spread, length * rnd.uniform(0.45, 0.7),
                       max(1, wid * 0.55), level + 1)

        # trunk: a tapering polygon, slightly crooked, with roots
        top = (x + lean * h, base - h * 0.62)
        d.polygon([(x - w, base), (x - w * 0.4 + lean * h * 0.5, base - h * 0.35), (top[0] - w * 0.3, top[1]),
                   (top[0] + w * 0.3, top[1]), (x + w * 0.4 + lean * h * 0.5, base - h * 0.35), (x + w, base)], fill=255)
        d.polygon([(x - w * 2.2, base), (x - w * 0.6, base - h * 0.08), (x, base)], fill=255)
        d.polygon([(x + w * 2.0, base), (x + w * 0.6, base - h * 0.07), (x, base)], fill=255)
        branch(top[0], top[1], math.pi / 2 + rnd.uniform(-0.2, 0.2), h * 0.45, w * 0.7, 0)
        for k in range(rnd.randint(1, 3)):
            yy = base - h * rnd.uniform(0.35, 0.6)
            side = rnd.choice([-1, 1])
            branch(x + lean * (base - yy), yy, math.pi / 2 - side * rnd.uniform(0.6, 1.1), h * rnd.uniform(0.25, 0.4), w * 0.45, 1)
        for k in range(int(h / 14) + 1):
            yy = base - h * rnd.uniform(0.08, 0.55)
            cracks.append((x + lean * (base - yy) + rnd.uniform(-w * 0.3, w * 0.3), yy, rnd.randint(2, 5)))
        return cracks

    def person(self, d, x, base, tool=None, facing=1, h=15, pose=0):
        """A Hellfarer in silhouette, `h` px tall, feet at `base`, with a tool."""
        s = facing
        hd = h * 0.17
        d.ellipse([x - hd, base - h, x + hd, base - h + hd * 2], fill=255)              # head
        d.polygon([(x - h * 0.2, base - h + hd * 2), (x + h * 0.2, base - h + hd * 2),  # coat, flared
                   (x + h * 0.26, base - h * 0.32), (x - h * 0.26, base - h * 0.32)], fill=255)
        d.line([(x - h * 0.1, base - h * 0.35), (x - h * 0.13 - pose * s, base)], fill=255, width=2)  # legs
        d.line([(x + h * 0.1, base - h * 0.35), (x + h * 0.13 + pose * s, base)], fill=255, width=2)
        hx, hy = x + s * h * 0.3, base - h * 0.62  # hands
        if tool == "axe":   # raised over the shoulder
            d.line([(x + s * h * 0.12, base - h * 0.7), (x - s * h * 0.18, base - h * 1.12)], fill=255, width=1)
            d.polygon([(x - s * h * 0.18, base - h * 1.12), (x - s * h * 0.42, base - h * 1.2), (x - s * h * 0.36, base - h * 0.98)], fill=255)
            d.line([(x, base - h * 0.75), (x + s * h * 0.12, base - h * 0.7)], fill=255, width=2)
        elif tool == "pick":
            d.line([(x + s * h * 0.1, base - h * 0.7), (x + s * h * 0.5, base - h * 1.05)], fill=255, width=1)
            d.line([(x + s * h * 0.32, base - h * 1.18), (x + s * h * 0.7, base - h * 0.9)], fill=255, width=1)
        elif tool == "rod":
            d.line([(x + s * h * 0.2, base - h * 0.6), (x + s * h * 1.9, base - h * 1.5)], fill=255, width=1)
        elif tool == "bow":
            d.arc([hx - h * 0.1, base - h * 1.0, hx + h * 0.35, base - h * 0.25], 270 if s > 0 else 90, 90 if s > 0 else 270, fill=255)
            d.line([(x, base - h * 0.65), (hx + s * 2, base - h * 0.62)], fill=255, width=1)
        elif tool == "basket":
            d.rectangle([x - s * h * 0.38 - 2, base - h * 0.55, x - s * h * 0.38 + 2, base - h * 0.3], fill=255)
        elif tool == "lantern":
            d.line([(x + s * h * 0.18, base - h * 0.62), (x + s * h * 0.34, base - h * 0.5)], fill=255, width=1)
        elif tool == "hoe":
            d.line([(x + s * h * 0.2, base - h * 0.7), (x + s * h * 0.6, base)], fill=255, width=1)
            d.line([(x + s * h * 0.6, base), (x + s * h * 0.85, base - 1)], fill=255, width=1)
        return (x + s * h * 0.36, base - h * 0.46)  # where a lantern hangs

    def hound(self, d, x, y, s=1, size=1.0):
        k = size
        P = lambda px, py: (x + s * px * k, y - py * k)
        d.polygon([P(-4, 9), P(2, 11), P(13, 10), P(17, 13), P(20, 15), P(23, 13), P(25, 10), P(21, 9), P(19, 6), P(14, 5),
                   P(3, 5), P(-2, 7), P(-7, 10)], fill=255)
        d.polygon([P(19, 14), P(19, 18), P(21, 15)], fill=255)  # ear
        for lx, fx in ((1, -1), (4, 5), (14, 12), (17, 19)):
            d.line([P(lx, 6), P(fx, 0)], fill=255, width=max(1, int(k)))
        return P(22, 12)  # eye


    def reflect(self, y0, tint, amount=0.35, darken=0.62, ripple=1.6, y1=H):
        """Water from y0 down: the picture above, mirrored, broken by ripples and tinted."""
        src_img = self.img.copy()
        wob = self.noise(6, 2)
        for y in range(y0, y1):
            src = max(0, 2 * y0 - y - 1)
            k = (y - y0) / max(1, y1 - y0)
            shift = int(round(self.rnd.uniform(-1, 1) * ripple * (0.5 + 1.5 * k)))
            row = np.roll(src_img[src], shift, axis=0) * darken
            self.img[y] = lerp(row, rgb(tint), amount * (0.4 + 0.6 * k))
        for _ in range(int((y1 - y0) * 1.4)):  # glints where the light lies on the water
            y = self.rnd.randrange(y0 + 1, y1)
            x = self.rnd.randrange(W)
            n = self.rnd.randint(2, 7)
            self.img[y, x:x + n] = lerp(self.img[y, x:x + n], self._lm[y, x:x + n] if hasattr(self, "_lm") else self.img[y, x:x + n], 0.7) * 1.15

    def weeping_tree(self, d, x, base, h, seed=None):
        """A black willow-like tree: a leaning trunk, a dome of boughs, curtains of strands.
        Returns sap drips (x, y, n)."""
        rnd = random.Random(seed if seed is not None else self.rnd.random())
        w = max(1.5, h / 16)
        lean = rnd.uniform(-0.12, 0.12) * h
        cx, cy = x + lean, base - h * 0.78
        mid = (x + lean * 0.3, base - h * 0.45)
        d.polygon([(x - w * 1.6, base), (mid[0] - w, mid[1]), (cx - w * 0.6, cy), (cx + w * 0.6, cy), (mid[0] + w, mid[1]), (x + w * 1.6, base)], fill=255)
        drips = []
        for k in range(11):
            a = math.pi * (0.04 + 0.92 * k / 10) + rnd.uniform(-0.06, 0.06)
            r = h * rnd.uniform(0.3, 0.42)
            ex, ey = cx + math.cos(a) * r * 1.2, cy - math.sin(a) * r * 0.35
            d.line([(cx, cy), ((cx + ex) / 2, (cy + ey) / 2 - h * 0.06), (ex, ey)], fill=255, width=max(1, int(w * 0.7)), joint="curve")
            for j in range(5):
                fx = ex + rnd.uniform(-5, 5) - math.cos(a) * j * 2
                fy = ey + rnd.uniform(-1, 2)
                d.line([(fx, fy), (fx + rnd.uniform(-1, 1), fy + h * rnd.uniform(0.2, 0.5))], fill=255)
            if rnd.random() < 0.5:
                drips.append((ex + rnd.uniform(-3, 3), ey + 4, rnd.randint(3, 8)))
        d.ellipse([cx - h * 0.3, cy - h * 0.14, cx + h * 0.3, cy + h * 0.06], fill=255)
        for k in range(2):
            drips.append((x + lean * 0.3 + rnd.uniform(-w * 0.4, w * 0.4), base - h * rnd.uniform(0.15, 0.45), rnd.randint(4, 9)))
        return drips

    def beast(self, d, kind, x, y, s=1, k=1.0):
        """Animal silhouettes standing at ground y, facing s. Returns the eye position."""
        P = lambda px, py: (x + s * px * k, y - py * k)
        if kind == "boar":
            d.polygon([P(-2, 6), P(0, 11), P(8, 14), P(18, 13), P(24, 10), P(27, 7), P(24, 5), P(20, 4), P(2, 3)], fill=255)
            d.line([P(23, 6), P(26, 9)], fill=255)
            for lx in (3, 7, 17, 21):
                d.line([P(lx, 4), P(lx, 0)], fill=255, width=max(1, int(k * 1.4)))
            return P(21, 10)
        if kind == "gorehorn":
            # a long heavy body, hump over the shoulders, head lowered, horns swept forward and up
            def E(cx, cy, rx, ry):
                xs = sorted([x + s * (cx - rx) * k, x + s * (cx + rx) * k])
                d.ellipse([xs[0], y - (cy + ry) * k, xs[1], y - (cy - ry) * k], fill=255)
            E(14, 13, 15, 6)                        # body
            E(24, 16, 7, 5)                         # hump
            d.polygon([P(28, 17), P(36, 13), P(40, 8), P(36, 6), P(30, 9), P(26, 10)], fill=255)  # neck and head
            d.polygon([P(36, 8), P(42, 6), P(43, 9), P(39, 11)], fill=255)                        # muzzle
            for lx, fx in ((3, 2), (8, 9), (21, 20), (26, 28)):
                d.line([P(lx, 9), P(fx, 0)], fill=255, width=max(1, int(k * 1.7)))
            d.line([P(-1, 14), P(-5, 9)], fill=255)  # tail
            d.line([P(36, 12), P(40, 18), P(46, 20), P(50, 18)], fill=255, width=max(1, int(k * 1.4)))
            d.line([P(34, 13), P(35, 20), P(39, 25)], fill=255, width=max(1, int(k * 1.2)))
            return P(38, 10)
        if kind == "bear":
            # shoulder hump, head low and forward
            d.polygon([P(0, 2), P(-2, 12), P(4, 22), P(16, 26), P(28, 30), P(36, 28), P(42, 22), P(48, 20), P(54, 17), P(56, 13),
                       P(52, 10), P(46, 10), P(42, 8), P(40, 0), P(33, 0), P(32, 8), P(14, 9), P(11, 0), P(4, 0)], fill=255)
            d.polygon([P(46, 20), P(47, 23), P(49, 20)], fill=255)
            return P(51, 15)
        if kind == "hare":
            d.ellipse([x - 4 * k, y - 6 * k, x + 4 * k, y], fill=255)
            d.ellipse([min(x + s * 2 * k, x + s * 7 * k), y - 8 * k, max(x + s * 2 * k, x + s * 7 * k), y - 3 * k], fill=255)
            d.line([P(5, 7), P(4, 13)], fill=255)
            d.line([P(6, 7), P(7, 13)], fill=255)
            return P(5, 6)
        if kind == "crow":
            d.line([(x - 3 * k, y - 1 * k), (x, y + 1), (x + 3 * k, y - 1 * k)], fill=255)
            return (x, y)
        if kind == "crawler":
            d.ellipse([x - 7 * k, y - 4 * k, x + 7 * k, y + 4 * k], fill=255)
            d.ellipse([min(x + s * 5 * k, x + s * 11 * k), y - 3 * k, max(x + s * 5 * k, x + s * 11 * k), y + 3 * k], fill=255)
            for j in range(4):
                bx = x + (j - 1.5) * 3.5 * k
                d.line([(bx, y), (bx - 5 * k, y - 6 * k), (bx - 7 * k, y + 1 * k)], fill=255)
                d.line([(bx, y), (bx + 5 * k, y + 6 * k), (bx + 7 * k, y + 1 * k)], fill=255)
            return (x + s * 9 * k, y - 1)
        return (x, y)

    def crag(self, d, pts, rough=3.0, step=3):
        """A filled polygon whose edges are broken up into rock."""
        out = []
        for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
            n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
            for i in range(n):
                t = i / n
                out.append((x0 + (x1 - x0) * t + self.rnd.uniform(-rough, rough) * 0.5,
                            y0 + (y1 - y0) * t + self.rnd.uniform(-rough, rough)))
        d.polygon(out, fill=255)

    def rain(self, n, colour, slant=-1, length=3, y0=0, y1=H):
        c = rgb(colour)
        for _ in range(n):
            x, y = self.rnd.randrange(W), self.rnd.randrange(y0, y1)
            for i in range(length):
                xx, yy = x + slant * i // 2, y + i
                if 0 <= xx < W and 0 <= yy < H:
                    self.img[yy, xx] = lerp(self.img[yy, xx], c, 0.55)

    def done(self, colours=48, dither=0.045, vignette=0.35, gamma=0.9):
        img = np.clip(self.img, 0, 1) ** gamma
        if vignette:
            d = np.sqrt(((self.xx - W / 2) / (W / 2)) ** 2 + ((self.yy - H / 2) / (H / 2)) ** 2)
            img = img * (1 - vignette * np.clip(d - 0.55, 0, 1) ** 1.5)[..., None]
        b = BAYER[(np.arange(H) % 4)[:, None], (np.arange(W) % 4)[None, :]]
        img = np.clip(img + b[..., None] * dither, 0, 1)
        im = Image.fromarray((img * 255).astype(np.uint8), "RGB")
        im = im.quantize(colors=colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGBA")
        return im


def particles(sc, n, colour, y0=0, y1=H, size=1, hot=None):
    c = rgb(colour)
    for _ in range(n):
        x, y = sc.rnd.randrange(W), sc.rnd.randrange(y0, y1)
        sc.img[y, x] = c
        if hot is not None and sc.rnd.random() < 0.5:
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if 0 <= x + ox < W and 0 <= y + oy < H:
                    sc.img[y + oy, x + ox] = lerp(sc.img[y + oy, x + ox], rgb(hot), 0.45)
        elif size > 1 and x + 1 < W:
            sc.img[y, x + 1] = lerp(sc.img[y, x + 1], c, 0.5)


# =================================================================== the banners
def cinderwood():
    sc = Scene(101, haze="#8a3a1c")
    sc.sky([(0, "#140a0a"), (24, "#2a1210"), (54, "#6a2814"), (78, "#c0541e"), (88, "#e88a34")], smoke="#3a1a14", smoke_amount=0.5)
    sc.glow(128, 84, 120, "#f08a30", 0.4)
    sc.light(128, 86, 150, "#ff8a32", 1.0)
    sc.light(150, 98, 46, "#ffb040", 1.3)
    sc.prepare_light()
    # far forest: a comb of thin dead trunks in the haze
    im, d = sc.canvas()
    for x in range(-6, W + 6, 5):
        sc.dead_tree(d, x + sc.rnd.uniform(-2, 2), 82, sc.rnd.uniform(20, 34), lean=sc.rnd.uniform(-0.05, 0.05), depth=2, width=1.2)
    sc.layer(sc.m(im) | sc.ridge_mask(80, 2, 40), "#2a1410", 0.85, rim=0.25)
    sc.fog(80, 7, "#d07030", 0.4)
    # middle forest
    im, d = sc.canvas()
    cracks_mid = []
    for x in range(4, W, 19):
        if 96 < x < 170:
            continue  # the clearing
        cracks_mid += sc.dead_tree(d, x + sc.rnd.uniform(-4, 4), 90, sc.rnd.uniform(40, 56), lean=sc.rnd.uniform(-0.08, 0.08), depth=3)
    sc.layer(sc.m(im) | sc.ridge_mask(89, 1.5, 30), "#1e0e0c", 0.5, rim=0.5)
    sc.fog(90, 4, "#b05a28", 0.3)
    # ground: the clearing catches the light
    g = sc.ridge_mask(95, 1.5, 50)
    sc.layer(g, "#2a1410", 0.1, rim=1.0, wash=1.1, texture=0.25, tex_scale=3)
    # near trees framing the scene, burning inside
    im, d = sc.canvas()
    cracks = []
    for x, h, lean in [(8, 124, 0.04), (42, 104, -0.03), (208, 116, -0.05), (238, 126, 0.02)]:
        cracks += sc.dead_tree(d, x, 126, h, lean=lean, depth=4, width=h / 13)
    im2, d2 = sc.canvas()
    d2.polygon([(0, 126), (0, 112), (60, 116), (120, 122), (190, 116), (246, 110), (246, 126)], fill=255)
    sc.layer(sc.m(im) | sc.m(im2), "#120808", 0.0, rim=1.0, texture=0.12)
    # the work: a felled trunk, a stump with an axe in it, a woodcutter with a lantern
    im, d = sc.canvas()
    d.polygon([(84, 102), (146, 97), (148, 103), (86, 106)], fill=255)
    d.rectangle([108, 88, 118, 101], fill=255)
    d.line([(114, 87), (120, 78)], fill=255, width=1)
    d.polygon([(118, 77), (124, 75), (123, 81)], fill=255)
    lx, ly = sc.person(d, 160, 104, tool="axe", facing=-1, h=19, pose=1)
    sc.layer(sc.m(im), "#140a08", 0.0, rim=1.3)
    # fire in the wood
    em, d = sc.canvas()
    for x, y, n in cracks + cracks_mid:
        d.line([(x, y), (x + sc.rnd.uniform(-1, 1), y + n)], fill=255)
    d.ellipse([143, 97, 150, 104], fill=255)      # the cut end, still glowing
    d.line([(108, 88), (118, 88)], fill=255)      # the stump's cut
    sc.emissive(sc.m(em), "#f07a28", hot="#ffd070", bloom=0.5, bloom_r=3)
    particles(sc, 90, "#d8c4b4", 0, 110)
    particles(sc, 22, "#ffb848", 10, 100, hot="#f06a20")
    return sc.done()


def _cracks(sc, cracks, colour, hot, bloom=0.5):
    em, d = sc.canvas()
    for x, y, n in cracks:
        d.line([(x, y), (x + sc.rnd.uniform(-1, 1), y + n)], fill=255)
    sc.emissive(sc.m(em), colour, hot=hot, bloom=bloom, bloom_r=3)


def _lamp(sc, x, y, colour="#ffd27a", r=6, bloom=1.2):
    sc.glow(x, y + 1, r * 2.4, colour, 0.28 * bloom, squash=1.0)
    sc.glow(x, y + 1, r * 0.9, colour, 0.35 * bloom, squash=1.0)
    em, d = sc.canvas()
    d.rectangle([x - 1, y - 1, x + 1, y + 2], fill=255)
    sc.emissive(sc.m(em), colour, bloom=bloom, bloom_r=r)


# ---------------------------------------------------------------- layer 1: the Ashen Verge
def gatepit():
    sc = Scene(102, haze="#7a3418")
    sc.sky([(0, "#160a0a"), (30, "#2e1410"), (60, "#6a2a16"), (84, "#b04e1e")], smoke="#3a1a14", smoke_amount=0.45)
    sc.glow(40, 80, 90, "#e07a30", 0.3)
    sc.light(40, 80, 140, "#ff8a32", 0.7)
    sc.light(128, 76, 70, "#ffb050", 1.6)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(58, 10, 45, sharp=True), "#3a1a12", 0.8, rim=0.3)
    sc.fog(70, 8, "#a04a20", 0.35)
    sc.layer(sc.ridge_mask(72, 6, 30), "#24100c", 0.5, rim=0.5)
    # the rock face, with a timbered adit lit from inside
    im, d = sc.canvas()
    sc.crag(d, [(40, 126), (46, 90), (58, 70), (70, 60), (84, 44), (96, 30), (112, 22), (126, 12), (146, 18), (166, 10), (188, 22),
                (206, 18), (226, 30), (246, 26), (246, 126)], rough=5, step=4)
    face = sc.m(im)
    sc.layer(face, "#2a140e", 0.1, rim=0.8, texture=0.3, tex_scale=4)
    st, d = sc.canvas()
    for y in range(30, 100, 9):
        x = 70 + sc.rnd.randint(0, 20)
        while x < 190:
            n = sc.rnd.randint(6, 18)
            d.line([(x, y + sc.rnd.randint(-1, 1)), (x + n, y + sc.rnd.randint(-2, 2))], fill=255)
            x += n + sc.rnd.randint(4, 14)
    sm = sc.m(st) & face
    sc.img = np.where(sm[..., None], sc.img * 0.6, sc.img)
    em, d = sc.canvas()
    d.rectangle([116, 60, 140, 96], fill=255)
    sc.emissive(sc.m(em), "#e0742a", hot=None, bloom=0.9, bloom_r=7)
    em, d = sc.canvas()
    d.polygon([(120, 96), (124, 66), (132, 66), (136, 96)], fill=255)
    sc.emissive(sc.m(em), "#ffc060")
    im, d = sc.canvas()
    d.rectangle([111, 55, 145, 59], fill=255)
    d.rectangle([111, 55, 115, 98], fill=255)
    d.rectangle([141, 55, 145, 98], fill=255)
    d.line([(111, 60), (120, 55)], fill=255, width=2)
    d.line([(145, 60), (136, 55)], fill=255, width=2)
    sc.layer(sc.m(im), "#3a2216", 0.0, rim=1.0)
    # rails out of the mouth and a cart of copper; a miner with a pick
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 104), (60, 100), (110, 97), (150, 97), (200, 102), (246, 106), (246, 126)], fill=255)
    sc.layer(sc.m(im), "#1c0e0a", 0.0, rim=1.0, wash=0.9, texture=0.3, tex_scale=3)
    im, d = sc.canvas()
    d.line([(124, 97), (70, 118)], fill=255)
    d.line([(132, 97), (92, 122)], fill=255)
    for t in range(0, 10):
        y = 99 + t * 2.4
        d.line([(124 - t * 5.4 - 2, y), (132 - t * 4 + 2, y)], fill=255)
    sc.layer(sc.m(im), "#5a3624", 0.0, rim=0.6)
    im, d = sc.canvas()
    d.polygon([(64, 98), (92, 98), (88, 110), (68, 110)], fill=255)
    d.ellipse([67, 108, 73, 114], fill=255)
    d.ellipse([83, 108, 89, 114], fill=255)
    sc.person(d, 168, 104, tool="pick", facing=-1, h=19)
    sc.person(d, 98, 104, tool="lantern", facing=1, h=17)
    sc.layer(sc.m(im), "#140a08", 0.0, rim=1.2)
    em, d = sc.canvas()
    for i in range(9):
        x = 67 + i * 2.6
        d.rectangle([x, 95 - (i % 3), x + 2, 98], fill=255)
    sc.emissive(sc.m(em), "#c8703a")
    _lamp(sc, 104, 96)
    particles(sc, 70, "#d0bcac", 0, 100)
    particles(sc, 10, "#ffb848", 20, 90, hot="#f06a20")
    return sc.done()


def ashmeadow():
    sc = Scene(103, haze="#9a6a50")
    sc.sky([(0, "#1a1012"), (30, "#3a2220"), (60, "#7a4430"), (84, "#d08a58")], smoke="#4a3430", smoke_amount=0.4)
    sc.glow(196, 82, 110, "#f0a060", 0.45)
    sc.light(196, 82, 170, "#ffa860", 1.0)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(72, 6, 60), "#4a3030", 0.85, rim=0.2)
    sc.fog(80, 6, "#d8a078", 0.5)
    sc.layer(sc.ridge_mask(86, 2, 40), "#3a2824", 0.55, rim=0.3, wash=0.8)
    for top, col, dep, n, hmax in [(92, "#3a2c28", 0.25, 500, 4), (104, "#2a201c", 0.0, 500, 9)]:
        im, d = sc.canvas()
        d.rectangle([0, top, W, H], fill=255)
        for _ in range(n):
            x = sc.rnd.randrange(W)
            y = sc.rnd.randint(top - 1, top + 3)
            d.line([(x, y), (x + sc.rnd.randint(-1, 1), y - sc.rnd.randint(1, hmax))], fill=255)
        sc.layer(sc.m(im), col, dep, rim=0.25, wash=0.8, texture=0.2, tex_scale=2)
    # foragers against the bright haze, one bent to pick, one with a full basket
    im, d = sc.canvas()
    sc.person(d, 112, 96, tool="basket", facing=1, h=20)
    sc.person(d, 148, 95, tool=None, facing=-1, h=18, pose=1)
    d.polygon([(132, 84), (142, 82), (143, 89), (133, 90)], fill=255)
    d.line([(138, 82), (146, 78)], fill=255)
    for x in (22, 232):
        sc.dead_tree(d, x, 116, 40, depth=3)
    sc.layer(sc.m(im), "#1c1412", 0.0, rim=0.7)
    for _ in range(60):
        x, y = sc.rnd.randrange(W), sc.rnd.randint(96, 122)
        sc.img[y, x] = rgb("#d8ccc0") * (0.6 + 0.4 * (y - 96) / 26)
    em, d = sc.canvas()
    for _ in range(26):
        x, y = sc.rnd.randrange(W), sc.rnd.randint(98, 122)
        d.rectangle([x, y, x + 1, y + 1], fill=255)
    d.rectangle([108, 86, 110, 87], fill=255)
    sc.emissive(sc.m(em), "#f06a2a", bloom=0.4, bloom_r=2)
    particles(sc, 110, "#cfc2b6", 0, 100)
    return sc.done()


def cinder_pool():
    sc = Scene(104, haze="#8a5a40")
    sc.sky([(0, "#140c0e"), (26, "#2e1814"), (50, "#6a3420"), (70, "#d07a38")], smoke="#3a2420", smoke_amount=0.45)
    sc.glow(170, 64, 80, "#ffa050", 0.6)
    sc.light(170, 66, 150, "#ffa050", 1.1)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(58, 7, 50), "#3a2420", 0.8, rim=0.2)
    sc.fog(66, 4, "#c08060", 0.45)
    im, d = sc.canvas()
    for x in range(0, W, 11):
        if 150 < x < 196:
            continue
        sc.dead_tree(d, x + sc.rnd.uniform(-3, 3), 72, sc.rnd.uniform(10, 20), depth=2, width=1.3)
    sc.layer(sc.m(im) | sc.ridge_mask(71, 1.5, 30, bottom=73), "#24140e", 0.45, rim=0.15)
    sc.reflect(73, "#3a2a24", amount=0.2, darken=0.85)
    em, d = sc.canvas()   # the glow lying on the water
    for y in range(74, 118, 2):
        half = 6 + (y - 74) * 0.5
        x0 = 170 - half + sc.rnd.uniform(-4, 4)
        d.line([(x0, y), (x0 + sc.rnd.uniform(half * 0.6, half * 1.8), y)], fill=255)
    m = sc.m(em)
    sc.img = np.where(m[..., None], lerp(sc.img, rgb("#ffb060"), 0.6), sc.img)
    im, d = sc.canvas()
    d.polygon([(0, 96), (96, 92), (96, 95), (0, 100)], fill=255)
    for x in (6, 30, 54, 78, 94):
        d.rectangle([x, 94, x + 1, 110], fill=255)
    sc.person(d, 86, 92, tool="rod", facing=1, h=20)
    d.line([(124, 54), (127, 86)], fill=255)
    d.rectangle([60, 87, 66, 92], fill=255)  # a creel
    d.polygon([(184, 126), (192, 108), (212, 102), (236, 106), (246, 112), (246, 126)], fill=255)
    d.polygon([(0, 126), (0, 112), (20, 116), (34, 126)], fill=255)
    sc.layer(sc.m(im), "#140c0a", 0.0, rim=1.1)
    em, d = sc.canvas()
    d.ellipse([123, 85, 131, 88], outline=255)
    sc.emissive(sc.m(em), "#e0a070")
    particles(sc, 70, "#d0bcac", 0, 72)
    return sc.done()


def hollow_fields():
    sc = Scene(105, haze="#7a4430")
    sc.sky([(0, "#160c0c"), (30, "#30161a"), (60, "#6e3020"), (80, "#b0582a")], smoke="#3a2220", smoke_amount=0.5)
    sc.glow(196, 78, 100, "#f08038", 0.45)
    sc.light(196, 80, 160, "#ff9040", 1.0)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(74, 3, 60), "#3a2018", 0.8, rim=0.3)
    sc.fog(78, 5, "#a06040", 0.4)
    for top, col, dep in [(82, "#3a2a24", 0.45), (92, "#2c201a", 0.2), (104, "#1e1612", 0.0)]:
        im, d = sc.canvas()
        d.rectangle([0, top, W, H], fill=255)
        for x in range(0, W):
            if sc.rnd.random() < 0.7:
                y = top + sc.rnd.randint(0, 3)
                d.line([(x, y), (x, y - sc.rnd.randint(1, 3 + (top - 80) // 3))], fill=255)
        sc.layer(sc.m(im), col, dep, rim=0.25, wash=0.8, texture=0.2, tex_scale=2)
    # a bone scarecrow with crows, a hunter drawing on an ashhare
    im, d = sc.canvas()
    x0 = 66
    d.rectangle([x0, 46, x0 + 2, 98], fill=255)
    d.line([(x0 - 16, 56), (x0 + 18, 54)], fill=255, width=2)
    d.polygon([(x0 - 10, 58), (x0 + 12, 57), (x0 + 9, 78), (x0 + 4, 74), (x0 - 2, 80), (x0 - 7, 76)], fill=255)
    sc.beast(d, "crow", x0 + 16, 51, k=1.3)
    sc.beast(d, "crow", x0 - 14, 53, k=1.3)
    for _ in range(9):
        sc.beast(d, "crow", sc.rnd.randint(110, 240), sc.rnd.randint(18, 50), k=sc.rnd.uniform(1.0, 1.6))
    sc.person(d, 134, 92, tool="bow", facing=1, h=20)
    sc.beast(d, "hare", 182, 93, s=-1, k=0.85)
    sc.layer(sc.m(im), "#140a0a", 0.0, rim=1.2)
    em, d = sc.canvas()
    d.polygon([(x0 - 3, 39), (x0 + 5, 39), (x0 + 5, 45), (x0 + 3, 48), (x0 - 1, 48), (x0 - 3, 45)], fill=255)
    d.line([(x0 - 3, 40), (x0 - 7, 34), (x0 - 6, 31)], fill=255)
    d.line([(x0 + 5, 40), (x0 + 9, 34), (x0 + 8, 31)], fill=255)
    sc.emissive(sc.m(em), "#c8b8a4")
    for px, py in [(x0 - 2, 42), (x0 - 1, 42), (x0 + 3, 42), (x0 + 4, 42), (x0 + 1, 45)]:
        sc.img[py, px] = rgb("#140a0a")
    particles(sc, 70, "#d0bcac", 0, 100)
    return sc.done()


def fallen_keep():
    sc = Scene(106, haze="#8a3a1c")
    sc.sky([(0, "#120808"), (30, "#2a100e"), (58, "#6a2414"), (84, "#c04e1c")], smoke="#2a1210", smoke_amount=0.55)
    sc.glow(124, 64, 110, "#f07028", 0.55)
    sc.light(124, 60, 160, "#ff8030", 1.1)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(84, 4, 50), "#3a1a12", 0.8, rim=0.3)
    sc.fog(84, 6, "#c06030", 0.4)
    # the crag and the keep that fell with it
    im, d = sc.canvas()
    d.polygon([(46, 126), (62, 96), (84, 88), (160, 86), (180, 94), (200, 126)], fill=255)
    d.rectangle([90, 44, 156, 90], fill=255)
    d.rectangle([108, 18, 134, 90], fill=255)
    for x in range(108, 135, 6):
        d.rectangle([x, 13, x + 3, 18], fill=255)
    for x in range(90, 157, 6):
        d.rectangle([x, 39, x + 3, 44], fill=255)
    d.rectangle([84, 30, 96, 90], fill=255)
    for x in range(84, 97, 5):
        d.rectangle([x, 26, x + 2, 30], fill=255)
    d.polygon([(156, 44), (166, 52), (162, 64), (168, 90), (156, 90)], fill=255)
    keep = sc.m(im)
    bite, d = sc.canvas()
    d.polygon([(134, 18), (128, 26), (134, 36), (140, 30)], fill=255)
    d.polygon([(150, 39), (146, 48), (158, 46)], fill=255)
    keep &= ~sc.m(bite)
    sc.layer(keep, "#1a0c0a", 0.05, rim=1.0, texture=0.25, tex_scale=3)
    em, d = sc.canvas()
    for x, y in [(118, 26), (124, 40), (96, 52), (142, 56), (116, 58), (88, 38), (100, 70), (146, 70)]:
        d.rectangle([x, y, x + 2, y + 4], fill=255)
    d.rectangle([117, 74, 125, 90], fill=255)
    sc.emissive(sc.m(em), "#f08a30", hot=None, bloom=0.7, bloom_r=4)
    em, d = sc.canvas()
    d.rectangle([119, 78, 123, 90], fill=255)
    sc.emissive(sc.m(em), "#ffd070")
    # a road up, the crew on it, dead trees either side
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 104), (70, 108), (110, 102), (150, 104), (246, 100), (246, 126)], fill=255)
    for x, h in [(22, 70), (222, 78)]:
        sc.dead_tree(d, x, 118, h, depth=3)
    for i, x in enumerate((70, 80, 90)):
        sc.person(d, x, 106, tool=["lantern", None, "pick"][i], facing=1, h=15, pose=i % 2)
    sc.layer(sc.m(im), "#120808", 0.0, rim=1.0)
    _lamp(sc, 76, 99)
    particles(sc, 80, "#d0bcac", 0, 104)
    particles(sc, 16, "#ffb848", 10, 90, hot="#f06a20")
    return sc.done()


# ---------------------------------------------------------------- layer 2: the Weeping Fens
def weepingwood():
    sc = Scene(201, haze="#6a1a22")
    sc.sky([(0, "#0e070a"), (30, "#200a10"), (60, "#4a1018"), (86, "#8a2026")], smoke="#2a0c12", smoke_amount=0.5)
    sc.glow(124, 86, 120, "#d0342e", 0.45)
    sc.light(124, 88, 150, "#ff4a3a", 1.0)
    sc.prepare_light()
    im, d = sc.canvas()
    for x in range(-10, W + 10, 22):
        sc.weeping_tree(d, x + sc.rnd.uniform(-5, 5), 84, sc.rnd.uniform(28, 38))
    sc.layer(sc.m(im) | sc.ridge_mask(82, 2, 40), "#2a0c12", 0.85, rim=0.2)
    sc.fog(84, 7, "#a02a2a", 0.45)
    im, d = sc.canvas()
    drips = []
    for x in (14, 58, 190, 232):
        drips += sc.weeping_tree(d, x + sc.rnd.uniform(-4, 4), 96, sc.rnd.uniform(52, 64))
    sc.layer(sc.m(im) | sc.ridge_mask(94, 2, 30), "#1a070c", 0.4, rim=0.5)
    sc.fog(96, 4, "#7a1a20", 0.3)
    # the clearing: a woodcutter at a black trunk, a guard with a lantern, hounds in the dark
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 108), (60, 104), (124, 100), (190, 104), (246, 108), (246, 126)], fill=255)
    drips += sc.weeping_tree(d, 104, 101, 70, seed=7)
    sc.person(d, 122, 101, tool="axe", facing=-1, h=20, pose=1)
    lx, ly = sc.person(d, 150, 102, tool="lantern", facing=-1, h=18)
    d.line([(156, 82), (160, 84)], fill=255)  # a spear over the shoulder
    d.line([(144, 98), (160, 74)], fill=255)
    sc.layer(sc.m(im), "#10060a", 0.0, rim=1.1)
    em, d = sc.canvas()
    d.polygon([(106, 92), (110, 90), (110, 95)], fill=255)  # the cut, weeping
    sc.emissive(sc.m(em), "#e03a30")
    _cracks(sc, drips, "#b0202a", "#f05040", bloom=0.4)
    em, d = sc.canvas()
    for x, y in [(36, 98), (72, 96), (196, 97), (222, 99), (180, 93)]:
        d.point((x, y), fill=255)
        d.point((x + 3, y), fill=255)
    sc.emissive(sc.m(em), "#ff6a40", bloom=0.6, bloom_r=2)
    _lamp(sc, int(lx), int(ly), colour="#ffcf7a")
    particles(sc, 40, "#a88a8a", 0, 100)
    return sc.done(gamma=0.78)


def sulphur_deeps():
    sc = Scene(202, haze="#8a6a24", ambient=0.2)
    sc.sky([(0, "#0c0804"), (126, "#1a1206")])
    sc.light(124, 70, 130, "#ffd86a", 1.4)
    sc.prepare_light()
    rock, d = sc.canvas()
    d.rectangle([0, 0, W, H], fill=255)
    sc.layer(sc.m(rock), "#24180a", 0.0, rim=0.0, texture=0.35, tex_scale=4)
    tunnel = [(200, 100, "#4a3612", 0.0), (150, 80, "#6a4e18", 0.15), (106, 62, "#a07e2a", 0.3), (70, 46, "#d8b850", 0.45), (40, 30, "#fff0a8", 0.6)]
    for w, h, col, dep in tunnel:
        x0, y0 = 124 - w // 2, 100 - h
        hole, d = sc.canvas()
        d.rectangle([x0, y0 + 12, x0 + w, 100], fill=255)
        d.ellipse([x0, y0, x0 + w, y0 + 26], fill=255)
        sc.layer(sc.m(hole), col, 0.0, rim=0.0, wash=0.3, texture=0.25, tex_scale=3)
        if w < 50:
            break
        props, d = sc.canvas()
        t = max(2, w // 40)
        d.rectangle([x0 + 2, y0 + 10, x0 + 2 + t, 100], fill=255)
        d.rectangle([x0 + w - 2 - t, y0 + 10, x0 + w - 2, 100], fill=255)
        d.rectangle([x0, y0 + 7, x0 + w, y0 + 7 + t], fill=255)
        sc.layer(sc.m(props), "#2a1a08", 0.0, rim=0.8, wash=0.5)
    sc.glow(124, 80, 50, "#fff0a0", 0.35)
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 106), (80, 100), (168, 100), (246, 106), (246, 126)], fill=255)
    sc.layer(sc.m(im), "#2a1e0a", 0.0, rim=0.8, wash=0.8, texture=0.3, tex_scale=3)
    rails, d = sc.canvas()
    d.line([(118, 100), (96, 126)], fill=255)
    d.line([(130, 100), (152, 126)], fill=255)
    sc.layer(sc.m(rails), "#5a4420", 0.0, rim=0.5)
    im, d = sc.canvas()
    sc.person(d, 100, 104, tool="pick", facing=1, h=21)
    d.polygon([(132, 102), (154, 102), (151, 93), (135, 93)], fill=255)
    d.ellipse([135, 100, 140, 105], fill=255)
    d.ellipse([146, 100, 151, 105], fill=255)
    eye = sc.beast(d, "crawler", 196, 44, s=-1, k=1.5)
    sc.layer(sc.m(im), "#0e0a04", 0.0, rim=1.1)
    em, d = sc.canvas()
    for _ in range(16):
        x, y = sc.rnd.randrange(W), sc.rnd.randint(104, 122)
        hh = sc.rnd.randint(3, 7)
        d.polygon([(x, y + 2), (x + 1, y - hh), (x + 3, y + 2)], fill=255)
    for _ in range(10):
        x, y = sc.rnd.choice([sc.rnd.randint(4, 26), sc.rnd.randint(220, 242)]), sc.rnd.randint(20, 100)
        d.polygon([(x, y + 2), (x + 1, y - 4), (x + 3, y + 2)], fill=255)
    d.rectangle([136, 90, 150, 93], fill=255)
    sc.emissive(sc.m(em), "#e8d050", bloom=0.5, bloom_r=3)
    em, d = sc.canvas()
    d.point((int(eye[0]), int(eye[1])), fill=255)
    d.point((int(eye[0]) - 2, int(eye[1])), fill=255)
    sc.emissive(sc.m(em), "#ff3a2a", bloom=0.8, bloom_r=2)
    particles(sc, 40, "#e8d060", 14, 96)
    return sc.done(vignette=0.5)


def bloodfen():
    sc = Scene(203, haze="#7a2026")
    sc.sky([(0, "#100608"), (28, "#240a10"), (56, "#5a1418"), (76, "#a02a26")], smoke="#300c12", smoke_amount=0.45)
    sc.glow(180, 74, 90, "#e0402e", 0.5)
    sc.light(180, 76, 160, "#ff5a3a", 1.0)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(64, 5, 50), "#3a1018", 0.85, rim=0.2)
    im, d = sc.canvas()
    for x in range(6, W, 26):
        sc.dead_tree(d, x + sc.rnd.uniform(-6, 6), 76, sc.rnd.uniform(14, 28), depth=2, width=1.5)
    sc.layer(sc.m(im) | sc.ridge_mask(75, 1.5, 30, bottom=77), "#24080e", 0.5, rim=0.2)
    sc.fog(76, 4, "#b03a30", 0.35)
    sc.reflect(77, "#3a0c12", amount=0.35, darken=0.75)
    # hummocks with reeds, a forager wading with a basket, gravecaps pale on the mounds
    im, d = sc.canvas()
    for x, y, w in [(-10, 98, 70), (60, 90, 40), (150, 94, 50), (200, 104, 70), (90, 112, 60)]:
        d.ellipse([x, y, x + w, y + 10], fill=255)
        for _ in range(int(w / 3)):
            rx = sc.rnd.uniform(x + 4, x + w - 4)
            d.line([(rx, y + 3), (rx + sc.rnd.uniform(-2, 2), y + 3 - sc.rnd.uniform(5, 14))], fill=255)
    sc.person(d, 120, 96, tool="basket", facing=-1, h=20)
    d.line([(40, 108), (52, 106), (60, 109), (72, 107)], fill=255, width=2)
    sc.layer(sc.m(im), "#14060a", 0.0, rim=0.6)
    for _ in range(18):
        x, y = sc.rnd.randrange(4, W - 4), sc.rnd.randint(90, 120)
        sc.img[y + 1:y + 3, x] = rgb("#a89888")
        sc.img[y, x - 1:x + 2] = rgb("#e8d8c8")
    em, d = sc.canvas()
    for _ in range(14):
        x, y = sc.rnd.randrange(W), sc.rnd.randint(94, 122)
        d.rectangle([x, y, x + 1, y], fill=255)
    sc.emissive(sc.m(em), "#e0303a", bloom=0.3, bloom_r=2)
    particles(sc, 40, "#a88a8a", 0, 76)
    return sc.done(gamma=0.78)


def styx_shallows():
    sc = Scene(204, haze="#5a1a20")
    sc.sky([(0, "#0c0608"), (24, "#1c080c"), (48, "#50141c"), (68, "#b03a30")], smoke="#24080e", smoke_amount=0.5)
    sc.glow(90, 66, 100, "#f05a3a", 0.6)
    sc.light(62, 68, 150, "#ff5038", 1.0)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(52, 9, 40, sharp=True), "#2e0e14", 0.85, rim=0.2)
    sc.layer(sc.ridge_mask(66, 4, 24, bottom=70), "#1e080c", 0.5, rim=0.4)
    sc.fog(68, 4, "#902a2a", 0.4)
    sc.reflect(70, "#1e0a0e", amount=0.3, darken=0.8, ripple=3)
    # fast water: long pale streaks running across, bones turning in it
    for _ in range(140):
        y = sc.rnd.randint(72, 124)
        x = sc.rnd.randrange(W)
        n = sc.rnd.randint(6, 24)
        sc.img[y, x:x + n] = lerp(sc.img[y, x:x + n], rgb("#6a2a30"), 0.6)
    for _ in range(10):
        x, y = sc.rnd.randrange(80, W - 10), sc.rnd.randint(80, 118)
        sc.img[y, x:x + sc.rnd.randint(3, 7)] = rgb("#d8c8b8")
    # the near bank and a wading angler with a lantern on a pole
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 92), (30, 94), (60, 98), (88, 104), (100, 112), (110, 126)], fill=255)
    sc.person(d, 78, 96, tool="rod", facing=1, h=21)
    d.line([(118, 65), (122, 92)], fill=255)
    d.line([(26, 98), (30, 76)], fill=255)
    d.line([(30, 76), (36, 78)], fill=255)
    for _ in range(14):
        x = sc.rnd.uniform(0, 60)
        d.line([(x, 100), (x + sc.rnd.uniform(-2, 2), 100 - sc.rnd.uniform(6, 14))], fill=255)
    sc.layer(sc.m(im), "#10060a", 0.0, rim=1.1)
    _lamp(sc, 36, 80, colour="#ffc070", r=8)
    particles(sc, 40, "#a88a8a", 0, 70)
    return sc.done(gamma=0.78)


def houndfang_hills():
    sc = Scene(205, haze="#7a2026")
    sc.sky([(0, "#0e0608"), (24, "#220a10"), (50, "#561418"), (74, "#b0302a")], smoke="#2a0a10", smoke_amount=0.45)
    sc.glow(150, 68, 100, "#f0502e", 0.6)
    sc.light(150, 70, 170, "#ff5a38", 1.1)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(54, 10, 40, sharp=True), "#3a1018", 0.85, rim=0.2)
    sc.fog(64, 6, "#c0402e", 0.4)
    sc.layer(sc.ridge_mask(70, 7, 30), "#28080e", 0.55, rim=0.4)
    # the pack on the near crest, against the light; a hunter crouched below; a hellboar
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 96), (40, 86), (90, 80), (150, 80), (200, 86), (246, 92), (246, 126)], fill=255)
    eyes = []
    for x, s, k in [(56, 1, 1.2), (96, 1, 1.3), (146, -1, 1.2), (172, 1, 1.1)]:
        eyes.append(sc.hound(d, x, 81, s=s, size=k))
    sc.person(d, 222, 92, tool="bow", facing=-1, h=20)
    sc.beast(d, "boar", 20, 98, s=1, k=1.1)
    sc.layer(sc.m(im), "#12060a", 0.0, rim=0.7, texture=0.15)
    em, d = sc.canvas()
    for x, y in eyes:
        d.point((int(x), int(y)), fill=255)
    sc.emissive(sc.m(em), "#ffb040", bloom=0.6, bloom_r=2)
    particles(sc, 40, "#a88a8a", 0, 90)
    return sc.done(gamma=0.78)


def drowned_abbey():
    sc = Scene(206, haze="#5a1a22")
    sc.sky([(0, "#0c0608"), (30, "#1e0a10"), (56, "#4a1218"), (80, "#8a2228")], smoke="#24080e", smoke_amount=0.5)
    sc.glow(124, 56, 110, "#d0402e", 0.45)
    sc.light(124, 52, 170, "#ff5a40", 0.9)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(76, 4, 50, bottom=80), "#2a0c12", 0.85, rim=0.2)
    # bell tower and nave, half under black water
    im, d = sc.canvas()
    d.rectangle([108, 18, 134, 80], fill=255)
    d.polygon([(104, 20), (121, 0), (138, 20)], fill=255)
    d.polygon([(134, 80), (134, 46), (196, 46), (206, 58), (206, 80)], fill=255)
    d.polygon([(36, 80), (46, 54), (108, 54), (108, 80)], fill=255)
    for x in range(140, 200, 12):
        d.polygon([(x, 46), (x + 4, 40), (x + 8, 46)], fill=255)
    abbey = sc.m(im)
    cut, d = sc.canvas()
    d.polygon([(36, 54), (60, 54), (52, 66), (40, 62)], fill=255)  # a fallen corner
    abbey &= ~sc.m(cut)
    sc.layer(abbey, "#14070c", 0.05, rim=0.9, texture=0.25, tex_scale=3)
    em, d = sc.canvas()
    d.rectangle([115, 26, 127, 40], fill=255)
    for x in range(142, 198, 12):
        d.rectangle([x, 54, x + 4, 68], fill=255)
        d.ellipse([x, 52, x + 4, 56], fill=255)
    sc.emissive(sc.m(em), "#f0703a", bloom=0.7, bloom_r=4)
    bell, d = sc.canvas()
    d.chord([116, 27, 126, 41], 180, 360, fill=255)
    d.rectangle([116, 33, 126, 37], fill=255)
    sc.flat(sc.m(bell), "#2a0c10")
    em, d = sc.canvas()
    for x in range(60, 104, 12):
        d.rectangle([x, 62, x + 3, 74], fill=255)
    sc.emissive(sc.m(em), "#7a2a28")
    sc.reflect(80, "#0c0608", amount=0.35, darken=0.7, ripple=1.2)
    # the drowned just under the surface, and a boat of the crew rowing in
    for _ in range(6):
        x, y = sc.rnd.randint(10, 230), sc.rnd.randint(96, 120)
        sc.img[y:y + 2, x:x + 4] = lerp(sc.img[y:y + 2, x:x + 4], rgb("#6a5a60"), 0.7)
    im, d = sc.canvas()
    d.polygon([(30, 104), (88, 104), (80, 112), (38, 112)], fill=255)
    for i, x in enumerate((44, 58, 72)):
        sc.person(d, x, 105, tool=["lantern", None, None][i], facing=1, h=14)
    d.line([(60, 100), (90, 116)], fill=255)
    sc.layer(sc.m(im), "#0c0508", 0.0, rim=1.0)
    _lamp(sc, 49, 98, colour="#ffc070", r=7)
    particles(sc, 40, "#a88a8a", 0, 80)
    return sc.done(gamma=0.78)


# ---------------------------------------------------------------- layer 3: the Brimstone Reach
def _lava(sc, x0, y0, y1, width=2):
    em, d = sc.canvas()
    x, y = x0, y0
    while y < y1:
        nx, ny = x + sc.rnd.uniform(-4, 4), y + 5
        d.line([(x, y), (nx, ny)], fill=255, width=width + int((y - y0) / 14))
        x, y = nx, ny
    sc.emissive(sc.m(em), "#f06a1a", hot="#ffe070", bloom=0.8, bloom_r=4)


def ember_slopes():
    sc = Scene(301, haze="#b0501a")
    sc.sky([(0, "#1a0a06"), (24, "#3a140a"), (50, "#8a3410"), (70, "#e0701a")], smoke="#3a1a0c", smoke_amount=0.55)
    sc.glow(172, 56, 100, "#ff9a30", 0.6)
    sc.light(172, 60, 170, "#ffa040", 1.2)
    sc.prepare_light()
    im, d = sc.canvas()
    d.polygon([(0, 74), (40, 52), (80, 58), (130, 40), (170, 22), (210, 34), (246, 46), (246, 126), (0, 126)], fill=255)
    sc.layer(sc.m(im), "#4a1c0c", 0.75, rim=0.4)
    sc.fog(60, 8, "#e0782a", 0.3)
    im, d = sc.canvas()
    sc.crag(d, [(0, 126), (0, 92), (50, 72), (110, 80), (170, 62), (246, 78), (246, 126)], rough=3, step=5)
    sc.layer(sc.m(im), "#2e1208", 0.35, rim=0.8, texture=0.3, tex_scale=4)
    _lava(sc, 170, 64, 126, 2)
    _lava(sc, 64, 76, 126, 1)
    # vents breathing fire; a forager with a basket between them
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 104), (80, 98), (160, 104), (246, 98), (246, 126)], fill=255)
    for vx, vy in ((30, 104), (124, 101), (214, 99)):
        d.polygon([(vx - 9, vy), (vx - 3, vy - 9), (vx + 3, vy - 9), (vx + 9, vy)], fill=255)
    sc.person(d, 90, 99, tool="basket", facing=1, h=20)
    sc.layer(sc.m(im), "#1a0a06", 0.0, rim=1.0, texture=0.25, tex_scale=3)
    em, d = sc.canvas()
    for vx, vy in ((30, 104), (124, 101), (214, 99)):
        d.polygon([(vx - 3, vy - 9), (vx - 2, vy - 20), (vx, vy - 14), (vx + 2, vy - 24), (vx + 3, vy - 9)], fill=255)
    sc.emissive(sc.m(em), "#f07a1a", hot="#ffe070", bloom=0.9, bloom_r=5)
    for _ in range(26):  # nightshade (violet) and emberbloom (gold)
        x, y = sc.rnd.randrange(W), sc.rnd.randint(104, 122)
        sc.img[y, x] = rgb("#ffcf50") if sc.rnd.random() < 0.5 else rgb("#9a4ad0")
        sc.img[y + 1, x] = rgb("#2a3a14")
    particles(sc, 40, "#ffb848", 4, 100, hot="#f06a20")
    return sc.done()


def lake_of_glass():
    sc = Scene(302, haze="#c06a2a")
    sc.sky([(0, "#1a0a06"), (20, "#3a140a"), (42, "#8a3412"), (58, "#f08a2a")], smoke="#3a1a0c", smoke_amount=0.4)
    sc.glow(124, 56, 110, "#ffb050", 0.6)
    sc.light(124, 58, 180, "#ffb050", 1.2)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(46, 8, 30, sharp=True), "#5a2410", 0.8, rim=0.4)
    sc.layer(sc.ridge_mask(56, 3, 24, bottom=60), "#2e1208", 0.45, rim=0.6)
    sc.reflect(60, "#3a1a0c", amount=0.08, darken=0.95, ripple=0.0, y1=106)
    for _ in range(6):  # one long glint line each
        y = sc.rnd.randint(64, 102)
        x = sc.rnd.randrange(W - 30)
        sc.img[y, x:x + sc.rnd.randint(10, 26)] = rgb("#ffd890")
    # a great pike breaking the glass, rings spreading
    im, d = sc.canvas()
    d.polygon([(146, 78), (156, 70), (170, 64), (184, 62), (194, 64), (186, 67), (172, 70), (158, 76)], fill=255)
    d.polygon([(146, 78), (138, 76), (142, 84)], fill=255)
    d.polygon([(166, 66), (170, 62), (172, 66)], fill=255)
    d.line([(194, 64), (198, 66)], fill=255)
    sc.layer(sc.m(im), "#1a0a06", 0.0, rim=1.2)
    em, d = sc.canvas()
    for r in (10, 18, 26):
        d.ellipse([164 - r, 80 - r * 0.18, 164 + r, 80 + r * 0.18], outline=255)
    sc.emissive(sc.m(em), "#ffe0a0")
    # the glass shore and a fisher with a net
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 104), (90, 102), (160, 108), (246, 106), (246, 126)], fill=255)
    sc.person(d, 70, 103, tool="rod", facing=1, h=21)
    sc.layer(sc.m(im), "#1a0a06", 0.0, rim=1.0, texture=0.2, tex_scale=3)
    for _ in range(40):
        x, y = sc.rnd.randrange(W - 4), sc.rnd.randint(106, 124)
        h = sc.rnd.randint(2, 5)
        c = rgb("#f6d8a0") if sc.rnd.random() < 0.4 else rgb("#c08a5a")
        for i in range(h):
            sc.img[y - i, x + (1 if i > h // 2 else 0)] = c
    particles(sc, 24, "#ffb848", 4, 60, hot="#f06a20")
    return sc.done()


def gorehorn_moor():
    sc = Scene(303, haze="#a8481a")
    sc.sky([(0, "#1a0a06"), (26, "#3a140a"), (52, "#7a2c10"), (74, "#d0601a")], smoke="#2a1208", smoke_amount=0.6)
    sc.glow(60, 70, 100, "#ff8a2a", 0.55)
    sc.light(60, 72, 180, "#ff9030", 1.2)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(64, 5, 50), "#4a1c0c", 0.8, rim=0.3)
    sc.fog(70, 6, "#e07028", 0.4)
    sc.layer(sc.ridge_mask(78, 2, 40), "#2a1008", 0.45, rim=0.5)
    em, d = sc.canvas()   # the moor burns in low lines
    for _ in range(40):
        x, y = sc.rnd.randrange(W), sc.rnd.randint(78, 92)
        d.line([(x, y), (x + sc.rnd.randint(3, 12), y)], fill=255)
    sc.emissive(sc.m(em), "#f07020", hot=None, bloom=0.6, bloom_r=3)
    # two gorehorns on the rise; a hunter with a spear, low in the heather
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 100), (60, 96), (110, 90), (170, 92), (246, 98), (246, 126)], fill=255)
    for x in range(0, W, 2):
        d.line([(x, 100), (x, 92 + sc.rnd.randint(0, 6) - (4 if 90 < x < 180 else 0))], fill=255)
    e1 = sc.beast(d, "gorehorn", 108, 91, s=1, k=1.2)
    e2 = sc.beast(d, "gorehorn", 214, 95, s=-1, k=0.9)
    sc.person(d, 46, 100, tool=None, facing=1, h=20)
    d.line([(36, 104), (62, 72)], fill=255)
    d.polygon([(61, 73), (64, 66), (64, 74)], fill=255)
    sc.layer(sc.m(im), "#140806", 0.0, rim=1.0, texture=0.15)
    em, d = sc.canvas()
    for x, y in (e1, e2):
        d.point((int(x), int(y)), fill=255)
    sc.emissive(sc.m(em), "#ffd060", bloom=0.5, bloom_r=2)
    particles(sc, 40, "#ffb848", 6, 100, hot="#f06a20")
    particles(sc, 40, "#c8a898", 0, 96)
    return sc.done()


# ---------------------------------------------------------------- layer 4: the Frozen Lament
def _ice(sc, d, top, count, hmin=10, hmax=30, x0=-10, x1=W):
    for _ in range(count):
        x = sc.rnd.randrange(x0, x1)
        h = sc.rnd.randint(hmin, hmax)
        w = sc.rnd.randint(4, 10)
        lean = sc.rnd.uniform(-3, 3)
        d.polygon([(x, top + 6), (x + w / 2 + lean, top + 6 - h), (x + w, top + 6)], fill=255)


def laments_edge():
    sc = Scene(401, haze="#7a8aa0", ambient=0.3)
    sc.sky([(0, "#0a0c12"), (26, "#161c28"), (50, "#2c3648"), (72, "#6a7c94")], smoke="#1c2230", smoke_amount=0.4)
    sc.glow(124, 64, 110, "#b8cce4", 0.4)
    sc.light(124, 66, 170, "#c8dcf0", 1.0)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(54, 8, 30, sharp=True), "#2e3646", 0.8, rim=0.3)
    sc.fog(62, 6, "#a8b8cc", 0.4)
    im, d = sc.canvas()
    _ice(sc, d, 66, 26, 10, 30)
    sc.layer(sc.m(im) | sc.ridge_mask(72, 1.5, 30), "#1c2230", 0.4, rim=0.9)
    # the ice field with faces held in it
    im, d = sc.canvas()
    d.rectangle([0, 76, W, H], fill=255)
    sc.layer(sc.m(im), "#3a4658", 0.15, rim=0.4, wash=0.9, texture=0.15, tex_scale=8)
    for _ in range(20):
        y = sc.rnd.randint(78, 124)
        x = sc.rnd.randrange(W)
        sc.img[y, x:x + sc.rnd.randint(8, 30)] = lerp(sc.img[y, x:x + 1].mean(0), rgb("#9aaac0"), 0.4)
    for x, y in [(30, 96), (112, 104), (186, 92), (220, 110)]:
        face, d = sc.canvas()
        d.ellipse([x, y, x + 11, y + 14], fill=255)
        sc.img = np.where(sc.m(face)[..., None], lerp(sc.img, rgb("#6a788c"), 0.35), sc.img)
        for px, py in [(x + 3, y + 5), (x + 7, y + 5)]:
            sc.img[py:py + 2, px] = lerp(sc.img[py:py + 2, px], rgb("#141820"), 0.6)
        sc.img[y + 9:y + 13, x + 5] = lerp(sc.img[y + 9:y + 13, x + 5], rgb("#141820"), 0.55)
    # a forager cutting lilies, a frost hound watching
    im, d = sc.canvas()
    sc.person(d, 140, 94, tool="basket", facing=-1, h=20)
    eye = sc.hound(d, 200, 82, s=-1, size=1.2)
    sc.layer(sc.m(im), "#0e1018", 0.0, rim=1.0)
    em, d = sc.canvas()
    for _ in range(16):
        x, y = sc.rnd.randrange(W), sc.rnd.randint(84, 122)
        d.polygon([(x - 2, y), (x, y - 3), (x + 2, y)], fill=255)
    sc.emissive(sc.m(em), "#e8f2ff", bloom=0.5, bloom_r=2)
    em, d = sc.canvas()
    d.point((int(eye[0]), int(eye[1])), fill=255)
    sc.emissive(sc.m(em), "#ff3a2a", bloom=0.8, bloom_r=2)
    sc.rain(120, "#dce6f4", slant=1, length=2)
    return sc.done()


def shore_of_tears():
    sc = Scene(402, haze="#5a6478", ambient=0.3)
    sc.sky([(0, "#0a0c12"), (24, "#161c28"), (46, "#2e3848"), (62, "#6a7a90")], smoke="#2a3240", smoke_amount=0.5, smoke_scale=30)
    sc.glow(150, 58, 110, "#b8c8e0", 0.45)
    sc.light(190, 60, 150, "#b0c4dc", 0.9)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(58, 4, 20, bottom=62), "#20283a", 0.7, rim=0.3)
    sc.reflect(62, "#1c2230", amount=0.4, darken=0.7, ripple=2)
    for y, amt in ((74, 0.25), (82, 0.35), (90, 0.5)):  # waves rolling in: broken crests, whiter near the shore
        em, d = sc.canvas()
        x = sc.rnd.randint(0, 10)
        while x < W:
            n = sc.rnd.randint(8, 26)
            yy = y + sc.rnd.randint(-2, 2)
            d.arc([x, yy, x + n, yy + 6], 200, 340, fill=255)
            x += n + sc.rnd.randint(4, 16)
        sc.img = np.where(sc.m(em)[..., None], lerp(sc.img, rgb("#c8d2e0"), amt), sc.img)
    # the shingle, rocks, an upturned boat and a fisher with a lantern by it
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 98), (70, 94), (150, 100), (246, 96), (246, 126)], fill=255)
    sc.layer(sc.m(im), "#262c38", 0.0, rim=0.6, wash=0.8, texture=0.35, tex_scale=2)
    im, d = sc.canvas()
    for x, y, w, h in [(4, 104, 40, 22), (200, 98, 46, 30), (160, 108, 26, 12)]:
        sc.crag(d, [(x, y), (x + w * 0.2, y - h), (x + w * 0.7, y - h * 1.1), (x + w, y)], rough=2, step=3)
    d.chord([66, 90, 116, 110], 180, 360, fill=255)
    lx, ly = sc.person(d, 132, 97, tool="lantern", facing=-1, h=21)
    d.line([(138, 99), (156, 66)], fill=255)
    sc.layer(sc.m(im), "#10141c", 0.0, rim=1.0)
    _lamp(sc, int(lx), int(ly), colour="#ffd27a", r=8)
    em, d = sc.canvas()
    d.ellipse([92, 112, 100, 117], fill=255)
    sc.emissive(sc.m(em), "#a83a2e")
    sc.rain(180, "#8a96a8", slant=-1, length=4)
    return sc.done(gamma=0.8)


def bleakridge():
    sc = Scene(403, haze="#6a7890", ambient=0.3)
    sc.sky([(0, "#0a0c12"), (30, "#161c28"), (56, "#2e384a"), (80, "#5a6a80")], smoke="#2a3242", smoke_amount=0.4)
    sc.glow(70, 64, 90, "#b8cce4", 0.4)
    sc.light(70, 66, 180, "#c8dcf0", 1.0)
    sc.prepare_light()
    im, d = sc.canvas()
    sc.crag(d, [(0, 80), (40, 50), (70, 58), (120, 22), (160, 44), (200, 34), (246, 56), (246, 126), (0, 126)], rough=3, step=4)
    sc.layer(sc.m(im), "#3a4658", 0.6, rim=0.6)
    snow, d = sc.canvas()
    d.polygon([(120, 22), (110, 38), (122, 34), (128, 42), (138, 34), (146, 38)], fill=255)
    d.polygon([(40, 50), (34, 60), (44, 56), (52, 62)], fill=255)
    sc.img = np.where(sc.m(snow)[..., None], lerp(sc.img, rgb("#d8e2ee"), 0.7), sc.img)
    sc.fog(70, 7, "#a8b8cc", 0.35)
    im, d = sc.canvas()
    sc.crag(d, [(0, 104), (60, 86), (130, 92), (200, 80), (246, 88), (246, 126), (0, 126)], rough=2, step=4)
    _ice(sc, d, 86, 10, 8, 20)
    sc.layer(sc.m(im), "#202838", 0.2, rim=0.9, texture=0.25, tex_scale=3)
    # a pitbear on the ridge, a hunter with a spear facing it
    im, d = sc.canvas()
    eye = sc.beast(d, "bear", 148, 86, s=1, k=1.15)
    sc.person(d, 98, 90, tool=None, facing=1, h=20)
    d.line([(90, 94), (118, 70)], fill=255)
    d.polygon([(117, 71), (122, 65), (121, 72)], fill=255)
    d.polygon([(0, 126), (0, 112), (80, 108), (246, 114), (246, 126)], fill=255)
    sc.layer(sc.m(im), "#0e1018", 0.0, rim=1.0)
    em, d = sc.canvas()
    d.point((int(eye[0]), int(eye[1])), fill=255)
    sc.emissive(sc.m(em), "#ff3a2a", bloom=0.8, bloom_r=2)
    for _ in range(150):  # wind-driven snow
        x, y = sc.rnd.randrange(W - 4), sc.rnd.randrange(H)
        sc.img[y, x:x + 3] = lerp(sc.img[y, x:x + 3], rgb("#dce6f4"), 0.6)
    return sc.done()


# ---------------------------------------------------------------- layer 5: the Abyss
def drowned_deep():
    sc = Scene(501, haze="#2a1a3a", ambient=0.2)
    sc.sky([(0, "#040408"), (30, "#0a0812"), (50, "#16102a")], smoke="#120c1e", smoke_amount=0.4)
    sc.light(140, 90, 90, "#9a6ad8", 1.0)
    sc.light(84, 34, 70, "#f0c060", 1.4)
    sc.prepare_light()
    water, d = sc.canvas()
    d.rectangle([0, 50, W, H], fill=255)
    sc.layer(sc.m(water), "#08060e", 0.0, rim=0.0, wash=0.5, texture=0.2, tex_scale=6)
    for y in range(52, H, 3):
        for x in range(sc.rnd.randrange(10), W, sc.rnd.randint(16, 34)):
            sc.img[y, x:x + sc.rnd.randint(4, 12)] = lerp(sc.img[y, x], rgb("#2a2044"), 0.6)
    sc.glow(140, 90, 70, "#7a4ac0", 0.6)
    sc.glow(140, 90, 18, "#d6c2f6", 0.8)
    # something vast under the boat
    im, d = sc.canvas()
    for k in range(4):
        x0 = 104 + k * 20
        pts = [(x0 + 10 * math.sin(t / 3.2 + k * 1.3), 126 - t * 3) for t in range(0, 24 - k * 2)]
        for i in range(len(pts) - 1):
            d.line([pts[i], pts[i + 1]], fill=255, width=max(1, 5 - i // 5))
    sc.layer(sc.m(im), "#1e1430", 0.2, rim=0.8)
    # the boat, a lantern, a line going down
    im, d = sc.canvas()
    d.polygon([(30, 48), (98, 48), (90, 57), (40, 57)], fill=255)
    d.polygon([(30, 48), (26, 44), (34, 48)], fill=255)
    sc.person(d, 54, 49, tool="rod", facing=1, h=19)
    d.rectangle([78, 30, 79, 48], fill=255)
    d.line([(79, 31), (84, 31)], fill=255)
    d.line([(122, 26), (126, 92)], fill=255)
    sc.layer(sc.m(im), "#140f22", 0.0, rim=1.3, wash=0.6)
    em, d = sc.canvas()   # the lantern's light lying on the water
    for y in range(58, 90, 2):
        w = 3 + (y - 58) * 0.3
        x0 = 84 - w + sc.rnd.uniform(-2, 2)
        d.line([(x0, y), (x0 + w * 2 * sc.rnd.uniform(0.4, 1), y)], fill=255)
    sc.img = np.where(sc.m(em)[..., None], lerp(sc.img, rgb("#c09040"), 0.45), sc.img)
    _lamp(sc, 84, 34, colour="#ffd27a", r=12, bloom=1.8)
    em, d = sc.canvas()
    for _ in range(8):  # voidpearls
        x, y = sc.rnd.randint(118, 170), sc.rnd.randint(80, 104)
        d.point((x, y), fill=255)
    sc.emissive(sc.m(em), "#f0e6ff", bloom=0.6, bloom_r=2)
    particles(sc, 30, "#5a4a7a", 0, 50)
    return sc.done(vignette=0.5)


# ---------------------------------------------------------------- above: the guild's farms in Last Lantern
def _surface(sc, maw_x=40):
    """Dusk over Last Lantern: a cold sky, the Maw's red glow low on the horizon."""
    sc.sky([(0, "#1a2030"), (30, "#2e3448"), (56, "#5a5262"), (76, "#a07060")], smoke="#3a3a4a", smoke_amount=0.35, smoke_scale=50)
    sc.glow(maw_x, 80, 70, "#d0482a", 0.45)
    sc.glow(170, 74, 120, "#e0a070", 0.25)
    sc.light(170, 72, 190, "#f0b080", 0.9)
    sc.light(maw_x, 82, 80, "#ff5030", 0.6)
    sc.prepare_light()
    sc.layer(sc.ridge_mask(70, 5, 70), "#3a3a4a", 0.8, rim=0.2)
    sc.fog(76, 6, "#a08080", 0.35)


def _town(sc, d, x0, x1, base, gable=True):
    """Roofs of Last Lantern along the horizon. Returns window spots."""
    windows = []
    x = x0
    while x < x1:
        w = sc.rnd.randint(10, 18)
        h = sc.rnd.randint(6, 12)
        d.rectangle([x, base - h, x + w, base], fill=255)
        d.polygon([(x - 1, base - h), (x + w / 2, base - h - w * 0.45), (x + w + 1, base - h)], fill=255)
        if sc.rnd.random() < 0.4:
            d.rectangle([x + w - 4, base - h - w * 0.5 - 3, x + w - 2, base - h], fill=255)
        if sc.rnd.random() < 0.7:
            windows.append((x + sc.rnd.randint(2, w - 3), base - sc.rnd.randint(3, h - 2)))
        x += w + sc.rnd.randint(0, 3)
    return windows


def _windows(sc, spots):
    em, d = sc.canvas()
    for x, y in spots:
        d.rectangle([x, y, x + 1, y + 1], fill=255)
    sc.emissive(sc.m(em), "#ffc870", bloom=0.5, bloom_r=2)


def home_fields():
    sc = Scene(601, haze="#8a7a80", ambient=0.32)
    _surface(sc, maw_x=30)
    im, d = sc.canvas()
    spots = _town(sc, d, 120, 246, 80)
    d.rectangle([150, 52, 158, 80], fill=255)   # the guild hall's lantern tower
    d.polygon([(147, 52), (154, 42), (161, 52)], fill=255)
    sc.layer(sc.m(im) | sc.ridge_mask(80, 1, 30, bottom=82), "#2a2a36", 0.45, rim=0.5)
    _windows(sc, spots + [(153, 56)])
    _lamp(sc, 154, 55, r=4, bloom=0.8)
    # wheat in rows running to the town, a farmhand with a hoe, a fence
    for top, col, dep in [(82, "#7a6a3a", 0.35), (92, "#8a7432", 0.15), (104, "#6a5420", 0.0)]:
        im, d = sc.canvas()
        d.rectangle([0, top, W, H], fill=255)
        for x in range(0, W, 2):
            y = top + sc.rnd.randint(0, 3)
            d.line([(x, y), (x + sc.rnd.randint(-1, 1), y - sc.rnd.randint(2, 3 + (top - 80) // 4))], fill=255)
        sc.layer(sc.m(im), col, dep, rim=0.5, wash=0.9, texture=0.2, tex_scale=2)
    im, d = sc.canvas()
    sc.person(d, 70, 98, tool="hoe", facing=1, h=21)
    for x in range(140, 246, 14):
        d.rectangle([x, 96, x + 1, 108], fill=255)
    d.line([(140, 99), (246, 97)], fill=255)
    d.line([(140, 104), (246, 102)], fill=255)
    for _ in range(4):
        sc.beast(d, "crow", sc.rnd.randint(60, 200), sc.rnd.randint(22, 44), k=1.3)
    sc.layer(sc.m(im), "#1a1814", 0.0, rim=1.0)
    return sc.done()


def tilled_acres():
    sc = Scene(602, haze="#8a7a80", ambient=0.32)
    _surface(sc, maw_x=210)
    im, d = sc.canvas()
    spots = _town(sc, d, 0, 90, 82)
    sc.layer(sc.m(im) | sc.ridge_mask(82, 1, 30, bottom=84), "#2a2a36", 0.45, rim=0.5)
    _windows(sc, spots)
    # furrows converging on the horizon
    im, d = sc.canvas()
    d.rectangle([0, 84, W, H], fill=255)
    sc.layer(sc.m(im), "#4a3828", 0.1, rim=0.3, wash=0.9, texture=0.3, tex_scale=3)
    fur, d = sc.canvas()
    for i in range(-14, 30):
        d.line([(124 + i * 6, 84), (124 + i * 26, 126)], fill=255)
    sc.img = np.where(sc.m(fur)[..., None], sc.img * 0.62, sc.img)
    for _ in range(60):  # seedlings and potato tops
        x, y = sc.rnd.randrange(W), sc.rnd.randint(88, 124)
        sc.img[y, x] = rgb("#6a8a3a") * (0.7 + 0.3 * (y - 88) / 36)
    # a plough horse and its driver, a cart of sacks
    im, d = sc.canvas()
    hx, hy = 150, 96
    d.ellipse([hx, hy - 16, hx + 26, hy - 6], fill=255)
    d.polygon([(hx + 22, hy - 14), (hx + 30, hy - 24), (hx + 34, hy - 22), (hx + 30, hy - 12)], fill=255)
    d.polygon([(hx + 30, hy - 24), (hx + 38, hy - 20), (hx + 36, hy - 17), (hx + 32, hy - 19)], fill=255)
    for lx in (3, 7, 19, 23):
        d.line([(hx + lx, hy - 8), (hx + lx, hy)], fill=255, width=2)
    d.line([(hx, hy - 12), (hx - 6, hy - 6)], fill=255)
    d.line([(hx + 2, hy - 10), (hx - 16, hy - 4)], fill=255)
    d.polygon([(hx - 18, hy - 4), (hx - 12, hy - 6), (hx - 10, hy)], fill=255)  # the plough
    sc.person(d, hx - 26, hy, tool=None, facing=1, h=20, pose=1)
    sc.person(d, 70, 104, tool="basket", facing=1, h=21, pose=1)
    for x, y in ((40, 104), (48, 106)):
        d.ellipse([x, y - 8, x + 8, y], fill=255)   # seed sacks
    sc.layer(sc.m(im), "#1a1612", 0.0, rim=1.0)
    for _ in range(14):  # seed flung from the hand
        x, y = sc.rnd.randint(78, 96), sc.rnd.randint(88, 100)
        sc.img[y, x] = rgb("#d8c090")
    return sc.done()


def beehives():
    sc = Scene(603, haze="#8a7a80", ambient=0.32)
    _surface(sc, maw_x=200)
    sc.light(120, 96, 50, "#ffb050", 0.8)
    sc.prepare_light()
    im, d = sc.canvas()
    sc.layer(sc.ridge_mask(84, 2, 40), "#3a3c30", 0.4, rim=0.5)
    # an orchard tree, the skeps on a bench, a keeper with a smoker
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 102), (246, 98), (246, 126)], fill=255)
    sc.layer(sc.m(im), "#2e3222", 0.0, rim=0.6, wash=0.9, texture=0.3, tex_scale=2)
    im, d = sc.canvas()
    d.polygon([(32, 104), (36, 70), (40, 70), (44, 104)], fill=255)
    for cx, cy, r in [(38, 52, 22), (24, 62, 14), (54, 60, 15), (40, 38, 14)]:
        d.ellipse([cx - r, cy - r * 0.8, cx + r, cy + r * 0.8], fill=255)
    sc.layer(sc.m(im), "#26301c", 0.0, rim=0.9, texture=0.35, tex_scale=2)
    im, d = sc.canvas()
    d.rectangle([84, 96, 178, 99], fill=255)
    for x in (88, 172):
        d.rectangle([x, 99, x + 2, 106], fill=255)
    sc.layer(sc.m(im), "#2a1e14", 0.0, rim=0.8)
    for cx in (98, 122, 146, 168):  # straw skeps, banded
        sk, d = sc.canvas()
        d.ellipse([cx - 9, 78, cx + 9, 100], fill=255)
        d.rectangle([cx - 9, 89, cx + 9, 96], fill=255)
        m = sc.m(sk) & (sc.yy < 97)
        sc.layer(m, "#b08a3a", 0.0, rim=0.6, wash=0.7, texture=0.1)
        for y in range(81, 96, 3):
            sc.img[y, cx - 8:cx + 9] = np.where(m[y, cx - 8:cx + 9, None], sc.img[y, cx - 8:cx + 9] * 0.65, sc.img[y, cx - 8:cx + 9])
        sc.img[93:96, cx - 1:cx + 2] = rgb("#140c08")
    im, d = sc.canvas()
    sc.person(d, 204, 100, tool=None, facing=-1, h=21)
    d.ellipse([186, 76, 196, 86], fill=255)     # the keeper's veiled hat
    d.rectangle([188, 84, 194, 90], fill=255)
    d.line([(198, 88), (188, 92)], fill=255)
    d.rectangle([184, 89, 188, 96], fill=255)   # smoker
    sc.layer(sc.m(im), "#1a1814", 0.0, rim=1.0)
    for _ in range(4):  # smoke
        sc.glow(176 - _ * 6, 84 - _ * 5, 8, "#c0b8b0", 0.35, squash=0.8)
    em, d = sc.canvas()
    for _ in range(40):  # bees
        d.point((sc.rnd.randint(80, 190), sc.rnd.randint(60, 96)), fill=255)
    sc.emissive(sc.m(em), "#f0c040")
    return sc.done()


def glasshouse():
    sc = Scene(604, haze="#8a7a80", ambient=0.32)
    _surface(sc, maw_x=40)
    sc.light(124, 74, 90, "#ffa060", 1.2)
    sc.prepare_light()
    im, d = sc.canvas()
    for x in range(160, 246, 16):
        d.polygon([(x, 92), (x + 8, 64), (x + 16, 92)], fill=255)
    for x in range(0, 70, 16):
        d.polygon([(x, 92), (x + 8, 68), (x + 16, 92)], fill=255)
    sc.layer(sc.m(im) | sc.ridge_mask(88, 2, 40), "#1e2a22", 0.4, rim=0.5)
    im, d = sc.canvas()
    d.polygon([(0, 126), (0, 100), (246, 100), (246, 126)], fill=255)
    sc.layer(sc.m(im), "#26281e", 0.0, rim=0.6, wash=0.9, texture=0.3, tex_scale=2)
    # the glasshouse, lit warm from the stove inside, emberpeppers in rows
    gx0, gx1, gy = 66, 182, 100
    em, d = sc.canvas()
    d.polygon([(gx0, gy), (gx0, 66), (124, 44), (gx1, 66), (gx1, gy)], fill=255)
    sc.emissive(sc.m(em), "#d89a6a", bloom=0.6, bloom_r=6)
    inner, d = sc.canvas()
    d.polygon([(gx0 + 2, gy), (gx0 + 2, 67), (124, 46), (gx1 - 2, 67), (gx1 - 2, gy)], fill=255)
    m = sc.m(inner)
    grad = np.clip((sc.yy - 46) / 54, 0, 1)
    warm = lerp(rgb("#f0c890"), rgb("#c06a3a"), grad[..., None])
    sc.img = np.where(m[..., None], warm, sc.img)
    frame, d = sc.canvas()
    d.line([(gx0, gy), (gx0, 66), (124, 44), (gx1, 66), (gx1, gy)], fill=255, width=2)
    for x in range(gx0, gx1 + 1, 12):
        top = 66 - (x - gx0) * 22 / 58 if x < 124 else 44 + (x - 124) * 22 / 58
        d.line([(x, gy), (x, top)], fill=255)
    for y in (78, 90):
        d.line([(gx0, y), (gx1, y)], fill=255)
    d.line([(124, 44), (124, gy)], fill=255)
    d.rectangle([150, 30, 155, 52], fill=255)  # stove pipe
    sc.layer(sc.m(frame), "#2a2420", 0.0, rim=0.6)
    em, d = sc.canvas()
    for row in (86, 96):
        for x in range(gx0 + 6, gx1 - 4, 7):
            d.line([(x, row), (x, row - 5)], fill=255)
    sc.flat(sc.m(em), "#3a5a22")
    for row in (84, 94):
        for x in range(gx0 + 6, gx1 - 4, 7):
            sc.img[row - 3, x + 1] = rgb("#e0281a")
    for k in range(4):
        sc.glow(153 + k * 3, 26 - k * 6, 6 + k * 2, "#b0a8a8", 0.3, squash=1.0)
    im, d = sc.canvas()
    sc.person(d, 200, 104, tool="basket", facing=-1, h=21)
    sc.layer(sc.m(im), "#1a1814", 0.0, rim=1.0)
    return sc.done()


BANNERS = {
    "forest_copse": cinderwood, "harlow_site": gatepit, "site_mossward_meadows": ashmeadow,
    "site_millbrook_pond": cinder_pool, "site_hollow_fields": hollow_fields, "dungeon_calder_keep": fallen_keep,
    "forest_oakwood": weepingwood, "mine_deepdelve": sulphur_deeps, "site_fenmire": bloodfen, "site_silverrun": styx_shallows,
    "site_greyfang_hills": houndfang_hills, "dungeon_sunken_abbey": drowned_abbey,
    "site_sunreach": ember_slopes, "site_glasswater": lake_of_glass, "site_elkmoor": gorehorn_moor,
    "site_frostvale": laments_edge, "site_greywater_coast": shore_of_tears, "site_bleakridge": bleakridge,
    "site_drowned_deep": drowned_deep,
    "site_home_fields": home_fields, "site_tilled_acres": tilled_acres, "site_beehives": beehives, "site_glasshouse": glasshouse,
}

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].endswith(".png") else None
    only = [a for a in sys.argv[1:] if not a.endswith(".png")]
    names = [n for n, f in BANNERS.items() if not only or n in only or f.__name__ in only]
    for name in names:
        BANNERS[name]().save("assets/ui/art/%s.png" % name)
    if out:
        cols = 2 if len(names) > 1 else 1
        sheet = Image.new("RGBA", (cols * 250, ((len(names) + cols - 1) // cols) * 130), (40, 30, 30, 255))
        for i, name in enumerate(names):
            sheet.alpha_composite(Image.open("assets/ui/art/%s.png" % name), ((i % cols) * 250 + 2, (i // cols) * 130 + 2))
        sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(out)
    print("painted %d banners" % len(names))
