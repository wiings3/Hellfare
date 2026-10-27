"""Paint the descent map for the Company page (run from the project root).

A cutaway of the ground under Last Lantern: the town and the guild's farms on the surface at dusk,
the Maw opening under the lantern tower, and the five layers of hell below it as lit cavern
ledges, narrowing as they go down, each in its own light (ember, blood red, brimstone, frost,
violet). Every site sits on its own layer as a small painted scene. Same painter as the
expedition banners (tools/paint_sites.py).

Writes:
  assets/ui/art/region_map.png   257x306, transparent around the cutaway
  tools/map_roads.json           everything the map scene needs, so art and scene never drift:
                                 "_spots" (site -> spot and label box), "_layers" (bands),
                                 "_chimneys", and one road per site (town -> the Maw -> the site)

Then run `python3 tools/build_pages.py company_map` to rebuild the scene from the json.

    python3 tools/paint_descent_map.py [preview.png]"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from paint_sites import Scene, rgb, lerp, particles  # noqa: E402

MW, MH = 257, 306
CX = 128
GROUND = 44
TOWN = (128, 44)

## Layer bands: id, name, y0, y1, palette (ceiling, mid, floor glow), light, haze, particle colour.
LAYERS = [
    (1, "Ashen Verge", 58, 120, ("#1a0c0a", "#40190f", "#9a441c"), "#ff8a32", "#8a3a1c", "#d0bcac"),
    (2, "Weeping Fens", 123, 178, ("#14070a", "#3a0e14", "#8e2226"), "#ff4a3a", "#6a1a22", "#a88a8a"),
    (3, "Brimstone Reach", 181, 222, ("#1e0c06", "#4a1e0e", "#b0561a"), "#ffa040", "#b0501a", "#ffb848"),
    (4, "Frozen Lament", 225, 270, ("#0c0e14", "#222a38", "#46566c"), "#c8dcf0", "#7a8aa0", "#dce6f4"),
    (5, "The Abyss", 273, 304, ("#050408", "#0e0a18", "#2a1838"), "#9a6ad8", "#2a1a3a", "#5a4a7a"),
]
LAYER_TIPS = {
    1: "Layer 1 · The Ashen Verge\nJust past the Maw. Dead woods that still burn, old copper workings, and ash falling like snow.",
    2: "Layer 2 · The Weeping Fens\nBlack water, red marsh, and trees that weep sap like blood. Hounds hunt here.",
    3: "Layer 3 · The Brimstone Reach\nBurning slopes, a lake as still as glass, and moors that never stop smouldering.",
    4: "Layer 4 · The Frozen Lament\nIce that holds the screaming, a shore that weeps salt, and pitbears on the ridges.",
    5: "Layer 5 · The Abyss\nBlack water at the bottom of everything. The Throne Below waits here.",
}

## Every place on the map: id -> (x, y) centre of its little scene; its name sits under it.
## Farms are on the surface (layer 0).
SPOTS = {
    "home_fields": (28, 33), "tilled_acres": (72, 33), "beehives": (186, 33), "glasshouse": (230, 33),
    "mossward_copse": (48, 72), "calder_keep": (128, 75), "harlow": (208, 72),
    "hollow_fields": (48, 100), "mossward_meadows": (128, 100), "millbrook_pond": (208, 100),
    "old_oakwood": (58, 136), "deepdelve": (198, 136),
    "fenmire": (52, 162), "silverrun": (128, 162), "greyfang_hills": (194, 162),
    "sunreach": (70, 196), "glasswater": (128, 196), "elkmoor": (184, 196),
    "frostvale": (76, 238), "bleakridge": (178, 238), "greywater_coast": (128, 252),
    "drowned_deep": (106, 286),
}
LAYER_OF = {"home_fields": 0, "tilled_acres": 0, "beehives": 0, "glasshouse": 0}
for sid, (_, y) in SPOTS.items():
    for lid, _n, y0, y1, *_ in LAYERS:
        if y0 <= y <= y1:
            LAYER_OF.setdefault(sid, lid)
## Planned crypts: painted, not yet places to go.
ABBEY = (128, 138)
THRONE = (160, 290)

TRUNK = [TOWN, (128, 50), (128, 58), (110, 60), (90, 64), (88, 120), (92, 124), (90, 178), (96, 184), (100, 222),
         (104, 226), (108, 270), (118, 276), (120, 296)]


def half(y):
    """Half the cavern's width at row y: the descent narrows as it goes down."""
    return 112 - (y - 58) * 48 / 246


def polyline(pts, step=2.0):
    out = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
        for k in range(n):
            out.append((x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n))
    out.append(pts[-1])
    return out


def road(spot_id):
    x, y = SPOTS[spot_id]
    feet = y + 6
    if LAYER_OF[spot_id] == 0:
        return polyline([TOWN, (x, GROUND)])
    pts = []
    for p in TRUNK:
        if p[1] > feet:
            break
        pts.append(p)
    # down the trunk to the spot's floor, then across to it
    last = pts[-1]
    nxt = TRUNK[len(pts)] if len(pts) < len(TRUNK) else last
    if nxt[1] > last[1]:
        t = (feet - last[1]) / (nxt[1] - last[1])
        pts.append((last[0] + (nxt[0] - last[0]) * t, feet))
    pts.append((x, feet))
    return polyline(pts)


# =============================================================================== painting
def paint():
    sc = Scene(77, haze="#3a2a24", ambient=0.25, w=MW, h=MH)
    yy, xx = sc.yy, sc.xx
    edge = sc.noise(5, 3)
    # --- what is cut away: the sky above, the earth below ---------------------------------
    sky = yy < GROUND
    earth = yy >= GROUND
    cav = np.zeros((MH, MW), bool)
    band_of = np.zeros((MH, MW), int)
    for lid, _n, y0, y1, *_ in LAYERS:
        h = np.array([half(y) for y in range(MH)])[:, None]
        rough = (edge - 0.5) * 6
        m = (yy >= y0) & (yy <= y1) & (np.abs(xx - CX) <= h + rough)
        ceil = sc.noise1d(8, 3)
        m &= yy >= y0 + (ceil * 3)[None, :]
        cav |= m
        band_of[m] = lid
    # the Maw: a throat from the surface into the first layer
    maw = (yy >= GROUND - 2) & (yy < 60) & (np.abs(xx - CX) <= 6 + (yy - GROUND) * 0.9 + (edge - 0.5) * 3)
    cav |= maw
    band_of[maw & (band_of == 0)] = 1
    # --- lights ---------------------------------------------------------------------------
    for lid, _n, y0, y1, pal, light, haze, _p in LAYERS:
        w = half((y0 + y1) / 2)
        for k, x in enumerate(np.linspace(CX - w * 0.7, CX + w * 0.7, 3)):
            sc.light(x, y1 - 4, w * 0.9, light, 0.6 if k == 1 else 0.45)
    sc.light(CX, 56, 40, "#ff5a30", 1.2)        # the Maw's glow
    sc.light(CX, 14, 46, "#ffd27a", 1.0)        # the lantern
    sc.light(200, 40, 130, "#f0b080", 0.6)      # dusk
    sc.prepare_light()
    # --- sky: dusk over Last Lantern -----------------------------------------------------
    sc.sky([(0, "#161c2a"), (20, "#2e3448"), (34, "#5a5262"), (44, "#a87060")], smoke="#3a3a4a", smoke_amount=0.3, smoke_scale=40)
    # --- caverns: each band its own air ----------------------------------------------------
    air = np.zeros((MH, MW, 3))
    smoke = sc.noise(18, 4)
    for lid, _n, y0, y1, pal, light, haze, _p in LAYERS:
        c0, c1, c2 = (rgb(c) for c in pal)
        for y in range(y0 - 3, y1 + 1):
            t = min(1, max(0, (y - y0) / max(1, y1 - y0)))
            col = lerp(c0, c1, t / 0.55) if t < 0.55 else lerp(c1, c2, (t - 0.55) / 0.45)
            air[y] = col
        rows = (yy >= y0 - 3) & (yy <= y1)
        air[rows] = lerp(air[rows], rgb(haze), (np.clip((smoke[rows] - 0.5) * 2, 0, 1) * 0.35)[:, None])
    sc.img = np.where(cav[..., None], air, sc.img)
    for lid, _n, y0, y1, pal, light, haze, _p in LAYERS:
        sc.glow(CX, y1 - 2, half(y1) * 1.1, light, 0.12, squash=0.18)
    sc.glow(CX, 58, 22, "#ff6a30", 0.6, squash=0.6)
    # --- the rock around the caverns, lit at the edges they face ----------------------------
    rock = earth & ~cav
    sc.layer(rock, "#2e221c", 0.0, rim=0.55, wash=0.5, texture=0.4, tex_scale=3)
    strata = sc.noise(4, 2)
    lines = (np.abs(np.sin((yy + strata * 9) * 0.55)) < 0.12) & rock
    sc.img = np.where(lines[..., None], sc.img * 0.72, sc.img)
    for _ in range(26):  # veins of ore in the rock
        x, y = sc.rnd.randrange(MW), sc.rnd.randint(GROUND + 6, MH - 4)
        if rock[y, x]:
            sc.img[y, x] = rgb(sc.rnd.choice(["#a86a3a", "#c8a050", "#8a9aa8"]))
    # ledges: the floor of each band, a lit lip
    for lid, _n, y0, y1, pal, light, *_ in LAYERS:
        lip = (yy >= y1 - 1) & (yy <= y1) & cav & (band_of == lid)
        sc.img = np.where(lip[..., None], lerp(sc.img, rgb(light), 0.35) * 0.6, sc.img)
    # --- the surface: ground, the town, the lantern tower, the Maw's mouth -------------------
    im, d = sc.canvas()
    d.rectangle([0, GROUND - 2, MW, GROUND + 1], fill=255)
    sc.layer(sc.m(im) & ~cav, "#3a3a2a", 0.0, rim=0.6, wash=0.6, texture=0.3, tex_scale=2)
    im, d = sc.canvas()
    chimneys = []
    for x, w, h in [(94, 9, 9), (104, 8, 13), (113, 7, 8), (139, 8, 11), (148, 7, 8), (156, 9, 12)]:
        d.rectangle([x, GROUND - 2 - h, x + w, GROUND - 1], fill=255)
        d.polygon([(x - 1, GROUND - 2 - h), (x + w / 2, GROUND - 2 - h - w * 0.55), (x + w + 1, GROUND - 2 - h)], fill=255)
        d.rectangle([x + w - 3, GROUND - 2 - h - w * 0.6 - 2, x + w - 2, GROUND - 2 - h], fill=255)
        chimneys.append([x + w - 2, GROUND - 4 - h - int(w * 0.6)])
    d.rectangle([124, 12, 132, GROUND - 1], fill=255)          # the lantern tower
    d.polygon([(121, 12), (128, 4), (135, 12)], fill=255)
    d.rectangle([118, GROUND - 6, 138, GROUND - 1], fill=255)  # the wall around the Maw
    sc.layer(sc.m(im), "#20202c", 0.0, rim=1.0, wash=0.6)
    em, d = sc.canvas()
    for x, w, h in [(94, 9, 9), (104, 8, 13), (113, 7, 8), (139, 8, 11), (148, 7, 8), (156, 9, 12)]:
        d.rectangle([x + 2, GROUND - 2 - h // 2 - 1, x + 3, GROUND - 2 - h // 2], fill=255)
    sc.emissive(sc.m(em), "#ffc870", bloom=0.5, bloom_r=2)
    em, d = sc.canvas()
    d.rectangle([126, 14, 130, 19], fill=255)
    sc.glow(128, 16, 18, "#ffd27a", 0.45, squash=1.0)
    sc.emissive(sc.m(em), "#ffe6a0")
    # --- the places ---------------------------------------------------------------------
    sc.rim_scale = 0.45
    for sid, (x, y) in SPOTS.items():
        VIGNETTES[sid](sc, x, y)
    abbey_teaser(sc, *ABBEY)
    throne_teaser(sc, *THRONE)
    # --- the way down: a faint dotted track ------------------------------------------------
    for k, (x, y) in enumerate(polyline(TRUNK[2:], 1.0)):
        if k % 3 == 0:
            xi, yi = int(round(x)), int(round(y))
            sc.img[yi, xi] = lerp(sc.img[yi, xi], rgb("#e8d5bd"), 0.45)
    # --- what drifts in the air ---------------------------------------------------------------
    for lid, _n, y0, y1, pal, light, haze, pc in LAYERS:
        for _ in range(int((y1 - y0) * half(y0) * 0.012)):
            x, y = sc.rnd.randrange(MW), sc.rnd.randint(y0, y1 - 2)
            if cav[y, x]:
                sc.img[y, x] = lerp(sc.img[y, x], rgb(pc), 0.7)
    img = sc.done(colours=64, dither=0.04, vignette=0.0, gamma=0.85)
    # --- cut it out: a pixel-dithered edge onto the page -------------------------------------
    # a torn edge all round, like a page cut from a surveyor's book
    tear = sc.noise(3, 2)
    side = np.minimum(np.minimum(xx, MW - 1 - xx), np.minimum(yy, MH - 1 - yy))
    alpha = ((side + (tear - 0.5) * 5) > 1.5).astype(np.uint8) * 255
    out = np.asarray(img).copy()
    out[..., 3] = alpha
    return Image.fromarray(out, "RGBA"), chimneys


# =============================================================================== little scenes
def _m(sc, draw):
    im, d = sc.canvas()
    draw(d)
    return sc.m(im)


def _glow_dots(sc, pts, colour, bloom=0.4, hot=None):
    em, d = sc.canvas()
    for p in pts:
        if len(p) == 2:
            d.point(p, fill=255)
        else:
            d.rectangle(p, fill=255)
    sc.emissive(sc.m(em), colour, hot=hot, bloom=bloom, bloom_r=2)


def _mound(d, x, y, w=16, h=3):
    d.ellipse([x - w, y + 4, x + w, y + 4 + h * 2], fill=255)


def v_home_fields(sc, x, y):
    m = _m(sc, lambda d: d.rectangle([x - 16, y + 2, x + 16, y + 9], fill=255))
    sc.layer(m, "#8a7432", 0.0, rim=0.5, wash=0.8, texture=0.3, tex_scale=1)
    for k in range(4):
        sc.img[y + 3 + k * 2, x - 15:x + 16] *= 0.8
    m = _m(sc, lambda d: (d.rectangle([x + 8, y - 4, x + 14, y + 2], fill=255), d.polygon([(x + 7, y - 4), (x + 11, y - 8), (x + 15, y - 4)], fill=255)))
    sc.layer(m, "#2a2420", 0.0, rim=0.8)
    _glow_dots(sc, [(x + 10, y - 2)], "#ffc870")


def v_tilled_acres(sc, x, y):
    m = _m(sc, lambda d: d.rectangle([x - 16, y + 2, x + 16, y + 9], fill=255))
    sc.layer(m, "#4a3828", 0.0, rim=0.4, wash=0.8, texture=0.3, tex_scale=1)
    for k in range(-5, 6):
        for t in range(8):
            xx = int(x + k * 3 + k * t * 0.4)
            if x - 16 <= xx <= x + 16:
                sc.img[y + 2 + t, xx] *= 0.7
    m = _m(sc, lambda d: (d.ellipse([x - 6, y - 6, x + 4, y], fill=255), d.line([(x - 4, y), (x - 4, y + 3)], fill=255),
                          d.line([(x + 2, y), (x + 2, y + 3)], fill=255), d.polygon([(x + 3, y - 5), (x + 7, y - 9), (x + 7, y - 4)], fill=255)))
    sc.layer(m, "#2a2018", 0.0, rim=0.9)


def v_beehives(sc, x, y):
    m = _m(sc, lambda d: (d.rectangle([x - 2, y - 2, x + 0, y + 8], fill=255), d.ellipse([x - 9, y - 12, x + 7, y - 1], fill=255)))
    sc.layer(m, "#28301c", 0.0, rim=0.8, texture=0.3, tex_scale=1)
    for hx in (x + 5, x + 12):
        m = _m(sc, lambda d, hx=hx: d.ellipse([hx - 3, y + 1, hx + 3, y + 8], fill=255))
        sc.layer(m, "#b08a3a", 0.0, rim=0.6, wash=0.6)
        sc.img[y + 4, hx - 2:hx + 3] *= 0.7
    _glow_dots(sc, [(x + 3 + sc.rnd.randint(0, 12), y - 4 + sc.rnd.randint(0, 6)) for _ in range(6)], "#f0c040", bloom=0)


def v_glasshouse(sc, x, y):
    em, d = sc.canvas()
    d.polygon([(x - 12, y + 8), (x - 12, y), (x, y - 7), (x + 12, y), (x + 12, y + 8)], fill=255)
    sc.emissive(sc.m(em), "#e8a870", bloom=0.6, bloom_r=4)
    m = _m(sc, lambda d: [d.line([(xx, y + 8), (xx, y - 7 + abs(xx - x) * 7 / 12)], fill=255) for xx in range(x - 12, x + 13, 6)]
           + [d.line([(x - 12, y + 3), (x + 12, y + 3)], fill=255), d.line([(x - 12, y), (x, y - 7), (x + 12, y)], fill=255)])
    sc.layer(m, "#2a2420", 0.0, rim=0.4)
    _glow_dots(sc, [(x - 9 + k * 3, y + 6) for k in range(7)], "#e0281a", bloom=0)


def v_cinderwood(sc, x, y):
    im, d = sc.canvas()
    cracks = []
    for k, (dx, h) in enumerate([(-11, 15), (-4, 19), (3, 14), (10, 17)]):
        cracks += sc.dead_tree(d, x + dx, y + 8, h, depth=2, width=1.3, seed=k + 11)
    _mound(d, x, y + 3, 15, 2)
    sc.layer(sc.m(im), "#1a0c0a", 0.0, rim=1.0)
    sc.glow(x, y + 6, 12, "#ff8a32", 0.35, squash=0.5)
    _glow_dots(sc, [(cx, cy, cx, cy + 2) for cx, cy, n in cracks[:12]], "#f07a28", bloom=0.6, hot=None)
    _glow_dots(sc, [(x - 1, y + 7, x + 2, y + 8)], "#ffd070", bloom=0.5)


def v_gatepit(sc, x, y):
    im, d = sc.canvas()
    sc.crag(d, [(x - 15, y + 9), (x - 11, y - 4), (x - 3, y - 9), (x + 6, y - 7), (x + 13, y - 1), (x + 15, y + 9)], rough=1.5, step=3)
    sc.layer(sc.m(im), "#3a2016", 0.0, rim=0.9, texture=0.3, tex_scale=2)
    em, d = sc.canvas()
    d.rectangle([x - 2, y + 1, x + 3, y + 9], fill=255)
    sc.emissive(sc.m(em), "#ffb050", bloom=0.8, bloom_r=3)
    m = _m(sc, lambda d: (d.line([(x - 3, y), (x + 4, y)], fill=255), d.line([(x - 3, y), (x - 3, y + 9)], fill=255),
                          d.line([(x + 4, y), (x + 4, y + 9)], fill=255)))
    sc.flat(m, "#2a160e")


def v_keep(sc, x, y):
    im, d = sc.canvas()
    d.polygon([(x - 15, y + 9), (x - 10, y + 5), (x + 10, y + 5), (x + 15, y + 9)], fill=255)
    d.rectangle([x - 8, y - 4, x + 8, y + 5], fill=255)
    d.rectangle([x - 3, y - 11, x + 3, y + 5], fill=255)
    for k in range(-3, 4, 2):
        d.rectangle([x + k, y - 13, x + k, y - 11], fill=255)
    for k in range(-8, 9, 3):
        d.rectangle([x + k, y - 6, x + k, y - 4], fill=255)
    d.polygon([(x + 8, y - 4), (x + 11, y - 1), (x + 9, y + 5)], fill=255)
    sc.layer(sc.m(im), "#140a08", 0.0, rim=1.0)
    _glow_dots(sc, [(x - 1, y + 1, x + 1, y + 5), (x, y - 8), (x - 5, y - 1), (x + 5, y), (x - 4, y + 2)], "#f08a30", bloom=0.6)


def v_ashmeadow(sc, x, y):
    im, d = sc.canvas()
    _mound(d, x, y + 2, 16, 3)
    for _ in range(40):
        gx = sc.rnd.randint(x - 15, x + 15)
        d.line([(gx, y + 7), (gx, y + 7 - sc.rnd.randint(1, 5))], fill=255)
    sc.layer(sc.m(im), "#3a2c28", 0.0, rim=0.5, wash=0.9)
    for _ in range(10):
        sc.img[y + sc.rnd.randint(3, 8), sc.rnd.randint(x - 14, x + 14)] = rgb("#d8ccc0")
    _glow_dots(sc, [(sc.rnd.randint(x - 13, x + 13), y + sc.rnd.randint(4, 8)) for _ in range(7)], "#f06a2a", bloom=0.3)


def v_pool(sc, x, y, water="#2a2220", glint="#ffb060", rim_col="#1a100c"):
    im, d = sc.canvas()
    d.ellipse([x - 15, y - 1, x + 15, y + 9], fill=255)
    sc.layer(sc.m(im), rim_col, 0.0, rim=0.8)
    em, d = sc.canvas()
    d.ellipse([x - 13, y + 1, x + 13, y + 8], fill=255)
    m = sc.m(em)
    sc.img = np.where(m[..., None], lerp(rgb(water), rgb(glint), (np.clip(1 - np.abs(sc.xx - x) / 14, 0, 1) * 0.35)[..., None]), sc.img)
    for k in range(3):
        yy = y + 3 + k * 2
        sc.img[yy, x - 6 + k * 3:x + 2 + k * 3] = lerp(sc.img[yy, x], rgb(glint), 0.6)


def v_cinder_pool(sc, x, y):
    v_pool(sc, x, y)
    m = _m(sc, lambda d: (d.rectangle([x - 15, y + 2, x - 6, y + 3], fill=255), d.line([(x - 8, y + 2), (x - 8, y - 6)], fill=255),
                          d.line([(x - 8, y - 6), (x + 2, y - 10)], fill=255)))
    sc.layer(m, "#140c0a", 0.0, rim=1.0)


def v_hollow_fields(sc, x, y):
    im, d = sc.canvas()
    _mound(d, x, y + 2, 16, 3)
    for _ in range(30):
        gx = sc.rnd.randint(x - 15, x + 15)
        d.line([(gx, y + 7), (gx, y + 7 - sc.rnd.randint(1, 3))], fill=255)
    d.line([(x - 3, y + 7), (x - 3, y - 8)], fill=255)
    d.line([(x - 9, y - 4), (x + 3, y - 5)], fill=255)
    d.polygon([(x - 7, y - 4), (x + 1, y - 4), (x, y + 2), (x - 6, y + 2)], fill=255)
    for cx, cy in [(x + 6, y - 9), (x + 11, y - 6), (x - 12, y - 8)]:
        d.line([(cx - 2, cy - 1), (cx, cy), (cx + 2, cy - 1)], fill=255)
    sc.layer(sc.m(im), "#1a1210", 0.0, rim=0.8)
    sc.img[y - 10:y - 7, x - 4:x - 1] = rgb("#c8b8a4")


def v_weepingwood(sc, x, y):
    im, d = sc.canvas()
    drips = []
    for k, (dx, h) in enumerate([(-8, 22), (7, 20)]):
        drips += sc.weeping_tree(d, x + dx, y + 8, h, seed=k + 21)
    _mound(d, x, y + 3, 15, 2)
    sc.layer(sc.m(im), "#14060a", 0.0, rim=1.0)
    _glow_dots(sc, [(int(a), int(b), int(a), int(b) + 2) for a, b, n in drips[:7]], "#c02a2a", bloom=0.3)


def v_sulphur(sc, x, y):
    im, d = sc.canvas()
    sc.crag(d, [(x - 15, y + 9), (x - 12, y - 5), (x, y - 9), (x + 12, y - 5), (x + 15, y + 9)], rough=1.5, step=3)
    sc.layer(sc.m(im), "#2a1e0a", 0.0, rim=0.8, texture=0.3, tex_scale=2)
    for w, h, c in [(9, 11, "#806418"), (6, 8, "#c8a838"), (3, 5, "#fff0a8")]:
        em, d = sc.canvas()
        d.rectangle([x - w, y + 9 - h, x + w, y + 9], fill=255)
        sc.emissive(sc.m(em), c, bloom=0.3 if w == 3 else 0, bloom_r=3)
    _glow_dots(sc, [(x - 12, y + 6), (x + 11, y + 5), (x - 13, y + 2), (x + 13, y + 8)], "#e8d050", bloom=0.2)


def v_bloodfen(sc, x, y):
    v_pool(sc, x, y, water="#3a0c12", glint="#e04a3a", rim_col="#14060a")
    im, d = sc.canvas()
    for _ in range(12):
        rx = sc.rnd.choice([sc.rnd.randint(x - 15, x - 7), sc.rnd.randint(x + 6, x + 15)])
        d.line([(rx, y + 5), (rx, y + 5 - sc.rnd.randint(4, 9))], fill=255)
    sc.layer(sc.m(im), "#14060a", 0.0, rim=0.7)
    for _ in range(4):
        sc.img[y + sc.rnd.randint(1, 3), sc.rnd.randint(x - 4, x + 4)] = rgb("#e8d8c8")


def v_styx(sc, x, y):
    im, d = sc.canvas()
    d.polygon([(x - 16, y + 9), (x - 14, y), (x + 14, y - 2), (x + 16, y + 9)], fill=255)
    sc.layer(sc.m(im), "#14080c", 0.0, rim=0.8)
    for k in range(5):
        yy = y + 1 + k * 2
        x0 = x - 13 + sc.rnd.randint(0, 6)
        sc.img[yy, x0:x0 + sc.rnd.randint(6, 14)] = rgb("#6a2a30")
    sc.img[y + 4, x + 2:x + 6] = rgb("#d8c8b8")
    m = _m(sc, lambda d: (d.line([(x - 10, y + 1), (x - 10, y - 7)], fill=255), d.line([(x - 10, y - 7), (x + 1, y - 11)], fill=255)))
    sc.layer(m, "#10060a", 0.0, rim=1.0)


def v_houndfang(sc, x, y):
    im, d = sc.canvas()
    d.polygon([(x - 16, y + 9), (x - 10, y + 1), (x - 2, y - 4), (x + 6, y - 2), (x + 16, y + 9)], fill=255)
    e1 = sc.hound(d, x - 7, y - 3, s=1, size=0.55)
    e2 = sc.hound(d, x + 6, y, s=-1, size=0.5)
    sc.layer(sc.m(im), "#14060a", 0.0, rim=1.0)
    _glow_dots(sc, [(int(e1[0]), int(e1[1])), (int(e2[0]), int(e2[1]))], "#ffb040", bloom=0.3)


def v_ember_slopes(sc, x, y):
    im, d = sc.canvas()
    d.polygon([(x - 16, y + 9), (x - 6, y - 6), (x, y - 9), (x + 5, y - 5), (x + 16, y + 9)], fill=255)
    sc.layer(sc.m(im), "#2e1208", 0.0, rim=0.9, texture=0.3, tex_scale=2)
    em, d = sc.canvas()
    d.line([(x, y - 8), (x - 2, y - 2), (x + 1, y + 3), (x - 1, y + 9)], fill=255, width=1)
    d.polygon([(x + 8, y + 9), (x + 9, y + 3), (x + 10, y + 6), (x + 11, y + 1), (x + 12, y + 9)], fill=255)
    d.polygon([(x - 11, y + 9), (x - 10, y + 4), (x - 9, y + 9)], fill=255)
    sc.emissive(sc.m(em), "#f07a1a", hot=None, bloom=0.7, bloom_r=3)


def v_glass_lake(sc, x, y):
    im, d = sc.canvas()
    d.ellipse([x - 16, y - 1, x + 16, y + 9], fill=255)
    sc.layer(sc.m(im), "#1a0a06", 0.0, rim=0.9)
    em, d = sc.canvas()
    d.ellipse([x - 14, y + 1, x + 14, y + 8], fill=255)
    m = sc.m(em)
    grad = np.clip((sc.yy - (y + 1)) / 7, 0, 1)
    sc.img = np.where(m[..., None], lerp(rgb("#f08a2a"), rgb("#5a2410"), grad[..., None]), sc.img)
    sc.img[y + 1, x - 10:x + 11] = rgb("#ffd890")
    m = _m(sc, lambda d: d.polygon([(x - 1, y + 3), (x + 4, y - 3), (x + 9, y - 4), (x + 5, y), (x + 1, y + 4)], fill=255))
    sc.layer(m, "#1a0a06", 0.0, rim=1.2)


def v_gorehorn(sc, x, y):
    im, d = sc.canvas()
    d.polygon([(x - 16, y + 9), (x - 12, y + 3), (x + 12, y + 2), (x + 16, y + 9)], fill=255)
    e = sc.beast(d, "gorehorn", x - 10, y + 3, s=1, k=0.5)
    sc.layer(sc.m(im), "#140806", 0.0, rim=1.0)
    em, d = sc.canvas()
    for _ in range(6):
        gx = sc.rnd.randint(x - 15, x + 14)
        d.line([(gx, y + 5), (gx + 3, y + 5)], fill=255)
    sc.emissive(sc.m(em), "#f07020", bloom=0.4, bloom_r=2)
    _glow_dots(sc, [(int(e[0]), int(e[1]))], "#ffd060", bloom=0)


def v_laments_edge(sc, x, y):
    im, d = sc.canvas()
    d.rectangle([x - 16, y + 4, x + 16, y + 9], fill=255)
    for k in range(7):
        ix = x - 15 + k * 5
        d.polygon([(ix, y + 5), (ix + 2, y + 5 - sc.rnd.randint(5, 12)), (ix + 4, y + 5)], fill=255)
    sc.layer(sc.m(im), "#2e3646", 0.0, rim=1.0, wash=0.9)
    _glow_dots(sc, [(x - 8, y + 6), (x + 3, y + 7), (x + 10, y + 6)], "#e8f2ff", bloom=0.3)
    em, d = sc.canvas()
    d.ellipse([x - 3, y + 4, x + 2, y + 9], fill=255)
    sc.img = np.where(sc.m(em)[..., None], lerp(sc.img, rgb("#7a889c"), 0.5), sc.img)


def v_shore(sc, x, y):
    im, d = sc.canvas()
    d.rectangle([x - 16, y, x + 16, y + 6], fill=255)
    sc.layer(sc.m(im), "#1c2230", 0.0, rim=0.6, wash=0.8)
    for k in range(3):
        yy = y + 1 + k * 2
        for xx in range(x - 15, x + 15, 5):
            sc.img[yy, xx:xx + 3] = lerp(sc.img[yy, xx], rgb("#c8d2e0"), 0.4 + k * 0.15)
    im, d = sc.canvas()
    d.polygon([(x - 16, y + 9), (x - 16, y + 5), (x, y + 6), (x + 16, y + 4), (x + 16, y + 9)], fill=255)
    sc.crag(d, [(x + 6, y + 6), (x + 8, y - 3), (x + 13, y - 4), (x + 15, y + 6)], rough=1, step=2)
    d.chord([x - 12, y + 1, x - 2, y + 8], 180, 360, fill=255)
    sc.layer(sc.m(im), "#10141c", 0.0, rim=0.9)


def v_bleakridge(sc, x, y):
    im, d = sc.canvas()
    sc.crag(d, [(x - 16, y + 9), (x - 9, y - 4), (x - 3, y - 1), (x + 4, y - 10), (x + 16, y + 9)], rough=1, step=2)
    sc.layer(sc.m(im), "#3a4658", 0.0, rim=0.9, texture=0.2, tex_scale=2)
    m = _m(sc, lambda d: d.polygon([(x + 4, y - 10), (x, y - 4), (x + 4, y - 6), (x + 8, y - 3)], fill=255))
    sc.img = np.where(m[..., None], rgb("#d8e2ee"), sc.img)
    im, d = sc.canvas()
    e = sc.beast(d, "bear", x - 12, y + 8, s=1, k=0.36)
    sc.layer(sc.m(im), "#0e1018", 0.0, rim=1.0)
    _glow_dots(sc, [(int(e[0]), int(e[1]))], "#ff3a2a", bloom=0)


def v_drowned_deep(sc, x, y):
    im, d = sc.canvas()
    d.rectangle([x - 17, y + 1, x + 17, y + 9], fill=255)
    sc.layer(sc.m(im), "#08060e", 0.0, rim=0.5, wash=0.6)
    for k in range(4):
        yy = y + 2 + k * 2
        x0 = x - 15 + sc.rnd.randint(0, 8)
        sc.img[yy, x0:x0 + 8] = lerp(sc.img[yy, x0], rgb("#3a2a5a"), 0.6)
    sc.glow(x + 6, y + 8, 10, "#9a6ad8", 0.5, squash=0.6)
    m = _m(sc, lambda d: (d.polygon([(x - 10, y), (x + 2, y), (x, y + 3), (x - 8, y + 3)], fill=255),
                          d.line([(x - 6, y), (x - 6, y - 7)], fill=255), d.line([(x - 2, y), (x + 8, y - 6)], fill=255)))
    sc.layer(m, "#1a1428", 0.0, rim=1.1)
    sc.glow(x - 6, y - 7, 6, "#ffd27a", 0.5, squash=1.0)
    _glow_dots(sc, [(x - 6, y - 8)], "#ffe6a0", bloom=0)
    _glow_dots(sc, [(x + 6, y + 7), (x + 9, y + 5)], "#f0e6ff", bloom=0.2)


def abbey_teaser(sc, x, y):
    im, d = sc.canvas()
    d.rectangle([x - 3, y - 12, x + 3, y + 6], fill=255)
    d.polygon([(x - 4, y - 12), (x, y - 17), (x + 4, y - 12)], fill=255)
    d.polygon([(x + 3, y + 6), (x + 3, y - 4), (x + 13, y - 4), (x + 15, y - 1), (x + 15, y + 6)], fill=255)
    d.polygon([(x - 14, y + 6), (x - 12, y - 1), (x - 3, y - 1), (x - 3, y + 6)], fill=255)
    sc.layer(sc.m(im), "#14070c", 0.6, rim=0.3)
    _glow_dots(sc, [(x - 1, y - 9, x + 1, y - 7)], "#8a3028", bloom=0.1)
    v = sc.m(_m_rect(sc, x - 16, y + 3, x + 16, y + 9))
    sc.img = np.where(v[..., None], lerp(sc.img, rgb("#1a0a10"), 0.6), sc.img)


def _m_rect(sc, x0, y0, x1, y1):
    im, d = sc.canvas()
    d.rectangle([x0, y0, x1, y1], fill=255)
    return im


def throne_teaser(sc, x, y):
    im, d = sc.canvas()
    d.polygon([(x - 14, y + 12), (x - 10, y + 6), (x + 10, y + 6), (x + 14, y + 12)], fill=255)
    d.rectangle([x - 5, y - 6, x + 5, y + 6], fill=255)
    d.polygon([(x - 7, y - 6), (x - 5, y - 13), (x - 2, y - 8), (x, y - 15), (x + 2, y - 8), (x + 5, y - 13), (x + 7, y - 6)], fill=255)
    sc.layer(sc.m(im), "#0a0610", 0.45, rim=0.4)
    _glow_dots(sc, [(x, y - 1)], "#a050d0", bloom=0.2)


VIGNETTES = {
    "home_fields": v_home_fields, "tilled_acres": v_tilled_acres, "beehives": v_beehives, "glasshouse": v_glasshouse,
    "mossward_copse": v_cinderwood, "calder_keep": v_keep, "harlow": v_gatepit, "hollow_fields": v_hollow_fields,
    "mossward_meadows": v_ashmeadow, "millbrook_pond": v_cinder_pool, "old_oakwood": v_weepingwood, "deepdelve": v_sulphur,
    "fenmire": v_bloodfen, "silverrun": v_styx, "greyfang_hills": v_houndfang, "sunreach": v_ember_slopes,
    "glasswater": v_glass_lake, "elkmoor": v_gorehorn, "frostvale": v_laments_edge, "greywater_coast": v_shore,
    "bleakridge": v_bleakridge, "drowned_deep": v_drowned_deep,
}


if __name__ == "__main__":
    img, chimneys = paint()
    img.save("assets/ui/art/region_map.png")
    data = {sid: [[round(px, 1), round(py, 1)] for px, py in road(sid)] for sid in SPOTS}
    data["_spots"] = {sid: {"x": x, "y": y, "layer": LAYER_OF[sid]} for sid, (x, y) in SPOTS.items()}
    data["_layers"] = [{"id": lid, "name": n, "y0": y0, "y1": y1, "left": round(CX - half(y0)), "tip": LAYER_TIPS[lid]}
                       for lid, n, y0, y1, *_ in LAYERS]
    data["_chimneys"] = chimneys
    data["_size"] = [MW, MH]
    json.dump(data, open("tools/map_roads.json", "w"), indent=1)
    if len(sys.argv) > 1:
        bg = Image.new("RGBA", img.size, (232, 214, 184, 255))
        bg.alpha_composite(img)
        bg.resize((MW * 3, MH * 3), Image.NEAREST).save(sys.argv[1])
    print("painted the descent map: %d places, %d roads" % (len(SPOTS), len(SPOTS)))
