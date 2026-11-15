#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Generates Eroxis's black-and-white wallpapers (numpy + Pillow). Run: python3 tools/make-wallpapers.py [OUT_DIR]"""
import sys
import numpy as np
from PIL import Image

W, H = 3840, 2160
OUT = sys.argv[1] if len(sys.argv) > 1 else "shell/assets/wallpapers"
rng = np.random.default_rng(7)

def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)

def _box(a, k, axis):
    pad = k // 2
    c = np.cumsum(np.pad(a, [(pad + 1, pad) if i == axis else (0, 0) for i in range(a.ndim)], mode="edge"), axis=axis, dtype=np.float64)
    n = a.shape[axis]
    hi = np.take(c, range(k, k + n), axis=axis); lo = np.take(c, range(0, n), axis=axis)
    return ((hi - lo) / k).astype(np.float32)

def blur(a, r):
    """Close to a gaussian of radius r: three box passes along each axis."""
    k = max(3, int(r * 1.8) | 1)
    for axis in (0, 1):
        for _ in range(3):
            a = _box(a, k, axis)
    return a

def encode(lin):
    srgb = np.clip(lin, 0, 1) ** (1 / 2.2)
    grain = rng.normal(0, 1.1 / 255, srgb.shape).astype(np.float32)
    return (np.clip(srgb + grain, 0, 1) * 255 + 0.5).astype(np.uint8)

def save(a, name, mode="L", q=95):
    im = Image.fromarray(a, "L")
    if mode == "RGB": im = im.convert("RGB")
    im.save(f"{OUT}/{name}", quality=q, subsampling=0) if name.endswith(".jpg") else im.save(f"{OUT}/{name}", optimize=True)

yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
cx, cy = 0.5 * W, 0.40 * H
floor = 0.78 * H

# --- hero: a torus, lit from the upper left
R, r = 0.20 * H, 0.050 * H
dx, dy = xx - cx, yy - cy
rho = np.hypot(dx, dy) + 1e-6
d = rho - R
cover = 1 - smooth(r - 1.2, r + 1.2, np.abs(d))
t = np.clip(d / r, -1, 1)
nz = np.sqrt(np.clip(1 - t * t, 0, 1))
n = np.stack([t * dx / rho, t * dy / rho, nz])
def unit(*v): v = np.array(v, np.float32); return v / np.linalg.norm(v)
L1, L2, V = unit(-0.55, -0.65, 0.55), unit(0.75, 0.55, 0.25), unit(0, 0, 1)
dot = lambda a, b: np.clip(a[0] * b[0] + a[1] * b[1] + a[2] * b[2], 0, 1)
hv = unit(*(L1 + V))
diffuse = dot(n, L1)
spec = dot(n, hv) ** 70
rim = dot(n, L2) ** 2
ring = (0.004 + 0.16 * diffuse ** 1.6 + 0.04 * rim + 0.9 * spec) * cover
spec_mask = np.clip(spec * 1.4, 0, 1) * cover

# --- two small spheres
def sphere(px, py, pr):
    sx, sy = xx - px, yy - py
    q = np.hypot(sx, sy) / pr
    cov = 1 - smooth(0.985, 1.015, q)
    z = np.sqrt(np.clip(1 - q * q, 0, 1))
    nn = np.stack([sx / pr, sy / pr, z])
    sh = (0.04 + 0.75 * dot(nn, L1) ** 1.2 + 0.9 * dot(nn, hv) ** 40) * cov
    glow = np.exp(-(np.hypot(sx, sy) / (pr * 4.5)) ** 2) * 0.012
    return sh, cov, glow
sA, cA, gA = sphere(cx + 0.205 * H, cy - 0.215 * H, 0.030 * H)
sB, cB, gB = sphere(cx - 0.265 * H, cy + 0.150 * H, 0.020 * H)

# --- room: soft backdrop, a floor with a pool of light under the ring
back = 0.0012 + 0.0075 * np.exp(-(((xx - cx) / (0.55 * W)) ** 2 + ((yy - cy) / (0.62 * H)) ** 2))
fl = smooth(floor - 6, floor + 6, yy)
floor_tone = 0.0016 + 0.0040 * np.exp(-((yy - floor) / (0.10 * H)) ** 2)
pool = 0.014 * np.exp(-(((xx - cx) / (0.30 * W)) ** 2 + ((yy - floor) / (0.045 * H)) ** 2))
scene = back * (1 - fl) + (floor_tone + pool) * fl
halo = 0.028 * np.exp(-(d / (0.11 * H)) ** 2) * (1 - cover)
scene = scene + halo + gA + gB

# --- its reflection in the floor
mirror_y = (2 * floor - yy).astype(np.int32)
ok = (mirror_y >= 0) & (mirror_y < H)
objects = ring + sA + sB
refl = np.zeros_like(objects)
refl[ok] = objects[mirror_y[ok], np.nonzero(ok)[1]]
refl = blur(refl, 5) * 0.20 * np.exp(-np.clip(yy - floor, 0, None) / (0.14 * H)) * fl
objects_on = np.where(yy < floor, objects, 0)

lin = scene + objects_on + refl
vig = 1 - 0.7 * smooth(0.30, 1.15, np.hypot((xx - cx) / (0.5 * W), (yy - 0.5 * H) / (0.5 * H)))
lin = lin * vig

base = encode(lin)
mask = np.clip(spec_mask * 0.9 + cA + cB + 0.0, 0, 1)
mask = np.where(yy < floor, mask, 0)
save(base, "default-base.jpg", "RGB", 96)
save(base, "default.jpg", "RGB", 96)          # accent white: the lights stay as they are
save((mask * 255 + 0.5).astype(np.uint8), "default-lights.png")

# --- contour: a map of nothing, in lines
def field(seed):
    g = np.random.default_rng(seed); f = np.zeros((H // 8, W // 8), np.float32)
    ys, xs = np.mgrid[0:H // 8, 0:W // 8].astype(np.float32)
    for _ in range(26):
        px, py = g.uniform(0, W // 8), g.uniform(0, H // 8)
        s, a = g.uniform(40, 160), g.uniform(-1, 1)
        f += a * np.exp(-(((xs - px) / s) ** 2 + ((ys - py) / (s * g.uniform(.6, 1.4))) ** 2))
    return f
f = np.asarray(Image.fromarray(field(11)).resize((W, H), Image.BICUBIC), dtype=np.float32)
f = (f - f.min()) / (f.max() - f.min()) * 34
lines = 1 - smooth(0.02, 0.07, np.abs(f - np.round(f)))
bold = (np.round(f) % 5 == 0).astype(np.float32)
c = lines * (0.05 + 0.10 * bold)
c = c * (0.25 + 0.75 * np.exp(-(((xx - cx) / (0.6 * W)) ** 2 + ((yy - 0.5 * H) / (0.75 * H)) ** 2)))
save(encode(0.006 + c * vig), "contour.jpg", "RGB", 95)
print("wallpapers written to", OUT)
