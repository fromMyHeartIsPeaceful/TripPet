#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image


@dataclass(frozen=True)
class ProcessedFrame:
    name: str
    rgba: np.ndarray
    mask: np.ndarray


def parse_hex_color(value: str) -> np.ndarray:
    text = value.strip().lstrip("#")
    if len(text) != 6:
        raise argparse.ArgumentTypeError("Color must be a 6-digit hex value like #ff00ff")
    try:
        return np.array([int(text[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)
    except ValueError as error:
        raise argparse.ArgumentTypeError("Color must be a 6-digit hex value like #ff00ff") from error


def extract_video_frames(video: Path, raw_dir: Path, fps: int) -> list[Path]:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg was not found on PATH")

    pattern = raw_dir / "frame_%04d.png"
    command = [
        ffmpeg,
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-i",
        str(video),
        "-vf",
        f"fps={fps}",
        str(pattern),
    ]
    subprocess.run(command, check=True)
    frames = sorted(raw_dir.glob("frame_*.png"))
    if not frames:
        raise RuntimeError(f"No frames were extracted from {video}")
    return frames


def chroma_key_frame(
    path: Path,
    key_rgb: np.ndarray,
    transparent_threshold: float,
    opaque_threshold: float,
    alpha_threshold: int,
) -> ProcessedFrame:
    image = Image.open(path).convert("RGBA")
    rgba = np.asarray(image, dtype=np.float32)
    rgb = rgba[:, :, :3]

    distance = np.sqrt(np.sum((rgb - key_rgb) ** 2, axis=2))
    alpha = np.clip(
        (distance - transparent_threshold) / max(1.0, opaque_threshold - transparent_threshold),
        0.0,
        1.0,
    )

    safe_alpha = np.maximum(alpha[:, :, None], 1.0 / 255.0)
    cleaned_rgb = (rgb - key_rgb * (1.0 - alpha[:, :, None])) / safe_alpha
    cleaned_rgb = np.clip(cleaned_rgb, 0.0, 255.0)

    out = np.dstack([cleaned_rgb, alpha * 255.0]).astype(np.uint8)
    mask = out[:, :, 3] > alpha_threshold
    return ProcessedFrame(path.name, out, mask)


def union_bbox(masks: list[np.ndarray], padding: int) -> tuple[int, int, int, int]:
    ys: list[np.ndarray] = []
    xs: list[np.ndarray] = []
    for mask in masks:
        y, x = np.nonzero(mask)
        if len(x) and len(y):
            xs.append(x)
            ys.append(y)
    if not xs or not ys:
        raise RuntimeError("No non-background pixels found after chroma keying")

    all_x = np.concatenate(xs)
    all_y = np.concatenate(ys)
    height, width = masks[0].shape
    left = max(0, int(all_x.min()) - padding)
    top = max(0, int(all_y.min()) - padding)
    right = min(width, int(all_x.max()) + 1 + padding)
    bottom = min(height, int(all_y.max()) + 1 + padding)
    return left, top, right, bottom


def save_frames(
    frames: list[ProcessedFrame],
    output_dir: Path,
    bbox: tuple[int, int, int, int],
    prefix: str,
) -> list[str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    left, top, right, bottom = bbox
    saved: list[str] = []
    for index, frame in enumerate(frames, start=1):
        cropped = frame.rgba[top:bottom, left:right, :]
        name = f"{prefix}_{index:04d}.png"
        Image.fromarray(cropped, "RGBA").save(output_dir / name)
        saved.append(name)
    return saved


def save_preview_gif(frames: list[ProcessedFrame], output: Path, bbox: tuple[int, int, int, int], fps: int) -> None:
    left, top, right, bottom = bbox
    beige = np.array([246, 239, 223], dtype=np.float32)
    preview_frames: list[Image.Image] = []
    for frame in frames:
        cropped = frame.rgba[top:bottom, left:right, :].astype(np.float32)
        alpha = cropped[:, :, 3:4] / 255.0
        rgb = cropped[:, :, :3] * alpha + beige * (1.0 - alpha)
        preview_frames.append(Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB"))

    duration_ms = max(1, int(1000 / fps))
    preview_frames[0].save(
        output,
        save_all=True,
        append_images=preview_frames[1:],
        duration=duration_ms,
        loop=0,
        optimize=False,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract a chroma-key video into stable transparent PNG animation frames."
    )
    parser.add_argument("video", type=Path, help="Input video generated on a flat chroma-key background")
    parser.add_argument("--out-dir", type=Path, required=True, help="Directory for extracted animation assets")
    parser.add_argument("--fps", type=int, default=24)
    parser.add_argument("--idle-start", type=float, default=2.0, help="Seconds where the idle loop starts")
    parser.add_argument("--skip-frames", type=int, default=0, help="Drop this many extracted frames from the start")
    parser.add_argument("--key-color", type=parse_hex_color, default=parse_hex_color("#ff00ff"))
    parser.add_argument("--transparent-threshold", type=float, default=36.0)
    parser.add_argument("--opaque-threshold", type=float, default=150.0)
    parser.add_argument("--alpha-threshold", type=int, default=8)
    parser.add_argument("--padding", type=int, default=24)
    parser.add_argument("--prefix", default="butterfly")
    args = parser.parse_args()

    video = args.video.resolve()
    out_dir = args.out_dir.resolve()
    all_dir = out_dir / "frames"
    idle_dir = out_dir / "idle_loop_frames"

    out_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="trip_pet_chroma_frames_") as temp:
        raw_paths = extract_video_frames(video, Path(temp), args.fps)
        if args.skip_frames < 0:
            raise RuntimeError("--skip-frames must be zero or greater")
        if args.skip_frames >= len(raw_paths):
            raise RuntimeError("--skip-frames would remove every extracted frame")
        raw_paths = raw_paths[args.skip_frames :]

        processed = [
            chroma_key_frame(
                path,
                args.key_color,
                args.transparent_threshold,
                args.opaque_threshold,
                args.alpha_threshold,
            )
            for path in raw_paths
        ]

    bbox = union_bbox([frame.mask for frame in processed], args.padding)
    all_names = save_frames(processed, all_dir, bbox, args.prefix)

    idle_start_index = min(len(processed), max(0, int(round(args.idle_start * args.fps)) - args.skip_frames))
    idle_frames = processed[idle_start_index:] or processed[-1:]
    idle_names = save_frames(idle_frames, idle_dir, bbox, f"{args.prefix}_idle")

    save_preview_gif(processed, out_dir / f"{args.prefix}_preview.gif", bbox, args.fps)
    save_preview_gif(idle_frames, out_dir / f"{args.prefix}_idle_preview.gif", bbox, args.fps)

    manifest = {
        "source_video": str(video),
        "fps": args.fps,
        "frame_count": len(processed),
        "idle_start_seconds": args.idle_start,
        "skip_frames": args.skip_frames,
        "idle_start_frame_index_zero_based": idle_start_index,
        "idle_frame_count": len(idle_frames),
        "key_color": "#{:02x}{:02x}{:02x}".format(*args.key_color.astype(int).tolist()),
        "crop_bbox_left_top_right_bottom": bbox,
        "frames_dir": str(all_dir),
        "idle_loop_frames_dir": str(idle_dir),
        "frames": all_names,
        "idle_loop_frames": idle_names,
        "preview_gif": str(out_dir / f"{args.prefix}_preview.gif"),
        "idle_preview_gif": str(out_dir / f"{args.prefix}_idle_preview.gif"),
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: manifest[k] for k in ("frame_count", "idle_frame_count", "frames_dir", "idle_loop_frames_dir", "preview_gif", "idle_preview_gif")}, indent=2))


if __name__ == "__main__":
    main()
