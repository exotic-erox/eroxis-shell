#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Builds the Eroxis emblem's shell files from assets/eroxis-logo.svg (one path, filled even-odd):
shell/components/LogoShape.js (the emblem and its star) and the small "eroxis" icon in shell/components/Icons.js.
Run: python3 tools/make-logo.py"""
import json, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
svg = (ROOT / "assets/eroxis-logo.svg").read_text()
vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', svg).group(1).split()]
d = re.search(r'\bd="([^"]+)"', svg).group(1)
subs = ["M" + p.strip() for p in d.split("M") if p.strip()]

def points(sub): return [(float(a), float(b)) for a, b in re.findall(r"(-?[\d.]+) (-?[\d.]+)", sub)]
def bbox(sub):
    pts = points(sub); xs = [x for x, _ in pts]; ys = [y for _, y in pts]
    return min(xs), min(ys), max(xs), max(ys)

# the star is the piece nearest the top right corner
def corner_distance(sub):
    x0, y0, x1, y1 = bbox(sub)
    return ((vb[0] + vb[2] - (x0 + x1) / 2) ** 2 + (vb[1] - (y0 + y1) / 2) ** 2)
star = min(subs, key=corner_distance)
body = [s for s in subs if s is not star]
sx0, sy0, sx1, sy1 = bbox(star)
pad = 6
shape = {
    "viewBox": vb,
    "all": d,
    "body": " ".join(body),
    "star": star,
    "starBox": [sx0 - pad, sy0 - pad, (sx1 - sx0) + 2 * pad, (sy1 - sy0) + 2 * pad],
}
(ROOT / "shell/components/LogoShape.js").write_text(".pragma library\n\nvar shape = " + json.dumps(shape, indent=1) + ";\n")

# the small icon: the emblem fitted into the icons' 24 x 24 box
s = 24 / vb[2]; oy = (24 - vb[3] * s) / 2
def fit(sub):
    pts = [(("%.2f" % ((x - vb[0]) * s)).rstrip("0").rstrip("."), ("%.2f" % ((y - vb[1]) * s + oy)).rstrip("0").rstrip(".")) for x, y in points(sub)]
    return "M" + "L".join("%s %s" % p for p in pts) + "Z"
small = "".join(fit(sub) for sub in subs)
icons = ROOT / "shell/components/Icons.js"
text = icons.read_text()
text, n = re.subn(r'("eroxis": \[\n\s*\{ fill: true, e: true, d: ")[^"]*(" \},?\n\s*\],)', lambda m: m.group(1) + small + m.group(2), text)
assert n == 1, "icon entry not found"
icons.write_text(text)
print("logo written; star = piece with bbox", [round(v) for v in (sx0, sy0, sx1, sy1)], "| icon path", len(small), "chars")
