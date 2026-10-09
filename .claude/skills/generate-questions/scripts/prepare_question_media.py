#!/usr/bin/env python3
"""Normalize image-mode question media to Quizoo's fixed 16:9 plate ratio.

The app's media plate is a fixed-height, full-width strip and draws every
photo with `BoxFit.contain`. That means the *only* thing that decides how
large a question's photo appears on screen is its aspect ratio — so every
image this skill uploads must be exactly 16:9, or the play screen shows a
ragged mix of tall and small photos.

This script has two modes:

  Inspect (no --crop):
      python3 prepare_question_media.py --input <image>
    Prints a JSON report: the EXIF-corrected pixel size, a suggested
    centered 16:9 crop band, and the output size that crop would take.

  Normalize (--crop X,Y,W):
      python3 prepare_question_media.py --input <image> --output <out.jpg>
          --crop 0,150,1600
    Crops the 16:9 band (height W*9/16, derived), downscales to the largest
    canonical 16:9 target that does not upscale (1280x720, 1120x630,
    960x540, 800x450, 640x360), and writes a clean JPEG or PNG.

Crop coordinates are in the EXIF-upright orientation (what you see when you
open the file), not the raw pixel grid. JPEG output is quality 88; PNG is
used for flat artworks like flags. Output never exceeds ~500 KB for photos.

Exit status is 0 on success; any violation prints `error: ...` to stderr and
exits 1.

Requires Pillow (`python3 -c "import PIL"` to check).
"""

import argparse
import json
import sys
from pathlib import Path

try:
    from PIL import Image, ImageOps
except ImportError:  # pragma: no cover
    sys.exit(
        "error: Pillow is required for prepare_question_media.py "
        '(install with `python3 -m pip install Pillow`)'
    )

RATIO_W, RATIO_H = 16, 9
CANONICAL_WIDTHS = (1280, 1120, 960, 800, 640)
MIN_WIDTH = 640
WARN_BYTES = 512 * 1024
JPEG_QUALITY = 88


def fail(message: str) -> "None":
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def load_upright(path_str: str) -> Image.Image:
    path = Path(path_str)
    if not path.is_file():
        fail(f"input file not found: {path}")
    try:
        image = Image.open(path)
        image.load()
    except Exception as exc:  # noqa: BLE001 - surface any decoder failure
        fail(f"cannot decode {path}: {exc}")
    return ImageOps.exif_transpose(image)


def band_for(width: int, height: int) -> dict:
    """The largest centered 16:9 band, and the widest crop the image allows."""

    full_width_band_h = round(width * RATIO_H / RATIO_W)
    if full_width_band_h <= height:
        max_width = width
        band_w = width
        band_h = full_width_band_h
    else:
        band_w = round(height * RATIO_W / RATIO_H)
        band_h = height
        max_width = band_w
    return {
        "band_width": band_w,
        "band_height": band_h,
        "max_crop_width": max_width,
        "suggested_crop": {
            "x": (width - band_w) // 2,
            "y": (height - band_h) // 2,
            "width": band_w,
        },
    }


def output_width_for(crop_width: int) -> int:
    for width in CANONICAL_WIDTHS:
        if width <= crop_width:
            return width
    return 0


def inspect(path: str) -> None:
    image = load_upright(path)
    width, height = image.size
    band = band_for(width, height)
    crop_w = band["suggested_crop"]["width"]
    out_w = output_width_for(crop_w)
    print(
        json.dumps(
            {
                "source": str(path),
                "source_width": width,
                "source_height": height,
                "suggested_crop": band["suggested_crop"],
                "suggested_crop_height": round(crop_w * RATIO_H / RATIO_W),
                "max_crop_width": band["max_crop_width"],
                "output_width_if_that_crop": out_w,
                "output_height_if_that_crop": out_w * RATIO_H // RATIO_W
                if out_w
                else 0,
                "canonical_outputs": [
                    f"{w}x{w * RATIO_H // RATIO_W}" for w in CANONICAL_WIDTHS
                ],
                "already_16_9": crop_w == width
                and round(crop_w * RATIO_H / RATIO_W) == height,
            },
            indent=2,
        )
    )


def flatten_to_rgb(image: Image.Image) -> Image.Image:
    if image.mode in ("RGBA", "LA", "P"):
        rgba = image.convert("RGBA")
        background = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
        return Image.alpha_composite(background, rgba).convert("RGB")
    return image.convert("RGB")


def normalize(input_path: str, output_path: str, crop_arg: str) -> None:
    parts = crop_arg.split(",")
    if len(parts) != 3:
        fail("--crop must be `X,Y,W` (height is derived as W*9/16)")
    try:
        x, y, crop_w = (int(part.strip()) for part in parts)
    except ValueError:
        fail("--crop values must be integers: `X,Y,W`")

    if x < 0 or y < 0:
        fail("--crop x/y must be >= 0")
    if crop_w < MIN_WIDTH:
        fail(
            f"crop width {crop_w} is below the {MIN_WIDTH}px minimum — "
            "reject this candidate or download a larger rendition"
        )
    crop_h = round(crop_w * RATIO_H / RATIO_W)

    image = load_upright(input_path)
    width, height = image.size
    if x + crop_w > width:
        fail(f"crop x+width = {x + crop_w} exceeds source width {width}")
    if y + crop_h > height:
        fail(
            f"crop y+height = {y + crop_h} exceeds source height {height} "
            f"(max y for this width is {height - crop_h})"
        )

    target_w = output_width_for(crop_w)
    if target_w == 0:  # unreachable given the MIN_WIDTH guard; kept for safety
        fail(f"crop width {crop_w} has no canonical 16:9 target")
    target_h = target_w * RATIO_H // RATIO_W

    output = Path(output_path)
    suffix = output.suffix.lower()
    if suffix not in (".jpg", ".jpeg", ".png"):
        fail("--output must end in .jpg, .jpeg or .png")

    cropped = image.crop((x, y, x + crop_w, y + crop_h))
    if cropped.size != (target_w, target_h):
        cropped = cropped.resize((target_w, target_h), Image.LANCZOS)
    cropped = flatten_to_rgb(cropped)

    output.parent.mkdir(parents=True, exist_ok=True)
    if suffix == ".png":
        cropped.save(output, format="PNG", optimize=True)
    else:
        cropped.save(
            output,
            format="JPEG",
            quality=JPEG_QUALITY,
            optimize=True,
            progressive=True,
        )

    size_bytes = output.stat().st_size
    if suffix != ".png" and size_bytes > WARN_BYTES:
        print(
            f"warning: {output.name} is {size_bytes // 1024} KB "
            "(> 500 KB) — consider re-cropping from a smaller rendition",
            file=sys.stderr,
        )

    print(
        json.dumps(
            {
                "output": str(output),
                "width": target_w,
                "height": target_h,
                "bytes": size_bytes,
                "source_crop": {
                    "x": x,
                    "y": y,
                    "width": crop_w,
                    "height": crop_h,
                },
            },
            indent=2,
        )
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize question media to a fixed 16:9 frame."
    )
    parser.add_argument("--input", required=True, help="downloaded source image")
    parser.add_argument("--output", help="normalized output (.jpg or .png)")
    parser.add_argument(
        "--crop",
        help="`X,Y,W` crop box in the upright image; height is derived (W*9/16)",
    )
    args = parser.parse_args()

    if args.crop is None:
        if args.output:
            fail("--output requires --crop (or drop --output to inspect only)")
        inspect(args.input)
        return

    if not args.output:
        fail("--crop requires --output")
    normalize(args.input, args.output, args.crop)


if __name__ == "__main__":
    main()
