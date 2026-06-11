# Postcard Art Guidelines

These rules define the only supported postcard detail layout and art style for TripPet.

## Global Art Style

- Production art must continue the existing formal TripPet watercolor hand-painted style.
- Do not add flat vector art, plain line art, clip-art shapes, AI-looking stickers, emoji-like illustrations, or assets that do not visually match the existing watercolor destination paintings.
- If an old watercolor asset exists, reuse it before creating a replacement.
- If a required asset cannot be found, generate or redraw it in the same watercolor hand-painted style, then validate it against the existing Paris, Reykjavik, Lisbon, and airport watercolor references.
- UI icons may remain simple functional symbols, but postcard artwork, onboarding hero art, cabin art, animal art, destination art, stamps, and decorative narrative art must stay within the formal watercolor style.
- Future iterations must not merge non-watercolor or non-matching art into runtime surfaces.

## Canvas

- Postcard detail uses a single portrait canvas.
- The production `@3x` postcard base size is `1080 x 1920` px.
- The app-facing base asset is `postcard_base_portrait`.
- SwiftUI renders the card at `.aspectRatio(9.0 / 16.0, contentMode: .fit)`.
- The base must be an opaque pale-yellow watercolor paper PNG with subtle paper texture and quiet layout zones.
- The base must not include landscapes, skies, plants, cities, animals, stamps, postmarks, oval marks, circles, destination names, titles, dates, body copy, or any other readable text.
- The previous 16:9 detail card is deprecated and must not be used as the main postcard detail surface.

## Layering

- The postcard detail structure is fixed: generic postcard base + location-specific watercolor landscape + postmark + SwiftUI text.
- Postcards must not show animal selfies, animal portrait stickers, animal cutouts, or any animal image layer.
- Postcards must not show extra motif/deco overlays, including the previous triangular/paper-plane-style motif at the right side of the landscape area.
- Location art must be the old watercolor hand-painted destination style. Current runtime references should use `postcard_destination_paris`, `postcard_destination_reykjavik`, `postcard_destination_lisbon`, and the watercolor airport source `postcard_airport_first_departure`.
- Destination landscape assets are fixed `940 x 560` PNGs and must fill the destination slot. Runtime rendering uses fill-and-clip behavior, never small centered sticker behavior.
- Postmark assets should use the existing `postcard_stamp_*` assets.
- SwiftUI owns all body copy, dates, city names, animal names, sender lines, and localized text.
- Do not bake text into raster art, even when the text seems static in the current build.
- The first airport postcard must still render inside the same portrait canvas.

## Text Structure

The detail page text is fixed and must appear in this order:

1. Sender line: one sentence formatted exactly as `{animalName}从{destination}寄来`, for example `墨迹从巴黎寄来`.
2. Body.

Do not render the old separate destination, animal name, or status rows (`机场寄来`, `旅途中寄来`, `即将返程寄来`) inside the postcard detail artwork.
Do not render postcard titles such as `小动物寄来的第一张明信片` or animal selfie titles inside the postcard detail artwork.

## Reserved Portrait Layout Slots

Use these `@3x` pixel slots as the source-art targets for postcard detail overlays:

- Destination watercolor landscape: `x=70 y=300 w=940 h=560`
- Text block: `x=120 y=940 w=840 h=620`
- Stamp overlay: `x=820 y=120 w=180 h=180`

Keep visual interest away from the text slots so the runtime layout remains readable in every locale.

## Export Checklist

- Base PNG is exactly `1080 x 1920`.
- Base PNG is fully opaque.
- Base PNG is only pale-yellow paper: no baked-in top landscape and no bottom-right oval mark.
- Watercolor destination assets must be exactly `940 x 560`, from existing matching watercolor resources or newly generated/redrawn assets in the same style.
- Postmark PNGs include alpha.
- No animal selfie or animal cutout appears in postcard detail.
- No triangular motif/deco element appears in postcard detail.
- The landscape fills the upper half visually and does not look like a small sticker.
- No city, animal, stamp, title, body, date, or city-name content is baked into the base.
- Do not import a complete horizontal postcard composition and layer runtime text or stickers over it.
