#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageColor, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
RES_DIR = ROOT / "android" / "app" / "src" / "main" / "res"
MASTER_OUTPUT = ROOT / "tooling" / "branding" / "aura_android_icon_master.png"

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

TOP = ImageColor.getrgb("#08101A")
BOTTOM = ImageColor.getrgb("#000000")
LAUNCH_BLACK = ImageColor.getrgb("#04080D")
TEAL = ImageColor.getrgb("#4EF4D5")
CORAL = ImageColor.getrgb("#FF8B5E")
WHITE = ImageColor.getrgb("#E8FBF7")


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def gradient_background(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        row = (
            lerp(TOP[0], BOTTOM[0], t),
            lerp(TOP[1], BOTTOM[1], t),
            lerp(TOP[2], BOTTOM[2], t),
            255,
        )
        for x in range(size):
            pixels[x, y] = row
    return image


def ellipse_bounds(center: int, radius: int) -> tuple[int, int, int, int]:
    return (center - radius, center - radius, center + radius, center + radius)


def add_diffuse_glow(
    canvas: Image.Image,
    *,
    center: int,
    radius: int,
    color: tuple[int, int, int],
    alpha: int,
    blur_radius: int,
) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse(ellipse_bounds(center, radius), fill=(*color, alpha))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur_radius)))


def add_arc_glow(
    canvas: Image.Image,
    *,
    center: int,
    radius: int,
    width: int,
    color: tuple[int, int, int],
    alpha: int,
    start: int,
    end: int,
    blur_radius: int,
) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.arc(
        ellipse_bounds(center, radius),
        start=start,
        end=end,
        fill=(*color, alpha),
        width=width,
    )
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur_radius)))


def build_master_icon(size: int = 1024) -> Image.Image:
    center = size // 2
    image = gradient_background(size)

    add_diffuse_glow(
        image,
        center=center,
        radius=338,
        color=TEAL,
        alpha=26,
        blur_radius=54,
    )
    add_diffuse_glow(
        image,
        center=center,
        radius=300,
        color=CORAL,
        alpha=18,
        blur_radius=38,
    )

    add_arc_glow(
        image,
        center=center,
        radius=338,
        width=52,
        color=TEAL,
        alpha=170,
        start=210,
        end=522,
        blur_radius=16,
    )
    add_arc_glow(
        image,
        center=center,
        radius=312,
        width=34,
        color=CORAL,
        alpha=205,
        start=18,
        end=136,
        blur_radius=12,
    )

    crisp = ImageDraw.Draw(image)
    crisp.arc(
        ellipse_bounds(center, 338),
        start=210,
        end=522,
        fill=(*TEAL, 235),
        width=34,
    )
    crisp.arc(
        ellipse_bounds(center, 312),
        start=18,
        end=136,
        fill=(*CORAL, 245),
        width=22,
    )
    crisp.arc(
        ellipse_bounds(center, 256),
        start=0,
        end=360,
        fill=(*WHITE, 40),
        width=8,
    )
    crisp.ellipse(ellipse_bounds(center, 236), fill=(*LAUNCH_BLACK, 255))
    crisp.ellipse(ellipse_bounds(center, 238), outline=(17, 32, 40, 140), width=4)

    vignette = Image.new("RGBA", image.size, (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    vignette_draw.ellipse(
        ellipse_bounds(center, 470),
        outline=(0, 0, 0, 34),
        width=84,
    )
    image.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(12)))
    return image


def save_density_icons(master: Image.Image) -> None:
    for folder, size in SIZES.items():
        output = RES_DIR / folder / "ic_launcher.png"
        output.parent.mkdir(parents=True, exist_ok=True)
        master.resize((size, size), Image.Resampling.LANCZOS).save(output)


def main() -> None:
    master = build_master_icon()
    MASTER_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    master.save(MASTER_OUTPUT)
    save_density_icons(master)
    print(f"Generated Android launcher icons at {MASTER_OUTPUT}")


if __name__ == "__main__":
    main()
