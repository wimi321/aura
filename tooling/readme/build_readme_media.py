#!/usr/bin/env python3
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "docs" / "readme" / "raw"
FINAL_DIR = ROOT / "docs" / "readme"

PNG_TARGETS = {
    "model-setup-raw.png": "model-setup.png",
    "story-library-raw.png": "story-library.png",
    "chat-scene-raw.png": "chat-scene.png",
    "import-flow-raw.png": "import-flow.png",
}


def export_png(source: Path, target: Path) -> None:
    image = Image.open(source).convert("RGB")
    max_width = 900
    if image.width > max_width:
        ratio = max_width / image.width
        image = image.resize(
            (max_width, int(image.height * ratio)),
            Image.Resampling.LANCZOS,
        )
    optimized = image.quantize(colors=192, method=Image.Quantize.MEDIANCUT)
    optimized.save(target, format="PNG", optimize=True)


def export_gif(source: Path, target: Path) -> None:
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        raise SystemExit("ffmpeg is required to build docs/readme/quick-start.gif")
    subprocess.run(
        [
            ffmpeg,
            "-y",
            "-ss",
            "0.4",
            "-t",
            "12",
            "-i",
            str(source),
            "-vf",
            (
                "fps=8,scale=540:-1:flags=lanczos,"
                "split[s0][s1];[s0]palettegen=max_colors=128[p];"
                "[s1][p]paletteuse=dither=bayer:bayer_scale=3"
            ),
            "-loop",
            "0",
            str(target),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> int:
    FINAL_DIR.mkdir(parents=True, exist_ok=True)

    missing = [name for name in PNG_TARGETS if not (RAW_DIR / name).exists()]
    if missing:
        raise SystemExit(f"Missing raw screenshots: {', '.join(missing)}")

    for source_name, target_name in PNG_TARGETS.items():
        export_png(RAW_DIR / source_name, FINAL_DIR / target_name)

    movie = RAW_DIR / "quick-start.mov"
    if not movie.exists():
        raise SystemExit("Missing raw recording: docs/readme/raw/quick-start.mov")
    export_gif(movie, FINAL_DIR / "quick-start.gif")

    for file_name in list(PNG_TARGETS.values()) + ["quick-start.gif"]:
        path = FINAL_DIR / file_name
        print(f"{file_name}: {path.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
