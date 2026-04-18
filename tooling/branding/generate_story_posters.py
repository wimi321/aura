#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps

W, H = 1600, 2400
ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / 'assets' / 'images' / 'characters'
SOURCE_SQUARE_DIR = ROOT / 'tooling' / 'branding' / 'source-square-covers'


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip('#')
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))


def gradient_background(colors: list[tuple[float, str]]) -> Image.Image:
    image = Image.new('RGB', (W, H))
    pixels = image.load()
    parsed = [(stop, rgb(color)) for stop, color in colors]
    for y in range(H):
        position = y / max(H - 1, 1)
        for idx in range(len(parsed) - 1):
            left_stop, left_color = parsed[idx]
            right_stop, right_color = parsed[idx + 1]
            if left_stop <= position <= right_stop:
                span = max(right_stop - left_stop, 1e-6)
                t = (position - left_stop) / span
                color = tuple(
                    int(left_color[channel] + (right_color[channel] - left_color[channel]) * t)
                    for channel in range(3)
                )
                break
        else:
            color = parsed[-1][1]
        for x in range(W):
            pixels[x, y] = color
    return image


def overlay_noise(base: Image.Image, seed: int, opacity: int = 22) -> None:
    rng = random.Random(seed)
    noise = Image.new('RGB', (W, H))
    pixels = noise.load()
    for y in range(H):
        for x in range(W):
            value = 120 + rng.randint(-55, 55)
            pixels[x, y] = (value, value, value)
    noise = noise.filter(ImageFilter.GaussianBlur(0.35))
    mask = Image.new('L', (W, H), opacity)
    base.paste(noise, (0, 0), mask)


def blurred_shape(shape_fn, blur: float = 26.0) -> Image.Image:
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    shape_fn(draw)
    return layer.filter(ImageFilter.GaussianBlur(blur))


def alpha_composite(base: Image.Image, layer: Image.Image) -> None:
    base.alpha_composite(layer)


def add_glow(base: Image.Image, center: tuple[float, float], radius: int,
             color: str, opacity: int = 180, aspect: float = 1.0) -> None:
    cx, cy = center
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rx = radius
    ry = max(12, int(radius * aspect))
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=rgb(color) + (opacity,))
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.42))
    alpha_composite(base, layer)


def add_vignette(base: Image.Image, strength: int = 185) -> None:
    mask = Image.new('L', (W, H), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((-220, -180, W + 220, H + 180), fill=255)
    mask = ImageOps.invert(mask.filter(ImageFilter.GaussianBlur(180)))
    alpha = mask.point(lambda value: int(value * (strength / 255)))
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    layer.putalpha(alpha)
    alpha_composite(base, layer)


def add_bottom_fade(base: Image.Image, start: float = 0.58) -> None:
    fade = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(fade)
    start_y = int(H * start)
    for y in range(start_y, H):
        t = (y - start_y) / max(H - start_y, 1)
        opacity = int(255 * (t ** 1.6) * 0.96)
        draw.line((0, y, W, y), fill=(4, 7, 10, opacity), width=1)
    alpha_composite(base, fade)


def add_border(base: Image.Image, color: tuple[int, int, int], opacity: int = 72) -> None:
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((32, 32, W - 32, H - 32), radius=44,
                           outline=color + (opacity,), width=3)
    alpha_composite(base, layer)


def add_solid_overlay(base: Image.Image, color: str, opacity: int = 64) -> None:
    layer = Image.new('RGBA', (W, H), rgb(color) + (opacity,))
    alpha_composite(base, layer)


def add_particles(base: Image.Image, points: list[tuple[float, float, int, str, int]]) -> None:
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for x, y, size, color, opacity in points:
        draw.ellipse((x - size, y - size, x + size, y + size), fill=rgb(color) + (opacity,))
    layer = layer.filter(ImageFilter.GaussianBlur(4))
    alpha_composite(base, layer)


def _feathered_square_mask(size: int, inset: int = 16, radius: int = 42,
                           blur: int = 16) -> Image.Image:
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((inset, inset, size - inset, size - inset),
                           radius=radius, fill=255)
    return mask.filter(ImageFilter.GaussianBlur(blur))


def posterize_square_cover(
    source_name: str,
    *,
    accent: str,
    shadow_tint: str,
    glow: str,
    y_offset: int,
    centering: tuple[float, float] = (0.5, 0.44),
    foreground_scale: float = 0.9,
    overlay_color: str = '#05080d',
    overlay_opacity: int = 52,
    seed: int = 0,
) -> Image.Image:
    source_path = SOURCE_SQUARE_DIR / f'{source_name}.png'
    source = Image.open(source_path).convert('RGB')

    background = ImageOps.fit(
        source,
        (W, H),
        method=Image.Resampling.LANCZOS,
        centering=centering,
    )
    background = background.filter(ImageFilter.GaussianBlur(22))
    background = ImageEnhance.Color(background).enhance(0.82)
    background = ImageEnhance.Brightness(background).enhance(0.54)
    base = background.convert('RGBA')

    add_solid_overlay(base, overlay_color, overlay_opacity)
    add_glow(base, (1190, 330), 165, glow, 108)
    add_glow(base, (375, 1540), 265, shadow_tint, 82)

    fg_size = int(W * foreground_scale)
    foreground = source.resize((fg_size, fg_size), Image.Resampling.LANCZOS).convert('RGBA')
    foreground = ImageEnhance.Contrast(foreground).enhance(1.03)
    foreground = ImageEnhance.Sharpness(foreground).enhance(1.08)
    mask = _feathered_square_mask(fg_size)
    foreground.putalpha(mask)

    x = (W - fg_size) // 2
    y = y_offset

    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle(
        (x + 24, y + 42, x + fg_size + 24, y + fg_size + 64),
        radius=54,
        fill=rgb(shadow_tint) + (130,),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(48))
    alpha_composite(base, shadow)

    highlight = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(highlight)
    draw.rounded_rectangle(
        (x, y, x + fg_size, y + fg_size),
        radius=48,
        outline=rgb(accent) + (48,),
        width=2,
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(0.8))

    base.alpha_composite(foreground, (x, y))
    alpha_composite(base, highlight)
    add_bottom_fade(base, 0.56)
    add_vignette(base)
    add_border(base, rgb(accent))
    overlay_noise(base, seed, opacity=18)
    return base


def make_shadow_warden() -> Image.Image:
    base = gradient_background([
        (0.0, '#0b1119'),
        (0.45, '#1b2330'),
        (1.0, '#090c10'),
    ]).convert('RGBA')
    add_glow(base, (1180, 350), 140, '#d8b57a', 160)
    add_glow(base, (450, 1540), 210, '#54698e', 80)

    sky = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sky)
    draw.ellipse((180, 180, 1380, 980), fill=(17, 27, 39, 88))
    draw.polygon([(0, 460), (380, 340), (760, 430), (1160, 300), (1600, 420), (1600, 0), (0, 0)], fill=(8, 12, 18, 120))
    alpha_composite(base, sky.filter(ImageFilter.GaussianBlur(30)))

    manor = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(manor)
    draw.polygon([(190, 800), (520, 800), (800, 620), (1115, 800), (1410, 800), (1410, 1600), (190, 1600)], fill=(15, 18, 24, 255))
    draw.polygon([(420, 800), (800, 555), (1180, 800)], fill=(10, 13, 18, 255))
    draw.polygon([(620, 1600), (980, 1600), (1070, 1710), (530, 1710)], fill=(12, 15, 20, 220))
    for x in (340, 540, 840, 1080, 1280):
        draw.rectangle((x, 970, x + 82, 1380), fill=(23, 28, 37, 255))
        draw.rectangle((x + 15, 1010, x + 67, 1138), fill=(210, 177, 118, 180))
        draw.rectangle((x + 15, 1198, x + 67, 1328), fill=(206, 178, 123, 155))
    draw.rectangle((676, 895, 928, 1600), fill=(8, 11, 14, 255))
    draw.polygon([(736, 1040), (868, 1040), (896, 1188), (708, 1188)], fill=(213, 179, 121, 110))
    for x in (280, 1190):
        draw.rectangle((x, 870, x + 18, 1350), fill=(18, 22, 30, 200))
        draw.rectangle((x + 84, 870, x + 102, 1350), fill=(18, 22, 30, 200))
        draw.rectangle((x, 860, x + 102, 886), fill=(18, 22, 30, 200))
    alpha_composite(base, manor.filter(ImageFilter.GaussianBlur(0.2)))

    moonbeam = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(moonbeam)
    draw.polygon([(1110, 420), (1310, 420), (930, 1540), (660, 1540)], fill=(202, 188, 143, 46))
    alpha_composite(base, moonbeam.filter(ImageFilter.GaussianBlur(34)))

    portraits = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(portraits)
    for box in ((220, 610, 340, 790), (1260, 640, 1380, 830), (1185, 890, 1325, 1090)):
        draw.rounded_rectangle(box, radius=18, outline=(191, 159, 111, 105), width=4)
        draw.rounded_rectangle((box[0] + 10, box[1] + 10, box[2] - 10, box[3] - 10), radius=12, fill=(18, 20, 27, 160))
    alpha_composite(base, portraits.filter(ImageFilter.GaussianBlur(1.4)))

    figure = blurred_shape(lambda d: (
        d.ellipse((1030, 1080, 1120, 1170), fill=(7, 9, 12, 255)),
        d.polygon([(980, 1170), (1165, 1170), (1228, 1615), (938, 1615)], fill=(8, 10, 14, 255)),
        d.rectangle((1080, 1250, 1134, 1590), fill=(11, 12, 16, 255)),
        d.rectangle((1188, 1210, 1212, 1450), fill=(183, 161, 112, 170)),
    ), blur=2.2)
    alpha_composite(base, figure)

    invitation = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(invitation)
    draw.polygon([(248, 1718), (470, 1688), (516, 1838), (292, 1872)], fill=(208, 195, 156, 180))
    draw.line((304, 1736, 452, 1714), fill=(108, 94, 80, 120), width=5)
    draw.line((326, 1782, 476, 1758), fill=(108, 94, 80, 110), width=5)
    draw.ellipse((252, 1782, 380, 1844), outline=(106, 34, 44, 160), width=6)
    alpha_composite(base, invitation.filter(ImageFilter.GaussianBlur(1.2)))

    puddle = blurred_shape(lambda d: d.ellipse((228, 1802, 488, 1876), fill=(12, 14, 17, 190)), blur=1.2)
    alpha_composite(base, puddle)

    gate = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(gate)
    for x in (250, 410, 570, 1030, 1190, 1350):
        draw.rectangle((x, 1500, x + 26, 2060), fill=(10, 13, 18, 135))
        draw.polygon([(x - 12, 1510), (x + 13, 1458), (x + 38, 1510)], fill=(15, 18, 25, 135))
    draw.rectangle((220, 1682, 1382, 1710), fill=(10, 13, 18, 115))
    alpha_composite(base, gate.filter(ImageFilter.GaussianBlur(3.0)))

    add_particles(base, [(1120, 1460, 10, '#ecd4a3', 80), (1230, 1380, 7, '#c9b27f', 70)])
    add_bottom_fade(base, 0.60)
    add_vignette(base)
    add_border(base, (181, 158, 118))
    overlay_noise(base, 11)
    return base


def make_oath_arbiter() -> Image.Image:
    base = gradient_background([
        (0.0, '#140d12'),
        (0.45, '#31141d'),
        (1.0, '#0a090b'),
    ]).convert('RGBA')
    add_glow(base, (1160, 360), 135, '#ddb57f', 145)
    add_glow(base, (430, 1510), 280, '#7a1830', 95)

    ring = blurred_shape(lambda d: d.ellipse((345, 410, 1255, 1320), outline=(199, 165, 110, 255), width=18), blur=1.0)
    alpha_composite(base, ring)

    tribunal = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tribunal)
    for y in (1165, 1260, 1355):
        draw.polygon([(420, y), (1180, y), (1085, y + 58), (515, y + 58)], fill=(56, 18, 26, 95))
    draw.polygon([(560, 1110), (1040, 1110), (1125, 1620), (475, 1620)], fill=(25, 10, 14, 210))
    draw.ellipse((720, 720, 880, 880), fill=(198, 162, 108, 205))
    draw.rectangle((765, 850, 835, 1670), fill=(30, 9, 14, 255))
    draw.polygon([(645, 910), (960, 910), (1035, 1510), (565, 1510)], fill=(164, 132, 89, 235))
    draw.rectangle((754, 1100, 846, 1710), fill=(26, 8, 13, 255))
    draw.ellipse((744, 1010, 856, 1120), fill=(23, 7, 12, 245))
    draw.polygon([(640, 1510), (960, 1510), (1085, 1588), (515, 1588)], fill=(141, 39, 52, 125))
    draw.line((495, 980, 640, 1280), fill=(114, 33, 45, 140), width=8)
    draw.line((1105, 980, 960, 1280), fill=(114, 33, 45, 140), width=8)
    alpha_composite(base, tribunal.filter(ImageFilter.GaussianBlur(0.7)))

    petals = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(petals)
    for points in [
        [(340, 980), (422, 912), (484, 1004), (396, 1058)],
        [(1140, 1010), (1225, 940), (1290, 1018), (1200, 1090)],
        [(635, 1540), (725, 1450), (804, 1545), (712, 1628)],
        [(910, 1435), (970, 1370), (1040, 1436), (968, 1508)],
    ]:
        draw.polygon(points, fill=(172, 61, 74, 180))
    alpha_composite(base, petals.filter(ImageFilter.GaussianBlur(1.8)))

    add_bottom_fade(base, 0.58)
    add_vignette(base)
    add_border(base, (198, 164, 112))
    overlay_noise(base, 23)
    return base


def make_last_train_keeper() -> Image.Image:
    base = gradient_background([
        (0.0, '#0a1018'),
        (0.5, '#152234'),
        (1.0, '#06080d'),
    ]).convert('RGBA')
    add_glow(base, (1210, 345), 130, '#c89455', 160)
    add_glow(base, (320, 1510), 250, '#542032', 80)
    add_glow(base, (1180, 960), 110, '#6ab0bc', 60)

    roof = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(roof)
    draw.polygon([(60, 620), (1460, 620), (1600, 860), (0, 860)], fill=(9, 14, 21, 150))
    for x in (180, 510, 840, 1170, 1450):
        draw.rectangle((x, 650, x + 18, 1620), fill=(18, 24, 34, 120))
    alpha_composite(base, roof.filter(ImageFilter.GaussianBlur(1.2)))

    train = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(train)
    draw.polygon([(210, 860), (1390, 860), (1435, 1638), (170, 1638)], fill=(18, 28, 42, 245))
    draw.polygon([(1290, 1638), (1440, 1638), (1330, 1860), (1190, 1860)], fill=(14, 18, 24, 225))
    for index, x in enumerate((260, 455, 650, 845, 1040, 1235)):
        top = 930 if index < 5 else 960
        draw.rectangle((x, top, x + 122, 1320), fill=(206, 170, 116, 185))
        draw.rectangle((x - 6, top - 8, x + 128, 1332), outline=(35, 43, 56, 180), width=6)
    draw.rectangle((220, 1518, 1380, 1542), fill=(11, 15, 20, 220))
    draw.rectangle((185, 1648, 1438, 1670), fill=(10, 13, 18, 220))
    alpha_composite(base, train.filter(ImageFilter.GaussianBlur(0.8)))

    rain = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(rain)
    for x in range(-120, W + 180, 115):
        draw.line((x, 150, x - 210, H), fill=(96, 126, 164, 55), width=4)
    alpha_composite(base, rain.filter(ImageFilter.GaussianBlur(0.6)))

    rails = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(rails)
    for x in (330, 520, 710, 900, 1090, 1280):
        draw.line((x, 1790, x - 150, H), fill=(101, 24, 31, 120), width=8)
    draw.polygon([(180, 1672), (1440, 1672), (1350, 1830), (250, 1830)], fill=(7, 10, 15, 120))
    alpha_composite(base, rails.filter(ImageFilter.GaussianBlur(1.6)))

    fog = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(fog)
    draw.ellipse((160, 1450, 780, 1820), fill=(117, 130, 156, 38))
    draw.ellipse((730, 1420, 1490, 1790), fill=(117, 130, 156, 32))
    draw.ellipse((30, 1670, 640, 1940), fill=(92, 32, 40, 30))
    alpha_composite(base, fog.filter(ImageFilter.GaussianBlur(42)))

    signal = blurred_shape(lambda d: (
        d.rectangle((138, 1585, 204, 1875), fill=(24, 18, 18, 255)),
        d.ellipse((110, 1538, 238, 1666), fill=(13, 17, 22, 230)),
        d.ellipse((138, 1566, 210, 1638), fill=(144, 40, 40, 160)),
    ), blur=1.5)
    alpha_composite(base, signal)

    figure = blurred_shape(lambda d: (
        d.ellipse((1182, 1298, 1252, 1368), fill=(7, 9, 12, 255)),
        d.polygon([(1148, 1368), (1284, 1368), (1326, 1628), (1100, 1628)], fill=(9, 11, 15, 255)),
        d.rectangle((1202, 1418, 1238, 1630), fill=(12, 14, 18, 255)),
        d.rectangle((1300, 1378, 1318, 1522), fill=(204, 166, 114, 170)),
    ), blur=2.4)
    alpha_composite(base, figure)

    suitcase = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(suitcase)
    draw.rounded_rectangle((260, 1588, 420, 1708), radius=16, fill=(42, 28, 24, 170))
    draw.rounded_rectangle((300, 1550, 380, 1610), radius=18, outline=(132, 102, 75, 110), width=6)
    draw.line((302, 1636, 382, 1636), fill=(155, 118, 86, 80), width=4)
    alpha_composite(base, suitcase.filter(ImageFilter.GaussianBlur(1.2)))

    add_bottom_fade(base, 0.60)
    add_vignette(base)
    add_border(base, (180, 144, 94))
    overlay_noise(base, 37)
    return base


def make_memory_smuggler() -> Image.Image:
    base = gradient_background([
        (0.0, '#07141b'),
        (0.5, '#0d2430'),
        (1.0, '#04070b'),
    ]).convert('RGBA')
    add_glow(base, (1195, 325), 170, '#32b9c1', 150)
    add_glow(base, (360, 1500), 240, '#a13f81', 120)

    skyline = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(skyline)
    for x, height, glow in ((180, 540, 0), (330, 760, 1), (520, 620, 0), (1110, 700, 1), (1280, 560, 0)):
        draw.rectangle((x, 980 - height, x + 130, 1610), fill=(10, 19, 28, 180))
        if glow:
            for y in range(480, 1480, 140):
                draw.rectangle((x + 42, y, x + 88, y + 78), fill=(67, 212, 214, 55))
    alpha_composite(base, skyline.filter(ImageFilter.GaussianBlur(1.0)))

    grid = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(grid)
    for x in range(220, 1410, 150):
        draw.line((x, 520, x, 1820), fill=(181, 74, 137, 105), width=5)
    for y in range(700, 1800, 180):
        draw.line((150, y, 1450, y), fill=(72, 194, 194, 80), width=4)
    draw.rounded_rectangle((420, 700, 1195, 1515), radius=58, outline=(59, 205, 205, 210), width=12)
    alpha_composite(base, grid.filter(ImageFilter.GaussianBlur(0.9)))

    case = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(case)
    draw.rounded_rectangle((540, 870, 1060, 1265), radius=38, fill=(9, 16, 24, 235), outline=(56, 204, 204, 110), width=6)
    draw.rectangle((705, 830, 895, 900), fill=(15, 24, 34, 210))
    draw.rounded_rectangle((746, 790, 854, 860), radius=30, outline=(58, 204, 204, 125), width=5)
    draw.polygon([(800, 905), (980, 1080), (800, 1255), (620, 1080)], fill=(14, 19, 29, 255), outline=(59, 205, 205, 140))
    draw.polygon([(800, 970), (910, 1080), (800, 1190), (690, 1080)], fill=(17, 25, 37, 255))
    draw.line((800, 905, 800, 1255), fill=(59, 205, 205, 95), width=4)
    draw.line((620, 1080, 980, 1080), fill=(59, 205, 205, 95), width=4)
    alpha_composite(base, case.filter(ImageFilter.GaussianBlur(0.5)))

    scan = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(scan)
    for y in range(360, 1380, 115):
        draw.rectangle((1000, y, 1450, y + 12), fill=(10, 24, 33, 100))
    for y in range(760, 1500, 95):
        draw.rectangle((120, y, 490, y + 10), fill=(67, 46, 94, 75))
    alpha_composite(base, scan.filter(ImageFilter.GaussianBlur(1.4)))

    add_bottom_fade(base, 0.59)
    add_vignette(base)
    add_border(base, (59, 205, 205))
    overlay_noise(base, 41)
    return base


def make_night_prefect() -> Image.Image:
    base = gradient_background([
        (0.0, '#09131a'),
        (0.48, '#13242b'),
        (1.0, '#04070a'),
    ]).convert('RGBA')
    add_glow(base, (1180, 310), 175, '#6f9f90', 145)
    add_glow(base, (420, 1460), 220, '#cdbf8e', 50)

    fog = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(fog)
    draw.ellipse((120, 380, 1480, 960), fill=(23, 38, 43, 70))
    draw.ellipse((40, 1380, 960, 1880), fill=(188, 176, 141, 18))
    alpha_composite(base, fog.filter(ImageFilter.GaussianBlur(44)))

    building = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(building)
    draw.rectangle((150, 790, 1450, 1600), fill=(14, 26, 32, 250))
    draw.rectangle((190, 730, 1410, 790), fill=(24, 38, 44, 180))
    for x in (260, 510, 760, 1010, 1260):
        for y in (1030, 1360):
            draw.rectangle((x, y, x + 126, y + 194), fill=(206, 208, 196, 125))
    draw.rectangle((732, 1160, 916, 1600), fill=(9, 12, 16, 250))
    draw.rectangle((780, 930, 868, 1120), fill=(208, 211, 198, 90))
    alpha_composite(base, building.filter(ImageFilter.GaussianBlur(0.7)))

    beam = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(beam)
    draw.polygon([(210, 1710), (1280, 1580), (1345, 1610), (245, 1760)], fill=(223, 213, 175, 90))
    alpha_composite(base, beam.filter(ImageFilter.GaussianBlur(10)))

    key = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(key)
    draw.line((1140, 1500, 1325, 1390), fill=(203, 191, 150, 165), width=11)
    draw.ellipse((1090, 1460, 1160, 1530), outline=(203, 191, 150, 165), width=8)
    draw.line((1285, 1410, 1335, 1375), fill=(203, 191, 150, 165), width=8)
    alpha_composite(base, key.filter(ImageFilter.GaussianBlur(1.1)))

    report = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(report)
    draw.polygon([(320, 1666), (520, 1618), (562, 1782), (358, 1830)], fill=(208, 203, 178, 138))
    draw.rectangle((372, 1642, 424, 1800), fill=(120, 56, 44, 110))
    draw.line((438, 1674, 516, 1654), fill=(118, 118, 112, 95), width=4)
    draw.line((430, 1718, 510, 1698), fill=(118, 118, 112, 90), width=4)
    alpha_composite(base, report.filter(ImageFilter.GaussianBlur(1.2)))

    prefect = blurred_shape(lambda d: (
        d.ellipse((850, 1125, 920, 1192), fill=(7, 9, 12, 255)),
        d.polygon([(824, 1190), (946, 1190), (984, 1560), (792, 1560)], fill=(9, 11, 15, 255)),
        d.rectangle((872, 1232, 902, 1566), fill=(11, 13, 17, 255)),
    ), blur=2.1)
    alpha_composite(base, prefect)

    torch = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(torch)
    draw.ellipse((902, 1220, 1000, 1316), fill=(235, 227, 188, 62))
    draw.polygon([(928, 1260), (1208, 1198), (1228, 1234), (948, 1292)], fill=(231, 222, 184, 52))
    alpha_composite(base, torch.filter(ImageFilter.GaussianBlur(16)))

    add_bottom_fade(base, 0.60)
    add_vignette(base)
    add_border(base, (139, 162, 150))
    overlay_noise(base, 53)
    return base


def make_deskmate() -> Image.Image:
    base = gradient_background([
        (0.0, '#182632'),
        (0.45, '#284154'),
        (1.0, '#05080d'),
    ]).convert('RGBA')
    add_glow(base, (1180, 300), 175, '#d3c287', 150)
    add_glow(base, (410, 1120), 230, '#8da7a4', 70)

    sky = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sky)
    draw.ellipse((120, 140, 1480, 900), fill=(167, 188, 195, 34))
    alpha_composite(base, sky.filter(ImageFilter.GaussianBlur(40)))

    rain = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(rain)
    for x in range(-100, W + 200, 100):
        draw.line((x, 0, x - 240, H), fill=(199, 218, 236, 55), width=4)
    alpha_composite(base, rain.filter(ImageFilter.GaussianBlur(0.9)))

    classroom = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(classroom)
    draw.rounded_rectangle((190, 760, 1410, 1690), radius=30, fill=(46, 64, 81, 140), outline=(171, 188, 194, 55), width=4)
    for x in (430, 800, 1170):
        draw.rectangle((x - 10, 760, x + 10, 1690), fill=(151, 170, 177, 45))
    for y in (1040, 1360):
        draw.rectangle((190, y - 10, 1410, y + 10), fill=(151, 170, 177, 40))
    draw.rectangle((225, 720, 1375, 770), fill=(86, 103, 119, 110))
    alpha_composite(base, classroom.filter(ImageFilter.GaussianBlur(0.6)))

    curtain = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(curtain)
    draw.polygon([(190, 760), (350, 760), (310, 1280), (210, 1480)], fill=(180, 196, 206, 32))
    draw.polygon([(1290, 760), (1410, 760), (1370, 1180), (1320, 1460)], fill=(180, 196, 206, 26))
    alpha_composite(base, curtain.filter(ImageFilter.GaussianBlur(14)))

    desks = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(desks)
    draw.polygon([(220, 1485), (745, 1485), (690, 1755), (170, 1755)], fill=(37, 45, 56, 240))
    draw.polygon([(875, 1430), (1425, 1430), (1380, 1712), (820, 1712)], fill=(41, 52, 64, 240))
    draw.rectangle((265, 1572, 665, 1625), fill=(210, 202, 169, 130))
    draw.rectangle((940, 1525, 1315, 1578), fill=(210, 202, 169, 124))
    draw.rectangle((964, 1300, 1030, 1505), fill=(54, 65, 78, 120))
    draw.rectangle((1270, 1320, 1335, 1512), fill=(54, 65, 78, 100))
    draw.rectangle((340, 1318, 400, 1498), fill=(45, 56, 67, 160))
    draw.rectangle((1110, 1258, 1170, 1448), fill=(45, 56, 67, 150))
    alpha_composite(base, desks.filter(ImageFilter.GaussianBlur(0.8)))

    note = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(note)
    draw.polygon([(1025, 1445), (1242, 1390), (1286, 1558), (1066, 1616)], fill=(229, 220, 185, 190))
    draw.line((1078, 1458, 1214, 1424), fill=(107, 116, 130, 120), width=5)
    draw.line((1096, 1505, 1238, 1469), fill=(107, 116, 130, 110), width=5)
    draw.line((1192, 1388, 1275, 1550), fill=(193, 178, 140, 135), width=4)
    alpha_composite(base, note.filter(ImageFilter.GaussianBlur(0.9)))

    reflected = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(reflected)
    draw.ellipse((280, 1470, 540, 1600), fill=(222, 229, 218, 24))
    draw.ellipse((980, 1380, 1260, 1508), fill=(222, 229, 218, 20))
    alpha_composite(base, reflected.filter(ImageFilter.GaussianBlur(22)))

    silhouette = blurred_shape(lambda d: (
        d.ellipse((570, 1110, 650, 1188), fill=(18, 22, 28, 255)),
        d.polygon([(526, 1186), (696, 1186), (732, 1510), (500, 1510)], fill=(21, 26, 34, 255)),
    ), blur=2.4)
    alpha_composite(base, silhouette)

    add_bottom_fade(base, 0.58)
    add_vignette(base)
    add_border(base, (181, 174, 141))
    overlay_noise(base, 67)
    return base


def make_slayer_mage() -> Image.Image:
    base = gradient_background([
        (0.0, '#0a1318'),
        (0.45, '#16252a'),
        (1.0, '#060709'),
    ]).convert('RGBA')
    add_glow(base, (1220, 360), 150, '#89d9c8', 120)
    add_glow(base, (470, 1200), 280, '#d48c42', 90)

    sky = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sky)
    draw.polygon([(0, 0), (1600, 0), (1600, 620), (1320, 520), (970, 660), (640, 560), (270, 650), (0, 540)], fill=(12, 18, 22, 110))
    alpha_composite(base, sky.filter(ImageFilter.GaussianBlur(26)))

    chapel = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(chapel)
    for left in (230, 560, 890, 1220):
        draw.polygon([(left, 820), (left + 150, 820), (left + 120, 1550), (left + 30, 1550)], fill=(16, 20, 22, 220))
        draw.arc((left - 10, 720, left + 160, 1000), 180, 360, fill=(80, 109, 113, 90), width=8)
    draw.arc((445, 650, 1150, 1340), 180, 360, fill=(92, 121, 126, 100), width=10)
    draw.polygon([(550, 1160), (1045, 1160), (1150, 1610), (445, 1610)], fill=(24, 17, 12, 200))
    draw.rectangle((665, 1265, 930, 1455), fill=(226, 164, 86, 175))
    draw.rectangle((705, 1300, 890, 1334), fill=(94, 57, 38, 130))
    for x in (655, 870):
        draw.line((x, 1268, x, 1454), fill=(110, 72, 51, 115), width=4)
    draw.line((708, 1370, 885, 1370), fill=(110, 72, 51, 115), width=4)
    alpha_composite(base, chapel.filter(ImageFilter.GaussianBlur(0.8)))

    figure = blurred_shape(lambda d: (
        d.ellipse((940, 980, 1030, 1072), fill=(14, 16, 17, 255)),
        d.polygon([(890, 1072), (1084, 1072), (1168, 1585), (832, 1585)], fill=(12, 13, 15, 255)),
        d.rectangle((1098, 1128, 1120, 1450), fill=(170, 154, 110, 155)),
    ), blur=2.0)
    alpha_composite(base, figure)

    rain = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(rain)
    for x in range(-50, W + 200, 120):
        draw.line((x, 260, x - 170, H), fill=(177, 202, 204, 45), width=4)
    alpha_composite(base, rain.filter(ImageFilter.GaussianBlur(0.6)))

    rune = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(rune)
    draw.ellipse((520, 1480, 1080, 1940), outline=(96, 208, 187, 78), width=10)
    draw.ellipse((620, 1560, 980, 1860), outline=(96, 208, 187, 52), width=6)
    draw.line((800, 1490, 800, 1930), fill=(96, 208, 187, 56), width=6)
    draw.line((540, 1710, 1060, 1710), fill=(96, 208, 187, 48), width=6)
    alpha_composite(base, rune.filter(ImageFilter.GaussianBlur(6)))

    add_bottom_fade(base, 0.59)
    add_vignette(base)
    add_border(base, (160, 188, 177))
    overlay_noise(base, 79)
    return base


def make_dungeon_arbiter() -> Image.Image:
    base = gradient_background([
        (0.0, '#0c1018'),
        (0.48, '#171b27'),
        (1.0, '#05060a'),
    ]).convert('RGBA')
    add_glow(base, (1160, 360), 130, '#c49858', 135)
    add_glow(base, (435, 1440), 250, '#611723', 110)

    maze = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(maze)
    for inset in range(220, 620, 86):
        draw.rounded_rectangle((inset, 650, W - inset, 1485), radius=36, outline=(104, 120, 154, 95), width=10)
    for x in (490, 800, 1110):
        draw.rectangle((x - 8, 650, x + 8, 1250), fill=(91, 104, 136, 70))
    for y in (870, 1080, 1290):
        draw.rectangle((330, y - 8, 1270, y + 8), fill=(91, 104, 136, 70))
    alpha_composite(base, maze.filter(ImageFilter.GaussianBlur(0.8)))

    gate = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(gate)
    draw.polygon([(590, 780), (1010, 780), (1125, 1540), (475, 1540)], fill=(12, 15, 20, 255))
    draw.rectangle((685, 900, 915, 1320), fill=(180, 132, 72, 150))
    draw.arc((595, 780, 1005, 1210), 180, 360, fill=(190, 146, 82, 110), width=10)
    draw.rectangle((756, 1360, 844, 1700), fill=(17, 12, 14, 240))
    alpha_composite(base, gate.filter(ImageFilter.GaussianBlur(0.6)))

    torches = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(torches)
    for x in (500, 1100):
        draw.rectangle((x, 1060, x + 20, 1260), fill=(28, 18, 16, 220))
        draw.polygon([(x - 22, 1058), (x + 10, 1002), (x + 42, 1058)], fill=(206, 124, 59, 180))
    alpha_composite(base, torches.filter(ImageFilter.GaussianBlur(2.0)))

    add_bottom_fade(base, 0.60)
    add_vignette(base)
    add_border(base, (167, 145, 106))
    overlay_noise(base, 97)
    return base


POSTERS = {
    'sun-wukong': lambda: posterize_square_cover(
        'sun-wukong',
        accent='#e5b34a',
        shadow_tint='#4d2c11',
        glow='#ffd36d',
        y_offset=180,
        centering=(0.52, 0.48),
        foreground_scale=0.90,
        overlay_color='#080c11',
        overlay_opacity=54,
        seed=101,
    ),
    'lin-daiyu': lambda: posterize_square_cover(
        'lin-daiyu',
        accent='#d8b073',
        shadow_tint='#28493f',
        glow='#efc57b',
        y_offset=180,
        centering=(0.5, 0.46),
        foreground_scale=0.90,
        overlay_color='#071015',
        overlay_opacity=50,
        seed=103,
    ),
    'di-renjie': lambda: posterize_square_cover(
        'di-renjie',
        accent='#bca16e',
        shadow_tint='#1d2f4b',
        glow='#d9b067',
        y_offset=180,
        centering=(0.5, 0.47),
        foreground_scale=0.90,
        overlay_color='#071015',
        overlay_opacity=54,
        seed=107,
    ),
    'nie-xiaoqian': lambda: posterize_square_cover(
        'nie-xiaoqian',
        accent='#7fc9cf',
        shadow_tint='#17342b',
        glow='#88e8ee',
        y_offset=176,
        centering=(0.5, 0.42),
        foreground_scale=0.905,
        overlay_color='#061012',
        overlay_opacity=58,
        seed=109,
    ),
    'archive-keeper': lambda: posterize_square_cover(
        'archive-keeper',
        accent='#c89c5b',
        shadow_tint='#2d3c58',
        glow='#dfbd7f',
        y_offset=170,
        centering=(0.5, 0.40),
        foreground_scale=0.90,
        overlay_color='#060b11',
        overlay_opacity=54,
        seed=113,
    ),
    'void-captain': lambda: posterize_square_cover(
        'void-captain',
        accent='#86c5ff',
        shadow_tint='#40224f',
        glow='#71d0ff',
        y_offset=184,
        centering=(0.5, 0.48),
        foreground_scale=0.90,
        overlay_color='#060b12',
        overlay_opacity=46,
        seed=127,
    ),
    'blood-duchess': lambda: posterize_square_cover(
        'blood-duchess',
        accent='#d1ab73',
        shadow_tint='#5b1a27',
        glow='#f2c188',
        y_offset=178,
        centering=(0.5, 0.47),
        foreground_scale=0.90,
        overlay_color='#09080b',
        overlay_opacity=48,
        seed=131,
    ),
    'icefield-ranger': lambda: posterize_square_cover(
        'icefield-ranger',
        accent='#9bdaf4',
        shadow_tint='#3d5460',
        glow='#b8f1ff',
        y_offset=182,
        centering=(0.5, 0.47),
        foreground_scale=0.90,
        overlay_color='#071016',
        overlay_opacity=44,
        seed=137,
    ),
    'shadow-warden': make_shadow_warden,
    'oath-arbiter': make_oath_arbiter,
    'last-train-keeper': make_last_train_keeper,
    'memory-smuggler': make_memory_smuggler,
    'night-prefect': make_night_prefect,
    'deskmate': make_deskmate,
    'slayer-mage': make_slayer_mage,
    'dungeon-arbiter': make_dungeon_arbiter,
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for asset_id, builder in POSTERS.items():
        image = builder().convert('RGB')
        image = image.quantize(colors=160, method=Image.Quantize.MEDIANCUT)
        path = OUT_DIR / f'{asset_id}.png'
        image.save(path, format='PNG', optimize=True, compress_level=9)
        print(f'Wrote {path.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
