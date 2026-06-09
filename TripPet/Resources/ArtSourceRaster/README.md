# ArtSourceRaster

This directory stores raster source exports for the final watercolor art pass.
The app-facing files live in `TripPet/Resources/Assets.xcassets`; files here are
the production masters and generated source references.

## Export Rules

- Keep asset names identical to `ContentManifest.json` and SwiftUI `Image(...)`
  names.
- Put final app assets in the matching `.imageset` as PNG `@3x`.
- Put reusable source exports in the matching category directory here.
- Keep generated chroma-key sources in `GeneratedKey/` when a transparent PNG
  was produced from background removal.
- Do not include business copy, UI labels, or destination-specific text inside
  illustration assets.
- Prefer transparent PNG for animals, props, stamps, destination cutouts, and
  other layerable objects.
- Use opaque PNG for full-scene backgrounds and paper textures.

## Current First-Pass PNG Replacements

| Asset | Source | App imageset |
| --- | --- | --- |
| `animal_cat_home` | `Animals/animal_cat_home.png` | `Assets.xcassets/Animals/animal_cat_home.imageset` |
| `animal_cat_selfie` | `Animals/animal_cat_selfie.png` | `Assets.xcassets/Animals/animal_cat_selfie.imageset` |
| `animal_visitor_unknown` | `Animals/animal_visitor_unknown.png` | `Assets.xcassets/Animals/animal_visitor_unknown.imageset` |
| `cabin_room_base` | `Cabin/cabin_room_base.png` | `Assets.xcassets/Cabin/cabin_room_base.imageset` |
| `prop_map_table` | `Cabin/prop_map_table.png` | `Assets.xcassets/Cabin/prop_map_table.imageset` |

