# TripPet Persistence Plan

## Goal

Move user-owned state out of the in-memory `AppRepository` without duplicating static catalog content from `ContentManifest.json`.

## Current Data Flow

- `ContentManifestLoader` reads bundled manifest data at app launch.
- `SeedData(manifest:)` builds the runtime catalog: animals, initial travel wishes, and sample postcards.
- `AppRepository` owns mutable app state for the current process:
  - `tickets`
  - `travelWishes` status
  - `trips`
  - `postcards` read state and generated postcards

## Manifest-Owned Content

These should stay in `ContentManifest.json` and be referenced by stable IDs:

- Animal identity and art names: `id`, display name, species, personality, home/selfie/visitor assets.
- Destination identity and art names: `id`, display name, landmark, stamp, route map, colors.
- Rules defaults: `stepsPerTicket`, `dailyTicketLimit`.
- Optional bundled postcards used as starter/sample content.

## User-Owned State

These should be persisted:

- `DailyStepGift`
  - `id`
  - `giftedAt`
  - `sourceSteps`
  - `ticketCount`
- `Ticket`
  - `id`
  - `date`
  - `sourceSteps`
  - `ticketCount`
  - `giftedAt`
- `TravelWishState`
  - `wishId`
  - `animalId`
  - `destinationId` or destination display fallback
  - `status`
  - `createdAt`
- `Trip`
  - `id`
  - `animalId`
  - `destinationId` or destination display fallback
  - `departedAt`
  - `expectedReturnAt`
  - `status`
- `PostcardState`
  - `id`
  - `tripId`
  - `destinationId` or destination display fallback
  - generated text fields
  - asset references used at generation time
  - `sentAt`
  - `isRead`
- App flags
  - onboarding completed
  - Health guide dismissed / last authorization prompt state

## Suggested SwiftData Models

- `PersistedTicket`
- `PersistedTrip`
- `PersistedPostcard`
- `PersistedTravelWishState`
- `PersistedAppFlag`

Avoid a persisted `Animal` or `Destination` model for v1. Store only manifest IDs plus user state. If catalog content changes later, the app can rehydrate names/assets from the latest manifest while preserving trip and postcard history.

## Repository Boundary

Keep `AppRepository` as the single mutation surface:

- `giftTicket(...)` creates the ticket and active trip atomically.
- `completeTrip(_:postcard:)` completes the trip, completes the matching wish, and inserts the generated postcard atomically.
- `markPostcardRead(_:)` updates mailbox read state.

When SwiftData is added, introduce a small storage adapter behind the repository instead of letting views write SwiftData directly.

## Migration Notes

- On first launch with no persisted user state, hydrate from manifest seed data.
- Once persisted state exists, load user state first, then enrich display fields from manifest.
- Do not persist starter/sample postcards unless the user modifies them, or mark them with stable IDs so duplicates are avoided.
- Generated postcards should persist their resolved asset names to keep old mailbox cards stable if manifest art changes.
