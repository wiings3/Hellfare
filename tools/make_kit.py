"""Generate Money Mercs' pixel UI kit (nine-patch frames, slots, bars, pips, desk).
All art is authored at 1 texel = 1 stage unit so it stays crisp at 2x (1080p)."""
import os, random
import numpy as np
from PIL import Image, ImageEnhance

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "ui")
KIT = os.path.join(ROOT, "kit")
PARTS = os.path.join(ROOT, "book", "parts")
SRC = os.path.join(ROOT, "..", "BookUI", "Pocket Inventory Series #7 Gems of Status v1.1", "Sprites", "Content")
os.makedirs(KIT, exist_ok=True)

T = (0, 0, 0, 0)
PAPER = (224, 199, 177, 255)
PAPER_LIGHT = (238, 220, 199, 255)
PAPER_TINT = (216, 189, 164, 255)
PAPER_DEEP = (204, 175, 150, 255)
SHADOW = (186, 154, 128, 255)
INK = (61, 40, 36, 255)
INK_SOFT = (122, 88, 74, 255)
INK_FAINT = (176, 141, 117, 255)
OX = (128, 44, 56, 255)
OX_DARK = (82, 26, 36, 255)
OX_LIGHT = (176, 74, 82, 255)
GOLD = (214, 160, 62, 255)
GOLD_DARK = (150, 100, 36, 255)
GOLD_LIGHT = (246, 210, 120, 255)
GREEN = (86, 122, 66, 255)
GREEN_LIGHT = (126, 160, 92, 255)


def canvas(w, h, fill=T):
    return Image.new("RGBA", (w, h), fill)


def box(w, h, outline, fill, notch=True, inner=None, inner_bottom=None, outline_w=1):
    """Rectangular frame with optional notched (clipped) corners and inner bevel lines."""
    im = canvas(w, h)
    px = im.load()
    for y in range(h):
        for x in range(w):
            edge = min(x, y, w - 1 - x, h - 1 - y)
            corner = notch and ((x < 1 or x > w - 2) and (y < 1 or y > h - 2))
            if corner:
                continue
            if edge < outline_w:
                px[x, y] = outline
            elif inner and edge == outline_w and (y == outline_w or x == outline_w):
                px[x, y] = inner
            elif inner_bottom and edge == outline_w and (y == h - 1 - outline_w or x == w - 1 - outline_w):
                px[x, y] = inner_bottom
            else:
                px[x, y] = fill
    if notch:  # diagonal fill so the notch reads as a bevel, not a hole
        for (x, y) in [(1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2)]:
            px[x, y] = outline
    return im


def save(im, name):
    im.save(os.path.join(KIT, name))


# --- Frames -----------------------------------------------------------------
save(box(12, 12, INK, PAPER_TINT, inner=PAPER_LIGHT, inner_bottom=PAPER_DEEP), "card.png")
save(box(12, 12, INK_FAINT, PAPER_TINT, inner=PAPER_LIGHT), "inset.png")
save(box(12, 12, OX, PAPER_TINT, inner=PAPER_LIGHT, inner_bottom=PAPER_DEEP), "card_alert.png")
save(box(12, 12, GOLD_DARK, (230, 204, 160, 255), inner=GOLD_LIGHT, inner_bottom=(214, 178, 120, 255)), "card_gold.png")
# Slots: recessed parchment wells (shadow on top/left like the BookUI inventory)
save(box(12, 12, INK, PAPER_DEEP, inner=SHADOW, inner_bottom=PAPER_LIGHT), "slot.png")
save(box(12, 12, OX, PAPER_DEEP, inner=SHADOW, inner_bottom=PAPER_LIGHT, outline_w=2), "slot_selected.png")
slot_empty = box(12, 12, INK_FAINT, PAPER_TINT, inner=PAPER_DEEP)
save(slot_empty, "slot_empty.png")
# Dark desk panel (for header readouts)
save(box(12, 12, (20, 12, 12, 255), (38, 24, 22, 220), inner=(70, 46, 40, 255)), "desk_panel.png")
# Toast
save(box(12, 12, GOLD_DARK, (36, 22, 20, 240), inner=(90, 60, 40, 255)), "toast.png")

# --- Paper buttons (secondary / toggles) ------------------------------------
save(box(12, 12, INK, PAPER_LIGHT, inner=(248, 234, 216, 255), inner_bottom=INK_FAINT), "paper_button.png")
save(box(12, 12, INK, (246, 230, 210, 255), inner=(255, 244, 228, 255), inner_bottom=INK_FAINT), "paper_button_hover.png")
save(box(12, 12, INK, PAPER_DEEP, inner=SHADOW), "paper_button_pressed.png")
save(box(12, 12, INK_FAINT, PAPER_TINT, inner=PAPER_TINT), "paper_button_disabled.png")
save(box(12, 12, OX_DARK, OX, inner=OX_LIGHT, inner_bottom=OX_DARK), "toggle_on.png")

# --- Primary buttons from the pack (oxblood) --------------------------------
src = Image.open(os.path.join(PARTS, "buttons", "5.png")).convert("RGBA").crop((6, 5, 57, 30))
save(src, "button.png")
save(ImageEnhance.Brightness(src).enhance(1.18), "button_hover.png")
save(ImageEnhance.Brightness(src).enhance(0.82), "button_pressed.png")
arr = np.array(src).astype(np.float32)
lum = (0.299 * arr[..., 0] + 0.587 * arr[..., 1] + 0.114 * arr[..., 2])[..., None]
grey = lum * np.array([1.05, 0.93, 0.88]) * 0.75 + 70
arr[..., :3] = np.clip(grey, 0, 255)
save(Image.fromarray(arr.astype(np.uint8)), "button_disabled.png")

# --- Bars ---------------------------------------------------------------------
save(box(6, 6, INK, PAPER_DEEP, notch=False, inner=SHADOW), "bar_bg.png")
for name, base, light in [("red", OX, OX_LIGHT), ("gold", GOLD, GOLD_LIGHT), ("green", GREEN, GREEN_LIGHT), ("ink", INK_SOFT, INK_FAINT)]:
    im = canvas(4, 4, base)
    for x in range(4):
        im.putpixel((x, 0), light)
    save(im, f"bar_{name}.png")

# --- Pips (7x7 diamonds) -------------------------------------------------------
def diamond(size, outline, fill):
    im = canvas(size, size)
    c = size // 2
    for y in range(size):
        for x in range(size):
            d = abs(x - c) + abs(y - c)
            if d == c:
                im.putpixel((x, y), outline)
            elif d < c and fill:
                im.putpixel((x, y), fill)
    return im

save(diamond(7, INK, OX), "pip_on.png")
save(diamond(7, INK_FAINT, PAPER_TINT), "pip_off.png")
save(diamond(7, GOLD_DARK, GOLD), "pip_gold.png")
save(diamond(5, INK_SOFT, INK_SOFT), "dot.png")
save(diamond(5, (210, 180, 130, 255), (210, 180, 130, 255)), "dot_desk.png")

# --- Header ornament for the desk (light parchment on dark wood) -------------
def ornament(w):
    im = canvas(w, 7)
    col = (196, 160, 112, 255)
    c = w // 2
    for x in range(w):
        if abs(x - c) > 5 and (x % 2 == 0 or abs(x - c) < w // 3):
            im.putpixel((x, 3), col)
    d = diamond(7, col, (110, 40, 48, 255))
    im.alpha_composite(d, (c - 3, 0))
    for side in (-1, 1):
        dd = diamond(5, col, col)
        im.alpha_composite(dd, (c + side * (w // 2 - 4) - 2, 1))
    return im

save(ornament(220), "ornament.png")

# --- Signs and icons recoloured to ink/oxblood for use on parchment ---------
def tint(path, color, dst):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    mask = a[..., 3] > 0
    a[..., 0][mask], a[..., 1][mask], a[..., 2][mask] = color[0], color[1], color[2]
    Image.fromarray(a).save(os.path.join(KIT, dst))

for n, label in [(6, "coin"), (7, "alert"), (8, "check"), (9, "home"), (10, "cross"), (11, "plus"), (12, "empty")]:
    tint(os.path.join(SRC, "9 Signs", f"{n}.png"), OX[:3], f"sign_{label}.png")

# --- Desk background ----------------------------------------------------------
def desk(w=960, h=540, seed=7):
    rnd = random.Random(seed)
    base = np.zeros((h, w, 3), np.float32)
    plank_h = 27
    for y in range(h):
        row = y % plank_h
        p = y // plank_h
        tone = 40 + (p * 37 % 7) - 3
        c = np.array([tone + 8, tone - 6, tone - 9], np.float32)
        if row == 0:
            c = c * 0.55
        elif row == 1:
            c = c * 1.25
        base[y, :, :] = c
    # grain streaks
    for _ in range(1400):
        y = rnd.randrange(h)
        if y % plank_h < 2:
            continue
        x = rnd.randrange(w)
        length = rnd.randrange(12, 90)
        k = rnd.choice([0.88, 0.92, 1.08, 1.12])
        base[y, x:x + length] *= k
    # butt joints between planks
    for p in range(h // plank_h + 1):
        x = (p * 311 + 97) % w
        y0, y1 = p * plank_h, min(h, (p + 1) * plank_h)
        base[y0:y1, x] *= 0.55
        if x + 1 < w:
            base[y0:y1, x + 1] *= 1.2
    # vignette, quantised to keep a pixel-art feel
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    v = 1.0 - np.clip(d - 0.55, 0, 1) * 0.75
    v = np.round(v * 10) / 10
    base *= v[..., None]
    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB")
    img.save(os.path.join(ROOT, "desk_background.png"))

desk()

# --- Pixel item icons from the pack (copied, named by game resource) ---------
ICONS = os.path.join(ROOT, "icons")
os.makedirs(ICONS, exist_ok=True)
item_map = {
    "copper": "1 Items/13.png", "iron": "1 Items/10.png", "timber": "1 Items/7.png",
    "herbs": "1 Items/12.png", "crystal": "1 Items/1.png", "relic": "1 Items/8.png",
    "sovereign": "1 Items/11.png", "gold": "1 Items/2.png", "book": "1 Items/9.png", "quill": "1 Items/14.png",
    "helmet": "8 Equipment/11.png", "armor_leather": "8 Equipment/8.png", "armor_iron": "8 Equipment/13.png",
    "gloves": "8 Equipment/12.png", "boots": "8 Equipment/15.png",
}
for name, rel in item_map.items():
    Image.open(os.path.join(SRC, rel)).convert("RGBA").save(os.path.join(ICONS, f"{name}.png"))
# Silver: brighten and desaturate the gold bar.
g = np.array(Image.open(os.path.join(SRC, "1 Items/11.png")).convert("RGBA")).astype(np.float32)
l = (0.299 * g[..., 0] + 0.587 * g[..., 1] + 0.114 * g[..., 2])
for i, k in enumerate([0.95, 1.0, 1.08]):
    g[..., i] = np.clip(l * k * 1.05 + 10, 0, 255)
Image.fromarray(g.astype(np.uint8)).save(os.path.join(ICONS, "silver.png"))
# Empty-slot silhouettes (pack outline icons) tinted faint ink.
for n, label in [(1, "helmet"), (2, "glove"), (3, "armor"), (4, "legs"), (5, "boots")]:
    im = np.array(Image.open(os.path.join(SRC, "8 Equipment", f"{n}.png")).convert("RGBA"))
    m = im[..., 3] > 0
    im[..., 0][m], im[..., 1][m], im[..., 2][m] = INK_FAINT[:3]
    Image.fromarray(im).save(os.path.join(ICONS, f"empty_{label}.png"))
# Portraits (pack character busts), cropped to the head and shoulders.
PORTRAITS = os.path.join(ROOT, "portraits")
os.makedirs(PORTRAITS, exist_ok=True)
for n, label in [(1, "miner"), (2, "guard"), (3, "scout")]:
    im = Image.open(os.path.join(PARTS, "icons", f"{n}.png")).convert("RGBA")
    bb = im.getbbox()
    im.crop(bb).save(os.path.join(PORTRAITS, f"{label}.png"))
print("kit done")
