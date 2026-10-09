#!/usr/bin/env python3
"""Validate a pattern (figure) SVG against Quizoo's fixed figure spec.

Every `figure_svg` artwork is drawn on the exact same canvas (640x360, 16:9)
so all pattern questions render at the same size on the play screen, and uses
only a fixed pair of stroke widths (6 for figure outlines, 3 for construction
lines such as grids and panel borders) so no artwork ever comes out with the
fat, overlapping strokes that made past batches look broken.

Usage:
    python3 validate_figure_svg.py <file.svg> [<file.svg> ...]

Exit status 0 when every file passes; otherwise every violation is printed
and the exit status is 1. This checks structure and stroke discipline only —
rendering the file (qlmanage -t) and looking at the PNG remains mandatory for
visual issues the geometry can't catch (overlap, clipping, legibility).
"""

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

CANVAS_W, CANVAS_H = 640, 360
VIEWBOX_VALUES = ("0", "0", str(CANVAS_W), str(CANVAS_H))
ALLOWED_STROKE_WIDTHS = {3.0, 6.0}
MAX_BYTES = 12 * 1024
FORBIDDEN_TAGS = {"script", "image", "foreignobject", "iframe", "audio", "video"}
LABEL_SETS = ({"A", "B", "C", "D"}, {"ا", "ب", "ج", "د"})
NUMBERS = re.compile(r"^[0-9]+(?:\.[0-9]+)?$")


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1].lower()


def check_file(path: Path) -> list:
    errors = []

    if not path.is_file():
        return [f"{path}: file not found"]
    raw = path.read_text(encoding="utf-8", errors="replace")
    size = path.stat().st_size
    if size > MAX_BYTES:
        errors.append(
            f"{path}: {size} bytes exceeds the {MAX_BYTES}-byte (12 KB) cap"
        )

    lowered = raw.lower()
    if "url(" in lowered:
        errors.append(f"{path}: external url() reference found")
    if "@font-face" in lowered or "@import" in lowered:
        errors.append(f"{path}: external font/import reference found")
    if re.search(r"stroke-width\s*:", lowered):
        errors.append(
            f"{path}: stroke-width set via CSS/style — use the stroke-width "
            "attribute instead"
        )

    try:
        root = ET.fromstring(raw)
    except ET.ParseError as exc:
        return errors + [f"{path}: not well-formed XML ({exc})"]

    if local_name(root.tag) != "svg":
        errors.append(f"{path}: root element is <{local_name(root.tag)}>, not <svg>")

    viewbox = re.sub(r"[\s,]+", " ", root.get("viewBox", "").strip())
    if tuple(viewbox.split(" ")) != VIEWBOX_VALUES:
        errors.append(
            f'{path}: viewBox is "{root.get("viewBox")}" — must be exactly '
            f'"0 0 {CANVAS_W} {CANVAS_H}"'
        )
    for attr, expected in (("width", str(CANVAS_W)), ("height", str(CANVAS_H))):
        if root.get(attr) != expected:
            errors.append(
                f'{path}: {attr}="{root.get(attr)}" — must be exactly "{expected}"'
            )

    stroke_values = set()
    labels = set()
    element_count = 0
    for element in root.iter():
        element_count += 1
        tag = local_name(element.tag)
        if tag in FORBIDDEN_TAGS:
            errors.append(f"{path}: forbidden <{tag}> element")
        for attr, value in element.attrib.items():
            attr_name = local_name(attr)
            if attr_name == "href":
                errors.append(f"{path}: forbidden href reference on <{tag}>")
            elif attr_name == "stroke-width":
                try:
                    stroke_values.add(float(value))
                except ValueError:
                    errors.append(
                        f'{path}: stroke-width="{value}" is not a number'
                    )
        if tag == "text" and (element.text or "").strip() in (
            LABEL_SETS[0] | LABEL_SETS[1]
        ):
            labels.add((element.text or "").strip())

    bad_strokes = sorted(v for v in stroke_values if v not in ALLOWED_STROKE_WIDTHS)
    if bad_strokes:
        errors.append(
            f"{path}: stroke-width values {bad_strokes} not allowed — only "
            "6 (figure outlines) and 3 (construction lines) are permitted"
        )
    if not any(label_set <= labels for label_set in LABEL_SETS):
        errors.append(
            f"{path}: option labels missing — the artwork must carry four "
            "text labels A,B,C,D (or ا,ب,ج,د)"
        )

    if not errors:
        print(
            f"OK: {path.name} — {element_count} elements, "
            f"stroke widths {sorted(stroke_values)}, {size / 1024:.1f} KB"
        )
    return errors


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("usage: validate_figure_svg.py <file.svg> [<file.svg> ...]")
    errors = []
    for arg in sys.argv[1:]:
        errors.extend(check_file(Path(arg)))
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
