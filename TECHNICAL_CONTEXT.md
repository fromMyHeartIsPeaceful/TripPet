# TripPet iOS Technical Context

## Current Goal

Build a native iOS app where Apple Health step counts become travel tickets for small animals. The current implementation has moved past the black-and-white wireframe into a watercolor travel-journal MVP using asset-backed SwiftUI scenes.

## Project

- Xcode project: `TripPet.xcodeproj`
- Main source root: `TripPet/`
- SwiftUI app entry: `TripPet/App/TripPetApp.swift`
- Bundle id: `com.qianyu.TripPet`
- Minimum iOS target: `17.0`
- Current build verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TripPet.xcodeproj -scheme TripPet -configuration Debug -sdk iphoneos -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build`
  - Result: build succeeded.
- Current test verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TripPet.xcodeproj -scheme TripPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO`
  - Result: test succeeded.

## Architecture

- UI: SwiftUI
- Pattern: lightweight MVVM + shared `AppEnvironment`
- Current state store: `AppRepository` backed by `AppUserStateStore`
- Persistence: SwiftData via `SwiftDataUserStateStore`, with `InMemoryUserStateStore` for previews/tests.
- Health integration: `HealthKitStepCountProvider` behind `StepCountProvider`
- Rule engine: `TicketRuleEngine`
- Content seed/catalog: `SeedData.preview` and bundled `ContentManifest.json`
- Content manifest: `TripPet/Resources/ContentManifest.json`
- Manifest loader: `ContentManifestLoader` reads bundled JSON and falls back to `SeedData.preview` / default ticket rules.
- Persistence plan: `PERSISTENCE_PLAN.md` separates manifest-owned catalog data from user-owned state; the first SwiftData pass is implemented under `TripPet/Data/Persistence`.
- Copy system: `AppCopy` is the first static Chinese copy hub for frequently reused MVP text. It is intentionally lightweight and does not introduce localization yet.

## Main Screens

- `AppRootView`
  - Startup gate before the tabs.
  - Shows onboarding until `onboardingCompleted` is saved.
  - Then shows Health connection guide until `healthGuideDismissed` is saved.
  - Enters `RootTabView` after both flags are complete.

- `OnboardingView`
  - Uses `onboarding_cabin_path` and `onboarding_cat_suitcase`.
  - Text and buttons are SwiftUI-rendered.

- `HealthConnectView`
  - Uses `health_steps_ticket`.
  - Can request Health permission or continue with “稍后再说”.
  - Distinguishes request failure from “request returned but authorization did not change,” so real-device Health validation has clearer user-facing states.

- `CabinView`
  - Two-tab app first tab.
  - Shows status, title, settings button, watercolor cabin scene, and a paper-ticket action card.
  - Uses `CabinViewModel`.
  - Health not connected state shows `Health 未连接`, a `连接 Apple 健康` primary button, and a `先看看小屋` secondary action.
  - Gift flow reads today's steps, evaluates ticket eligibility, then shows a paper confirmation sheet before creating a trip in the repository.
  - When `AppRepository.activeTrip` exists, shows a paper trip status card with route map from manifest, cat marker, and paper plane assets.
  - Runs eligible postcard reveal checks when the page appears.
  - Includes lightweight native animation for resident animal breathing, ticket floating, and gift flight feedback; Reduce Motion lowers these effects.

- `MailboxView`
  - Second tab.
  - Shows mailbox title, watercolor mail tray, and envelope rows using `envelope_*` assets.
  - Shows a warm empty state when no postcards exist.
  - Runs eligible postcard reveal checks when the page appears.
  - Row text is SwiftUI-rendered, not baked into images.
  - Opens `PostcardDetailView` using `fullScreenCover`, so the detail covers the tab bar.

- `PostcardDetailView`
  - Uses `postcard_template_classic` plus `destinationAssetName`, `animalAssetName`, and `stampAssetName` from `Postcard`.
  - Paris and Iceland seed postcards are resource-driven rather than switched in the view.

- `SettingsView`
  - Paper-strip settings page with hand-drawn icon assets.
  - Health permission status and request flow are still wired through `StepCountProvider`.
  - Links to notification, postcard collection, and about subpages using the new settings art assets.

## Domain Models

- `Animal`
  - Includes `homeAssetName`, `selfieAssetName`, and `visitorAssetName`.
- `TravelWish`
  - Includes `destinationId` so persisted user state can rehydrate from the latest manifest catalog.
- `Ticket`
- `Trip`
  - Includes `destinationId` so route maps and generated postcards can be resolved from manifest content.
- `Postcard`
  - Includes `templateAssetName`, `destinationAssetName`, `stampAssetName`, `animalAssetName`, and `envelopeAssetName` for asset-driven rendering.

Current core rule:

- Daily steps >= 3000 gives 1 ticket.
- Daily ticket limit is 1.
- User can gift today's steps once per day.
- `AppRepository.giftTicket(...)` only creates a ticket/trip when there is no active trip and an active wish exists.
- `AppRepository.completeTrip(_:postcard:)` completes the trip, completes the matching wish, and inserts the generated postcard.
- `AppRepository.revealEligiblePostcards(...)` completes eligible active trips and inserts one generated unread postcard per trip.
- `AppRepository.completeOnboarding()` and `dismissHealthGuide()` persist app startup flags.

## Services

- `StepCountProvider`
  - Protocol for step data.
- `HealthKitStepCountProvider`
  - Reads HealthKit `.stepCount`.
  - Requests read authorization only.
  - Tracks `readPermissionRequested` locally after a successful read authorization request, because `HKHealthStore.authorizationStatus(for:)` is not a reliable read-access signal for a read-only app.
  - Uses explicit Health errors for unavailable devices, missing step type, and read failures.
  - Floors and clamps HealthKit step totals with `max(0, Int(steps.rounded(.down)))`.
  - Starts a HealthKit observer query after read permission is requested so foreground UI can refresh when step samples change.
- `AppEnvironment`
  - Owns the latest `StepCountSnapshot` with status, steps, read timestamp, and error message.
  - Immediately reads today's steps after Health authorization succeeds.
  - Refreshes steps on app launch, foreground activation, Health connection screens, settings, and cabin appearance.
- `TicketRuleEngine`
  - Evaluates today's steps and daily gifting limit.
- `AnimalVisitService`
  - Chooses a non-resident animal and the cabin scene displays its `visitorAssetName`.
- `PostcardScheduler`
  - Handles time-based postcard reveal checks.
  - Creates asset-backed `Postcard` values from `Trip`, `Animal`, and manifest destination config.
  - Runtime postcard title/subtitle/body now come from `ManifestDestination` templates with `{animal}` and `{destination}` replacements.

## Persistence

- SwiftData models:
  - `PersistedTicket`
  - `PersistedTrip`
  - `PersistedPostcard`
  - `PersistedTravelWishState`
  - `PersistedAppFlag`
- Persisted data stores user-owned state only: tickets, trip state, postcard/read state, travel wish status, onboarding flag, and Health guide flag.
- Manifest-owned catalog data stays in `ContentManifest.json`; persisted `destinationId` values are rehydrated from the current manifest at load time.
- Views do not write SwiftData directly; mutations stay behind `AppRepository`.

## Resources

- Content manifest: `TripPet/Resources/ContentManifest.json`
- Asset catalog: `TripPet/Resources/Assets.xcassets`
- Source SVGs: `TripPet/Resources/ArtSource`
- Generator script: `Tools/generate_art_assets.js`
- `Assets.xcassets` is included in the target Resources build phase and compiles into `Assets.car`.

Asset catalog groups:

- `Animals`
- `Cabin`
- `Destinations`
- `Postcards`
- `Stamps`
- `Envelopes`
- `UI`
- `Textures`

Current P0 assets include:

- `animal_cat_home`
- `animal_cat_selfie`
- `animal_visitor_unknown`
- `cabin_room_base`
- `prop_map_table`
- `prop_ticket_single`
- `destination_paris_line`
- `destination_iceland_line`
- `postcard_template_classic`
- `stamp_paris`
- `stamp_iceland`
- `mailbox_tray_base`
- `envelope_unread`
- `envelope_read`
- `envelope_old`
- `texture_paper_grain`
- `trip_route_map_paris`
- `trip_marker_cat`
- `prop_paper_plane`
- `onboarding_cabin_path`
- `onboarding_cat_suitcase`
- `health_steps_ticket`
- `ticket_confirm_card`
- `ticket_flight_trail`
- `trip_route_map_iceland`
- `animal_dog_home`
- `animal_dog_visitor`
- `animal_rabbit_home`
- `animal_rabbit_visitor`
- `settings_notification_note`
- `settings_collection_empty`
- `settings_about_cabin`

Current UI icons include:

- `icon_home`
- `icon_mail`
- `icon_settings`
- `icon_back`
- `icon_health`
- `icon_ticket`
- `icon_steps`
- `icon_notification`
- `icon_collection`
- `icon_about`

Manifest shape:

- `animals`: display name, species, personality, home/selfie/visitor assets, resident flag.
- `destinations`: display name, landmark asset, stamp asset, route map asset, primary color, runtime postcard title/subtitle/body templates.
- `postcards`: destination/animal ids plus template, destination, stamp, animal, envelope asset names, title, subtitle, body, and read state.
- `rules`: `stepsPerTicket`, `dailyTicketLimit`.

## Design System

- `AppTheme` contains the watercolor palette from `VISUAL_ART_SPEC.md`, font levels, paper card modifier, and primary/outline button styles.
- `AppCopy` contains the first pass of shared MVP Chinese UI copy for onboarding, Health, cabin, gift confirmation, mailbox, settings, tabs, and ticket-rule messages.
- `PaperBackground` applies warm paper plus low-opacity `texture_paper_grain`.
- `ArtImage` wraps asset loading, template rendering for `icon_*`, and debug fallback placeholders.

## Design Direction

- Watercolor travel-journal UI with paper texture, pencil lines, low saturation, and asset-backed scenes.
- Two primary tabs only: `小屋`, `邮箱`.
- Details should be in-app full-screen overlays when they conceptually leave the primary tab surface.

## Tests

- Test target: `TripPetTests`
- Current simulator test count: 17.
- `TicketRuleEngineTests` covers:
  - below 3000 steps is not eligible
  - exactly 3000 steps is eligible
  - above 3000 steps is eligible
  - daily gift limit blocks repeat gifts
  - repository gift state resets across days
- `AppRepositoryTripTests` covers:
  - gifting creates and exposes active trips
  - completing trips inserts generated postcards
  - duplicate gifts do not create duplicate trips
  - SwiftData state round-trip for tickets/trips/postcards/read state/app flags
  - eligible active trips reveal one postcard only once
  - persisted destination ids rehydrate from the latest manifest catalog
  - runtime postcard generation uses destination copy templates
  - manifest destination copy fields decode
  - visual-only animal visitor rotation is stable and skips the unknown placeholder when dog/rabbit are available
- `CabinViewModelTests` covers:
  - `readPermissionRequested` Health refresh does not hide the step-read result after tapping the cabin gift button
  - Health connection immediately reads today's steps and surfaces the read value

## Known Follow-ups

- Add real device HealthKit validation because simulator step data is limited.
- Real-device HealthKit validation matrix is tracked in `MVP_PAGE_CHECKLIST.md`.
- Latest real-device package is installed under `com.qianyu.TripPet`; manual launch/testing is needed when `devicectl` reports the device as locked.
- Notification subpage currently records local toggle UI only; system notifications are not scheduled yet.
- New partner unlock/click/postcard behavior remains a future rule task; MVP visitor behavior is visual-only and does not persist discovery state.
