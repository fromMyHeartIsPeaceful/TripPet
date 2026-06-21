#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

BUNDLED_PYTHON = (
    Path.home()
    / ".cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
)

try:
    from PIL import Image
except ModuleNotFoundError:
    if BUNDLED_PYTHON.exists() and Path(sys.executable).resolve() != BUNDLED_PYTHON.resolve():
        os.execv(str(BUNDLED_PYTHON), [str(BUNDLED_PYTHON), *sys.argv])
    raise


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "TripPet" / "Resources" / "Assets.xcassets"
DEFAULT_IMAGEGEN_DIR = Path("/Users/qianyu/.codex/generated_images/019ed5c9-ef81-71b2-ba99-4250baf09fd8")
DEFAULT_BEIJING_SOURCE = DEFAULT_IMAGEGEN_DIR / "ig_01e0f35a3ac9e09e016a32a85ac93881918ffb350ec0e716f6.png"
DEFAULT_MARKER = Path("/private/tmp/trippet_imagegen_marker")
REMOVE_CHROMA_KEY = Path("/Users/qianyu/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py")

DESTINATION_SIZE = (940, 560)
EDGE_SIZE = (1080, 1920)
MOTIF_SIZE = (160, 160)

CITY_ASSETS = [
    ("postcard_destination_city_beijing", "beijing"),
    ("postcard_destination_city_shanghai", "shanghai"),
    ("postcard_destination_city_tokyo", "tokyo"),
    ("postcard_destination_city_kyoto", "kyoto"),
    ("postcard_destination_city_seoul", "seoul"),
    ("postcard_destination_city_hongkong", "hongkong"),
    ("postcard_destination_city_singapore", "singapore"),
    ("postcard_destination_city_paris", "paris"),
    ("postcard_destination_city_london", "london"),
    ("postcard_destination_city_rome", "rome"),
    ("postcard_destination_city_venice", "venice"),
    ("postcard_destination_city_barcelona", "barcelona"),
    ("postcard_destination_city_amsterdam", "amsterdam"),
    ("postcard_destination_city_new_york", "new_york"),
    ("postcard_destination_city_los_angeles", "los_angeles"),
    ("postcard_destination_city_san_francisco", "san_francisco"),
    ("postcard_destination_city_vancouver", "vancouver"),
    ("postcard_destination_city_sydney", "sydney"),
    ("postcard_destination_city_melbourne", "melbourne"),
    ("postcard_destination_city_istanbul", "istanbul"),
    ("postcard_destination_city_cairo", "cairo"),
    ("postcard_destination_city_rio", "rio"),
    ("postcard_destination_city_cape_town", "cape_town"),
    ("postcard_destination_city_reykjavik", "reykjavik"),
]

ARCHETYPE_ASSETS = [
    "postcard_destination_archetype_east_asia_city",
    "postcard_destination_archetype_european_old_town",
    "postcard_destination_archetype_harbor",
    "postcard_destination_archetype_snow",
    "postcard_destination_archetype_desert",
    "postcard_destination_archetype_mountain",
    "postcard_destination_archetype_tropical",
    "postcard_destination_archetype_north_america_street",
    "postcard_destination_archetype_river_lake",
    "postcard_destination_archetype_modern_skyline",
    "postcard_destination_archetype_historic_market",
    "postcard_destination_archetype_oceania_coast",
]

ANIMAL_KEYS = [
    "xiaoman_hamster",
    "tangyuan_puppy",
    "moji_cat",
    "dengdeng_rabbit",
    "feifei_parrot",
    "xiaolu_guinea_pig",
    "deer_visitor",
    "fox_visitor",
    "bear_visitor",
]


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def ensure_group(group: str) -> Path:
    group_dir = ASSET_ROOT / group
    group_dir.mkdir(parents=True, exist_ok=True)
    write_json(group_dir / "Contents.json", {"info": {"author": "xcode", "version": 1}})
    return group_dir


def write_image_asset(group: str, name: str, image: Image.Image) -> None:
    group_dir = ensure_group(group)
    image_dir = group_dir / f"{name}.imageset"
    image_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{name}@3x.png"
    image.save(image_dir / filename, optimize=True)
    write_json(
        image_dir / "Contents.json",
        {
            "images": [{"filename": filename, "idiom": "universal", "scale": "3x"}],
            "info": {"author": "xcode", "version": 1},
        },
    )


def cover_resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    source_ratio = image.width / image.height
    target_ratio = size[0] / size[1]
    if source_ratio > target_ratio:
        new_height = size[1]
        new_width = round(new_height * source_ratio)
    else:
        new_width = size[0]
        new_height = round(new_width / source_ratio)
    resized = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
    left = (new_width - size[0]) // 2
    top = (new_height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def contain_resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    image.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(image, ((size[0] - image.width) // 2, (size[1] - image.height) // 2))
    return canvas


def chroma_key_to_alpha(source: Path, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            sys.executable,
            str(REMOVE_CHROMA_KEY),
            "--input",
            str(source),
            "--out",
            str(output),
            "--auto-key",
            "border",
            "--soft-matte",
            "--transparent-threshold",
            "18",
            "--opaque-threshold",
            "220",
            "--despill",
        ],
        check=True,
    )


def imagegen_files_after_marker(imagegen_dir: Path, marker: Path) -> list[Path]:
    marker_mtime = marker.stat().st_mtime
    files = [path for path in imagegen_dir.glob("*.png") if path.stat().st_mtime > marker_mtime]
    return sorted(files, key=lambda path: path.stat().st_mtime)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--imagegen-dir", type=Path, default=DEFAULT_IMAGEGEN_DIR)
    parser.add_argument("--beijing-source", type=Path, default=DEFAULT_BEIJING_SOURCE)
    parser.add_argument("--marker", type=Path, default=DEFAULT_MARKER)
    args = parser.parse_args()

    files = imagegen_files_after_marker(args.imagegen_dir, args.marker)
    expected_after_marker = (len(CITY_ASSETS) - 1) + len(ARCHETYPE_ASSETS) + len(ANIMAL_KEYS) * 2
    if len(files) != expected_after_marker:
        raise RuntimeError(f"Expected {expected_after_marker} imagegen files after marker, found {len(files)}")
    if not args.beijing_source.exists():
        raise RuntimeError(f"Missing Beijing source image: {args.beijing_source}")

    sources = [args.beijing_source, *files]
    source_index = 0

    for asset_name, _ in CITY_ASSETS:
        image = cover_resize(Image.open(sources[source_index]), DESTINATION_SIZE).convert("RGB")
        write_image_asset("Destinations", asset_name, image)
        source_index += 1

    for asset_name in ARCHETYPE_ASSETS:
        image = cover_resize(Image.open(sources[source_index]), DESTINATION_SIZE).convert("RGB")
        write_image_asset("Destinations", asset_name, image)
        source_index += 1

    tmp_dir = ROOT / ".tmp" / "imagegen_postcard_alpha"
    tmp_dir.mkdir(parents=True, exist_ok=True)

    for animal_key in ANIMAL_KEYS:
        asset_name = f"postcard_edge_{animal_key}"
        keyed = tmp_dir / f"{asset_name}_keyed.png"
        alpha = tmp_dir / f"{asset_name}_alpha.png"
        shutil.copyfile(sources[source_index], keyed)
        chroma_key_to_alpha(keyed, alpha)
        image = cover_resize(Image.open(alpha), EDGE_SIZE)
        write_image_asset("Postcards", asset_name, image)
        source_index += 1

    for animal_key in ANIMAL_KEYS:
        asset_name = f"postcard_motif_{animal_key}"
        keyed = tmp_dir / f"{asset_name}_keyed.png"
        alpha = tmp_dir / f"{asset_name}_alpha.png"
        shutil.copyfile(sources[source_index], keyed)
        chroma_key_to_alpha(keyed, alpha)
        image = contain_resize(Image.open(alpha), MOTIF_SIZE)
        write_image_asset("Postcards", asset_name, image)
        source_index += 1

    print(f"Imported {source_index} imagegen postcard assets into asset catalogs.")


if __name__ == "__main__":
    main()
