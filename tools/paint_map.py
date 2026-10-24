"""Paint the region map and the crew figures for the Company chapter (run from the project root).

Writes:
  assets/ui/art/region_map.png      257x280, transparent, ink-on-parchment like the site art
  assets/ui/art/crew/*.png          9x11 crew figures: walk, work (axe / pick) and carry frames
  tools/map_roads.json              road polylines, used for the Path2D roads in the map scene

Everything is drawn pixel by pixel in the book palette, so it stays crisp at 2x.
"""
import json, math, os, random
from PIL import Image

INK = (61, 40, 36, 255)
SOFT = (122, 88, 74, 255)
FAINT = (176, 141, 117, 255)
WASH = (205, 178, 148, 255)
OX = (128, 44, 56, 255)
OX_LIGHT = (176, 74, 82, 255)
SKIN = (233, 196, 158, 255)
NONE = (0, 0, 0, 0)

W, H = 257, 280
rnd = random.Random(7)
img = Image.new("RGBA", (W, H), NONE)
px = img.load()


def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        px[int(x), int(y)] = c


def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, c)


def line_points(pts, step=1.0):
    out = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
        for i in range(n):
            t = i / n
            out.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t))
    out.append(pts[-1])
    return out


def smooth(pts, passes=2):
    # Chaikin smoothing so roads and the river curve gently.
    for _ in range(passes):
        out = [pts[0]]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            out.append((0.75 * x0 + 0.25 * x1, 0.75 * y0 + 0.25 * y1))
            out.append((0.25 * x0 + 0.75 * x1, 0.25 * y0 + 0.75 * y1))
        out.append(pts[-1])
        pts = out
    return pts


# --- Ground texture: sparse grass ticks and a few hills -------------------------
for _ in range(260):
    x, y = rnd.randrange(4, W - 4), rnd.randrange(4, H - 4)
    put(x, y, FAINT)
    if rnd.random() < 0.4:
        put(x + 1, y - 1, FAINT)


def hill(cx, cy, w):
    for i in range(-w, w + 1):
        y = cy - int(round((1 - (i / w) ** 2) * (w * 0.45)))
        put(cx + i, y, FAINT)


for (cx, cy, w) in [(30, 245, 9), (95, 255, 7), (215, 200, 8), (238, 140, 6), (25, 120, 6), (180, 30, 7)]:
    hill(cx, cy, w)

# --- River --------------------------------------------------------------------
river = smooth([(150, 0), (141, 45), (160, 95), (152, 140), (171, 185), (158, 230), (176, 280)], 3)
for (x, y) in line_points(river, 0.5):
    for dx in range(-2, 3):
        put(round(x) + dx, round(y), WASH)
for (x, y) in line_points(river, 0.5):
    put(round(x) - 3, round(y), FAINT)
    put(round(x) + 3, round(y), FAINT)
for i, (x, y) in enumerate(line_points(river, 6)):
    if i % 2 == 0:
        put(round(x), round(y), FAINT)  # current marks

# --- Roads (dotted) -----------------------------------------------------------
TOWN = (124, 206)
roads = {
    "mossward_copse": smooth([(112, 208), (96, 200), (80, 190), (64, 181)], 2),
    "old_oakwood": smooth([(117, 197), (104, 168), (94, 132), (78, 100), (66, 84)], 2),
    "harlow": smooth([(137, 199), (150, 178), (163, 152), (182, 124), (197, 102), (205, 92)], 2),
    "greyvein_quarry": smooth([(137, 199), (150, 178), (157, 167), (172, 162), (195, 159), (214, 156), (224, 153)], 2),
    "deepdelve": smooth([(137, 199), (150, 178), (163, 152), (182, 124), (197, 102), (205, 92), (211, 82), (218, 71), (226, 61)], 2),
}
fog_roads = {
    "fenmire": smooth([(140, 214), (170, 232), (200, 247), (224, 256)], 2),
}
for name, pts in roads.items():
    for i, (x, y) in enumerate(line_points(pts, 1.0)):
        if i % 3 != 2:
            put(round(x), round(y), SOFT)
for name, pts in fog_roads.items():
    for i, (x, y) in enumerate(line_points(pts, 1.0)):
        if i % 4 == 0:
            put(round(x), round(y), FAINT)

# Bridge where the Harlow road crosses the river.
for dx in range(-4, 5):
    put(157 + dx, 166, INK)
    put(157 + dx, 170, INK)
for dx in (-4, 4):
    for dy in range(166, 171):
        put(157 + dx, dy, INK)
rect(154, 167, 160, 169, FAINT)


# --- Forests ------------------------------------------------------------------
def pine(x, y, dark=False):
    body = SOFT if dark else FAINT
    edge = INK if dark else SOFT
    for row in range(8):
        half = (row + 1) // 2
        for dx in range(-half, half + 1):
            put(x + dx, y + row, body)
        put(x - half, y + row, edge)
        put(x + half, y + row, edge)
    put(x, y - 1, edge)
    put(x, y + 8, INK)


def oak(x, y):
    for dy in range(-3, 4):
        for dx in range(-4, 5):
            if dx * dx / 16 + dy * dy / 9 <= 1.0:
                put(x + dx, y + dy, SOFT)
    for dx in range(-4, 5):
        for dy in range(-3, 4):
            if 0.75 < dx * dx / 16 + dy * dy / 9 <= 1.0 and dy >= 0:
                put(x + dx, y + dy, INK)
    put(x - 1, y - 2, FAINT)
    put(x - 2, y - 1, FAINT)
    put(x, y + 4, INK)
    put(x, y + 5, INK)


copse = []
for _ in range(80):
    x, y = 50 + rnd.gauss(0, 11), 166 + rnd.gauss(0, 8)
    if math.hypot(x - 64, y - 181) > 7 and all(math.hypot(x - a, y - b) > 6.0 for a, b in copse):
        copse.append((round(x), round(y)))
for (x, y) in sorted(copse, key=lambda p: p[1]):
    pine(x, y)
for _ in range(500):
    x, y = 58 + rnd.gauss(0, 16), 66 + rnd.gauss(0, 11)
    if (x + y) % 3 == 0:
        put(round(x), round(y), FAINT)
oaks = []
for _ in range(120):
    x, y = 58 + rnd.gauss(0, 17), 66 + rnd.gauss(0, 12)
    if all(math.hypot(x - a, y - b) > 6.5 for a, b in oaks):
        oaks.append((x, y))
for (x, y) in sorted(oaks, key=lambda p: p[1]):
    oak(round(x), round(y))


# --- Harlow mountains -----------------------------------------------------------
def mountain(cx, base, w, h):
    for row in range(h):
        y = base - h + row
        half = int(w * row / h / 2)
        for dx in range(-half, half + 1):
            put(cx + dx, y, FAINT if dx < 0 else WASH)
        put(cx - half, y, SOFT)
        put(cx + half, y, INK)
        if row > 3 and row % 2 == 0:
            for dx in range(2, half - 1, 3):
                put(cx + dx, y, FAINT)
    for dx in range(-w // 2, w // 2 + 1):
        put(cx + dx, base, INK)
    # snow-free ridge line
    for row in range(min(4, h)):
        put(cx, base - h + row, INK)


for (cx, base, w, h) in [(214, 60, 22, 18), (240, 66, 22, 20), (190, 70, 20, 16), (250, 96, 16, 14), (196, 86, 26, 22), (222, 94, 32, 30), (238, 82, 18, 16), (176, 94, 18, 14)]:
    mountain(cx, base, w, h)
# Deepdelve: a dwarven gate between the high peaks.
rect(222, 52, 231, 53, INK)
for y in range(54, 62):
    put(222, y, INK); put(231, y, INK)
rect(224, 55, 229, 61, INK)
put(225, 54, INK); put(228, 54, INK)
put(221, 56, (214, 160, 62, 255)); put(232, 56, (214, 160, 62, 255))
# Greyvein Quarry: a stepped pit in the eastern hills with a small derrick.
for i, (x0, y0, x1, y1) in enumerate([(214, 144, 240, 160), (217, 147, 237, 158), (220, 150, 234, 156)]):
    rect(x0, y0, x1, y1, [FAINT, SOFT, INK][i])
    for x in range(x0, x1 + 1):
        put(x, y0, INK if i == 0 else FAINT)
for y in range(136, 146):
    put(212 + (146 - y) // 3, y, INK)
    put(216 - (146 - y) // 3 + 4, y, INK)
for x in range(212, 226):
    put(x, 136, INK)
put(225, 137, SOFT); put(225, 138, SOFT); put(225, 139, INK)
# Mine entrance with timber frame.
rect(204, 82, 210, 88, INK)
rect(203, 81, 211, 81, SOFT)
put(203, 82, SOFT); put(211, 82, SOFT)
for y in range(82, 89):
    put(203, y, SOFT)
    put(211, y, SOFT)

# --- Town of Mossward -----------------------------------------------------------
cx, cy = TOWN
def field(x0, y0, x1, y1, slant):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if (x + y * slant) % 3 == 0:
                put(x, y, FAINT)
    for x in range(x0, x1 + 1):
        put(x, y0, SOFT); put(x, y1, SOFT)
    for y in range(y0, y1 + 1):
        put(x0, y, SOFT); put(x1, y, SOFT)


field(80, 214, 97, 226, 1)
field(92, 238, 108, 248, -1)
field(142, 226, 154, 238, 0)
for a in range(0, 360, 3):
    x = cx + 25 * math.cos(math.radians(a))
    y = cy + 15 * math.sin(math.radians(a))
    put(round(x), round(y), INK if a % 9 == 0 else SOFT)


def house(x, y, w=5):
    for row in range(3):
        for dx in range(row, w - row):
            put(x + dx, y + row - 3, SOFT if row else INK)
    rect(x, y, x + w - 1, y + 3, WASH)
    for dx in range(w):
        put(x + dx, y + 3, INK)
    put(x, y, SOFT); put(x + w - 1, y, SOFT)
    put(x + w // 2, y + 2, INK)


HOUSES = [(113, 197), (120, 194), (127, 196), (134, 199), (106, 203), (140, 205), (110, 210), (117, 204), (131, 207), (137, 213), (104, 213), (112, 217)]
for (x, y) in sorted(HOUSES, key=lambda p: p[1]):
    house(x, y)
# Guildhall: the company's own building, bigger, with a banner.
for row in range(4):
    for dx in range(row, 15 - row):
        put(118 + dx, 211 + row - 4, OX if row else INK)
rect(118, 211, 132, 217, FAINT)
for dx in range(15):
    put(118 + dx, 217, INK)
put(118, 211, SOFT); put(132, 211, SOFT)
for y in range(214, 217):
    put(124, y, INK); put(125, y, INK)
put(120, 213, INK); put(130, 213, INK)
for y in range(199, 207):
    put(133, y, INK)
rect(134, 199, 138, 201, OX_LIGHT)
put(134, 202, OX)

# --- Fog over unsurveyed lands ------------------------------------------------------
def fog(x0, y0, x1, y1):
    for y in range(y0, y1):
        for x in range(x0, x1):
            if (x + y) % 4 == 0 and rnd.random() < 0.85:
                cxm, cym = (x0 + x1) / 2, (y0 + y1) / 2
                if ((x - cxm) / ((x1 - x0) / 2)) ** 2 + ((y - cym) / ((y1 - y0) / 2)) ** 2 <= 1.0:
                    put(x, y, FAINT)


fog(196, 230, 254, 276)   # Fenmire marsh: foraging, not surveyed yet
fog(96, 6, 168, 44)       # Old ruins: dungeons, not surveyed yet

# --- Compass ------------------------------------------------------------------
ccx, ccy = 30, 228
for d in range(-6, 7):
    put(ccx, ccy + d, SOFT)
    put(ccx + d, ccy, FAINT)
for d in range(1, 5):
    put(ccx - 1, ccy - 6 + d, INK)
put(ccx, ccy - 8, INK); put(ccx - 1, ccy - 9, INK); put(ccx + 1, ccy - 9, INK); put(ccx - 1, ccy - 10, INK); put(ccx + 1, ccy - 8, INK)

for x in range(W):
    put(x, 0, INK); put(x, H - 1, INK); put(x, 2, FAINT); put(x, H - 3, FAINT)
for y in range(H):
    put(0, y, INK); put(W - 1, y, INK); put(2, y, FAINT); put(W - 3, y, FAINT)
CHIMNEYS = [(115, 192), (136, 197), (129, 202), (108, 201)]
for (x, y) in CHIMNEYS:
    put(x, y, INK); put(x, y + 1, INK)

os.makedirs("assets/ui/art/crew", exist_ok=True)
img.save("assets/ui/art/region_map.png")

# --- Crew figures (9x11) --------------------------------------------------------------
def figure(frame, tool=None, carry=False, swing=0):
    f = Image.new("RGBA", (9, 11), NONE)
    p = f.load()
    def s(x, y, c):
        if 0 <= x < 9 and 0 <= y < 11:
            p[x, y] = c
    # head
    for x, y in [(3, 1), (4, 1), (5, 1), (3, 2), (4, 2), (5, 2)]:
        s(x, y, SKIN)
    for x in (3, 4, 5):
        s(x, 0, INK)
    s(2, 1, INK); s(6, 1, INK); s(2, 2, INK); s(6, 2, INK)
    # tunic
    for y in range(3, 7):
        for x in range(3, 6):
            s(x, y, OX)
    s(2, 4, OX_LIGHT); s(6, 4, OX_LIGHT)
    for y in range(3, 7):
        s(2 if y > 3 else 2, y, INK) if y in (5, 6) else None
    s(3, 7, INK); s(5, 7, INK)
    # legs (walk cycle)
    if frame == 0:
        s(3, 8, INK); s(3, 9, INK); s(5, 8, INK); s(6, 9, INK)
    else:
        s(3, 8, INK); s(2, 9, INK); s(5, 8, INK); s(5, 9, INK)
    s(3, 10, INK) if frame == 0 else s(2, 10, INK)
    s(6, 10, INK) if frame == 0 else s(5, 10, INK)
    if carry:
        for x, y in [(0, 3), (1, 3), (0, 4), (1, 4), (0, 5), (1, 5), (1, 2)]:
            s(x, y, FAINT)
        s(0, 2, SOFT); s(2, 3, SOFT)
    if tool:
        head = INK
        if swing == 0:  # raised
            for y in range(0, 5):
                s(7, y, SOFT)
            if tool == "axe":
                s(8, 0, head); s(8, 1, head); s(6, 0, head)
            else:
                s(6, 0, head); s(8, 0, head); s(8, 1, head); s(6, 1, head)
        else:  # struck
            for x in range(6, 9):
                s(x, 6, SOFT)
            if tool == "axe":
                s(8, 7, head); s(8, 8, head)
            else:
                s(8, 5, head); s(8, 7, head); s(8, 8, head)
    return f


frames = {
    "walk_0": figure(0), "walk_1": figure(1),
    "carry_0": figure(0, carry=True), "carry_1": figure(1, carry=True),
    "axe_0": figure(0, "axe", swing=0), "axe_1": figure(0, "axe", swing=1),
    "pick_0": figure(0, "pick", swing=0), "pick_1": figure(0, "pick", swing=1),
}
for name, f in frames.items():
    f.save("assets/ui/art/crew/%s.png" % name)

out = {k: [[round(x, 1), round(y, 1)] for x, y in v] for k, v in roads.items()}
out["_chimneys"] = [[x, y - 1] for x, y in CHIMNEYS]
json.dump(out, open("tools/map_roads.json", "w"), indent=1)
puff = Image.new("RGBA", (3, 3), NONE)
for x, y in [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)]:
    puff.putpixel((x, y), FAINT)
puff.putpixel((1, 1), WASH)
puff.save("assets/ui/art/crew/smoke.png")

# Grave marker for fallen gear: a sword planted in a small mound (7x9).
grave = Image.new("RGBA", (7, 9), NONE)
for y in range(0, 6):
    grave.putpixel((3, y), SOFT if y else INK)
for x in (1, 2, 4, 5):
    grave.putpixel((x, 2), INK)
for x in range(0, 7):
    grave.putpixel((x, 8), INK)
for x in range(1, 6):
    grave.putpixel((x, 7), FAINT)
grave.putpixel((3, 6), INK); grave.putpixel((2, 6), FAINT); grave.putpixel((4, 6), FAINT)
grave.save("assets/ui/art/crew/grave.png")

# Glint shown over a crew member carrying something found among the fallen (5x5).
for i, size in enumerate((1, 2)):
    glint = Image.new("RGBA", (5, 5), NONE)
    gold, light = (214, 160, 62, 255), (246, 222, 140, 255)
    glint.putpixel((2, 2), light)
    for d in range(1, size + 1):
        for (x, y) in [(2 - d, 2), (2 + d, 2), (2, 2 - d), (2, 2 + d)]:
            glint.putpixel((x, y), gold)
    glint.save("assets/ui/art/crew/glint_%d.png" % i)
print("painted region map, %d crew frames" % len(frames))
