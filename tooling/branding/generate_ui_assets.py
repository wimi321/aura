#!/usr/bin/env python3
"""Generate deterministic UI atmosphere assets for Aura.

The assets are intentionally abstract, brand-owned, and reproducible:
no stock art, no copyrighted references, no model weights. They provide
the app-wide "Eclipse Core" atmosphere used by Flutter surfaces.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "images" / "ui"
RNG = random.Random(240424)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(lerp(a, b, t) for a, b in zip(c1, c2))


def radial_glow(
    image: Image.Image,
    center: tuple[float, float],
    radius: float,
    color: tuple[int, int, int],
    strength: float,
) -> None:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    pixels = overlay.load()
    width, height = image.size
    cx, cy = center
    for y in range(height):
        for x in range(width):
            dx = (x - cx) / radius
            dy = (y - cy) / radius
            d = math.sqrt(dx * dx + dy * dy)
            if d < 1:
                alpha = int(255 * strength * (1 - d) ** 2.6)
                if alpha > 0:
                    pixels[x, y] = (*color, alpha)
    image.alpha_composite(overlay)


def make_deep_space() -> None:
    width, height = 1440, 2560
    top = (4, 9, 14)
    mid = (7, 13, 20)
    bottom = (0, 0, 0)
    image = Image.new("RGBA", (width, height))
    px = image.load()
    for y in range(height):
        t = y / (height - 1)
        base = mix(top, mid, min(t * 1.6, 1.0)) if t < 0.62 else mix(mid, bottom, (t - 0.62) / 0.38)
        for x in range(width):
            vignette = abs((x / width) - 0.5) * 0.28
            noise = RNG.randint(-3, 3)
            r = max(0, int(base[0] * (1 - vignette)) + noise)
            g = max(0, int(base[1] * (1 - vignette)) + noise)
            b = max(0, int(base[2] * (1 - vignette)) + noise)
            px[x, y] = (r, g, b, 255)

    radial_glow(image, (width * 0.12, height * 0.06), width * 0.72, (70, 224, 181), 0.20)
    radial_glow(image, (width * 0.92, height * 0.22), width * 0.52, (250, 160, 120), 0.12)
    radial_glow(image, (width * 0.62, height * 0.88), width * 0.78, (53, 122, 170), 0.10)

    dust = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(dust)
    for _ in range(3600):
        x = RNG.randrange(width)
        y = RNG.randrange(height)
        alpha = RNG.randrange(7, 34)
        shade = RNG.randrange(150, 235)
        draw.point((x, y), fill=(shade, shade, shade + RNG.randrange(0, 12), alpha))
    dust = dust.filter(ImageFilter.GaussianBlur(0.25))
    image.alpha_composite(dust)

    # Subtle editorial vignette keeps text readable on OLED screens.
    vignette = Image.new("RGBA", image.size, (0, 0, 0, 0))
    vpx = vignette.load()
    for y in range(height):
        for x in range(width):
            nx = (x / width - 0.5) * 2
            ny = (y / height - 0.48) * 2
            d = min(1.0, math.sqrt(nx * nx + ny * ny))
            alpha = int(150 * max(0.0, d - 0.35) ** 1.7)
            vpx[x, y] = (0, 0, 0, alpha)
    image.alpha_composite(vignette)
    image.convert("RGB").save(
        OUT / "deep-space-grain.jpg",
        quality=90,
        optimize=True,
        progressive=True,
    )


def make_eclipse_orb() -> None:
    size = 1024
    center = size / 2
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = image.load()
    for y in range(size):
        for x in range(size):
            dx = x - center
            dy = y - center
            d = math.sqrt(dx * dx + dy * dy)
            angle = (math.atan2(dy, dx) + math.pi) / (math.pi * 2)
            teal = (78, 224, 181)
            coral = (250, 160, 120)
            color = mix(teal, coral, 0.5 + 0.5 * math.sin(angle * math.pi * 2 + 0.7))

            alpha = 0
            if 230 <= d <= 350:
                ring = 1 - abs(d - 290) / 60
                alpha = max(alpha, int(210 * max(0, ring) ** 0.72))
            if 350 < d <= 460:
                halo = 1 - (d - 350) / 110
                alpha = max(alpha, int(86 * halo ** 2))
            if d < 235:
                edge = min(1.0, max(0.0, (235 - d) / 42))
                core = int(255 * edge)
                px[x, y] = (2, 4, 6, core)
                continue
            if alpha > 0:
                px[x, y] = (*color, alpha)

    bloom = image.filter(ImageFilter.GaussianBlur(28))
    bloom.alpha_composite(image)
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.ellipse((center - 242, center - 242, center + 242, center + 242), fill=(1, 3, 5, 255))
    draw.ellipse((center - 242, center - 242, center + 242, center + 242), outline=(255, 255, 255, 14), width=2)
    bloom.alpha_composite(shadow)
    bloom.save(OUT / "eclipse-core.png", optimize=True)


def make_model_constellation() -> None:
    width, height = 1600, 1000
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    nodes = [
        (250, 520, 8), (430, 380, 5), (620, 600, 6), (820, 420, 7),
        (1040, 560, 5), (1210, 350, 7), (1380, 500, 5), (1120, 720, 6),
        (760, 760, 4), (500, 720, 5),
    ]
    for a, b in zip(nodes, nodes[1:]):
        draw.line((a[0], a[1], b[0], b[1]), fill=(105, 225, 196, 34), width=2)
    for x, y, r in nodes:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(180, 255, 236, 210))
        draw.ellipse((x - r * 5, y - r * 5, x + r * 5, y + r * 5), outline=(78, 224, 181, 28), width=2)
    image = image.filter(ImageFilter.GaussianBlur(0.35))
    image.save(OUT / "model-constellation.png", optimize=True)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    make_deep_space()
    make_eclipse_orb()
    make_model_constellation()


if __name__ == "__main__":
    main()
