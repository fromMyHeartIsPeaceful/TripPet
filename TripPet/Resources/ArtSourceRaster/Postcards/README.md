# Postcards

Postcard paper templates, ticket confirmation cards, and postcard detail support art.

## Format

- Final app format: PNG `@3x`
- Unified postcard detail canvas: portrait 9:16.
- Current portrait base: `postcard_base_portrait@3x.png`, fixed `1080 x 1920`.
- Background: opaque for full postcard paper bases; transparent for overlays.
- The portrait base is only a pale-yellow watercolor paper surface.
- Do not bake titles, body copy, dates, city names, animal names, sender lines, stamps, postmarks, oval marks, circles, landscapes, or destination art into the base image.
- Preserve quiet paper texture and open areas for SwiftUI text.
- See `POSTCARD_ART_GUIDELINES.md` at the repository root for the full slot and export rules.

## Detail Structure

- Runtime postcard detail is fixed to: generic paper base, old watercolor destination art, postmark, and SwiftUI text.
- Do not use animal selfie/cutout layers in postcard detail.
- Do not use motif/deco overlays in postcard detail, including the old triangular/paper-plane-style motif.
