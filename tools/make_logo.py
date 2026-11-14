"""Draws FieldGuide's project logo (an open field guide with a trail and a
waypoint) to media/logo.png. Original artwork, no game assets.

    python tools/make_logo.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

S = 4  # supersampling
W = 400 * S
img = Image.new("RGB", (W, W), (24, 32, 44))
d = ImageDraw.Draw(img)

# Night-sky backdrop with a soft glow behind the book.
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse((W * 0.12, W * 0.12, W * 0.88, W * 0.88), fill=255)
glow = glow.filter(ImageFilter.GaussianBlur(60 * S))
img.paste(Image.new("RGB", (W, W), (58, 78, 98)), (0, 0), glow)
random.seed(7)
for _ in range(70):
    x, y, r = random.uniform(0, W), random.uniform(0, W * 0.4), random.uniform(1, 2.6) * S
    d.ellipse((x - r, y - r, x + r, y + r), fill=(200, 210, 230))

def p(x, y):
    return (x * S, y * S)

# Book: two pages as quadrilaterals, a dark cover behind them.
cover = [p(52, 128), p(200, 150), p(348, 128), p(352, 312), p(200, 338), p(48, 312)]
d.polygon(cover, fill=(92, 52, 30))
left = [p(64, 122), p(198, 144), p(198, 322), p(62, 300)]
right = [p(202, 144), p(336, 122), p(338, 300), p(202, 322)]
d.polygon(left, fill=(236, 220, 182))
d.polygon(right, fill=(244, 230, 194))
d.line([p(200, 144), p(200, 324)], fill=(150, 112, 70), width=4 * S)

# Left page: lines of text.
for i in range(7):
    y0 = 158 + i * 19
    d.line([p(80, y0 - 2 + i * 0.5), p(182, y0 + 14 - (i * 0.3))], fill=(160, 138, 104), width=3 * S)

# Right page: a dotted trail winding to a waypoint.
pts = []
for i in range(60):
    t = i / 59
    x = 222 + t * 88
    y = 290 - t * 120 + math.sin(t * math.pi * 2.2) * 22
    pts.append((x, y))
for i, (x, y) in enumerate(pts):
    if i % 4 < 2:
        d.ellipse((p(x - 2.6, y - 2.6) + p(x + 2.6, y + 2.6)), fill=(176, 64, 40))
# Waypoint marker.
mx, my = pts[-1]
d.polygon([p(mx, my + 4), p(mx - 13, my - 16), p(mx + 13, my - 16)], fill=(214, 72, 44))
d.ellipse((p(mx - 14, my - 34) + p(mx + 14, my - 6)), fill=(214, 72, 44))
d.ellipse((p(mx - 6, my - 26) + p(mx + 6, my - 14)), fill=(244, 230, 194))

# Bookmark ribbon.
d.polygon([p(272, 126), p(290, 123), p(290, 360), p(281, 348), p(272, 362)], fill=(52, 120, 168))

img = img.resize((400, 400), Image.LANCZOS)
out = os.path.join(os.path.dirname(__file__), "..", "media", "logo.png")
os.makedirs(os.path.dirname(out), exist_ok=True)
img.save(out)
print(os.path.abspath(out))
