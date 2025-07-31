#!/usr/bin/env python3
import os
import sys
import math
from PIL import Image, ImageDraw, ImageFont

TTF_PATH = "/tmp/font/font8x8_basic.ttf"
OUTPUT_DIR = "/home/matte/coding/lua/jmtk25/assets/font"

SIZES = [8, 12, 16, 24, 32, 48]
COLS = 16
PAD_X, PAD_Y = 0, 0
CHANNEL = 15
FIRST_CHAR = 0
LAST_CHAR = 127

if not os.path.isfile(TTF_PATH):
    print("Error: TTF not found at", TTF_PATH)
    sys.exit(1)
if not os.path.isdir(OUTPUT_DIR):
    print("Error: output dir not found at", OUTPUT_DIR)
    sys.exit(1)

for size in SIZES:
    font = ImageFont.truetype(TTF_PATH, size)
    # measure max glyph dims for cell
    dummy = Image.new("RGBA", (1, 1))
    draw = ImageDraw.Draw(dummy)
    max_w = max_h = 0
    for code in range(FIRST_CHAR, LAST_CHAR+1):
        ch = chr(code)
        bbox = draw.textbbox((0, 0), ch, font=font)
        w = bbox[2]-bbox[0]
        h = bbox[3]-bbox[1]
        max_w = max(max_w, w)
        max_h = max(max_h, h)
    cell_w = max_w + PAD_X*2
    cell_h = max_h + PAD_Y*2
    count = LAST_CHAR - FIRST_CHAR + 1
    rows = math.ceil(count / COLS)
    atlas_w = COLS * cell_w
    atlas_h = rows * cell_h

    # render PNG atlas
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
    drawA = ImageDraw.Draw(atlas)
    for idx, code in enumerate(range(FIRST_CHAR, LAST_CHAR+1)):
        ch = chr(code)
        col, row = idx % COLS, idx // COLS
        x0 = col * cell_w + PAD_X
        y0 = row * cell_h + PAD_Y
        drawA.text((x0, y0), ch, font=font, fill=(255, 255, 255, 255))

    base = f"font8x8_basic_{size}"
    png_path = os.path.join(OUTPUT_DIR, base + ".png")
    fnt_path = os.path.join(OUTPUT_DIR, base + ".fnt")
    atlas.save(png_path)
    print("Wrote", png_path)

    # write full‐cell .fnt so glyphs aren’t cropped
    with open(fnt_path, "w", encoding="utf-8") as f:
        f.write(
            f'info face="font8x8_basic" size={size} bold=0 italic=0 '
            'charset="" unicode=1 stretchH=100 smooth=1 aa=1 '
            'padding=0,0,0,0 spacing=1,1\n'
        )
        f.write(
            f'common lineHeight={cell_h} base={cell_h} '
            f'scaleW={atlas_w} scaleH={atlas_h} pages=1 packed=0\n'
        )
        f.write(f'page id=0 file="{base}.png"\n')
        f.write(f'chars count={count}\n')
        for idx, code in enumerate(range(FIRST_CHAR, LAST_CHAR+1)):
            col, row = idx % COLS, idx // COLS
            x = col * cell_w
            y = row * cell_h
            # use full cell dims:
            w = cell_w
            h = cell_h
            f.write(
                f'char id={code} x={x} y={y} '
                f'width={w} height={h} '
                f'xoffset=0 yoffset=0 xadvance={cell_w} '
                f'page=0 chnl={CHANNEL}\n'
            )
    print("Wrote", fnt_path)

print("All done!")
