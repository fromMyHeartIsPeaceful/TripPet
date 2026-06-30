#!/usr/bin/env python3
"""Extract built-in image_gen PNG results from a Codex rollout JSONL file."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
import struct
import sys
from pathlib import Path
from typing import Any


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def png_info(data: bytes) -> tuple[int, int, bool]:
    if data[:8] != PNG_SIGNATURE:
        raise ValueError("result is not a PNG")
    if data[12:16] != b"IHDR":
        raise ValueError("missing PNG IHDR chunk")
    width, height = struct.unpack(">II", data[16:24])
    color_type = data[25]
    return width, height, color_type in (4, 6)


def safe_name(value: str) -> str:
    name = re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("._")
    return name or "imagegen_result"


def payload_from_line(line: str) -> dict[str, Any] | None:
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        return None
    payload = event.get("payload")
    return payload if isinstance(payload, dict) else None


def iter_results(rollout: Path):
    seen: set[str] = set()
    with rollout.open(encoding="utf-8", errors="replace") as handle:
        for line_number, line in enumerate(handle, 1):
            payload = payload_from_line(line)
            if payload is None:
                continue
            if payload.get("type") not in ("image_generation_call", "image_generation_end"):
                continue

            encoded = payload.get("result")
            if not isinstance(encoded, str) or not encoded:
                continue

            try:
                data = base64.b64decode(encoded, validate=True)
                width, height, has_alpha = png_info(data)
            except (ValueError, base64.binascii.Error):
                continue

            digest = hashlib.sha256(data).hexdigest()
            call_id = payload.get("id") or payload.get("call_id") or f"line_{line_number}"
            duplicate_key = f"{call_id}:{digest}"
            if duplicate_key in seen:
                continue
            seen.add(duplicate_key)

            yield {
                "call_id": call_id,
                "line_number": line_number,
                "payload_type": payload.get("type"),
                "revised_prompt": payload.get("revised_prompt", ""),
                "width": width,
                "height": height,
                "has_alpha": has_alpha,
                "byte_count": len(data),
                "sha256": digest,
                "data": data,
            }


def matches_filters(result: dict[str, Any], call_ids: set[str], prompt_filters: list[str]) -> bool:
    if not call_ids and not prompt_filters:
        return True
    call_match = bool(call_ids and result["call_id"] in call_ids)
    prompt = str(result.get("revised_prompt", "")).lower()
    prompt_match = any(fragment.lower() in prompt for fragment in prompt_filters)
    return call_match or prompt_match


def write_result(out_dir: Path, rollout: Path, result: dict[str, Any], asset_name: str) -> None:
    raw_path = out_dir / f"{asset_name}.raw.png"
    meta_path = out_dir / f"{asset_name}.imagegen.json"
    raw_path.write_bytes(result["data"])

    metadata = {
        "asset_name": asset_name,
        "call_id": result["call_id"],
        "line_number": result["line_number"],
        "payload_type": result["payload_type"],
        "source_rollout": str(rollout),
        "raw_png": raw_path.name,
        "width": result["width"],
        "height": result["height"],
        "has_alpha": result["has_alpha"],
        "byte_count": result["byte_count"],
        "sha256": result["sha256"],
        "revised_prompt": result["revised_prompt"],
    }
    meta_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{asset_name}: {result['width']}x{result['height']} {result['byte_count']} bytes")
    print(f"  raw: {raw_path}")
    print(f"  provenance: {meta_path}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Extract image_gen PNG base64 results from a Codex rollout JSONL file."
    )
    parser.add_argument("--rollout", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--call-id", action="append", default=[])
    parser.add_argument("--prompt-contains", action="append", default=[])
    parser.add_argument(
        "--asset",
        action="append",
        default=[],
        help="Asset name for selected results, applied in result order. Count must match.",
    )
    args = parser.parse_args()

    rollout = args.rollout.expanduser().resolve()
    if not rollout.exists():
        print(f"ERROR: rollout not found: {rollout}", file=sys.stderr)
        return 2

    results = [
        result
        for result in iter_results(rollout)
        if matches_filters(result, set(args.call_id), args.prompt_contains)
    ]
    if not results:
        print("ERROR: no image_gen PNG results matched", file=sys.stderr)
        return 1

    if args.asset and len(args.asset) != len(results):
        print(
            f"ERROR: --asset count ({len(args.asset)}) must match selected results ({len(results)})",
            file=sys.stderr,
        )
        return 2

    out_dir = args.out_dir.expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    for index, result in enumerate(results):
        asset_name = args.asset[index] if args.asset else safe_name(str(result["call_id"]))
        write_result(out_dir, rollout, result, safe_name(asset_name))

    print(f"\nExtracted {len(results)} image_gen result(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
