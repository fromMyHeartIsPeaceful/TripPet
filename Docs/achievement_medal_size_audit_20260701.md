# Achievement Medal Size Audit - 2026-07-01

## Purpose

This document records the current size consistency problems in TripPet achievement medal art.

The current visual result is only barely acceptable in several places. Some assets were mechanically normalized after import so the app grid no longer looks obviously broken, but those fixes should be treated as temporary production patches, not final art quality.

## Measurement Method

- Source files measured: `TripPet/Resources/ArtSourceRaster/Achievements/*.source.png`
- Runtime files expected to match: `TripPet/Resources/Assets.xcassets/Achievements/*.imageset/*@3x.png`
- Canvas contract: `768x768` transparent PNG, RGBA.
- Effective visible size: alpha bounding box using `alpha > 8`.
- Primary metric: `visible max edge / 768`.

Recommended size bands:

| Band | Visible max edge | Interpretation |
| --- | ---: | --- |
| Fail | `< 680px` | Visibly undersized in grid/detail unless UI compensates. Should be regenerated or recropped. |
| Warning | `680-699px` | Marginal. May pass alone, but looks inconsistent next to stronger tiers. |
| Target | `700-735px` | Good general range for standard circular medals. |
| Watch | `736-755px` | Acceptable for winged/final/ornate medals, but check for edge crowding. |
| Risk | `> 755px` | Too close to canvas edge; likely crop/shadow risk. |

## Summary

| Category | Current status |
| --- | --- |
| Travel | Several early tiers remain visibly small. Tier 001 and 003 should be regenerated or recropped; tier 004 is marginal. |
| Steps | Tiers 001, 002, 005, 011 were mechanically enlarged to pass the target band. Tiers 012 and 014 are large/ornate and should be watched for edge crowding. Tiers 015 and 016 are missing entirely. |
| Postcards | Low tiers were mechanically normalized and now pass numerically, but tier 006 remains horizontally narrow even though its max edge passes. |

## Missing Step Medals

These two medals appear in the design/progression expectation but are not currently present in code or assets.

| Tier | Threshold | Title | Subtitle | Expected asset name | Current status |
| ---: | ---: | --- | --- | --- | --- |
| 015 | 1,200,000 steps | 走路也是思考 | 知名哲学家沃卜德说过此话 | `achievement_medal_steps_tier_015` | Missing tier definition, source PNG, raw PNG, provenance, and `.imageset`. |
| 016 | 1,500,000 steps | 洪荒之境 | 大圆满！（我实在编不动了，谢谢您能获得这个勋章） | `achievement_medal_steps_tier_016` | Missing tier definition, source PNG, raw PNG, provenance, and `.imageset`. |

Required work for these two:

1. Generate raster medal art with `image_gen`.
2. Store candidate handoff files under `ArtCandidates/`.
3. Preserve `raw.png`, `alpha.png`, `source.png`, and `.imagegen.json`.
4. Add formal files under `TripPet/Resources/ArtSourceRaster/Achievements`.
5. Add matching `.imageset` entries under `TripPet/Resources/Assets.xcassets/Achievements`.
6. Add two `AchievementEngine.stepTiers` entries.
7. Update tests that currently assume 14 step tiers.

## Travel Medals

| Tier | Asset | Visible bbox | Max edge | Ratio | Status | Notes |
| ---: | --- | ---: | ---: | ---: | --- | --- |
| 001 | `achievement_medal_travel_tier_001` | `602x613` | `613` | `79.8%` | Fail | Clearly undersized. Needs regenerated or recropped source art. |
| 002 | `achievement_medal_travel_tier_002` | `692x702` | `702` | `91.4%` | Target | Numerically acceptable. |
| 003 | `achievement_medal_travel_tier_003` | `657x644` | `657` | `85.5%` | Fail | Too small compared with later travel tiers. |
| 004 | `achievement_medal_travel_tier_004` | `686x657` | `686` | `89.3%` | Warning | Marginal and vertically uneven; bottom margin is large. |
| 005 | `achievement_medal_travel_tier_005` | `698x714` | `714` | `93.0%` | Target | Acceptable. |
| 006 | `achievement_medal_travel_tier_006` | `696x720` | `720` | `93.8%` | Target | Acceptable. |

Travel action list:

- Rework tier 001.
- Rework tier 003.
- Review tier 004 against grid screenshot; recrop/regenerate if it still reads smaller than 005/006.

## Step Medals

| Tier | Asset | Visible bbox | Max edge | Ratio | Status | Notes |
| ---: | --- | ---: | ---: | ---: | --- | --- |
| 001 | `achievement_medal_steps_tier_001` | `700x707` | `707` | `92.1%` | Temporary pass | Was previously undersized; mechanically enlarged. Prefer regenerated final art. |
| 002 | `achievement_medal_steps_tier_002` | `702x709` | `709` | `92.3%` | Temporary pass | Was the most obvious problem in grid; mechanically enlarged. Prefer regenerated final art. |
| 003 | `achievement_medal_steps_tier_003` | `704x709` | `709` | `92.3%` | Target | Acceptable. |
| 004 | `achievement_medal_steps_tier_004` | `717x708` | `717` | `93.4%` | Target | Acceptable. |
| 005 | `achievement_medal_steps_tier_005` | `699x708` | `708` | `92.2%` | Temporary pass | Mechanically enlarged from a smaller source. Prefer regenerated final art. |
| 006 | `achievement_medal_steps_tier_006` | `734x700` | `734` | `95.6%` | Target | Upper end of target, acceptable. |
| 007 | `achievement_medal_steps_tier_007` | `720x722` | `722` | `94.0%` | Target | Acceptable. |
| 008 | `achievement_medal_steps_tier_008` | `719x719` | `719` | `93.6%` | Target | Acceptable. |
| 009 | `achievement_medal_steps_tier_009` | `708x704` | `708` | `92.2%` | Target | Acceptable. |
| 010 | `achievement_medal_steps_tier_010` | `734x731` | `734` | `95.6%` | Target | Upper end of target, acceptable. |
| 011 | `achievement_medal_steps_tier_011` | `698x708` | `708` | `92.2%` | Temporary pass | Mechanically enlarged; review at small grid size. |
| 012 | `achievement_medal_steps_tier_012` | `750x738` | `750` | `97.7%` | Watch | Ornate/winged tier. Check edge crowding and shine overlay. |
| 013 | `achievement_medal_steps_tier_013` | `683x723` | `723` | `94.1%` | Target | Max edge passes, but horizontal visual weight is narrower. |
| 014 | `achievement_medal_steps_tier_014` | `751x730` | `751` | `97.8%` | Watch | Final ornate tier. Check edge crowding and detail readability. |
| 015 | `achievement_medal_steps_tier_015` | N/A | N/A | N/A | Missing | Needs generation and integration. |
| 016 | `achievement_medal_steps_tier_016` | N/A | N/A | N/A | Missing | Needs generation and integration. |

Step action list:

- Generate tier 015 and tier 016.
- Add tier 015 and tier 016 to `AchievementEngine.stepTiers`.
- Update tests currently expecting 14 step tiers.
- Replace mechanically enlarged tiers 001, 002, 005, and 011 with properly generated/cropped source art when time allows.
- Review tier 012 and 014 in the running grid for edge crowding.

## Postcard Medals

| Tier | Asset | Visible bbox | Max edge | Ratio | Status | Notes |
| ---: | --- | ---: | ---: | ---: | --- | --- |
| 001 | `achievement_medal_postcards_tier_001` | `682x708` | `708` | `92.2%` | Temporary pass | Mechanically enlarged; acceptable short term. |
| 002 | `achievement_medal_postcards_tier_002` | `691x707` | `707` | `92.1%` | Temporary pass | Mechanically enlarged slightly. |
| 003 | `achievement_medal_postcards_tier_003` | `701x708` | `708` | `92.2%` | Temporary pass | Mechanically enlarged slightly. |
| 004 | `achievement_medal_postcards_tier_004` | `657x708` | `708` | `92.2%` | Temporary pass | Max edge passes, but horizontal visual weight is narrow. |
| 005 | `achievement_medal_postcards_tier_005` | `731x723` | `731` | `95.2%` | Target | Acceptable. |
| 006 | `achievement_medal_postcards_tier_006` | `634x707` | `707` | `92.1%` | Warning | Max edge passes, but horizontally narrow; may still look smaller in grid. |
| 007 | `achievement_medal_postcards_tier_007` | `669x720` | `720` | `93.8%` | Target | Acceptable, slightly narrow horizontally. |
| 008 | `achievement_medal_postcards_tier_008` | `714x718` | `718` | `93.5%` | Target | Acceptable. |
| 009 | `achievement_medal_postcards_tier_009` | `729x735` | `735` | `95.7%` | Target | Acceptable. |

Postcard action list:

- Review tier 006 in the actual grid; likely needs a wider source composition rather than mechanical scaling.
- Treat tiers 001-004 as temporary pass because they were normalized after import.

## Acceptance Checklist For Future Medal Imports

Before a medal is promoted from `ArtCandidates/` to formal app resources:

1. Source PNG must be `768x768` RGBA with transparency.
2. Visible max edge should usually be `700-735px`.
3. Winged/final medals may be `736-755px`, but must be checked for edge crowding.
4. Source PNG and `.xcassets` PNG must be byte-identical or intentionally documented.
5. Raw provenance must exist and pass `verify_asset_files.py --require-provenance`.
6. A contact sheet must be reviewed at small grid size.
7. The running simulator grid must be screenshot-checked before calling the asset integrated.

## Current Conclusion

The current resource set is usable for local testing, but not final-quality. The main blockers before a clean art handoff are:

- Missing step tiers 015 and 016.
- Travel 001 and 003 are still undersized.
- Several step/postcard assets only pass because of mechanical normalization.
- Postcard 006 and step 013 have narrow horizontal visual weight and should be reviewed in-grid.
