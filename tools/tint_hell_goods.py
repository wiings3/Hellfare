"""Tint the icons of goods that come up from hell (run from the project root).

Shapes stay; colours change. Each icon's non-outline pixels are mapped by brightness onto a
four-tone ramp for its Hellfare good (ashwood grey, brimstone yellow, bloodgarnet red...).
Crops, gear, tools, food and potions keep their colours: they are made above.

The untinted icons are kept in tools/icon_sources/ (ignored by Godot), so this can be re-run
after tools/paint_icons.py or tools/paint_goods.py repaint an icon: it always tints from the
source. If a painter rewrites an icon, the next run copies the fresh one into the sources."""
import os
import shutil
import sys
from PIL import Image

ICONS = "assets/ui/icons/"
SOURCES = "tools/icon_sources/"

## good id -> dark, mid, light, highlight
RAMPS = {
    "timber": [(66, 60, 58), (112, 104, 98), (162, 152, 142), (210, 202, 192)],          # ashwood
    "oak": [(58, 22, 26), (102, 38, 42), (148, 62, 60), (196, 104, 96)],                 # weepwood
    "amber": [(120, 36, 10), (196, 76, 20), (238, 138, 40), (255, 210, 120)],             # cinder amber
    "coal": [(104, 84, 10), (176, 156, 28), (226, 210, 78), (250, 244, 168)],             # brimstone
    "garnet": [(70, 0, 12), (130, 10, 26), (190, 30, 42), (240, 110, 110)],               # bloodgarnet
    "crystal": [(70, 66, 108), (120, 116, 168), (180, 178, 220), (238, 236, 255)],        # soulglass
    "herbs": [(66, 72, 64), (112, 118, 104), (164, 168, 152), (212, 214, 202)],           # ashleaf
    "berries": [(110, 22, 10), (190, 58, 20), (238, 118, 40), (255, 198, 120)],           # cinderberries
    "mushrooms": [(78, 70, 64), (134, 124, 114), (188, 180, 168), (232, 226, 216)],       # gravecaps
    "sunpetal": [(128, 28, 10), (208, 78, 20), (248, 158, 40), (255, 228, 140)],          # emberbloom
    "frostbloom": [(88, 98, 120), (148, 162, 186), (208, 218, 236), (250, 252, 255)],     # lament lily
    "perch": [(58, 56, 56), (106, 102, 100), (156, 152, 146), (206, 202, 196)],           # ash perch
    "trout": [(28, 24, 34), (68, 48, 62), (118, 78, 94), (178, 128, 138)],                # styx trout
    "eel": [(88, 78, 64), (148, 136, 116), (204, 194, 174), (242, 236, 222)],             # bone eel
    "pearl": [(108, 128, 150), (168, 188, 206), (218, 230, 242), (255, 255, 255)],        # tear pearl
    "cod": [(68, 78, 96), (118, 130, 150), (174, 184, 200), (222, 228, 238)],             # weeping cod
    "crab": [(78, 38, 44), (128, 68, 72), (178, 108, 106), (220, 168, 158)],              # shore crab
    "game_meat": [(88, 28, 34), (138, 58, 62), (180, 108, 104), (220, 168, 158)],         # gaunt meat
    "rabbit_hide": [(70, 64, 60), (116, 108, 102), (164, 156, 148), (208, 200, 192)],     # ashhare hide
    "feathers": [(28, 24, 32), (58, 50, 66), (98, 88, 110), (150, 140, 162)],             # carrion feathers
    "boar_meat": [(98, 10, 10), (158, 30, 24), (208, 70, 50), (240, 140, 110)],           # hellboar meat
    "wolf_pelt": [(34, 26, 26), (70, 44, 42), (112, 70, 64), (162, 110, 100)],            # hound pelt
    "fang": [(108, 94, 60), (168, 154, 108), (220, 208, 164), (250, 244, 220)],           # hound fang
    "venison": [(88, 20, 14), (148, 48, 30), (198, 88, 60), (236, 150, 120)],             # gorehorn meat
    "elk_hide": [(68, 30, 14), (118, 56, 26), (168, 90, 46), (214, 140, 90)],             # gorehorn hide
    "antler": [(40, 20, 18), (90, 40, 34), (140, 70, 56), (196, 120, 96)],                # gorehorn horn
    "bear_meat": [(80, 14, 20), (140, 40, 40), (190, 80, 74), (230, 140, 130)],           # pitbear meat
    "direbear_pelt": [(30, 32, 40), (64, 66, 80), (104, 108, 124), (156, 160, 176)],      # pitbear pelt
    "relic": [(108, 78, 30), (168, 128, 60), (218, 188, 110), (250, 236, 180)],           # saint's relic
    "sovereign": [(40, 30, 30), (92, 60, 50), (200, 90, 40), (250, 190, 90)],             # ashen crown shard
}


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def tint(src, ramp):
    im = Image.open(src).convert("RGBA")
    px = im.load()
    body = [px[x, y] for y in range(im.height) for x in range(im.width) if px[x, y][3] > 0 and lum(px[x, y]) >= 28]
    if not body:
        return im
    lo, hi = min(lum(c) for c in body), max(lum(c) for c in body)
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            if c[3] == 0 or lum(c) < 28:
                continue  # transparent, or the black outline
            t = (lum(c) - lo) / max(1.0, hi - lo) * (len(ramp) - 1)
            i = min(len(ramp) - 2, int(t))
            f = t - i
            col = tuple(int(ramp[i][k] + (ramp[i + 1][k] - ramp[i][k]) * f) for k in range(3))
            px[x, y] = col + (c[3],)
    return im


if __name__ == "__main__":
    os.makedirs(SOURCES, exist_ok=True)
    open(SOURCES + ".gdignore", "w").close()
    for key, ramp in RAMPS.items():
        icon, source = ICONS + key + ".png", SOURCES + key + ".png"
        if not os.path.exists(source) or os.path.getmtime(icon) > os.path.getmtime(source) + 1:
            shutil.copy2(icon, source)  # first run, or a painter repainted it
        out = tint(source, ramp)
        out.save(icon)
        os.utime(source, None)  # the tinted icon is now older than its source
    if len(sys.argv) > 1:
        keys = list(RAMPS)
        sheet = Image.new("RGBA", (10 * 20, ((len(keys) + 9) // 10) * 40), (232, 215, 184, 255))
        for i, key in enumerate(keys):
            x, y = (i % 10) * 20 + 2, (i // 10) * 40 + 2
            sheet.alpha_composite(Image.open(SOURCES + key + ".png").convert("RGBA"), (x, y))
            sheet.alpha_composite(Image.open(ICONS + key + ".png").convert("RGBA"), (x, y + 18))
        sheet.resize((sheet.width * 5, sheet.height * 5), Image.NEAREST).save(sys.argv[1])
    print("tinted %d goods icons" % len(RAMPS))
