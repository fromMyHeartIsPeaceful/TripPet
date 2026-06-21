#!/usr/bin/env python3
"""Create transparent animal GIFs from watercolor MP4 clips."""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageSequence
from rembg import new_session, remove


VIDEO_DIR = Path("/Users/qianyu/Downloads/视频")
ROOM_IMAGE = Path(
    "/Users/qianyu/Library/Containers/com.tencent.xinWeChat/Data/Documents/"
    "xwechat_files/wxid_8024380243611_5dc6/temp/RWTemp/2026-06/"
    "9e20f478899dc29eb19741386f9343c8/3bb9b12922eeaf3f3fdba1daa363b020.png"
)
OUTPUT_DIR = Path("/Users/qianyu/Documents/Trip/exports/animal_gifs")


@dataclass(frozen=True)
class Clip:
    source: Path
    stem: str


CLIPS = [
    Clip(VIDEO_DIR / "aini.mp4", "aini"),
    Clip(VIDEO_DIR / "dundun.mp4", "dundun"),
    Clip(VIDEO_DIR / "feifei.mp4", "feifei"),
    Clip(VIDEO_DIR / "jiujiu.mp4", "jiujiu"),
    Clip(VIDEO_DIR / "moji.mp4", "moji"),
    Clip(VIDEO_DIR / "tangyuan.mp4", "tangyuan"),
    Clip(VIDEO_DIR / "video (1).mp4", "video_1"),
    Clip(VIDEO_DIR / "xiaolu.mp4", "xiaolu"),
    Clip(
        Path(
            "/Users/qianyu/Library/Containers/com.tencent.xinWeChat/Data/Documents/"
            "xwechat_files/wxid_8024380243611_5dc6/msg/video/2026-06/"
            "0727ca7ad1cf461273bb90e816f5d798.mp4"
        ),
        "hamster",
    ),
]

FIXED_CROP_CLIPS = {"aini", "moji", "tangyuan", "video_1"}


def largest_valid_components(mask: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    """Keep the animal/props and discard paper texture, border blobs, and shadows."""
    height, width = mask.shape
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8), 8)
    if count <= 1:
        return mask

    components = []
    for label in range(1, count):
        x, y, w, h, area = stats[label]
        touches_border = x <= 1 or y <= 1 or x + w >= width - 1 or y + h >= height - 1
        if touches_border or area < 24:
            continue
        components.append((label, int(area), int(x), int(y), int(w), int(h)))

    if not components:
        return mask

    main = max(components, key=lambda item: item[1])
    _, main_area, mx, my, mw, mh = main
    main_bbox = (
        max(0, mx - 100),
        max(0, my - 100),
        min(width, mx + mw + 100),
        min(height, my + mh + 100),
    )

    cleaned = np.zeros_like(mask, dtype=bool)
    for label, area, x, y, w, h in components:
        if area < max(18, main_area * 0.0025):
            continue

        cx = x + w / 2
        cy = y + h / 2
        near_main = main_bbox[0] <= cx <= main_bbox[2] and main_bbox[1] <= cy <= main_bbox[3]
        if not near_main:
            continue

        tiny_floor_line = h <= 4 and cy > (my + mh * 0.72)
        if tiny_floor_line:
            continue

        cleaned[labels == label] = True

    return cleaned


def remove_floor_shadow(mask: np.ndarray, rgba: np.ndarray) -> np.ndarray:
    """Drop low-saturation floor shadows that often survive foreground segmentation."""
    if not np.any(mask):
        return mask

    ys, xs = np.where(mask)
    top, bottom = int(ys.min()), int(ys.max())
    left, right = int(xs.min()), int(xs.max())
    body_height = max(1, bottom - top + 1)
    lower_zone = top + int(body_height * 0.58)

    rgb = rgba[:, :, :3]
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    sat = hsv[:, :, 1]
    val = hsv[:, :, 2]
    alpha = rgba[:, :, 3]

    shadow_like = (
        mask
        & (np.indices(mask.shape)[0] >= lower_zone)
        & (sat < 42)
        & (val < 235)
        & (alpha < 150)
    )

    count, labels, stats, _ = cv2.connectedComponentsWithStats(shadow_like.astype(np.uint8), 8)
    cleaned = mask.copy()
    for label in range(1, count):
        x, y, w, h, area = stats[label]
        if area < 16:
            continue
        wide = w / max(h, 1) > 2.8
        shallow = h < body_height * 0.09
        below_body = y + h > top + body_height * 0.76
        mostly_under = left - 20 <= x and x + w <= right + 20
        if wide and shallow and below_body and mostly_under:
            cleaned[labels == label] = False

    return cleaned


def segment_frame(frame_rgb: np.ndarray, session) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    pil = Image.fromarray(frame_rgb)
    cut = remove(
        pil,
        session=session,
        alpha_matting=True,
        alpha_matting_foreground_threshold=245,
        alpha_matting_background_threshold=20,
        alpha_matting_erode_size=7,
        post_process_mask=True,
    ).convert("RGBA")
    rgba = np.array(cut)
    alpha = rgba[:, :, 3]

    candidate = alpha > 8
    candidate = largest_valid_components(candidate, alpha)

    mask = alpha > 36
    mask = cv2.medianBlur(mask.astype(np.uint8) * 255, 3) > 0
    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, kernel, iterations=1) > 0
    mask = largest_valid_components(mask, alpha)
    mask = remove_floor_shadow(mask, rgba)

    out = rgba.copy()
    out[:, :, 3] = np.where(mask, 255, 0).astype(np.uint8)
    out[:, :, :3][~mask] = 255
    return out, mask, candidate


def read_sampled_frames(path: Path, target_fps: int, max_frames: int | None) -> tuple[list[np.ndarray], int]:
    cap = cv2.VideoCapture(str(path))
    if not cap.isOpened():
        raise RuntimeError(f"Could not open {path}")

    source_fps = cap.get(cv2.CAP_PROP_FPS) or target_fps
    step = max(1, int(round(source_fps / target_fps)))
    effective_fps = max(1, int(round(source_fps / step)))

    frames: list[np.ndarray] = []
    index = 0
    while True:
        ok, bgr = cap.read()
        if not ok:
            break
        if index % step == 0:
            rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
            frames.append(rgb)
            if max_frames and len(frames) >= max_frames:
                break
        index += 1
    cap.release()

    if not frames:
        raise RuntimeError(f"No frames decoded from {path}")
    return frames, effective_fps


def union_bbox(masks: list[np.ndarray], padding: int = 20) -> tuple[int, int, int, int]:
    union = np.zeros_like(masks[0], dtype=bool)
    for mask in masks:
        union |= mask
    ys, xs = np.where(union)
    if len(xs) == 0:
        height, width = union.shape
        return 0, 0, width, height
    height, width = union.shape
    left = max(0, int(xs.min()) - padding)
    top = max(0, int(ys.min()) - padding)
    right = min(width, int(xs.max()) + padding + 1)
    bottom = min(height, int(ys.max()) + padding + 1)
    return left, top, right, bottom


def mask_bbox(mask: np.ndarray) -> tuple[int, int, int, int] | None:
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def repair_temporal_masks(
    rgba_frames: list[np.ndarray],
    masks: list[np.ndarray],
    candidates: list[np.ndarray],
    window: int = 2,
) -> tuple[list[np.ndarray], list[np.ndarray]]:
    """Use neighboring frames to recover intermittent details like tails and maps."""
    repaired_masks: list[np.ndarray] = []
    repaired_frames: list[np.ndarray] = []
    kernel = np.ones((3, 3), np.uint8)

    for index, (rgba, mask, candidate) in enumerate(zip(rgba_frames, masks, candidates)):
        start = max(0, index - window)
        end = min(len(masks), index + window + 1)
        temporal = np.zeros_like(mask, dtype=bool)
        for neighbor in masks[start:end]:
            temporal |= neighbor

        repaired = mask | (temporal & candidate)
        repaired = cv2.morphologyEx(repaired.astype(np.uint8), cv2.MORPH_CLOSE, kernel, iterations=1) > 0
        repaired = largest_valid_components(repaired, rgba[:, :, 3])
        repaired = remove_floor_shadow(repaired, rgba)

        out = rgba.copy()
        out[:, :, 3] = np.where(repaired, 255, 0).astype(np.uint8)
        out[:, :, :3][~repaired] = 255
        repaired_masks.append(repaired)
        repaired_frames.append(out)

    return repaired_frames, repaired_masks


def crop_frames(frames: list[np.ndarray], bbox: tuple[int, int, int, int]) -> list[Image.Image]:
    left, top, right, bottom = bbox
    return [Image.fromarray(frame[top:bottom, left:right, :], "RGBA") for frame in frames]


def stabilized_frames(
    rgba_frames: list[np.ndarray],
    masks: list[np.ndarray],
    padding: int,
    max_dimension: int,
) -> list[Image.Image]:
    """Normalize subject scale and baseline so the GIF does not pulse in size."""
    boxes = [mask_bbox(mask) for mask in masks]
    valid_boxes = [box for box in boxes if box is not None]
    if not valid_boxes:
        return resize_frames(crop_frames(rgba_frames, union_bbox(masks, padding)), max_dimension)

    widths = np.array([box[2] - box[0] for box in valid_boxes], dtype=np.float32)
    heights = np.array([box[3] - box[1] for box in valid_boxes], dtype=np.float32)
    target_w = int(np.percentile(widths, 90)) + padding * 2
    target_h = int(np.percentile(heights, 90)) + padding * 2
    scale_limit = min(1.0, max_dimension / max(target_w, target_h))
    canvas_w = max(1, int(target_w * scale_limit))
    canvas_h = max(1, int(target_h * scale_limit))

    target_subject_h = float(np.median(heights))
    target_center_x = canvas_w / 2
    target_bottom = canvas_h - padding * scale_limit
    images: list[Image.Image] = []

    previous_box = valid_boxes[0]
    for rgba, box in zip(rgba_frames, boxes):
        if box is None:
            box = previous_box
        previous_box = box
        left, top, right, bottom = box
        subject_h = max(1, bottom - top)
        scale = target_subject_h / subject_h
        scale = float(np.clip(scale, 0.94, 1.06)) * scale_limit

        frame = Image.fromarray(rgba, "RGBA")
        scaled_size = (max(1, int(frame.width * scale)), max(1, int(frame.height * scale)))
        scaled = frame.resize(scaled_size, Image.Resampling.LANCZOS)

        scaled_left = left * scale
        scaled_right = right * scale
        scaled_bottom = bottom * scale
        subject_center_x = (scaled_left + scaled_right) / 2

        paste_x = int(round(target_center_x - subject_center_x))
        paste_y = int(round(target_bottom - scaled_bottom))
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (255, 255, 255, 0))
        canvas.alpha_composite(scaled, (paste_x, paste_y))
        images.append(canvas)

    return images


def persistent_detail_overlay(frames: list[Image.Image], clip_name: str) -> list[Image.Image]:
    if clip_name == "moji":
        return apply_persistent_roi(frames, y_min=0.55, x_min=0.0, x_max=1.0)
    if clip_name == "aini":
        return apply_fox_tail_reference(frames)
    return frames


def apply_fox_tail_reference(frames: list[Image.Image]) -> list[Image.Image]:
    if not frames:
        return frames

    width, height = frames[0].size
    left = int(width * 0.54)
    right = width
    top = int(height * 0.28)
    bottom = int(height * 0.82)

    def tail_color_mask(frame: Image.Image) -> np.ndarray:
        rgba = np.array(frame.convert("RGBA"))
        roi = rgba[top:bottom, left:right, :]
        rgb = roi[:, :, :3]
        alpha = roi[:, :, 3] > 0
        hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
        hue = hsv[:, :, 0]
        sat = hsv[:, :, 1]
        val = hsv[:, :, 2]
        orange = alpha & (hue >= 4) & (hue <= 32) & (sat > 42) & (val > 80)
        pale_tip = alpha & (sat < 70) & (val > 178) & (rgb[:, :, 0] > 175) & (rgb[:, :, 1] > 145)
        mask = orange | pale_tip
        mask = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8), iterations=1) > 0
        return mask

    reference = max(frames, key=lambda frame: int(tail_color_mask(frame).sum()))
    ref_rgba = np.array(reference.convert("RGBA"))
    ref_seed = tail_color_mask(reference)
    ref_alpha = ref_rgba[:, :, 3] > 0
    expanded_seed = np.zeros((height, width), dtype=bool)
    expanded_seed[top:bottom, left:right] = ref_seed
    expanded_seed = cv2.dilate(expanded_seed.astype(np.uint8), np.ones((19, 19), np.uint8), iterations=1) > 0
    full_ref_mask = ref_alpha & expanded_seed

    count, labels, stats, _ = cv2.connectedComponentsWithStats(full_ref_mask.astype(np.uint8), 8)
    if count > 1:
        seed_labels = labels[expanded_seed]
        seed_labels = seed_labels[seed_labels > 0]
        if len(seed_labels):
            keep = int(np.bincount(seed_labels).argmax())
            full_ref_mask = labels == keep
    full_ref_mask &= np.indices((height, width))[1] >= int(width * 0.50)
    full_ref_mask = cv2.morphologyEx(
        full_ref_mask.astype(np.uint8),
        cv2.MORPH_CLOSE,
        np.ones((9, 9), np.uint8),
        iterations=1,
    ) > 0

    overlay = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    overlay_arr = np.zeros_like(ref_rgba)
    overlay_arr[full_ref_mask] = ref_rgba[full_ref_mask]
    overlay.alpha_composite(Image.fromarray(overlay_arr, "RGBA"))

    fixed: list[Image.Image] = []
    clear_kernel = np.ones((5, 5), np.uint8)
    for frame in frames:
        current = np.array(frame.convert("RGBA"))
        current_tail_mask = np.zeros((height, width), dtype=bool)
        current_tail_mask[top:bottom, left:right] = tail_color_mask(frame)
        current_tail_mask &= cv2.dilate(full_ref_mask.astype(np.uint8), clear_kernel, iterations=5) > 0
        current[current_tail_mask, 3] = 0

        bridge_mask = full_ref_mask & (current[:, :, 3] == 0)
        bridge_arr = np.zeros_like(ref_rgba)
        bridge_arr[bridge_mask] = ref_rgba[bridge_mask]

        canvas = Image.new("RGBA", (width, height), (255, 255, 255, 0))
        canvas.alpha_composite(overlay)
        canvas.alpha_composite(Image.fromarray(current, "RGBA"))
        canvas.alpha_composite(Image.fromarray(bridge_arr, "RGBA"))
        fixed.append(canvas)
    return fixed


def apply_persistent_roi(
    frames: list[Image.Image],
    y_min: float,
    x_min: float,
    x_max: float,
) -> list[Image.Image]:
    if not frames:
        return frames

    width, height = frames[0].size
    left = int(width * x_min)
    right = int(width * x_max)
    top = int(height * y_min)

    best = max(
        frames,
        key=lambda frame: np.array(frame.getchannel("A").crop((left, top, right, height))).sum(),
    )
    overlay = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    roi = best.crop((left, top, right, height))
    overlay.alpha_composite(roi, (left, top))

    fixed: list[Image.Image] = []
    for frame in frames:
        canvas = Image.new("RGBA", frame.size, (255, 255, 255, 0))
        canvas.alpha_composite(overlay)
        canvas.alpha_composite(frame)
        fixed.append(canvas)
    return fixed


def resize_frames(frames: list[Image.Image], max_dimension: int) -> list[Image.Image]:
    if not frames:
        return frames
    width, height = frames[0].size
    scale = min(1.0, max_dimension / max(width, height))
    if scale >= 1.0:
        return frames
    size = (max(1, int(width * scale)), max(1, int(height * scale)))
    return [frame.resize(size, Image.Resampling.LANCZOS) for frame in frames]


def save_gif(frames: list[Image.Image], output: Path, fps: int) -> None:
    duration = max(20, int(round(1000 / fps)))
    gif_frames = [rgba_to_gif_frame(frame) for frame in frames]
    gif_frames[0].save(
        output,
        save_all=True,
        append_images=gif_frames[1:],
        duration=duration,
        loop=0,
        disposal=2,
        optimize=False,
        transparency=255,
    )


def rgba_to_gif_frame(frame: Image.Image) -> Image.Image:
    """Quantize an RGBA frame while reserving palette index 255 for transparency."""
    rgba = frame.convert("RGBA")
    alpha = np.array(rgba.getchannel("A"))

    matte = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
    matte.alpha_composite(rgba)
    palette_source = matte.convert("RGB").quantize(colors=255, method=Image.Quantize.MEDIANCUT)

    indexed = np.array(palette_source, dtype=np.uint8)
    indexed[alpha < 128] = 255
    paletted = Image.fromarray(indexed, "P")

    palette = palette_source.getpalette()[: 255 * 3]
    palette += [255, 255, 255]
    palette += [0] * (768 - len(palette))
    paletted.putpalette(palette)
    paletted.info["transparency"] = 255
    return paletted


def checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
    width, height = size
    img = Image.new("RGB", size, "#f7f3e8")
    draw = ImageDraw.Draw(img)
    for y in range(0, height, cell):
        for x in range(0, width, cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill="#dfd8c8")
    return img


def centered_preview(frame: Image.Image, background: Image.Image, label: str) -> Image.Image:
    canvas = background.convert("RGBA")
    scale = min(0.86, (canvas.width * 0.76) / frame.width, (canvas.height * 0.72) / frame.height)
    obj = frame.resize((max(1, int(frame.width * scale)), max(1, int(frame.height * scale))), Image.Resampling.LANCZOS)
    x = (canvas.width - obj.width) // 2
    y = max(8, (canvas.height - obj.height) // 2 - 2)
    canvas.alpha_composite(obj, (x, y))
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    draw.text((10, canvas.height - 28), label, fill=(72, 60, 45, 255), font=font)
    return canvas.convert("RGB")


def room_patch(size: tuple[int, int]) -> Image.Image:
    if not ROOM_IMAGE.exists():
        return Image.new("RGB", size, "#dfc58d")
    room = Image.open(ROOM_IMAGE).convert("RGB")
    crop = room.crop((110, 260, 610, 700))
    return crop.resize(size, Image.Resampling.LANCZOS)


def make_overview(stills: dict[str, Image.Image], output: Path) -> None:
    tile = (260, 260)
    gap = 18
    label_h = 30
    rows = []
    for name, still in stills.items():
        check = centered_preview(still, checker(tile), f"{name} checker")
        room = centered_preview(still, room_patch(tile), f"{name} room")
        row = Image.new("RGB", (tile[0] * 2 + gap, tile[1]), "white")
        row.paste(check, (0, 0))
        row.paste(room, (tile[0] + gap, 0))
        rows.append(row)

    cols = 2
    sheet_w = (tile[0] * 2 + gap) * cols + gap * (cols - 1)
    sheet_h = math.ceil(len(rows) / cols) * (tile[1] + label_h)
    sheet = Image.new("RGB", (sheet_w, sheet_h), "#fffaf0")
    for idx, row in enumerate(rows):
        x = (idx % cols) * (row.width + gap)
        y = (idx // cols) * (tile[1] + label_h)
        sheet.paste(row, (x, y))
    sheet.save(output)


def extract_gif_still(path: Path) -> Image.Image:
    with Image.open(path) as gif:
        frame_count = getattr(gif, "n_frames", 1)
        gif.seek(min(frame_count - 1, max(0, frame_count // 2)))
        rgba = gif.convert("RGBA")
    return rgba


def process_clip(clip: Clip, session, args) -> Image.Image:
    print(f"Processing {clip.source.name} -> {clip.stem}.gif", flush=True)
    raw_frames, fps = read_sampled_frames(clip.source, args.fps, args.max_frames)
    rgba_frames = []
    masks = []
    candidates = []
    for index, frame in enumerate(raw_frames, start=1):
        rgba, mask, candidate = segment_frame(frame, session)
        rgba_frames.append(rgba)
        masks.append(mask)
        candidates.append(candidate)
        if index % 10 == 0 or index == len(raw_frames):
            print(f"  segmented {index}/{len(raw_frames)} frames", flush=True)

    rgba_frames, masks = repair_temporal_masks(rgba_frames, masks, candidates)
    if clip.stem in FIXED_CROP_CLIPS:
        bbox = union_bbox(masks, args.padding)
        images = crop_frames(rgba_frames, bbox)
        images = resize_frames(images, args.max_dimension)
    else:
        images = stabilized_frames(rgba_frames, masks, args.padding, args.max_dimension)
    images = persistent_detail_overlay(images, clip.stem)

    output = OUTPUT_DIR / f"{clip.stem}.gif"
    save_gif(images, output, fps)
    print(f"  saved {output}", flush=True)

    still = images[len(images) // 2]
    centered_preview(still, checker((360, 360)), f"{clip.stem} checker").save(
        OUTPUT_DIR / f"{clip.stem}_checker_preview.png"
    )
    centered_preview(still, room_patch((360, 360)), f"{clip.stem} room").save(
        OUTPUT_DIR / f"{clip.stem}_room_preview.png"
    )
    return still


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fps", type=int, default=12)
    parser.add_argument("--max-frames", type=int, default=None)
    parser.add_argument("--max-dimension", type=int, default=420)
    parser.add_argument("--padding", type=int, default=22)
    parser.add_argument("--model", default="isnet-general-use")
    parser.add_argument("--only", choices=[clip.stem for clip in CLIPS])
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    clips = [clip for clip in CLIPS if args.only is None or clip.stem == args.only]
    for clip in clips:
        if not clip.source.exists():
            raise FileNotFoundError(clip.source)

    session = new_session(args.model)
    stills: dict[str, Image.Image] = {}
    for clip in clips:
        stills[clip.stem] = process_clip(clip, session, args)

    if len(stills) > 1:
        make_overview(stills, OUTPUT_DIR / "overview_preview.png")

    print("Done.", flush=True)


if __name__ == "__main__":
    main()
