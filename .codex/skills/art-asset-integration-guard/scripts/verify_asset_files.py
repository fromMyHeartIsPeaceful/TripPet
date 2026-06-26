#!/usr/bin/env python3
"""Verify TripPet asset catalog files exist and look shippable at file level."""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_png_info(path: Path) -> tuple[int, int, bool]:
    with path.open("rb") as handle:
        signature = handle.read(8)
        if signature != PNG_SIGNATURE:
            raise ValueError("not a PNG file")

        length_data = handle.read(4)
        chunk_type = handle.read(4)
        if len(length_data) != 4 or chunk_type != b"IHDR":
            raise ValueError("missing PNG IHDR chunk")

        ihdr = handle.read(struct.unpack(">I", length_data)[0])
        if len(ihdr) < 10:
            raise ValueError("truncated PNG IHDR chunk")

    width, height = struct.unpack(">II", ihdr[:8])
    color_type = ihdr[9]
    has_alpha = color_type in (4, 6)
    return width, height, has_alpha


def find_imageset(project_root: Path, asset_name: str) -> Path | None:
    candidates = list(project_root.glob(f"**/{asset_name}.imageset"))
    if not candidates:
        return None
    candidates.sort(key=lambda path: len(path.parts))
    return candidates[0]


def load_imageset_pngs(imageset: Path) -> list[Path]:
    contents_path = imageset / "Contents.json"
    if not contents_path.exists():
        raise FileNotFoundError(f"missing {contents_path}")

    data = json.loads(contents_path.read_text(encoding="utf-8"))
    filenames = [
        image.get("filename")
        for image in data.get("images", [])
        if image.get("filename")
    ]
    return [imageset / filename for filename in filenames]


def find_source(project_root: Path, asset_name: str) -> Path | None:
    source_root = project_root / "TripPet" / "Resources" / "ArtSourceRaster"
    if not source_root.exists():
        return None
    patterns = [
        f"{asset_name}.source.png",
        f"{asset_name}.png",
        f"{asset_name}@3x.png",
    ]
    for pattern in patterns:
        matches = list(source_root.glob(f"**/{pattern}"))
        if matches:
            matches.sort(key=lambda path: len(path.parts))
            return matches[0]
    return None


def find_provenance(project_root: Path, asset_name: str) -> Path | None:
    source_root = project_root / "TripPet" / "Resources" / "ArtSourceRaster"
    if not source_root.exists():
        return None
    matches = list(source_root.glob(f"**/{asset_name}.imagegen.json"))
    if not matches:
        return None
    matches.sort(key=lambda path: len(path.parts))
    return matches[0]


def verify_provenance(project_root: Path, asset_name: str, require_provenance: bool) -> bool:
    provenance = find_provenance(project_root, asset_name)
    if provenance is None:
        if require_provenance:
            print("  ERROR: missing imagegen provenance (.imagegen.json)")
            return False
        print("  WARN: imagegen provenance not found")
        return True

    try:
        data = json.loads(provenance.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        print(f"  ERROR: invalid provenance JSON {provenance}: {error}")
        return False

    required_fields = ["call_id", "line_number", "revised_prompt", "width", "height", "sha256"]
    missing = [field for field in required_fields if not data.get(field)]
    if missing:
        print(f"  ERROR: provenance missing fields: {', '.join(missing)}")
        return False

    raw_png = data.get("raw_png")
    if raw_png:
        raw_path = Path(raw_png)
        if not raw_path.is_absolute():
            raw_path = provenance.parent / raw_path
        if not raw_path.exists():
            print(f"  ERROR: provenance raw_png does not exist: {raw_path}")
            return False

    print(
        "  provenance: "
        f"{provenance} (call_id {data['call_id']}, {data['width']}x{data['height']})"
    )
    return True


def verify_asset(
    project_root: Path,
    asset_name: str,
    require_alpha: bool,
    require_provenance: bool,
) -> bool:
    ok = True
    print(f"\nasset: {asset_name}")

    ok = verify_provenance(project_root, asset_name, require_provenance) and ok

    imageset = find_imageset(project_root, asset_name)
    if imageset is None:
        print("  ERROR: .imageset not found")
        return False
    print(f"  imageset: {imageset}")

    try:
        pngs = load_imageset_pngs(imageset)
    except (FileNotFoundError, json.JSONDecodeError) as error:
        print(f"  ERROR: {error}")
        return False

    if not pngs:
        print("  ERROR: Contents.json does not reference any PNG files")
        ok = False

    for png in pngs:
        if not png.exists():
            print(f"  ERROR: missing PNG {png}")
            ok = False
            continue
        try:
            width, height, has_alpha = read_png_info(png)
        except ValueError as error:
            print(f"  ERROR: {png}: {error}")
            ok = False
            continue
        alpha_note = "alpha" if has_alpha else "no alpha"
        print(f"  png: {png} ({width}x{height}, {alpha_note})")
        if require_alpha and not has_alpha:
            print("  ERROR: PNG must include alpha for layerable app art")
            ok = False

    source = find_source(project_root, asset_name)
    if source is None:
        print("  WARN: matching ArtSourceRaster source not found")
    else:
        try:
            width, height, has_alpha = read_png_info(source)
            alpha_note = "alpha" if has_alpha else "no alpha"
            print(f"  source: {source} ({width}x{height}, {alpha_note})")
            if require_alpha and not has_alpha:
                print("  ERROR: source PNG must include alpha for layerable app art")
                ok = False
        except ValueError as error:
            print(f"  ERROR: source {source}: {error}")
            ok = False

    return ok


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify TripPet .xcassets PNG files for generated art integration."
    )
    parser.add_argument("--project-root", required=True, type=Path)
    parser.add_argument("--asset", action="append", required=True)
    parser.add_argument(
        "--no-require-alpha",
        action="store_true",
        help="Do not require alpha in app-facing PNGs.",
    )
    parser.add_argument(
        "--require-provenance",
        action="store_true",
        help="Require <asset>.imagegen.json provenance under ArtSourceRaster.",
    )
    args = parser.parse_args()

    project_root = args.project_root.expanduser().resolve()
    if not project_root.exists():
        print(f"ERROR: project root does not exist: {project_root}", file=sys.stderr)
        return 2

    all_ok = True
    for asset_name in args.asset:
        all_ok = (
            verify_asset(
                project_root,
                asset_name,
                not args.no_require_alpha,
                args.require_provenance,
            )
            and all_ok
        )

    print("\nFile-level check complete.")
    print("Still required: preview the actual art and verify the running UI screenshot.")
    return 0 if all_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
