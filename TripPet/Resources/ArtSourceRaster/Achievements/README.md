# Achievement Medal Sources

Generated TripPet 1.0.8 achievement medal source files. Raw `image_gen` PNGs and provenance JSON live in `raw/`; processed transparent app-facing sources live beside this README and are mirrored into `Assets.xcassets/Achievements`. Runtime text remains in SwiftUI.

## Medal Art Rules

- Medal art must be generated raster art with raw PNG provenance, not code-drawn replacement art.
- App-facing medal PNGs are transparent `768x768` assets with no baked text, numbers, thresholds, labels, or Chinese copy.
- Medal content must contrast clearly with the pale paper base, using stronger center-object outlines and value separation than the background.
- The three categories share a watercolor travel-journal medal system while keeping distinct center symbols:
  - Travel: suitcase, ticket, map, compass, route, stamp-like travel details.
  - Steps: footprints or paw-like steps, walking path, route marker, milestone details.
  - Postcards: envelope, postcard, stamp, postmark rings, mail route waves.
- Formal border rings are applied in SwiftUI by tier ordinal, two medals per color: gray, white, pale green, blue, pale yellow, purple, gold, orange, and a thicker glowing orange.
