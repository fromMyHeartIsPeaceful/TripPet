# TripPet 1.0.8 Medal Formal Art Context Summary

Date: 2026-06-26

## Executive Summary

This round fixed the TripPet 1.0.8 achievement medal art pipeline and integrated the first formal generated medal assets into the 1.0.8 worktree.

The key issue was not the SwiftUI placement logic alone. The repeated failure pattern was that `image_gen` previews existed, but the project was later populated with simplified replacement art made locally with `PIL/ImageDraw`. The running client therefore displayed simplified stand-ins rather than the generated watercolor medals.

The current state is now corrected for the first tier of all three categories:

- Travel tier 001 uses `achievement_medal_travel_tier_001`.
- Steps tier 001 uses `achievement_medal_steps_tier_001`.
- Postcards tier 001 uses `achievement_medal_postcards_tier_001`.
- Later tiers intentionally have `medalAssetName == nil` and show a clear `待美术` development placeholder.
- Runtime text, thresholds, titles, progress, and localization remain in SwiftUI rather than being baked into PNG files.

## Important Worktrees And Project Files

Primary planning/project root:

- `/Users/edy/Documents/心理`

1.0.8 implementation worktree:

- `/Users/edy/Documents/TripPet-1.0.8-achievements`

Mandatory project skill entry:

- `/Users/edy/Documents/心理/AGENTS.md`
- `/Users/edy/Documents/心理/.codex/skills/project-guardrails/SKILL.md`
- `/Users/edy/Documents/心理/.codex/skills/art-asset-integration-guard/SKILL.md`

The latest project guardrails are already in the project under `.codex/skills/`, and `AGENTS.md` instructs future agents to read `.codex/skills/project-guardrails/SKILL.md` before working.

## Failure Diagnosis

The failure was reproduced and diagnosed from the Codex rollout:

- The built-in `image_gen` tool did not create visible files in `~/.codex/generated_images` for this run.
- However, the rollout JSONL did contain `image_generation_call` / `image_generation_end` records with PNG base64 in the `result` field.
- The generated images were real `1254x1254` PNGs, but the previous workflow only searched for filesystem paths.
- After failing to find generated file paths, a local `PIL/ImageDraw` script created simplified line-art style PNGs and wrote those into the project.
- This caused the client to show simplified replacement medals, even though generated watercolor previews had existed.

The root cause is now documented in the skill:

- A generated preview is not enough.
- There must be a raw generated artifact handoff before any `.imageset` replacement or UI integration.
- Acceptable handoff forms are:
  - a real generated image file path, or
  - rollout `image_generation_call.result` / `image_generation_end.result` decoded from PNG base64.

## Skill Guardrail Updates

The project now contains an explicit art integration guard:

- `.codex/skills/art-asset-integration-guard/SKILL.md`
- `.codex/skills/art-asset-integration-guard/scripts/extract_imagegen_results.py`
- `.codex/skills/art-asset-integration-guard/scripts/verify_asset_files.py`

New hard rules:

- Before replacing source rasters, `.imageset` files, or UI references for generated art, prove the raw generated artifact handoff.
- Save a raw generated PNG and `<asset>.imagegen.json` provenance before chroma-key removal, cropping, resizing, or asset catalog replacement.
- If a generated preview exists but no raw PNG/provenance can be produced, stop.
- Do not substitute `PIL/ImageDraw`, SVG, SwiftUI drawing, canvas, SF Symbols, old art, line sketches, or other "good enough" replacement art.
- `UIImage(named:) != nil` is not sufficient; it only proves a resource name resolves.
- Final evidence must include raw PNG, provenance JSON, processed source, `.imageset` PNG, compiled bundle evidence, and running UI screenshot.

Validation already run:

```bash
python3 /Users/edy/.codex/skills/.system/skill-creator/scripts/quick_validate.py .codex/skills/project-guardrails
python3 /Users/edy/.codex/skills/.system/skill-creator/scripts/quick_validate.py .codex/skills/art-asset-integration-guard
```

Both skills are valid.

## Image Generation Provenance

The formal medal art came from built-in `image_gen` results extracted from:

```text
/Users/edy/.codex/sessions/2026/06/26/rollout-2026-06-26T10-37-05-019f01c9-b848-7a83-81bd-bb209cee30c5.jsonl
```

Chosen call IDs:

- Travel: `ig_03d96a498a14b437016a3e0ab61e588191bb9bfcd57f673166`
- Steps: `ig_03d96a498a14b437016a3e0b07f55c8191bbbaac1270cca0f4`
- Postcards: `ig_03d96a498a14b437016a3e0b4e6f5881919778264e6b2ca49c`

Raw extracted files:

- `TripPet/Resources/ArtSourceRaster/Achievements/raw/achievement_medal_travel_tier_001.raw.png`
- `TripPet/Resources/ArtSourceRaster/Achievements/raw/achievement_medal_steps_tier_001.raw.png`
- `TripPet/Resources/ArtSourceRaster/Achievements/raw/achievement_medal_postcards_tier_001.raw.png`

Provenance files:

- `TripPet/Resources/ArtSourceRaster/Achievements/raw/achievement_medal_travel_tier_001.imagegen.json`
- `TripPet/Resources/ArtSourceRaster/Achievements/raw/achievement_medal_steps_tier_001.imagegen.json`
- `TripPet/Resources/ArtSourceRaster/Achievements/raw/achievement_medal_postcards_tier_001.imagegen.json`

Each provenance JSON records:

- asset name
- image generation call id
- rollout line number
- original rollout path
- raw PNG filename
- width and height
- alpha status
- byte count
- SHA-256
- revised prompt

## Asset Processing Pipeline

The selected raw `image_gen` images were generated on a flat green chroma-key background.

Processing steps:

1. Extract rollout base64 PNG into raw source files with `extract_imagegen_results.py`.
2. Remove chroma key with:

```bash
python3 /Users/edy/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py \
  --input <asset>.raw.png \
  --out <asset>.alpha.png \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force
```

3. Crop to alpha content.
4. Resize into a `768x768` transparent canvas with the medal content around `720px`.
5. Save processed source PNG under `ArtSourceRaster/Achievements/`.
6. Mirror the same processed PNG into the app-facing `.imageset`.

Processed source files:

- `TripPet/Resources/ArtSourceRaster/Achievements/achievement_medal_travel_tier_001.source.png`
- `TripPet/Resources/ArtSourceRaster/Achievements/achievement_medal_steps_tier_001.source.png`
- `TripPet/Resources/ArtSourceRaster/Achievements/achievement_medal_postcards_tier_001.source.png`

App-facing asset catalog files:

- `TripPet/Resources/Assets.xcassets/Achievements/achievement_medal_travel_tier_001.imageset/achievement_medal_travel_tier_001@3x.png`
- `TripPet/Resources/Assets.xcassets/Achievements/achievement_medal_steps_tier_001.imageset/achievement_medal_steps_tier_001@3x.png`
- `TripPet/Resources/Assets.xcassets/Achievements/achievement_medal_postcards_tier_001.imageset/achievement_medal_postcards_tier_001@3x.png`

All app-facing medal PNGs are:

- `768x768`
- PNG
- alpha-enabled
- no baked text
- no baked threshold
- no Chinese copy
- transparent background

## Art Direction Achieved

Shared visual DNA:

- circular paper medal base
- scalloped handmade edge
- pencil outline
- watercolor travel journal texture
- low-saturation TripPet palette
- warm paper/cream base

Category distinction:

- Travel: suitcase, ticket, compass/rosette, ochre + mist blue.
- Steps: footprints/paw-like walking marks, curved path, ticket scrap, sage + peach.
- Postcards: envelope/postcard, stamp, postmark waves, peach + mist blue.

This meets the intended relationship:

- about 70% shared style
- at least 30% category distinction
- future tiers can inherit base style and increase detail/decorations rather than changing the visual system.

## Code Integration

Changed 1.0.8 code:

- `TripPet/Domain/Models/Achievement.swift`
- `TripPet/Domain/Services/AchievementEngine.swift`
- `TripPet/Features/Achievements/TravelAchievementWallView.swift`
- `TripPetTests/AchievementEngineTests.swift`

Important code behavior:

- `AchievementTier` now has `medalAssetName: String?`.
- First tier of each category has the formal medal asset name.
- Non-produced tiers remain `nil`.
- `AchievementMedalView` loads `ArtImage(name:)` when `medalAssetName` exists.
- Missing art uses a clear `待美术` dashed placeholder.
- No fallback art is allowed to masquerade as formal medals.
- Threshold badges remain SwiftUI text below the medal image.
- Collected/in-progress/locked state uses light opacity/saturation treatment.

Screenshots from the user confirmed:

- Travel wall first medal displays the suitcase/compass watercolor medal.
- Steps wall first medal displays the footprints/path watercolor medal.
- Postcards wall first medal displays the envelope/stamp watercolor medal.
- Missing tiers display `待美术`.

## Verification Completed

File-level asset guard:

```bash
python3 .codex/skills/art-asset-integration-guard/scripts/verify_asset_files.py \
  --project-root /Users/edy/Documents/TripPet-1.0.8-achievements \
  --require-provenance \
  --asset achievement_medal_travel_tier_001 \
  --asset achievement_medal_steps_tier_001 \
  --asset achievement_medal_postcards_tier_001
```

Result: passed.

Unit tests:

```bash
xcodebuild test \
  -project TripPet.xcodeproj \
  -scheme TripPet \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:TripPetTests/AchievementEngineTests
```

Result: `TEST SUCCEEDED`.

UI-related tests:

```bash
xcodebuild test \
  -project TripPet.xcodeproj \
  -scheme TripPet \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:TripPetTests/RootTabViewTests
```

Result: `TEST SUCCEEDED`.

Bundle check:

- Built `TripPet.app`.
- Confirmed `Assets.car` includes:
  - `achievement_medal_travel_tier_001`
  - `achievement_medal_steps_tier_001`
  - `achievement_medal_postcards_tier_001`

Simulator:

- Installed and launched on iPhone 17 simulator.
- User screenshots confirmed all three categories show the formal first-tier medal.

## Current Git State

In `/Users/edy/Documents/TripPet-1.0.8-achievements`, expected changed/untracked files include:

- Modified:
  - `TripPet/Domain/Models/Achievement.swift`
  - `TripPet/Domain/Services/AchievementEngine.swift`
  - `TripPet/Features/Achievements/TravelAchievementWallView.swift`
  - `TripPetTests/AchievementEngineTests.swift`
- Added/untracked:
  - `TripPet/Resources/ArtSourceRaster/Achievements/`
  - `TripPet/Resources/Assets.xcassets/Achievements/`

No commit, push, PR, or upload was performed.

In `/Users/edy/Documents/心理`, project-level guardrail files exist under:

- `.codex/skills/project-guardrails/`
- `.codex/skills/art-asset-integration-guard/`

This summary file is:

- `TripPet_1.0.8_Medal_Formal_Art_Context_Summary.md`

## Future Work Notes

When continuing medal work:

1. Always read `.codex/skills/project-guardrails/SKILL.md`.
2. For visible art assets, also read `.codex/skills/art-asset-integration-guard/SKILL.md`.
3. Do not generate a preview and then replace it with hand-drawn code art.
4. Extract or copy the real generated artifact first.
5. Save raw PNG and `.imagegen.json` provenance.
6. Process into transparent source PNG.
7. Mirror into `.imageset`.
8. Run `verify_asset_files.py --require-provenance`.
9. Build and check `Assets.car`.
10. Install on simulator and screenshot the running UI.

For future tiers:

- Continue naming: `achievement_medal_<category>_tier_<nnn>`.
- Add `medalAssetName` to the matching tier only after the art is truly generated and integrated.
- Keep same base medal system per category.
- Increase tier richness through rim details, watercolor density, additional stamps/flourishes, small charms, or layered decorations.
- Do not bake thresholds, Chinese titles, progress, or localized text into PNG files.

