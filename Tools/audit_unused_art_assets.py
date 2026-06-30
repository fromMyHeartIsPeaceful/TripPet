#!/usr/bin/env python3
"""Audit app art assets and write a review report.

The script is intentionally conservative: it treats source/runtime references,
manifest asset fields, and common dynamic naming patterns as used, then reports
remaining bundled assets as cleanup candidates for human review.
"""

from __future__ import annotations

import csv
import json
import os
import re
import shutil
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSETS_ROOT = ROOT / "TripPet" / "Resources" / "Assets.xcassets"
TRIPPET_ROOT = ROOT / "TripPet"
REPORT_ROOT = ROOT / "UnusedArtAssetsReview"

RUNTIME_TEXT_EXTENSIONS = {
    ".swift",
    ".json",
    ".plist",
    ".pbxproj",
    ".storyboard",
    ".xib",
}

RESOURCE_FOLDERS_IN_BUNDLE = {
    "TripPet/Resources/AnimalAnimations",
    "TripPet/Resources/DepartureTransitions",
}

NON_RUNTIME_RESOURCE_DIR_PARTS = {
    "Assets.xcassets",
    "ArtSource",
    "ArtSourceRaster",
}


@dataclass(frozen=True)
class ImageSet:
    asset_name: str
    category: str
    imageset_path: Path
    files: tuple[Path, ...]
    byte_size: int

    @property
    def rel_imageset_path(self) -> str:
        return rel(self.imageset_path)


def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def iter_runtime_text_files() -> list[Path]:
    files: list[Path] = []
    for base in [TRIPPET_ROOT, ROOT / "TripPet.xcodeproj"]:
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix not in RUNTIME_TEXT_EXTENSIONS:
                continue
            rel_parts = path.relative_to(ROOT).parts
            if any(part in NON_RUNTIME_RESOURCE_DIR_PARTS for part in rel_parts):
                continue
            files.append(path)
    return sorted(files)


def gather_runtime_text() -> str:
    chunks: list[str] = []
    for path in iter_runtime_text_files():
        try:
            chunks.append(path.read_text(encoding="utf-8"))
        except UnicodeDecodeError:
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(chunks)


def gather_manifest_asset_names() -> set[str]:
    names: set[str] = set()
    for manifest in [
        TRIPPET_ROOT / "Resources" / "ContentManifest.json",
        TRIPPET_ROOT / "Resources" / "LocationDestinationCatalog.json",
    ]:
        if not manifest.exists():
            continue
        data = json.loads(manifest.read_text(encoding="utf-8"))
        collect_asset_values(data, names)
    return names


def collect_asset_values(value: object, names: set[str]) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if key.endswith("AssetName") and isinstance(child, str):
                names.add(child)
            collect_asset_values(child, names)
    elif isinstance(value, list):
        for child in value:
            collect_asset_values(child, names)


def gather_image_sets() -> list[ImageSet]:
    image_sets: list[ImageSet] = []
    for path in sorted(ASSETS_ROOT.rglob("*.imageset")):
        asset_name = path.stem
        category = path.parent.relative_to(ASSETS_ROOT).as_posix()
        files = tuple(sorted(child for child in path.rglob("*") if child.is_file()))
        byte_size = sum(child.stat().st_size for child in files)
        image_sets.append(
            ImageSet(
                asset_name=asset_name,
                category=category,
                imageset_path=path,
                files=files,
                byte_size=byte_size,
            )
        )
    return image_sets


def classify_image_sets(image_sets: list[ImageSet], runtime_text: str, manifest_names: set[str]) -> tuple[list[ImageSet], list[tuple[ImageSet, str]]]:
    used: list[tuple[ImageSet, str]] = []
    unused: list[ImageSet] = []
    dynamic_names = gather_dynamic_asset_names()

    for image_set in image_sets:
        name = image_set.asset_name
        if name in dynamic_names:
            used.append((image_set, "modeled dynamic reference"))
            continue
        if name in manifest_names:
            used.append((image_set, "manifest asset field"))
            continue
        if re.search(rf'(?<![A-Za-z0-9_]){re.escape(name)}(?![A-Za-z0-9_])', runtime_text):
            used.append((image_set, "runtime text/reference"))
            continue
        unused.append(image_set)

    return unused, used


def gather_dynamic_asset_names() -> set[str]:
    """Known app naming conventions that do not appear as complete literals."""
    names: set[str] = set()
    animal_style_keys = {
        "xiaoman_hamster",
        "tangyuan_puppy",
        "moji_cat",
        "dengdeng_rabbit",
        "feifei_parrot",
        "xiaolu_guinea_pig",
        "deer_visitor",
        "fox_visitor",
        "bear_visitor",
    }
    for key in animal_style_keys:
        names.add(f"postcard_edge_{key}")
        names.add(f"postcard_motif_{key}")
    return names


def classify_bundle_folder_files(runtime_text: str) -> tuple[list[Path], list[tuple[Path, str]]]:
    unused: list[Path] = []
    used: list[tuple[Path, str]] = []
    for folder in RESOURCE_FOLDERS_IN_BUNDLE:
        base = ROOT / folder
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            if path.name == "manifest.json":
                used.append((path, "bundle manifest"))
                continue
            filename = path.name
            stem = path.stem
            if filename in runtime_text or stem in runtime_text:
                used.append((path, "runtime text/reference"))
            else:
                unused.append(path)
    return unused, used


def gather_non_bundled_art_sources() -> list[Path]:
    candidates: list[Path] = []
    for base in [
        TRIPPET_ROOT / "Resources" / "ArtSource",
        TRIPPET_ROOT / "Resources" / "ArtSourceRaster",
        ROOT / "ArtReferences",
    ]:
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}:
                candidates.append(path)
    return candidates


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def reset_report_dir() -> None:
    if REPORT_ROOT.exists():
        shutil.rmtree(REPORT_ROOT)
    REPORT_ROOT.mkdir(parents=True)


def write_symlink_index(image_sets: list[ImageSet], bundle_files: list[Path]) -> None:
    link_root = REPORT_ROOT / "candidate_links"
    link_root.mkdir()

    for image_set in image_sets:
        category_dir = link_root / "xcassets" / image_set.category
        category_dir.mkdir(parents=True, exist_ok=True)
        link = category_dir / image_set.imageset_path.name
        link.symlink_to(os.path.relpath(image_set.imageset_path, category_dir), target_is_directory=True)

    for path in bundle_files:
        category_dir = link_root / "bundled_resource_files" / path.parent.relative_to(ROOT).as_posix()
        category_dir.mkdir(parents=True, exist_ok=True)
        link = category_dir / path.name
        link.symlink_to(os.path.relpath(path, category_dir))


def main() -> None:
    runtime_text = gather_runtime_text()
    manifest_names = gather_manifest_asset_names()
    image_sets = gather_image_sets()
    unused_image_sets, used_image_sets = classify_image_sets(image_sets, runtime_text, manifest_names)
    unused_bundle_files, used_bundle_files = classify_bundle_folder_files(runtime_text)
    source_files = gather_non_bundled_art_sources()

    reset_report_dir()
    write_symlink_index(unused_image_sets, unused_bundle_files)

    unused_rows = [
        {
            "category": image_set.category,
            "asset_name": image_set.asset_name,
            "imageset_path": image_set.rel_imageset_path,
            "file_count": len(image_set.files),
            "bytes": image_set.byte_size,
        }
        for image_set in unused_image_sets
    ]
    write_csv(
        REPORT_ROOT / "unused_xcassets_candidates.csv",
        unused_rows,
        ["category", "asset_name", "imageset_path", "file_count", "bytes"],
    )

    used_rows = [
        {
            "category": image_set.category,
            "asset_name": image_set.asset_name,
            "imageset_path": image_set.rel_imageset_path,
            "reason": reason,
        }
        for image_set, reason in used_image_sets
    ]
    write_csv(
        REPORT_ROOT / "used_xcassets_reference_trace.csv",
        used_rows,
        ["category", "asset_name", "imageset_path", "reason"],
    )

    bundle_rows = [
        {
            "path": rel(path),
            "bytes": path.stat().st_size,
        }
        for path in unused_bundle_files
    ]
    write_csv(REPORT_ROOT / "unused_bundled_resource_files.csv", bundle_rows, ["path", "bytes"])

    source_rows = [
        {
            "path": rel(path),
            "bytes": path.stat().st_size,
        }
        for path in source_files
    ]
    write_csv(REPORT_ROOT / "non_bundled_art_source_files.csv", source_rows, ["path", "bytes"])

    by_category: dict[str, list[ImageSet]] = {}
    for image_set in unused_image_sets:
        by_category.setdefault(image_set.category, []).append(image_set)

    total_unused_bytes = sum(image_set.byte_size for image_set in unused_image_sets) + sum(
        path.stat().st_size for path in unused_bundle_files
    )
    total_source_bytes = sum(path.stat().st_size for path in source_files)

    lines = [
        "# Unused Art Assets Review",
        "",
        "Generated by `Tools/audit_unused_art_assets.py`.",
        "",
        "## Summary",
        "",
        f"- Bundled `.imageset` assets scanned: {len(image_sets)}",
        f"- Bundled `.imageset` cleanup candidates: {len(unused_image_sets)}",
        f"- Bundled loose resource file candidates: {len(unused_bundle_files)}",
        f"- Approx bundled candidate size: {total_unused_bytes / 1024 / 1024:.2f} MB",
        f"- Non-bundled source/reference art files listed separately: {len(source_files)} ({total_source_bytes / 1024 / 1024:.2f} MB)",
        "",
        "## How to Review",
        "",
        "- `unused_xcassets_candidates.csv`: app-bundled asset catalog candidates that were not found in runtime code or manifest asset fields.",
        "- `unused_bundled_resource_files.csv`: app-bundled loose files not referenced by code/manifests.",
        "- `candidate_links/`: symlinks to each candidate so you can browse them without moving originals.",
        "- `used_xcassets_reference_trace.csv`: assets kept because a reference was detected.",
        "- `non_bundled_art_source_files.csv`: source/reference art files that are not copied into the app bundle by the current Xcode project.",
        "",
        "## Caveats",
        "",
        "- This is a static audit. Assets referenced only by a future server config or manual runtime string input can still be false positives.",
        "- The script excludes `ArtSource`, `ArtSourceRaster`, and `Assets.xcassets` self-references when deciding usage, so generated-source docs do not mask unused bundled assets.",
        "",
        "## Bundled `.imageset` Candidates by Category",
        "",
    ]

    for category in sorted(by_category):
        entries = by_category[category]
        lines.append(f"### {category} ({len(entries)})")
        for image_set in entries:
            size_kb = image_set.byte_size / 1024
            lines.append(f"- `{image_set.asset_name}` - `{image_set.rel_imageset_path}` ({size_kb:.1f} KB)")
        lines.append("")

    if unused_bundle_files:
        lines.extend(["## Bundled Loose File Candidates", ""])
        for path in unused_bundle_files:
            lines.append(f"- `{rel(path)}` ({path.stat().st_size / 1024:.1f} KB)")
        lines.append("")

    (REPORT_ROOT / "README.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {rel(REPORT_ROOT)}")
    print(f"unused_xcassets={len(unused_image_sets)} unused_bundled_files={len(unused_bundle_files)}")


if __name__ == "__main__":
    main()
