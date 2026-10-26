"""Build every game sound from Kenney's CC0 packs and from synthesis (run from the project root).

    python3 tools/make_sounds.py <rpg-audio folder> <interface-sounds folder>

The two folders are the "Audio" folders of Kenney's RPG Audio and Interface Sounds packs
(CC0, kenney.nl). They are not kept in the repository; the processed sounds are.

Writes:
  assets/audio/<group>/<name>_<n>.ogg   the sounds, 44.1 kHz Ogg Vorbis, peaks at -6 dB or lower
  assets/audio/sounds.json             the name table scripts/sfx.gd reads: group, files, volume, pitch
  assets/audio/CREDITS.md              where every sound came from

Names and groups follow the Hellfare sound list doc. Bells, the Maw, the crypt drones and the
ambience loops are synthesised here (no recording needed); the rest are Kenney recordings,
trimmed, levelled and sometimes layered."""
import json
import os
import shutil
import subprocess
import sys
import numpy as np
from scipy import signal

SR = 44100
OUT = "assets/audio/"
rng = np.random.default_rng(7)


# --- io -------------------------------------------------------------------------------------
def load(path):
    raw = subprocess.run(["ffmpeg", "-v", "quiet", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)


def save(x, path, peak_db=-6.0, stereo=None):
    x = np.asarray(x, np.float64)
    if stereo is not None:
        data = np.stack([x, stereo], axis=1)
    else:
        data = x[:, None]
    peak = np.abs(data).max()
    if peak > 0:
        data = data / peak * 10 ** (peak_db / 20)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    raw = data.astype(np.float32).tobytes()
    subprocess.run(["ffmpeg", "-v", "quiet", "-y", "-f", "f32le", "-ar", str(SR), "-ac", str(data.shape[1]), "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "5", path], input=raw, check=True)


# --- shaping ----------------------------------------------------------------------------------
def trim(x, db=-50.0, pad=0.01):
    """Cut silence off both ends (keeps a few ms of pad at the end)."""
    thr = 10 ** (db / 20) * max(1e-9, np.abs(x).max())
    idx = np.nonzero(np.abs(x) > thr)[0]
    if len(idx) == 0:
        return x
    return x[idx[0]: min(len(x), idx[-1] + int(pad * SR))]


def fade(x, fin=0.002, fout=0.02):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b and b < len(x):
        x[-b:] *= np.linspace(1, 0, b)
    return x


def lowpass(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def highpass(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def bandpass(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def reverb(x, seconds=1.6, wet=0.35, dark=3000):
    """A plain stone-room reverb: convolve with decaying, darkened noise."""
    n = int(seconds * SR)
    ir = rng.standard_normal(n) * np.exp(-np.linspace(0, 7, n))
    ir = lowpass(ir, dark)
    ir /= np.sqrt((ir ** 2).sum())
    tail = np.zeros(len(x) + n)
    full = signal.fftconvolve(x, ir)
    tail[: min(len(tail), len(full))] = full[: len(tail)]
    dry = np.concatenate([x, np.zeros(n)])
    return dry * (1 - wet) + tail * wet * 3


def mix(*parts):
    """mix((signal, start_seconds, gain), ...): each part is levelled to a peak of 1 first,
    so the gains alone set the balance."""
    end = max(int(s * SR) + len(p) for p, s, g in parts)
    out = np.zeros(end)
    for p, s, g in parts:
        i = int(s * SR)
        out[i: i + len(p)] += norm(p) * g
    return out


def norm(x):
    return x / max(1e-9, np.abs(x).max())


# --- synthesis ----------------------------------------------------------------------------------
BELL_PARTIALS = [(0.5, 0.6, 1.0), (1.0, 1.0, 0.8), (1.19, 0.5, 0.6), (1.5, 0.35, 0.5), (2.0, 0.45, 0.45),
                 (2.52, 0.2, 0.3), (2.66, 0.18, 0.28), (3.01, 0.12, 0.22), (4.1, 0.06, 0.15)]


def bell(freq, seconds, decay=1.0, bright=1.0):
    """A struck bell from its overtones (ratio, level, how long each rings)."""
    t = np.arange(int(seconds * SR)) / SR
    x = np.zeros_like(t)
    for ratio, level, ring in BELL_PARTIALS:
        f = freq * ratio
        if f > SR / 2.2:
            continue
        lvl = level * (bright if ratio > 1.6 else 1.0)
        x += lvl * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-t / (ring * decay * seconds * 0.35))
    strike = rng.standard_normal(int(0.01 * SR)) * np.exp(-np.linspace(0, 8, int(0.01 * SR))) * 0.3
    x[: len(strike)] += highpass(strike, 2000)
    return fade(x, 0.001, 0.05)


def far(x, hz=1800, room=2.2, wet=0.55):
    """Heard from far down a stone shaft: darker and wetter."""
    return reverb(lowpass(x, hz), room, wet, dark=1500)


def brown(seconds, lp=120.0):
    n = int(seconds * SR)
    x = np.cumsum(rng.standard_normal(n))
    x = highpass(x, 15)
    return lowpass(x, lp, 4)


def loopable(x, xfade=2.0):
    """Make a seamless loop: crossfade the tail into the head."""
    n = int(xfade * SR)
    head, body, tail = x[:n], x[n:-n], x[-n:]
    w = np.linspace(0, 1, n)
    return np.concatenate([body, tail * (1 - w) + head * w])


def slow_wobble(seconds, rate, depth, base=1.0):
    t = np.arange(int(seconds * SR)) / SR
    return base + depth * np.sin(2 * np.pi * rate * t + rng.uniform(0, 6.28))


# --- the sounds ---------------------------------------------------------------------------------
def build(rpg, ui):
    R = lambda n: trim(load(os.path.join(rpg, n + ".ogg")))
    U = lambda n: trim(load(os.path.join(ui, n + ".ogg")))
    S = {}   # name -> (group, [signals], volume dB, pitch spread, loop, source note)

    def add(name, group, takes, db=0.0, pitch=0.05, loop=False, source="", peak=-6.0):
        S[name] = dict(group=group, takes=[fade(t) if not loop and not isinstance(t, tuple) else t for t in takes], db=db, pitch=pitch, loop=loop,
                       source=source, peak=peak)

    # ---- alerts
    scrape = lowpass(R("creak3"), 1400)
    add("event_open", "alerts", [mix((far(scrape, 1400, 1.2, 0.4), 0, 0.8), (bell(98 * k, 1.6, 0.6, 0.6), 0.12, 0.9))
                                 for k in (1.0, 1.06)], source="Kenney RPG Audio (creak3) + synthesised bell")
    add("event_tick", "alerts", [U("tick_004")], db=-10, pitch=0.0, source="Kenney Interface Sounds (tick_004)")
    add("crew_waiting", "alerts", [far(mix((bell(392, 1.4, 0.5), 0, 1), (bell(330, 1.6, 0.5), 0.32, 1)), 2600, 1.6, 0.45)
                                   for _ in range(2)], source="Synthesised hand bell")
    add("crew_back", "alerts", [reverb(mix((bell(262, 2.2, 0.7), 0, 1), (bell(262 * k, 2.2, 0.7), 0.55, 0.9)), 1.2, 0.3)
                                for k in (1.0, 0.89)], source="Synthesised lantern bell")
    add("death", "alerts", [far(bell(73, 4.0, 1.2, 0.5), 900, 3.0, 0.5)], db=-2, pitch=0.0, source="Synthesised low bell")
    add("crew_wiped", "alerts", [mix((far(bell(55, 5.0, 1.3, 0.4), 700, 3.5, 0.55), 0, 1.0),
                                     (fade(brown(5.5, 80) * np.linspace(0, 1, int(5.5 * SR)) ** 0.5, 0.5, 2.0), 0, 0.9))],
        db=-1, pitch=0.0, source="Synthesised low bell + rumble")
    purse = R("dropLeather")
    coins = R("handleCoins2")
    add("sale", "alerts", [mix((coins, 0, 0.7), (purse, 0.08, 1.0))], source="Kenney RPG Audio (handleCoins2, dropLeather)")
    knock = lowpass(R("bookPlace3"), 2500)[: int(0.14 * SR)]
    add("trade_request", "alerts", [mix((fade(knock), 0, 1), (fade(knock), 0.16, 0.85))], db=-4,
        source="Kenney RPG Audio (bookPlace3)")
    add("level_up", "alerts", [mix((U("scratch_004"), 0, 0.5), (reverb(bell(784, 1.0, 0.4, 0.8), 0.8, 0.25), 0.1, 0.8))],
        db=-6, source="Kenney Interface Sounds (scratch_004) + synthesised chime")

    # ---- interface
    add("page_turn", "interface", [R("bookFlip1"), R("bookFlip2"), R("bookFlip3")], db=-4,
        source="Kenney RPG Audio (bookFlip1-3)")
    add("click", "interface", [lowpass(U(n), 5000) for n in ("click_002", "click_003", "click_005")], db=-10,
        source="Kenney Interface Sounds (click_002, 003, 005)")
    add("toggle", "interface", [lowpass(U(n), 5000) for n in ("toggle_001", "toggle_002", "toggle_004")], db=-10,
        source="Kenney Interface Sounds (toggle_001, 002, 004)")
    add("denied", "interface", [U("drop_002"), U("drop_003")], db=-8, source="Kenney Interface Sounds (drop_002, 003)")
    add("coin_spend", "interface", [coins, R("handleCoins")[: int(0.45 * SR)]], db=-6,
        source="Kenney RPG Audio (handleCoins, handleCoins2)")
    add("coin_earn", "interface", [R("handleCoins")], db=-5, source="Kenney RPG Audio (handleCoins)")
    add("coin_big", "interface", [mix((R("handleCoins"), 0, 0.8), (purse, 0.25, 1.0), (bell(523, 0.9, 0.3, 0.7), 0.3, 0.25))],
        db=-3, pitch=0.02, source="Kenney RPG Audio (handleCoins, dropLeather) + synthesised chime")
    gate = R("doorOpen_2")
    add("send_down", "interface", [mix((lowpass(gate, 3000), 0, 1.0), (fade(brown(1.6, 90), 0.3, 0.8), 0.5, 0.45))], db=-3,
        pitch=0.03, source="Kenney RPG Audio (doorOpen_2) + synthesised rumble")
    add("hire", "interface", [U("scratch_004"), U("scratch_005")], db=-6, source="Kenney Interface Sounds (scratch_004, 005)")
    add("sign_charter", "interface", [mix((U("scratch_005"), 0, 0.8), (R("bookClose"), 0.3, 1.0))], db=-4,
        source="Kenney Interface Sounds (scratch_005) + Kenney RPG Audio (bookClose)")
    add("equip", "interface", [R("beltHandle1"), R("beltHandle2"), R("clothBelt")], db=-6,
        source="Kenney RPG Audio (beltHandle1-2, clothBelt)")
    add("craft", "interface", [mix((R("metalPot2"), 0, 1), (R("metalPot3"), 0.28, 0.9))], db=-6,
        source="Kenney RPG Audio (metalPot2, metalPot3)")
    add("cook", "interface", [R("metalPot1")], db=-8, source="Kenney RPG Audio (metalPot1)")
    add("repair", "interface", [R("knifeSlice"), R("knifeSlice2")], db=-8, source="Kenney RPG Audio (knifeSlice, knifeSlice2)")
    add("list_item", "interface", [R("bookPlace1"), R("bookPlace2")], db=-9, source="Kenney RPG Audio (bookPlace1-2)")
    add("chat_post", "interface", [U("drop_001")], db=-10, source="Kenney Interface Sounds (drop_001)")

    # ---- crypt runs
    add("choice_safe", "interface", [R("cloth1"), R("cloth2")], db=-6, source="Kenney RPG Audio (cloth1-2)")
    add("choice_bold", "interface", [R("drawKnife1"), R("drawKnife2"), R("drawKnife3")], db=-5,
        source="Kenney RPG Audio (drawKnife1-3)")
    add("outcome_good", "interface", [mix((coins, 0, 0.6), (reverb(bell(196, 1.2, 0.4, 0.5), 0.9, 0.3), 0.05, 0.8))],
        db=-4, source="Kenney RPG Audio (handleCoins2) + synthesised bell")
    add("outcome_bad", "interface", [far(mix((purse, 0, 1.0), (R("footstep04"), 0.05, 0.8)), 1600, 0.8, 0.3)], db=-3,
        source="Kenney RPG Audio (dropLeather, footstep04)")
    add("floor_cleared", "interface", [far(mix((R("knifeSlice"), 0, 1.0), (R("knifeSlice2"), 0.18, 0.7)), 2200, 1.8, 0.5)],
        db=-5, source="Kenney RPG Audio (knifeSlice, knifeSlice2)")
    add("boss_down", "interface", [far(mix((R("doorClose_3"), 0, 1.0), (R("metalPot3"), 0.05, 0.5)), 1800, 2.6, 0.55)],
        db=-3, pitch=0.0, source="Kenney RPG Audio (doorClose_3, metalPot3)")
    steps = [R("footstep0%d" % i) for i in range(4)]
    add("retreat", "interface", [far(mix(*[(s, i * 0.17, 1.0 - i * 0.18) for i, s in enumerate(steps)]), 2500, 1.0, 0.35)],
        db=-5, source="Kenney RPG Audio (footstep00-03)")
    add("find_gear", "interface", [R("metalClick"), R("metalLatch")], db=-6, source="Kenney RPG Audio (metalClick, metalLatch)")
    add("blueprint", "interface", [R("bookOpen")], db=-6, source="Kenney RPG Audio (bookOpen)")

    # ---- ambience (synthesised loops)
    secs = 92
    hearth_l = np.zeros(int(secs * SR))
    for _ in range(900):  # crackles
        i = rng.integers(0, len(hearth_l) - 2000)
        n = rng.integers(60, 600)
        hearth_l[i: i + n] += highpass(rng.standard_normal(n), 1200) * np.exp(-np.linspace(0, 6, n)) * rng.uniform(0.05, 0.6)
    roar = lowpass(rng.standard_normal(len(hearth_l)), 400) * 0.25 * slow_wobble(secs, 0.13, 0.4)
    room = brown(secs, 300) * 0.4
    creaks = np.zeros(len(hearth_l))
    for t in (17, 51, 78):
        c = lowpass(R("creak%d" % rng.integers(1, 4)), 1800) * 0.25
        creaks[int(t * SR): int(t * SR) + len(c)] += c
    left = hearth_l + roar + room + creaks
    right = np.roll(hearth_l, 9000) + roar + room * 0.9 + np.roll(creaks, 400)
    add("amb_hall", "ambience", [(loopable(left), loopable(right))], loop=True, pitch=0.0,
        source="Synthesised hearth and room, Kenney RPG Audio (creak1-3)")
    secs = 124
    maw = brown(secs, 70) * slow_wobble(secs, 0.03, 0.35) + lowpass(brown(secs, 200), 160) * 0.3 * slow_wobble(secs, 0.07, 0.5)
    add("amb_maw", "ambience", [(loopable(maw), loopable(np.roll(maw, 20000)))], loop=True, pitch=0.0,
        source="Synthesised rumble")
    secs = 90
    wind = bandpass(rng.standard_normal(int(secs * SR)), 250, 900) * slow_wobble(secs, 0.05, 0.6) * 0.5
    drips = np.zeros(len(wind))
    for _ in range(60):
        i = rng.integers(0, len(drips) - SR)
        f = rng.uniform(900, 1700)
        n = int(0.09 * SR)
        t = np.arange(n) / SR
        drips[i: i + n] += np.sin(2 * np.pi * (f + 900 * t) * t) * np.exp(-t * 60) * rng.uniform(0.2, 0.7)
    drips = reverb(drips, 2.4, 0.6, 2500)[: len(wind)]
    add("amb_below", "ambience", [(loopable(wind + drips), loopable(np.roll(wind, 30000) + np.roll(drips, 7000)))],
        loop=True, pitch=0.0, source="Synthesised wind and drips")
    compose(add)
    return S


# --- music (synthesised: a bowed string, a hummed choir, drones and a frame drum) ----------------
def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def smooth_env(n, attack, release):
    env = np.ones(n)
    a, r = min(n // 2, int(attack * SR)), min(n // 2, int(release * SR))
    if a:
        env[:a] = 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    if r:
        env[-r:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, r))
    return env


def bowed(freq, dur, attack=0.25, release=0.5):
    """A cello-like bowed note: a saw-ish tone with slow vibrato, bow noise and a wooden body."""
    n = int((dur + release) * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.0045 * np.sin(2 * np.pi * 5.1 * t) * np.clip(t / 0.7, 0, 1)
    phase = 2 * np.pi * freq * np.cumsum(vib) / SR
    x = np.zeros(n)
    for k in range(1, 15):
        if freq * k > 9000:
            break
        x += np.sin(k * phase) / k * (1.0 if k % 2 else 0.7)
    x += highpass(rng.standard_normal(n), 3000) * 0.015
    x = lowpass(x, 2400) + 0.35 * bandpass(x, 220, 480)
    swell = 1 + 0.15 * np.sin(np.pi * np.clip(t / max(dur, 0.1), 0, 1))
    return x * smooth_env(n, attack, release) * swell


def hum(freq, dur, attack=1.2, release=1.6):
    """A low hummed choir: three detuned voices through 'mm / oo' formants."""
    n = int((dur + release) * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for cents in (-6, 0, 7):
        f = freq * 2 ** (cents / 1200)
        ph = 2 * np.pi * f * t + rng.uniform(0, 6.28)
        for k in range(1, 11):
            x += np.sin(k * ph) / k
    x = bandpass(x, 240, 480) + 0.45 * bandpass(x, 700, 1050) + 0.2 * lowpass(x, 240)
    return x * smooth_env(n, attack, release)


def drone(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(4 * np.pi * freq * t) + 0.15 * np.sin(6 * np.pi * freq * t)
    return x * (1 + 0.1 * np.sin(2 * np.pi * 0.11 * t)) * smooth_env(n, 4.0, 5.0)


def frame_drum(strength=1.0):
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    f = 58 + 60 * np.exp(-t * 18)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 5)
    slap = lowpass(rng.standard_normal(n), 1400) * np.exp(-t * 45) * 0.5
    return (body + slap) * strength


class Score:
    """A stereo mix: place(sound, at seconds, gain, pan -1..1)."""

    def __init__(self, seconds):
        self.l = np.zeros(int(seconds * SR))
        self.r = np.zeros(int(seconds * SR))

    def place(self, x, at, gain=1.0, pan=0.0):
        i = int(at * SR)
        if i >= len(self.l):
            return
        x = x[: len(self.l) - i] * gain
        self.l[i: i + len(x)] += x * np.sqrt((1 - pan) / 2)
        self.r[i: i + len(x)] += x * np.sqrt((1 + pan) / 2)

    def finish(self, room=2.6, wet=0.3, dark=2600, lp=None, fade_out=6.0):
        out = []
        for ch in (self.l, self.r):
            y = reverb(ch, room, wet, dark)[: len(ch)]
            if lp:
                y = lowpass(y, lp)
            out.append(y * smooth_env(len(y), 1.5, fade_out))
        return tuple(out)


D_MINOR_TO_MAJOR = {5: 6, 0: 1, 10: 11}   # F -> F#, C -> C#, Bb -> B


def play_line(score, notes, start, beat, gain, pan=0.0, transpose=0, major=False):
    """notes: [(midi or None for a rest, beats)]. Returns the time after the last note."""
    t = start
    for m, beats in notes:
        if m is not None:
            m = m + transpose
            if major and m % 12 in D_MINOR_TO_MAJOR:
                m += D_MINOR_TO_MAJOR[m % 12] - m % 12
            score.place(bowed(midi(m), beats * beat * 0.95), t, gain * (0.9 + 0.2 * rng.random()), pan)
        t += beats * beat
    return t


# The guild's theme, in D minor (midi notes, beats).
THEME = [
    [(57, 2), (62, 1), (60, 1), (58, 2), (57, 2), (None, 2)],
    [(53, 1), (55, 1), (57, 2), (58, 1), (57, 1), (55, 2), (53, 2), (None, 2)],
    [(62, 2), (64, 1), (65, 1), (64, 2), (62, 2), (60, 1), (58, 1), (57, 4), (None, 3)],
    [(57, 1), (58, 1), (57, 1), (55, 1), (53, 2), (52, 2), (50, 6), (None, 4)],
]


def compose(add):
    beat = 1.0
    # By the fire: the theme on one string, then again with a second voice a sixth below.
    sc = Score(122)
    sc.place(drone(midi(38), 120), 0, 0.10, -0.2)
    sc.place(drone(midi(45), 120), 0, 0.06, 0.2)
    t = 2.0
    for phrase in THEME:
        t = play_line(sc, phrase, t, beat, 0.32, 0.1)
    second = t
    for phrase in THEME:
        t = play_line(sc, phrase, second, beat, 0.30, 0.15)
        play_line(sc, [(m - 9 if m else None, b) for m, b in phrase], second, beat, 0.18, -0.25)
        second = t
    add("mus_hall", "music", [sc.finish(2.8, 0.32)], pitch=0.0, source="Synthesised (strings and drone)")

    # While a crew is below: a drone and a hummed choir, heard through the floor.
    sc = Score(118)
    sc.place(drone(midi(26), 118), 0, 0.22)
    sc.place(drone(midi(33), 118), 0, 0.10)
    chords = [(50, 53, 57), (46, 50, 53), (43, 46, 50), (45, 49, 52), (50, 53, 57), (46, 50, 55), (45, 49, 52), (50, 53, 57)]
    for i, chord in enumerate(chords):
        for j, m in enumerate(chord):
            sc.place(hum(midi(m), 12.5), 3 + i * 13.5, 0.16, (j - 1) * 0.5)
    for k in range(11):  # a slow heartbeat, now and then
        at = 6 + k * 10 + rng.uniform(-1.5, 1.5)
        sc.place(frame_drum(0.6), at, 0.35)
        sc.place(frame_drum(0.45), at + 0.42, 0.3)
    add("mus_descent", "music", [sc.finish(3.2, 0.4, 1800, lp=1300, fade_out=8.0)], pitch=0.0,
        source="Synthesised (choir, drone, drum)")

    # Entering a crypt: a frame drum, a low choir, and the theme's first bar, rising.
    sc = Score(62)
    sc.place(drone(midi(38), 62), 0, 0.14)
    pattern = [0, 3, 3.5, 6]
    for bar in range(9):
        for b in pattern:
            sc.place(frame_drum(1.0 if b == 0 else 0.7), 2 + bar * 6.4 + b * 0.8, 0.5, rng.uniform(-0.2, 0.2))
    for i, chord in enumerate([(38, 45, 50), (43, 46, 50), (45, 49, 52), (38, 45, 50)]):
        for j, m in enumerate(chord):
            sc.place(hum(midi(m), 13), 4 + i * 14, 0.15, (j - 1) * 0.4)
    play_line(sc, THEME[0][:4], 30, 1.2, 0.26, 0.2, transpose=-12)
    add("mus_crypt", "music", [sc.finish(2.2, 0.3, 2400, fade_out=5.0)], pitch=0.0,
        source="Synthesised (drum, choir, strings)")

    # Title and pause: the theme, a little brighter (D major) and a little higher.
    sc = Score(70)
    sc.place(drone(midi(50), 70), 0, 0.07)
    sc.place(drone(midi(57), 70), 0, 0.05)
    t = 1.5
    for phrase in THEME[:3]:
        t = play_line(sc, phrase, t, 1.05, 0.3, 0.05, transpose=0, major=True)
    play_line(sc, [(62, 2), (64, 1), (66, 1), (62, 8)], t, 1.05, 0.28, 0.05)
    add("mus_title", "music", [sc.finish(2.6, 0.3, 3000, fade_out=6.0)], pitch=0.0,
        source="Synthesised (strings and drone)")


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    sounds = build(sys.argv[1], sys.argv[2])
    if os.path.isdir(OUT):
        for g in ("alerts", "interface", "ambience", "music"):
            shutil.rmtree(OUT + g, ignore_errors=True)
    table = {}
    credits = ["# Sound credits", "",
               "Recordings from Kenney's **RPG Audio** and **Interface Sounds** packs (CC0, https://kenney.nl). "
               "Everything marked synthesised was made by `tools/make_sounds.py`.", "",
               "| Sound | Group | Source |", "| --- | --- | --- |"]
    for name, s in sounds.items():
        files = []
        for i, take in enumerate(s["takes"], 1):
            path = OUT + "%s/%s_%d.ogg" % (s["group"], name, i)
            if isinstance(take, tuple):
                save(take[0], path, s["peak"], stereo=take[1])
            else:
                save(take, path, s["peak"])
            files.append("res://" + path)
        table[name] = {"group": s["group"], "files": files, "db": s["db"], "pitch": s["pitch"], "loop": s["loop"]}
        credits.append("| `%s` | %s | %s |" % (name, s["group"], s["source"]))
    json.dump(table, open(OUT + "sounds.json", "w"), indent=1)
    open(OUT + "CREDITS.md", "w").write("\n".join(credits) + "\n")
    print("built %d sounds, %d files" % (len(table), sum(len(v["files"]) for v in table.values())))


if __name__ == "__main__":
    main()
