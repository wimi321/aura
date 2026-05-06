#!/usr/bin/env python3
"""Apply generated story-cover sources to built-in Aura poster assets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "tooling" / "branding" / "source-generated-covers"
OUT_DIR = ROOT / "assets" / "images" / "characters"
TARGET_SIZE = (1600, 2400)
POSTER_PALETTE_COLORS = 224

GENERATED_COVER_IDS = [
    "shadow-warden",
    "oath-arbiter",
    "last-train-keeper",
    "memory-smuggler",
    "night-prefect",
    "deskmate",
    "slayer-mage",
    "dungeon-arbiter",
]


def _cover_fit(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    target_w, target_h = TARGET_SIZE
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def _add_readability_grade(image: Image.Image) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    width, height = image.size
    for y in range(height):
        t = y / max(height - 1, 1)
        if t < 0.54:
            alpha = 0
        else:
            alpha = round(178 * ((t - 0.54) / 0.46) ** 1.7)
        draw.line((0, y, width, y), fill=(0, 0, 0, alpha))
    result = image.convert("RGBA")
    result.alpha_composite(overlay)
    return result.convert("RGB")


def _optimized_poster(image: Image.Image) -> Image.Image:
    """Keep painterly detail while avoiding multi-megabyte PNG posters."""
    return image.quantize(
        colors=POSTER_PALETTE_COLORS,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.FLOYDSTEINBERG,
    )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    missing = [
        cover_id
        for cover_id in GENERATED_COVER_IDS
        if not (SOURCE_DIR / f"{cover_id}.png").exists()
    ]
    if missing:
        raise SystemExit(f"Missing generated cover sources: {', '.join(missing)}")

    for cover_id in GENERATED_COVER_IDS:
        source = Image.open(SOURCE_DIR / f"{cover_id}.png")
        poster = _optimized_poster(_add_readability_grade(_cover_fit(source)))
        poster.save(OUT_DIR / f"{cover_id}.png", optimize=True)
        print(f"updated {cover_id}")


if __name__ == "__main__":
    main()
