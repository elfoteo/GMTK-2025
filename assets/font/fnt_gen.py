#!/usr/bin/env python3
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFont

# ──────────────────────────────────────────────────────────────────────────────
# USAGE / ARGS
# ──────────────────────────────────────────────────────────────────────────────

if len(sys.argv) > 2:
    print("Usage: python3 fnt_gen.py [path/to/font8x8_basic.ttf]")
    sys.exit(1)

TTF_PATH = sys.argv[1] if len(sys.argv) == 2 else "font8x8_basic.ttf"
if not os.path.isfile(TTF_PATH):
    print(f"Error: cannot find TTF at '{TTF_PATH}'.")
    sys.exit(2)

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────

BASENAME = os.path.splitext(os.path.basename(TTF_PATH))[0]
PNG_PATH = f"{BASENAME}.png"
FNT_PATH = f"{BASENAME}.fnt"

FIRST_CHAR = 0
LAST_CHAR = 127

FONT_PX = 8
COLS = 16
PAD_X = 0
PAD_Y = 0
CHANNEL = 15

# ──────────────────────────────────────────────────────────────────────────────
# 1) LOAD FONT
# ──────────────────────────────────────────────────────────────────────────────

try:
    font = ImageFont.truetype(TTF_PATH, FONT_PX)
except OSError as e:
    print(f"Error: failed to load TTF '{TTF_PATH}': {e}")
    sys.exit(3)

# Create a dummy image just for measurement
_dummy_img = Image.new("RGBA", (1, 1))
_draw = ImageDraw.Draw(_dummy_img)

# Measure max glyph size to define cell size
max_w = max_h = 0
for code in range(FIRST_CHAR, LAST_CHAR + 1):
    ch = chr(code)
    bbox = _draw.textbbox((0, 0), ch, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    max_w = max(max_w, w)
    max_h = max(max_h, h)

CELL_W = max_w + PAD_X * 2
CELL_H = max_h + PAD_Y * 2

count = LAST_CHAR - FIRST_CHAR + 1
rows = math.ceil(count / COLS)
atlas_w = COLS * CELL_W
atlas_h = rows * CELL_H

# ──────────────────────────────────────────────────────────────────────────────
# 2) RENDER ATLAS PNG
# ──────────────────────────────────────────────────────────────────────────────

img = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

for idx, code in enumerate(range(FIRST_CHAR, LAST_CHAR + 1)):
    ch = chr(code)
    col = idx % COLS
    row = idx // COLS
    x0 = col * CELL_W + PAD_X
    y0 = row * CELL_H + PAD_Y
    draw.text((x0, y0), ch, font=font, fill=(255, 255, 255, 255))

img.save(PNG_PATH)
print("✔ Wrote atlas PNG:", PNG_PATH)

# ──────────────────────────────────────────────────────────────────────────────
# 3) WRITE .fnt FILE
# ──────────────────────────────────────────────────────────────────────────────

with open(FNT_PATH, "w", encoding="utf-8") as f:
    f.write(
        f'info face="{BASENAME}" size={FONT_PX} bold=0 italic=0 charset="" '
        'unicode=1 stretchH=100 smooth=1 aa=1 '
        'padding=0,0,0,0 spacing=1,1\n'
    )
    f.write(
        f'common lineHeight={CELL_H} base={CELL_H} '
        f'scaleW={atlas_w} scaleH={atlas_h} pages=1 packed=0\n'
    )
    f.write(f'page id=0 file="{os.path.basename(PNG_PATH)}"\n')
    f.write(f'chars count={count}\n')

    for idx, code in enumerate(range(FIRST_CHAR, LAST_CHAR + 1)):
        col = idx % COLS
        row = idx // COLS
        x = col * CELL_W
        y = row * CELL_H
        ch = chr(code)
        bbox = draw.textbbox((0, 0), ch, font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        f.write(
            f'char id={code} x={x} y={y} '
            f'width={w} height={h} '
            f'xoffset=0 yoffset=0 xadvance={CELL_W} '
            f'page=0 chnl={CHANNEL}\n'
        )

print("✔ Wrote BMFont descriptor:", FNT_PATH)
