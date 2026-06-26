# Butterfly Video Generation Prompt

Use this source image as the character reference:

`TripPet/Resources/ArtSourceRaster/Decorations/butterfly_travel_pet_style.png`

Paste this into the video generation model:

```text
Use the provided butterfly image as the exact character reference. Preserve its soft watercolor-and-colored-pencil texture, paper-grain surface, muted sage green, dusty teal, warm cream and pale honey palette, delicate antennae, wing markings, tiny fuzzy body, and warm hand-painted outline. Create a 4-second animation as a clean cutout-ready asset on a perfectly flat solid #ff00ff chroma-key background; the background must remain one uniform color with no shadows, gradients, texture, transparency checkerboard, floor plane, lighting variation, props, text, or watermark. Keep the camera locked with no zoom or pan, and keep the butterfly fully visible with generous padding for every frame. From 0.0s to 0.8s, the butterfly gently lifts upward from the lower center with soft natural wing flaps. From 0.8s to 1.6s, it floats forward very slightly and descends with a small body bob, still flapping lightly. From 1.6s to 2.0s, it lands softly and settles into place as the wing motion slows. From 2.0s to 4.0s, it remains mostly still in the landed pose as a loopable idle animation, with only a subtle wing tremble or tiny wing twitch every 0.8 to 1.2 seconds, very gentle and not full flapping. The motion should feel light, cozy, natural, and charming, suitable for a warm travel-pet journal app. Avoid realistic insect horror, glossy 3D rendering, heavy motion blur, deformation, extra wings, missing antennae, art-style changes, background scenery, flowers, leaves, cast shadows, contact shadows, black background, checkerboard background, text, and watermark.
```

Recommended generation settings:

- Duration: 4 seconds
- Frame rate: 24 fps
- Background: solid `#ff00ff`
- Camera: locked
- Output: MP4 or MOV, no compression presets that introduce strong chroma artifacts

After exporting the generated video, extract transparent frames:

```bash
python3 Tools/extract_chroma_key_animation.py path/to/butterfly_video.mp4 \
  --out-dir TripPet/Resources/ArtSourceRaster/Decorations/butterfly_animation \
  --fps 24 \
  --idle-start 2.0 \
  --prefix butterfly
```
