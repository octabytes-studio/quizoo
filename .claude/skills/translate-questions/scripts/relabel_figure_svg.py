#!/usr/bin/env python3
"""Check or RTL-relabel the four option labels of a Quizoo figure (`figure_svg`).

Translated figure questions reuse the source language's artwork verbatim; the
only language-bearing part of a figure SVG is the four single-glyph option
labels (``A``-``D`` for LTR, ``ا``-``د`` for Arabic). This script is the
translation skill's tool for that one edit.

Usage:
    python3 relabel_figure_svg.py --check <file.svg> [<file.svg> ...]
    python3 relabel_figure_svg.py --labels rtl <file.svg> [<file.svg> ...]

- ``--check`` asserts each file has **exactly one** single-glyph ``<text>``
  element for each of ``A``, ``B``, ``C``, ``D``. Any other single-glyph
  ``<text>`` content (``?``, numbers) is left alone — only ``A``-``D`` are
  inspected. Exit status is 1 if any file fails.
- ``--labels rtl`` runs the same check, then rewrites ``A``→``ا``, ``B``→``ب``,
  ``C``→``ج``, ``D``→``د`` **inside those four elements only** (files are
  edited in place) and prints each replacement.

The script deliberately never runs ``generate-questions``'s
``validate_figure_svg.py``: existing figure artwork uses the older 640×400
canvas and 2/3.5 stroke widths, which the newer 640×360 + stroke-6/3 validator
would reject. It does print a warning whenever a file's canvas is not the
current ``0 0 640 360`` so the mandatory render-and-look check is not skipped.

Stdlib only.
"""

import re
import sys
from pathlib import Path

LABELS_LTR = ("A", "B", "C", "D")
LABELS_RTL = ("ا", "ب", "ج", "د")
RELABEL = dict(zip(LABELS_LTR, LABELS_RTL))

# A single-glyph <text> element: <text ...>A</text> (optional surrounding space).
TEXT_RE = re.compile(r"(<text\b[^>]*>)(\s*)([ABCD])(\s*)(</text>)")
CURRENT_CANVAS = "0 0 640 360"
USAGE = (
    "usage: relabel_figure_svg.py (--check | --labels rtl) <file.svg> "
    "[<file.svg> ...]"
)


def parse_canvas_viewbox(raw: str):
    match = re.search(r"<svg\b[^>]*\bviewBox\s*=\s*\"([^\"]*)\"", raw)
    if not match:
        return None
    return re.sub(r"[\s,]+", " ", match.group(1).strip())


def find_labels(raw: str, path: Path):
    """Return (matches, errors) for one file's option labels."""
    matches = list(TEXT_RE.finditer(raw))
    counts = {}
    for match in matches:
        glyph = match.group(3)
        counts[glyph] = counts.get(glyph, 0) + 1

    errors = []
    for glyph in LABELS_LTR:
        found = counts.get(glyph, 0)
        if found != 1:
            errors.append(
                f"{path}: expected exactly one single-glyph <text>{glyph}</text>, "
                f"found {found}"
            )
    return matches, errors


def process(path: Path, relabel: bool):
    errors = []
    if not path.is_file():
        return [f"{path}: file not found"]

    raw = path.read_text(encoding="utf-8")
    matches, label_errors = find_labels(raw, path)
    errors.extend(label_errors)

    canvas = parse_canvas_viewbox(raw)
    if canvas != CURRENT_CANVAS:
        print(
            f"WARNING: {path}: canvas viewBox is \"{canvas}\", not the current "
            f"\"{CURRENT_CANVAS}\" — legacy artwork; reuse it as-is but still run "
            "the mandatory render-and-look check (qlmanage) on the result.",
            file=sys.stderr,
        )

    if errors:
        return errors

    if not relabel:
        print(f"OK: {path.name} — one <text> each of A, B, C, D")
        return []

    # Rewrite from the last match backwards so earlier offsets stay valid.
    new_raw = raw
    for match in reversed(matches):
        glyph = match.group(3)
        replacement = (
            f"{match.group(1)}{match.group(2)}{RELABEL[glyph]}"
            f"{match.group(4)}{match.group(5)}"
        )
        new_raw = new_raw[: match.start()] + replacement + new_raw[match.end():]
        print(f"{path.name}: <text>{glyph}</text> -> <text>{RELABEL[glyph]}</text>")
    path.write_text(new_raw, encoding="utf-8")
    print(f"OK: {path.name} — relabeled A/B/C/D to ا/ب/ج/د")
    return []


def main() -> None:
    args = sys.argv[1:]
    if not args:
        sys.exit(USAGE)

    if args[0] == "--check":
        relabel = False
        files = args[1:]
    elif args[0] == "--labels":
        if len(args) < 2 or args[1].lower() != "rtl":
            sys.exit("--labels only supports the value 'rtl'")
        relabel = True
        files = args[2:]
    else:
        sys.exit(USAGE)

    if not files:
        sys.exit("no SVG files given\n" + USAGE)

    errors = []
    for arg in files:
        errors.extend(process(Path(arg), relabel))

    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
