"""Paint the descent map for the Company page (run from the project root).

Writes:
  assets/ui/art/region_map.png   257x280: Last Lantern on the surface, the Maw, and the five
                                 layers of hell below it, in coloured washes over the page
  tools/map_roads.json           the roads crews walk (town -> the Maw -> a site), and chimneys

Site labels, grave markers and layer names are editor nodes placed by tools/build_pages.py
(company_map); keep MAP_SPOTS there in step with SPOTS here. Crew figures still come from
tools/paint_map.py."""
import json
import math
import random
from PIL import Image, ImageDraw

W, H = 257, 280
INK = (61, 40, 36, 255)
SOFT = (122, 88, 74, 255)
FAINT = (176, 141, 117, 255)
WASH = (205, 178, 148, 255)
GOLD = (214, 160, 62, 255)
EMBER = (196, 84, 40, 255)
SAP = (150, 40, 44, 255)
rnd = random.Random(5)

## Layer bands: y0, y1, inset at the top, inset at the bottom, wash, light edge, speckle.
LAYERS = [
    (66, 146, 4, 12, (201, 171, 148), (216, 192, 168), (176, 146, 126)),
    (148, 196, 14, 24, (190, 146, 136), (206, 168, 158), (160, 104, 98)),
    (198, 230, 26, 36, (204, 156, 118), (220, 180, 140), (214, 128, 74)),
    (232, 256, 38, 48, (170, 176, 186), (198, 204, 212), (140, 148, 160)),
    (258, 278, 50, 60, (126, 108, 120), (148, 130, 142), (96, 80, 96)),
]
TOWN = (128, 54)
MAW = (128, 64)
## Where each road ends: the crew works here. Site ids, trade regions and crypts.
SPOTS = {
    "mossward_copse": (44, 88), "harlow": (210, 90), "hunting": (38, 120), "fishing": (206, 118),
    "foraging": (90, 126), "calder_keep": (150, 124), "old_oakwood": (50, 180), "deepdelve": (206, 180),
    "farming": (40, 54),
}

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)


def band(y0, y1, a, b):
    return [(a, y0), (W - 1 - a, y0), (W - 1 - b, y1), (b, y1)]


# --- the layers -----------------------------------------------------------------------
for i, (y0, y1, a, b, wash, light, speck) in enumerate(LAYERS):
    poly = band(y0, y1, a, b)
    d.polygon(poly, fill=wash + (255,))
    d.polygon(band(y0, y0 + 3, a, a + (b - a) * 3 / (y1 - y0)), fill=light + (255,))
    for _ in range((y1 - y0) * 14):
        y = rnd.randint(y0 + 4, y1 - 2)
        t = (y - y0) / (y1 - y0)
        inset = a + (b - a) * t
        x = rnd.randint(int(inset) + 2, int(W - 2 - inset))
        d.point((x, y), fill=speck + (255,))
    d.line(poly + [poly[0]], fill=INK, width=1)
    # rock strata between layers
    if i + 1 < len(LAYERS):
        d.line([(b + 1, y1 + 1), (W - 2 - b, y1 + 1)], fill=SOFT)

# --- the surface, the town and the Maw ----------------------------------------------------
d.rectangle([0, 57, W - 1, 65], fill=SOFT)
d.line([(0, 57), (W - 1, 57)], fill=INK)
for x in range(0, W, 3):
    d.point((x, 56), fill=FAINT if x % 2 else WASH)
d.polygon([(112, 57), (144, 57), (136, 66), (120, 66)], fill=INK)   # the Maw
d.polygon([(118, 58), (138, 58), (133, 64), (123, 64)], fill=(40, 20, 18, 255))
d.point((128, 61), fill=EMBER)
chimneys = []
for x, w, h in [(96, 7, 10), (105, 6, 14), (113, 7, 9), (143, 7, 12), (152, 6, 9), (160, 7, 13)]:
    d.rectangle([x, 56 - h, x + w, 56], fill=SOFT)
    d.polygon([(x - 1, 56 - h), (x + w / 2, 50 - h), (x + w + 1, 56 - h)], fill=INK)
    d.rectangle([x + 2, 52 - h // 2, x + 3, 53 - h // 2], fill=GOLD)
    chimneys.append([x + w - 1, 52 - h])
# the lantern tower over the Maw
d.rectangle([125, 30, 131, 56], fill=INK)
d.polygon([(123, 30), (128, 24), (133, 30)], fill=INK)
d.rectangle([126, 31, 130, 35], fill=GOLD)
for r, a in [(9, 50), (6, 90), (3, 160)]:
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(over).ellipse([128 - r, 33 - r, 128 + r, 33 + r], fill=(240, 190, 90, a))
    img.alpha_composite(over)
d = ImageDraw.Draw(img)
# the wall at the Maw
d.rectangle([116, 52, 140, 56], fill=SOFT)
# Home Fields on the surface, left
for i, y in enumerate(range(46, 56, 3)):
    d.line([(14 + i, y), (66 - i, y)], fill=(150, 160, 90, 255) if i % 2 else (176, 150, 80, 255))
d.rectangle([70, 47, 76, 55], fill=SOFT)
d.polygon([(69, 47), (73, 43), (77, 47)], fill=INK)
for x in (6, 186, 200, 232):  # trees above, still green
    d.ellipse([x, 44, x + 8, 52], fill=(120, 130, 80, 255))
    d.line([(x + 4, 52), (x + 4, 56)], fill=SOFT)

# --- the descent path (dotted) -----------------------------------------------------------
TRUNK = [MAW, (128, 72), (114, 82), (142, 98), (116, 114), (140, 130), (128, 146), (128, 152), (112, 164),
         (144, 178), (128, 196), (128, 204), (116, 214), (138, 226), (128, 236), (120, 246), (132, 258), (128, 272)]


def polyline(pts, step=1.0):
    out = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
        for k in range(n):
            out.append((x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n))
    out.append(pts[-1])
    return out


for k, (x, y) in enumerate(polyline(TRUNK)):
    if k % 3 == 0:
        d.point((round(x), round(y)), fill=SOFT)

# --- things in the layers -----------------------------------------------------------------
def dead_tree(x, base, h, ember=False):
    d.line([(x, base), (x, base - h)], fill=INK)
    for k in range(3):
        y = base - h * (0.4 + 0.2 * k)
        s = -1 if k % 2 else 1
        d.line([(x, y), (x + s * h * 0.35, y - h * 0.3)], fill=INK)
    if ember:
        d.point((x, base - h // 2), fill=EMBER)


# Cinderwood: burnt trees
for x in range(20, 66, 6):
    dead_tree(x + rnd.randint(-1, 1), 86, rnd.randint(9, 14), ember=rnd.random() < 0.5)
# the Gatepit: a rock face and a lit adit
d.polygon([(192, 92), (198, 72), (214, 68), (232, 74), (240, 92)], fill=SOFT)
d.rectangle([207, 80, 215, 92], fill=INK)
d.rectangle([209, 83, 213, 92], fill=GOLD)
# Hollow Fields: grey grass and crows
for _ in range(60):
    x, y = rnd.randint(14, 64), rnd.randint(108, 124)
    d.line([(x, y), (x, y - 2)], fill=FAINT if rnd.random() < 0.6 else SOFT)
for x, y in [(24, 102), (34, 99), (50, 104)]:
    d.line([(x - 2, y - 1), (x, y), (x + 2, y - 1)], fill=INK)
# the Cinder Pool
d.ellipse([186, 108, 236, 122], fill=(150, 132, 124, 255), outline=SOFT)
for y in (112, 116):
    d.line([(196, y), (206, y)], fill=WASH)
    d.line([(214, y + 1), (224, y + 1)], fill=EMBER)
# Ashmeadow: pale flowers and red berries
for _ in range(40):
    x, y = rnd.randint(72, 108), rnd.randint(118, 130)
    d.point((x, y), fill=(230, 220, 206, 255) if rnd.random() < 0.6 else EMBER)
# the Fallen Keep
k = INK
d.polygon([(150, 127), (154, 120), (178, 120), (182, 127)], fill=SOFT)
d.rectangle([156, 108, 176, 121], fill=k)
d.rectangle([162, 98, 170, 121], fill=k)
for x in range(162, 171, 3):
    d.rectangle([x, 96, x + 1, 98], fill=k)
for x in range(156, 177, 3):
    d.rectangle([x, 106, x + 1, 108], fill=k)
d.rectangle([165, 116, 167, 121], fill=GOLD)
d.point((165, 102), fill=GOLD)
d.point((159, 112), fill=GOLD)
# Weepingwood: drooping trees with red sap
for x in range(30, 74, 9):
    base = 176
    d.line([(x, base), (x, base - 12)], fill=INK)
    for s in (-1, 1):
        d.line([(x, base - 12), (x + s * 5, base - 9), (x + s * 6, base - 4)], fill=INK)
    d.point((x + 3, base - 5), fill=SAP)
# the Sulphur Deeps: a yellow-lit gallery
d.polygon([(186, 182), (190, 160), (226, 156), (232, 182)], fill=SOFT)
d.rectangle([200, 168, 216, 182], fill=INK)
d.rectangle([202, 171, 214, 182], fill=(222, 200, 90, 255))
# the Brimstone Reach: lava seams
for x0 in (60, 170):
    pts = [(x0, 202)]
    for _ in range(5):
        pts.append((pts[-1][0] + rnd.randint(-4, 4), pts[-1][1] + 5))
    d.line(pts, fill=EMBER)
# the Frozen Lament: ice teeth
for x in range(56, 204, 12):
    d.polygon([(x, 254), (x + 3, 242 + rnd.randint(0, 4)), (x + 6, 254)], fill=(224, 230, 236, 255))
# the Abyss: the throne at the very bottom
d.rectangle([123, 266, 133, 276], fill=INK)
d.polygon([(121, 266), (124, 260), (128, 264), (132, 260), (135, 266)], fill=INK)
d.point((128, 270), fill=EMBER)

img.save("assets/ui/art/region_map.png")

# --- roads: town -> the Maw -> down the trunk -> across to the site -------------------------
def road(spot):
    x, y = spot
    if y < 60:  # surface: walk along the ground
        return polyline([TOWN, (TOWN[0] - 20, 55), (x, y)], 2.0)
    trunk = [TOWN, MAW]
    for p in TRUNK[1:]:
        if p[1] >= y - 4:
            break
        trunk.append(p)
    return polyline(trunk + [(x, y)], 2.0)


roads = {k: [[round(px, 1), round(py, 1)] for px, py in road(v)] for k, v in SPOTS.items()}
roads["_chimneys"] = chimneys
json.dump(roads, open("tools/map_roads.json", "w"), indent=1)
print("painted the descent map, %d roads" % len(SPOTS))
