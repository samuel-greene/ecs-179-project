# Generates the game's sprites in the style of friendly_placeholder.png:
# black outlines, flat colours, dark left/bottom edges.
# Run: python3 sprites.py
import math
import os
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
os.chdir(Path(__file__).parent)

# Shades from dark to light.
RAMPS = {
    'H': ['#c99a6a', '#f9cb9c', '#fff2cc'],  # friendly skin, house walls
    'B': ['#20124d', '#1c4587'],             # friendly blue
    'G': ['#008d00', '#31ee35', '#9dff8a'],  # alien skin
    'L': ['#5fa800', '#99ff00'],             # alien suit
    'M': ['#4a4f5e', '#8a90a3', '#c5cad6'],  # metal
    'R': ['#a3172a', '#ff3b3b'],             # red
    'T': ['#00828a', '#00d1c1'],             # teal
    'Y': ['#c47f00', '#ffc933', '#fff3a6'],  # gold
}
EXACT = {'k': '#000000', 'w': '#ffffff', 'n': '#20124d', 'd': '#5fa800', 'y': '#c47f00'}


def hex_rgba(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def render(rows):
    w = max(len(r) for r in rows)
    g = [list(r.ljust(w, '.')) for r in rows]
    h = len(g)

    def filled(x, y):
        return 0 <= x < w and 0 <= y < h and g[y][x] != '.'

    def same(x, y, m):
        return 0 <= x < w and 0 <= y < h and (g[y][x] == m or g[y][x] in EXACT)

    def dist(x, y, dx, dy, m):
        d = 0
        while same(x, y, m):
            x += dx
            y += dy
            d += 1
        return d

    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            ch = g[y][x]
            if ch == '.':
                if any(filled(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    img.putpixel((x, y), hex_rgba(EXACT['k']))
                continue
            if ch in EXACT:
                img.putpixel((x, y), hex_rgba(EXACT[ch]))
                continue
            ramp = RAMPS[ch]
            edge = min(dist(x, y, -1, 0, ch), dist(x, y, 0, 1, ch))
            shade = 0 if edge == 1 else (1 if edge == 2 or len(ramp) == 2 else 2)
            img.putpixel((x, y), hex_rgba(ramp[min(shade, len(ramp) - 1)]))
    # Trim evenly from both sides so the body stays centred when flipped.
    left, top, right, bottom = img.getbbox()
    side = min(left, w - right)
    return img.crop((side, top, w - side, bottom))


def friendly():
    src = Image.open(ROOT / 'Sprites' / 'friendly_placeholder.png').convert('RGBA')
    src = src.resize((20, 20), Image.NEAREST)
    return src.crop(src.getbbox())


BASIC = [
    '.....L.......L.....',
    '.....G.......G.....',
    '......G.....G......',
    '......G.....G......',
    '.......GGGGG.......',
    '.....GGGGGGGGG.....',
    '.....GGwkGGwkG.....',
    '.....GGwkGGwkG.....',
    '.....GGGGGGGGG.....',
    '.....GGGGkGGGG.....',
    '......GGGGGGG......',
    '...................',
    '......LLLLLLL......',
    '......LdLLLdL......',
    '......LLdLdLL......',
    '......LLLdLLL......',
    '......LLLLLLL......',
    '......GG...GG......',
    '......GG...GG......',
    '...................',
]

GUN = list(BASIC)
GUN[13] = '......LdLLLdLMMMMR.'
GUN[14] = '......LLdLdLLGMM...'

HEAVY = [
    '...................',
    '......MMMMMMM......',
    '.....MMMMMMMMM.....',
    '....GGGGGGGGGGG....',
    '....GGRRGGGRRGG....',
    '....GGGGGGGGGGG....',
    '....GGGkkkkkGGG....',
    '.....GGGGGGGGG.....',
    '...................',
    '.GG.MMMMMMMMMMM.GG.',
    '.GG.MMMMRRRMMMM.GG.',
    '.GG.MMMMRRRMMMM.GG.',
    '.GG.MMMMMMMMMMM.GG.',
    '.MM.MMMMMMMMMMM.MM.',
    '.....MMM...MMM.....',
    '.....MMM...MMM.....',
    '....MMMM...MMMM....',
    '...................',
]

FAST = [
    '...................',
    '....T....T.........',
    '.....G....G........',
    '......G....G.......',
    '......GGGGGGG......',
    '.....GGGGGGGGG.....',
    '.....TTTwTTTwT.....',
    '.....GGGGGGGGG.....',
    '......GGkkkGG......',
    '...................',
    '.......TTTTT.......',
    '.......TTTwT.......',
    '.......TTwTT.......',
    '.......TwTTT.......',
    '.......G...G.......',
    '.......G...G.......',
    '.......G...G.......',
    '......MM...MM......',
    '...................',
]

HOUSE = []
for r in range(1, 10):
    half = 1 + int(r * 1.4)
    row = ['.'] * 27
    for x in range(13 - half, 14 + half):
        row[x] = 'R'
    HOUSE.append(''.join(row))
HOUSE.insert(0, '.' * 27)
for r in range(1, 5):
    HOUSE[r] = HOUSE[r][:18] + 'MM' + HOUSE[r][20:]
HOUSE.append('.' * 27)
for r in range(11):
    HOUSE.append('...' + 'H' * 21 + '...')
HOUSE.append('.' * 27)


def stamp(rows, x, y, patch):
    for dy, line in enumerate(patch):
        r = list(rows[y + dy])
        for dx, ch in enumerate(line):
            r[x + dx] = ch
        rows[y + dy] = ''.join(r)


for wx in (4, 17):
    stamp(HOUSE, wx, 13, ['kkkkkk', 'kTTTTk', 'kTwTTk', 'kTTTTk', 'kkkkkk'])
stamp(HOUSE, 10, 14, ['kkkkkkk', 'kBBBBBk', 'kBBBBBk', 'kBBBByk', 'kBBBBBk', 'kBBBBBk', 'kBBBBBk', 'kBBBBBk'])

COIN = []
for y in range(11):
    row = ''
    for x in range(11):
        row += 'Y' if math.hypot(x - 5, y - 5) <= 3.9 else '.'
    COIN.append(row)
stamp(COIN, 5, 3, ['y', 'y', 'y', 'y', 'y'])

# Tiling lawn: muted greens, no outlines, so units and health bars stand out.
LAWN_BASE, LAWN_DARK, LAWN_LIGHT = '#3f6e36', '#345d2d', '#4b7f40'
TUFT = ['x.x', '.x.']
LAWN_TUFTS = [(3, 4), (20, 9), (37, 3), (10, 22), (29, 27), (42, 20), (5, 38), (22, 42), (38, 36)]
LAWN_SPECKS = [(14, 13), (33, 15), (46, 30), (17, 33), (2, 26), (27, 2), (44, 45), (9, 47)]


def lawn(size=48):
    img = Image.new('RGBA', (size, size), hex_rgba(LAWN_BASE))
    for i, (x, y) in enumerate(LAWN_TUFTS):
        colour = hex_rgba(LAWN_DARK if i % 2 else LAWN_LIGHT)
        for dy, line in enumerate(TUFT):
            for dx, ch in enumerate(line):
                if ch == 'x':
                    img.putpixel(((x + dx) % size, (y + dy) % size), colour)
    for x, y in LAWN_SPECKS:
        img.putpixel((x, y), hex_rgba(LAWN_DARK))
    return img


out = {
    'Aliens/alien_basic': render(BASIC),
    'Aliens/alien_gun': render(GUN),
    'Aliens/alien_heavy': render(HEAVY),
    'Aliens/alien_fast': render(FAST),
    'friendly': friendly(),
    'house': render(HOUSE),
    'coin': render(COIN),
}
for name, img in out.items():
    img.save(ROOT / 'Sprites' / f'{name}.png')
lawn().save(ROOT / 'Sprites' / 'lawn.png')
Image.new('RGBA', (2, 2), hex_rgba(EXACT['k'])).save(ROOT / 'Sprites' / 'projectile.png')

scale, pad = 8, 16
tallest = max(i.height for i in out.values()) * scale
sheet = Image.new('RGBA', (sum(i.width * scale + pad for i in out.values()) + pad, tallest + 2 * pad), (40, 44, 60, 255))
x = pad
for img in [out['friendly']] + [v for k, v in out.items() if k != 'friendly']:
    big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    sheet.alpha_composite(big, (x, pad + tallest - big.height))
    x += big.width + pad
sheet.save('preview.png')
print('ok')
