---
name: art-asset-integration-guard
description: Guardrail workflow for TripPet visible art asset generation, replacement, integration, and validation. Use when Codex creates, edits, imports, replaces, wires, or reviews any app-visible art resource, including achievement medals, icons, backgrounds, animals, postcards, stamps, decorative images, generated PNGs, source raster files, asset catalogs, SwiftUI image loading, simulator screenshots, or any task where generated art must appear in the running client.
---

# Art Asset Integration Guard

Use this skill to close the gap between "art was generated" and "the running app displays the intended final asset." Treat it as mandatory for visible art work in TripPet.

## Failure Pattern To Prevent

Do not count any of these as completed art integration:

- A generated preview, temporary clipboard image, composite sheet, or green-screen mockup that was not exported into final app assets.
- An `image_gen` preview whose returned PNG bytes were never copied or decoded into a real raw source file.
- Any generated-image result described only from the chat preview, UI thumbnail, or memory of a prior generation, with no current filesystem path that can be opened by tools.
- A source file in `ArtSourceRaster` that differs materially from the app-facing `.imageset` PNG.
- A simplified line sketch, placeholder, code-drawn shape, SF Symbol, or fallback image used where final art was requested.
- A passing `UIImage(named:) != nil` test without checking the actual pixels and a running UI screenshot.
- A build artifact that contains an asset name but displays the wrong visual in the target screen.

If the generated asset, source raster, asset catalog file, installed app bundle, and simulator screenshot do not all point to the same intended visual, stop and report the mismatch.

## Built-In Image Generation Handoff Gate

For built-in `image_gen`, treat the generation as **not yet usable for project work** until one of these handoff proofs exists:

- A real local PNG/WebP path returned or discoverable from the generator output, copied into the workspace.
- A rollout `image_generation_call` or `image_generation_end` `result` decoded into a raw PNG with `scripts/extract_imagegen_results.py`.

Before editing, cropping, chroma-keying, importing into `.xcassets`, or wiring SwiftUI to a generated asset:

- Open or inspect the raw local file path.
- Write the matching `<asset>.imagegen.json` provenance beside the raw source.
- If no raw file or rollout-decodable PNG can be found, stop and say the image handoff failed.

Never continue from only "the image appeared in chat" or "the skill probably saved it under generated_images." Do not search indefinitely; after checking the expected `$CODEX_HOME/generated_images/...` area and available rollout extraction route, report the missing handoff instead of substituting code-drawn art or an old asset.

## Required Workflow

1. Establish the target asset contract.
   - Record each asset name, source path, `.imageset` path, expected dimensions, alpha requirement, and target UI screen.
   - For generated art, keep a final individual asset per runtime image. Do not rely on composite previews or temporary clipboard files.

2. Complete the generated artifact handoff before editing assets.
   - For built-in `image_gen`, accept only these raw generated inputs:
     - A real local image path produced by the generator and copied into the project source/staging area.
     - A rollout `image_generation_call` or `image_generation_end` `result` field decoded from PNG base64 with `scripts/extract_imagegen_results.py`.
   - Save a raw generated PNG and a matching `<asset>.imagegen.json` provenance file before chroma-key removal, cropping, resizing, `.imageset` replacement, or UI wiring.
   - Record call id, rollout line number, revised prompt, dimensions, byte count, and SHA-256 in provenance.
   - If a preview exists but no raw generated PNG can be handed off, stop. Do not substitute `PIL/ImageDraw`, SVG, SwiftUI drawing, canvas, SF Symbols, old art, line sketches, or any other "good enough" replacement.

3. Verify the actual files before wiring UI.
   - Open or preview the exact source raster and app-facing PNG that will ship.
   - Confirm the app-facing file is final art, not a placeholder or intermediate.
   - Confirm transparency for layerable assets such as medals, characters, props, stamps, and icons.
   - Run `scripts/verify_asset_files.py --require-provenance` for generated `.xcassets` art unless the user explicitly supplied a non-generated file.

4. Wire UI without fake completion.
   - Code may load, place, mask, tint, desaturate, or animate generated art.
   - Code must not recreate requested art as the primary visual unless the user explicitly requested code-native art.
   - Missing art fallback must look clearly unfinished in debug/development. It must not masquerade as an acceptable replacement.

5. Verify the installed app, not only the source tree.
   - Build the app and confirm the target asset names are present in the compiled bundle, such as `Assets.car`.
   - Install and launch the app on the simulator or device used for review.
   - Capture the target UI screen and compare it to the intended art, including scale, opacity, cropping, background, and state styling.

6. Report evidence before claiming completion.
   - Include raw generated PNG path, provenance JSON path, source path, `.imageset` path, bundle evidence, screenshot path, and any tests run.
   - If visual evidence is missing or inconsistent, say the asset is not fully integrated.

## File-Level Helper

Extract built-in `image_gen` PNG bytes from a rollout when no generated file path is visible:

```bash
python3 .codex/skills/art-asset-integration-guard/scripts/extract_imagegen_results.py \
  --rollout /path/to/rollout.jsonl \
  --out-dir /path/to/TripPet/Resources/ArtSourceRaster/Achievements/raw \
  --prompt-contains "first travel tier"
```

Use the helper for asset catalog checks:

```bash
python3 .codex/skills/art-asset-integration-guard/scripts/verify_asset_files.py \
  --project-root /path/to/TripPet \
  --require-provenance \
  --asset achievement_medal_travel_tier_001 \
  --asset achievement_medal_steps_tier_001
```

The helpers check generated handoff metadata, `.imageset/Contents.json`, referenced PNG files, dimensions, alpha metadata when available, and optional source rasters. They cannot judge visual correctness. Always pair them with image preview and running UI screenshots.

## Completion Bar

Only mark visible art work complete when all are true:

- Final individual art files exist outside temporary clipboard or generated-preview locations.
- Generated art has a raw PNG handoff and `.imagegen.json` provenance, unless the user explicitly supplied the source file.
- `ArtSourceRaster` and `.imageset` assets are visually the same intended asset.
- The running UI displays the final art at the requested location and state.
- Placeholder/fallback UI is either absent from the reviewed path or clearly marked as missing art.
- Tests/checks prove the bundle can load assets, and screenshots prove users can see the correct art.
