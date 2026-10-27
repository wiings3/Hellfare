"""Cut the Hellfare promo Short (1080x1920, 30 fps) from a recorded session and the game's art.

Record the gameplay first (Godot's Movie Maker, under a virtual display on Linux):

    xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-method gl_compatibility \
        --resolution 1920x1080 --write-movie $PROMO_OUT/clips/session.avi --fixed-fps 30 \
        --script res://tools/promo/record_session.gd

Then, from the project root:

    python3 tools/promo/make_short.py preview   # a contact sheet of key frames
    python3 tools/promo/make_short.py           # $PROMO_OUT/hellfare_short.mp4, with music and sounds
    CTA="WISHLIST ON STEAM" python3 tools/promo/make_short.py   # a different end-card line

The shot times in SHOTS match the MARK lines record_session.gd prints. Needs ffmpeg, numpy, Pillow.
"""
import math
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

GAME = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../.."))
HERE = os.environ.get("PROMO_OUT", "/tmp/hellfare_promo")
os.makedirs(HERE, exist_ok=True)
SRC = os.path.join(HERE, "clips/session.avi")
FPS = 30
W, H = 1080, 1920
CLIP_Y, CLIP_H = 360, 1260          # where gameplay sits in the frame
FONT_BIG = os.path.join(GAME, "assets/fonts/Jersey20-Regular.ttf")
FONT_BODY = os.path.join(GAME, "assets/fonts/Jersey15-Regular.ttf")
ART = os.path.join(GAME, "assets/ui/art")
CTA = os.environ.get("CTA", "COMING SOON")

BG_TOP = np.array([20, 10, 9], float)
BG_BOT = np.array([42, 16, 12], float)
PARCH = (238, 222, 196)
EMBER = (255, 168, 72)
GOLD = (226, 178, 92)

# --------------------------------------------------------------------------- the cut
# Each shot: kind, video start, length, settings. Times in seconds.
SHOTS = [
    ("map", 0.0, 3.2, {}),
    ("game", 3.2, 2.5, {"src": 3.0, "crop": (966, 168, 640, 640 * CLIP_H / W)}),       # recruit + hire
    ("game", 5.7, 2.8, {"src": 6.9, "crop": (966, 168, 640, 640 * CLIP_H / W)}),       # send down
    ("game", 8.5, 2.8, {"src": 18.4, "crop": (402, 222, 440, 440 * CLIP_H / W), "flags": "neighbor"}),  # crews walking the map
    ("layers", 11.3, 5.0, {}),
    ("game", 16.3, 3.4, {"src": 10.45, "crop": (966, 168, 640, 640 * CLIP_H / W), "inset": (1372, 742, 520, 314)}),   # crypt event card
    ("game", 19.7, 2.8, {"src": 25.1, "crop": (966, 168, 640, 640 * CLIP_H / W)}),     # back with reports
    ("title", 22.5, 5.0, {}),
]
DURATION = 27.5

CAPTIONS = [  # start, end, line 1, line 2
    (0.15, 3.2, "YOUR GUILD SENDS", "PEOPLE INTO HELL"),
    (3.2, 5.7, "HIRE THEM", ""),
    (5.7, 8.5, "SEND THEM DOWN", ""),
    (8.5, 11.3, "THEY KEEP WORKING", "EVEN WHILE YOU'RE AWAY"),
    (11.3, 13.8, "THE DEEPER THEY GO", ""),
    (13.8, 16.3, "THE MORE IT PAYS", ""),
    (16.3, 19.7, "MAKE THE HARD CALLS", ""),
    (19.7, 22.5, "NOT EVERYONE COMES", "BACK IN ONE PIECE"),
]

LAYERS = [  # banner, label, colour
    ("forest_copse", "LAYER 1 · THE ASHEN VERGE", (255, 150, 70)),
    ("forest_oakwood", "LAYER 2 · THE WEEPING FENS", (240, 90, 80)),
    ("site_sunreach", "LAYER 3 · THE BRIMSTONE REACH", (255, 190, 80)),
    ("site_bleakridge", "LAYER 4 · THE FROZEN LAMENT", (190, 215, 245)),
    ("site_drowned_deep", "LAYER 5 · THE ABYSS", (190, 150, 250)),
]

SFX = [  # time, sound file (in assets/audio), gain dB
    (0.05, "interface/page_turn_1.ogg", -4),
    (4.45, "interface/hire_1.ogg", -2),
    (5.7, "interface/page_turn_2.ogg", -6),
    (7.3, "interface/send_down_1.ogg", 0),
    (11.3, "interface/page_turn_1.ogg", -6),
    (16.3, "alerts/event_open_1.ogg", 0),
    (19.75, "alerts/crew_back_1.ogg", 0),
    (22.5, "interface/floor_cleared_1.ogg", -2),
]


# --------------------------------------------------------------------------- helpers
def font(path, size):
    return ImageFont.truetype(path, size)


def background():
    t = np.linspace(0, 1, H)[:, None, None]
    bg = BG_TOP * (1 - t) + BG_BOT * t
    bg = np.broadcast_to(bg, (H, W, 3)).copy()
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt(((xx - W / 2) / (W * 0.75)) ** 2 + ((yy - H / 2) / (H * 0.7)) ** 2)
    bg *= np.clip(1.15 - d * 0.5, 0.55, 1.0)[..., None]
    return Image.fromarray(bg.astype(np.uint8))


BG = None


def text_outlined(d, xy, s, f, fill, outline=(14, 7, 6), width=5, anchor="mm"):
    d.text(xy, s, font=f, fill=fill, anchor=anchor, stroke_width=width, stroke_fill=outline)


def ease(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def caption(img, t):
    d = ImageDraw.Draw(img)
    for a, b, l1, l2 in CAPTIONS:
        if a <= t < b:
            k = ease((t - a) / 0.18)          # pop in
            size = int(96 * (0.86 + 0.14 * k))
            f = font(FONT_BIG, size)
            y = 150 if l2 else 190
            text_outlined(d, (W // 2, y), l1, f, PARCH, width=6)
            if l2:
                text_outlined(d, (W // 2, y + 100), l2, f, EMBER, width=6)


def frame_border(img, box, colour=GOLD):
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    d.rectangle([x0 - 6, y0 - 6, x1 + 5, y1 + 5], outline=(14, 7, 6), width=6)
    d.rectangle([x0 - 3, y0 - 3, x1 + 2, y1 + 2], outline=colour, width=3)


def read_segment(src_t, length, crop, size, flags="lanczos"):
    """Frames of the session from src_t, cropped and scaled to `size`."""
    x, y, w, h = crop
    n = int(round(length * FPS)) + 2
    vf = "crop=%d:%d:%d:%d,scale=%d:%d:flags=%s" % (w, h, x, y, size[0], size[1], flags)
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", "%.3f" % src_t, "-i", SRC, "-frames:v", str(n), "-vf", vf,
                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    frames = np.frombuffer(raw, np.uint8).reshape(-1, size[1], size[0], 3)
    return frames


def nearest(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


# --------------------------------------------------------------------------- shots
class Shot:
    def __init__(self, kind, start, length, cfg):
        self.kind, self.start, self.length, self.cfg = kind, start, length, cfg
        self.frames = None
        if kind == "game":
            self.frames = read_segment(cfg["src"], length, cfg["crop"], (W, CLIP_H), cfg.get("flags", "lanczos"))
            if "inset" in cfg:
                ix, iy, iw, ih = cfg["inset"]
                k = (W - 40) / iw
                self.inset_size = (W - 40, int(ih * k))
                self.inset = read_segment(cfg["src"], length, cfg["inset"], self.inset_size)
        elif kind == "map":
            m = Image.open(os.path.join(ART, "region_map.png")).convert("RGBA")
            self.map = nearest(m, 5)          # 1285 x 1530
        elif kind == "layers":
            self.banners = [nearest(Image.open(os.path.join(ART, b + ".png")).convert("RGB"), 8) for b, _, _ in LAYERS]
        elif kind == "title":
            self.bg = nearest(Image.open(os.path.join(ART, "dungeon_calder_keep.png")).convert("RGB"), 8)

    def render(self, img, t):
        lt = t - self.start
        if self.kind == "game":
            i = min(len(self.frames) - 1, int(lt * FPS))
            base = Image.fromarray(self.frames[i])
            if self.frames is not None and "inset" in self.cfg:
                base = Image.blend(base.filter(ImageFilter.GaussianBlur(3)), Image.new("RGB", base.size, (12, 6, 5)), 0.55)
            img.paste(base, (0, CLIP_Y))
            frame_border(img, (0, CLIP_Y, W, CLIP_Y + CLIP_H))
            if "inset" in self.cfg:
                k = ease(lt / 0.25)
                ins = Image.fromarray(self.inset[min(len(self.inset) - 1, i)])
                sw, sh = int(ins.width * (0.9 + 0.1 * k)), int(ins.height * (0.9 + 0.1 * k))
                ins = ins.resize((sw, sh), Image.LANCZOS)
                x, y = (W - sw) // 2, CLIP_Y + (CLIP_H - sh) // 2
                shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
                ImageDraw.Draw(shadow).rectangle([x - 10, y + 14, x + sw + 10, y + sh + 24], fill=(0, 0, 0, 170))
                shadow = shadow.filter(ImageFilter.GaussianBlur(14))
                img.paste(shadow, (0, 0), shadow)
                img.paste(ins, (x, y))
                frame_border(img, (x, y, x + sw, y + sh), EMBER)
        elif self.kind == "map":
            # a slow push in, drifting down from the town into the layers
            k = ease(lt / self.length)
            scale = 1.0 + 0.18 * k
            m = self.map.resize((int(self.map.width * scale), int(self.map.height * scale)), Image.NEAREST)
            x = (W - m.width) // 2
            y = int(CLIP_Y - 40 - k * (m.height - CLIP_H) * 0.55)
            layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            layer.paste(m, (x, y), m)
            mask = Image.new("L", (W, H), 0)
            ImageDraw.Draw(mask).rectangle([0, CLIP_Y, W, CLIP_Y + CLIP_H], fill=255)
            img.paste(layer, (0, 0), Image.composite(layer.getchannel("A"), Image.new("L", (W, H), 0), mask))
        elif self.kind == "layers":
            per = self.length / len(LAYERS)
            i = min(len(LAYERS) - 1, int(lt / per))
            u = (lt - i * per) / per
            b = self.banners[i]
            # banner fills the clip height; pan across it
            bh = CLIP_H - 300
            scale = bh / b.height
            bb = b.resize((int(b.width * scale), bh), Image.NEAREST)
            x = -int((bb.width - W) * (0.15 + 0.7 * u)) if i % 2 == 0 else -int((bb.width - W) * (0.85 - 0.7 * u))
            img.paste(bb, (x, CLIP_Y + 60))
            frame_border(img, (0, CLIP_Y + 60, W, CLIP_Y + 60 + bh), LAYERS[i][2])
            d = ImageDraw.Draw(img)
            text_outlined(d, (W // 2, CLIP_Y + 60 + bh + 110), LAYERS[i][1], font(FONT_BIG, 64), LAYERS[i][2], width=5)
            # a quick flash on each cut
            if u < 0.06:
                a = 1 - u / 0.06
                img.paste(Image.blend(img, Image.new("RGB", (W, H), (255, 220, 170)), 0.35 * a))
        elif self.kind == "title":
            k = ease(lt / 0.8)
            b = self.bg
            scale = (H * 0.62) / b.height * (1.0 + 0.04 * lt / self.length)
            bb = b.resize((int(b.width * scale), int(b.height * scale)), Image.NEAREST)
            dim = Image.blend(bb, Image.new("RGB", bb.size, (10, 5, 4)), 0.35)
            img.paste(dim, ((W - bb.width) // 2, 520))
            fade = Image.new("RGB", (W, H), (10, 5, 4))
            g = np.zeros((H, W), np.uint8)
            g[:520 + 80] = 255
            yy = np.arange(H)
            ramp = np.clip((yy - 520) / 160, 0, 1)
            g = (255 * (1 - ramp)).astype(np.uint8)[:, None].repeat(W, 1)
            ramp2 = np.clip((yy - (520 + bb.height - 260)) / 240, 0, 1)
            g = np.maximum(g, (255 * ramp2).astype(np.uint8)[:, None].repeat(W, 1))
            img.paste(fade, (0, 0), Image.fromarray(g))
            d = ImageDraw.Draw(img)
            logo = font(FONT_BIG, int(230 * (0.9 + 0.1 * k)))
            glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            ImageDraw.Draw(glow).text((W // 2, 360), "HELLFARE", font=logo, fill=(255, 110, 40, int(200 * k)), anchor="mm")
            glow = glow.filter(ImageFilter.GaussianBlur(26))
            img.paste(glow, (0, 0), glow)
            text_outlined(d, (W // 2, 360), "HELLFARE", logo, (255, 214, 150) if k > 0.5 else PARCH, width=8)
            if lt > 0.5:
                text_outlined(d, (W // 2, 520), "HIRE THEM. SEND THEM DOWN. GET PAID.", font(FONT_BODY, 54), PARCH, width=4)
            if lt > 1.4:
                pulse = 0.85 + 0.15 * math.sin(lt * 5)
                c = tuple(int(v * pulse) for v in EMBER)
                text_outlined(d, (W // 2, 1650), CTA, font(FONT_BIG, 104), c, width=7)


def build():
    global BG
    BG = background()
    shots = [Shot(*s) for s in SHOTS]

    def frame(t):
        img = BG.copy()
        for s in shots:
            if s.start <= t < s.start + s.length:
                s.render(img, t)
        caption(img, t)
        # fade in / out
        if t < 0.25:
            img = Image.blend(Image.new("RGB", (W, H)), img, t / 0.25)
        if t > DURATION - 0.6:
            img = Image.blend(img, Image.new("RGB", (W, H)), (t - (DURATION - 0.6)) / 0.6)
        return img
    return frame


def audio(path):
    music = os.path.join(GAME, "assets/audio/music/mus_title_1.ogg")
    inputs = ["-ss", "0.6", "-t", str(DURATION), "-i", music]
    filters = ["[0:a]volume=-3dB,afade=t=in:d=0.4,afade=t=out:st=%.2f:d=1.6[m]" % (DURATION - 1.6)]
    labels = ["[m]"]
    for i, (t, f, db) in enumerate(SFX):
        inputs += ["-i", os.path.join(GAME, "assets/audio", f)]
        filters.append("[%d:a]volume=%ddB,adelay=%d|%d[s%d]" % (i + 1, db, int(t * 1000), int(t * 1000), i))
        labels.append("[s%d]" % i)
    filters.append("%samix=inputs=%d:normalize=0,alimiter=limit=0.9,loudnorm=I=-14:TP=-1.5:LRA=11[out]" % ("".join(labels), len(labels)))
    subprocess.run(["ffmpeg", "-v", "error", "-y"] + inputs + ["-filter_complex", ";".join(filters), "-map", "[out]",
                    "-ar", "48000", "-ac", "2", path], check=True)


if __name__ == "__main__":
    frame = build()
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        ts = [float(x) for x in (sys.argv[2:] or [1.5, 4.6, 7.5, 10, 12, 15, 18, 21, 23.2, 26])]
        thumbs = [frame(t).resize((270, 480)) for t in ts]
        sheet = Image.new("RGB", (270 * 5 + 24, 480 * ((len(ts) + 4) // 5) + 4 * 2), (60, 60, 60))
        for i, im in enumerate(thumbs):
            sheet.paste(im, (4 + (i % 5) * 274, 4 + (i // 5) * 484))
        sheet.save(os.path.join(HERE, "preview.png"))
        sys.exit(0)
    wav = os.path.join(HERE, "audio.wav")
    audio(wav)
    out = os.path.join(HERE, "hellfare_short.mp4")
    enc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", "%dx%d" % (W, H),
                            "-r", str(FPS), "-i", "-", "-i", wav, "-c:v", "libx264", "-preset", "slow", "-crf", "17",
                            "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", out],
                           stdin=subprocess.PIPE)
    n = int(DURATION * FPS)
    for i in range(n):
        enc.stdin.write(frame(i / FPS).tobytes())
    enc.stdin.close()
    enc.wait()
    print("wrote", out)
