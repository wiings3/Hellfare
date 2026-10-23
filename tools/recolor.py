"""Bake the BookUI pack's blue/cyan pixels into an oxblood palette.
Only pixels where blue clearly dominates red are changed; paper, wood and gold stay original."""
import sys, os
import numpy as np
from PIL import Image

def recolor(src, dst):
    im = np.array(Image.open(src).convert("RGBA")).astype(np.float32)
    r, g, b, a = im[..., 0], im[..., 1], im[..., 2], im[..., 3]
    mask = (b - r > 12) & (g - r > -4) & (a > 0)
    light = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    # Map lightness through a hand-picked oxblood ramp (dark -> light).
    ramp = np.array([[20, 10, 14], [52, 20, 28], [92, 30, 42], [128, 44, 56], [168, 66, 74], [214, 120, 116]], np.float32)
    pos = np.clip(light * 1.35, 0, 1) * (len(ramp) - 1)
    i0 = np.floor(pos).astype(int); i1 = np.minimum(i0 + 1, len(ramp) - 1); t = (pos - i0)[..., None]
    col = ramp[i0] * (1 - t) + ramp[i1] * t
    out = im.copy()
    out[..., :3][mask] = col[mask]
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(dst)

if __name__ == "__main__":
    recolor(sys.argv[1], sys.argv[2])
