#!/usr/bin/env python3
"""Generate Aura app icon, launch mark, and README logo assets.

The source artwork is generated once and committed at
`tooling/branding/aura_icon_source_generated.png`. This script makes every
platform asset from that single master so Android, iOS, macOS, Flutter, and
GitHub all present the same brand mark.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "tooling" / "branding" / "aura_icon_source_generated.png"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_APPICON = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_LAUNCH = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
MAC_APPICON = (
    ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
)

MASTER_ICON = ROOT / "tooling" / "branding" / "aura_android_icon_master.png"
README_ICON = ROOT / "docs" / "readme" / "aura-icon.png"
FLUTTER_MARK = ROOT / "assets" / "images" / "ui" / "eclipse-core.png"

ANDROID_DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

LAUNCH_IMAGE_SIZES = {
    "LaunchImage.png": 168,
    "LaunchImage@2x.png": 336,
    "LaunchImage@3x.png": 504,
}


def _cover_square(image: Image.Image, size: int, zoom: float = 1.0) -> Image.Image:
    image = image.convert("RGB")
    scale = max(size / image.width, size / image.height) * zoom
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size) // 2
    top = (resized.height - size) // 2
    return resized.crop((left, top, left + size, top + size))


def _radial_alpha_mask(
    size: int,
    opaque_radius: float,
    fade_radius: float,
) -> Image.Image:
    center = (size - 1) / 2
    mask = Image.new("L", (size, size), 0)
    pixels = mask.load()
    for y in range(size):
        for x in range(size):
            distance = math.hypot(x - center, y - center) / center
            if distance <= opaque_radius:
                alpha = 255
            elif distance >= fade_radius:
                alpha = 0
            else:
                t = (distance - opaque_radius) / (fade_radius - opaque_radius)
                alpha = round(255 * (1 - t) ** 2.2)
            pixels[x, y] = alpha
    return mask.filter(ImageFilter.GaussianBlur(max(1, size // 160)))


def _transparent_mark(master: Image.Image, size: int) -> Image.Image:
    mark = master.resize((size, size), Image.Resampling.LANCZOS).convert("RGBA")
    # Keep all glow within Android's adaptive-icon safe zone and avoid a square
    # black patch when launchers apply unusual icon masks.
    mark.putalpha(_radial_alpha_mask(size, opaque_radius=0.54, fade_radius=0.78))
    return mark


def _save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def _parse_point_size(value: str) -> float:
    return float(value.split("x", maxsplit=1)[0])


def _generate_android(master: Image.Image, mark: Image.Image) -> None:
    for folder, size in ANDROID_DENSITIES.items():
        _save_png(
            master.resize((size, size), Image.Resampling.LANCZOS),
            ANDROID_RES / folder / "ic_launcher.png",
        )

    _save_png(
        mark.resize((432, 432), Image.Resampling.LANCZOS),
        ANDROID_RES / "drawable-nodpi" / "ic_launcher_foreground_art.png",
    )


def _generate_ios(master: Image.Image) -> None:
    contents = json.loads((IOS_APPICON / "Contents.json").read_text())
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        point_size = _parse_point_size(item["size"])
        scale = int(item["scale"].replace("x", ""))
        pixels = round(point_size * scale)
        icon = master.resize((pixels, pixels), Image.Resampling.LANCZOS)
        _save_png(icon, IOS_APPICON / filename)


def _generate_macos(master: Image.Image) -> None:
    contents = json.loads((MAC_APPICON / "Contents.json").read_text())
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        point_size = _parse_point_size(item["size"])
        scale = int(item["scale"].replace("x", ""))
        pixels = round(point_size * scale)
        icon = master.resize((pixels, pixels), Image.Resampling.LANCZOS)
        _save_png(icon, MAC_APPICON / filename)


def _generate_launch_images(mark: Image.Image) -> None:
    for filename, size in LAUNCH_IMAGE_SIZES.items():
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        logo_size = round(size * 0.86)
        logo = mark.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
        offset = (size - logo_size) // 2
        canvas.alpha_composite(logo, (offset, offset))
        _save_png(canvas, IOS_LAUNCH / filename)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source artwork: {SOURCE}")

    source = Image.open(SOURCE)
    master = _cover_square(source, 1024, zoom=1.18)
    mark = _transparent_mark(master, 1024)

    _save_png(master, MASTER_ICON)
    _save_png(master, README_ICON)
    _save_png(mark, FLUTTER_MARK)
    _generate_android(master, mark)
    _generate_ios(master)
    _generate_macos(master)
    _generate_launch_images(mark)

    print(f"Generated Aura brand assets from {SOURCE}")


if __name__ == "__main__":
    main()
