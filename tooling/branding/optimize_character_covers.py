#!/usr/bin/env python3
"""Compress built-in story-cover PNGs for mobile release builds."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
COVER_DIR = ROOT / "assets" / "images" / "characters"
POSTER_SIZE = (1600, 2400)
PALETTE_COLORS = 224


def _optimize(path: Path) -> None:
    image = Image.open(path).convert("RGB")
    if image.size != POSTER_SIZE:
        raise SystemExit(f"{path.name} is {image.size}, expected {POSTER_SIZE}.")
    optimized = image.quantize(
        colors=PALETTE_COLORS,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.FLOYDSTEINBERG,
    )
    optimized.save(path, optimize=True)


def main() -> None:
    covers = sorted(COVER_DIR.glob("*.png"))
    if not covers:
        raise SystemExit(f"No character cover PNGs found in {COVER_DIR}.")
    for cover in covers:
        before = cover.stat().st_size
        _optimize(cover)
        after = cover.stat().st_size
        print(f"{cover.name}: {before / 1024:.1f} KB -> {after / 1024:.1f} KB")


if __name__ == "__main__":
    main()
