# Hearth — Architecture & Implementation Plan

A private, unified lifestyle/household app for two people on separate iCloud
accounts, built with SwiftUI + SwiftData + CloudKit sharing.

"Hearth" is a placeholder name — rename freely (bundle IDs, App Group, and
CloudKit container identifier are all centralized so this is a find/replace,
see [Renaming](#renaming--things-you-must-change-before-building)).

## 1. Why the project is laid out this way

```
Hearth/
  project.yml                     # XcodeGen spec -> generates Hearth.xcodeproj
  Packages/HearthKit/              # local SPM package: models, persistence, services
  App/Hearth/                      # main app target (SwiftUI)
  ShareExtension/HearthDropZone/   # "Drop Zone" share extension target
  WidgetExtension/HearthWidgets/   # WidgetKit extension target
  docs/ARCHITECTURE.md             # this file
```

Three separate binaries (app, share extension, widget extension) all need to
read and write the *same* SwiftData store and the *same* CloudKit container.
Rather than hand-maintain a multi-target `.xcodeproj` (large, mostly-binary,
terrible diffs, easy to desync entitlements between targets), the project is
defined declaratively in `project.yml` and generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
cd Hearth
xcodegen generate
open Hearth.xcodeproj
```

All shared code — every `@Model`, the CloudKit sharing coordinator, and the
on-device intelligence services — lives in the local Swift package
`HearthKit`, which all three targets depend on. This is what guarantees the
share extension and widget extension see the exact same schema as the app;
there is no copy-pasted model code to drift.

## 2. Core architecture decisions

### 2.1 One shared root: `Household`

CloudKit sharing (`CKShare`) shares a *record graph reachable from one root
record*, not individual records one at a time. So the data model has exactly
one root type, `Household`, and every other top-level type (`HouseholdMember`,
`Category`, `TaskItem`, `CapturedItem`, `Board`, `Trip`, `LocationReminder`)
holds a direct optional relationship back to it.

Practical effect: **you share once.** From Settings, tap "Share with Saral,"
send her the CloudKit invite (Messages/Mail/link, via the standard
`UICloudSharingController` sheet), she accepts it once, and every task,
board, and trip either of you creates from then on is already inside the
shared zone because it's attached to the same `Household`.

This is the answer to "how do two separate iCloud accounts sync the same
data" — plain SwiftData + CloudKit only syncs a *private* database between
devices signed into the *same* iCloud account. Two different accounts need
`CKShare`, which is why `HearthKit/Persistence/CloudSharingCoordinator.swift`
exists as its own piece of the architecture rather than being folded into
"just turn on CloudKit."

### 2.2 CloudKit's SwiftData constraints, and how the models satisfy them

CloudKit-backed `ModelConfiguration`s impose three rules the models are
written against from the start:

1. **No `@Attribute(.unique)`.** CloudKit has no server-side uniqueness
   constraint, so SwiftData disallows it entirely on a CloudKit-synced store.
   Every model uses a plain `UUID` `id` property for logical identity
   instead, generated locally and never enforced-unique at the persistence
   layer. (If you ever need "exactly one of these," check for one in code —
   e.g. `Settings`-style singletons aren't a good CloudKit fit, see §2.4.)
2. **All relationships are optional**, both to-one (`var assignee:
   HouseholdMember?`) and to-many (`var tasks: [TaskItem]?`). CloudKit
   records can't guarantee a related record has already synced down, so
   SwiftData requires every relationship to tolerate "not here yet" as `nil`
   / empty rather than crash.
3. **Every non-optional attribute has a default value** (`var title: String
   = ""`, `var isCompleted: Bool = false`, `var createdAt: Date = .now`,
   etc.), because CloudKit record fields are optional at the wire level and
   SwiftData needs something to hydrate a property with while a record is
   partially downloaded.

### 2.3 "Me" vs "Saral" is computed, not stored

`HouseholdMember` does **not** have an `isCurrentUser: Bool` field. A synced
boolean like that would say `true` on both of your devices for whichever
member record it was set on — CloudKit doesn't know or care which device is
looking at the data. Instead:

- `HouseholdMember.cloudKitUserRecordName` stores the CloudKit participant
  identity (`CKRecord.ID.recordName`) for that person, captured when the
  share is created/accepted.
- `CurrentMemberResolver` (app target) calls `CKContainer.userRecordID()` for
  *this* device's signed-in account and matches it against the roster at
  read time.
- The to-do swipe/assignment logic (`TaskItem.cycleAssignment`) takes
  `currentMember`/`partner` as parameters rather than baking in an
  assumption — so the exact same code shows "Me" correctly on both of your
  phones.

### 2.4 What stays out of SwiftData

Not everything belongs in the shared, synced store:

- **Per-device preferences** (notification toggles, "which member am I,"
  last-viewed tab) belong in `UserDefaults`/`@AppStorage` in the app target,
  not a SwiftData model — they're meaningless to sync and a bad fit for the
  no-unique-constraint, eventually-consistent CloudKit store.
- **Large binary content** (dropped photos, board images) use
  `@Attribute(.externalStorage)` on `Data?` properties (`CapturedItem.imageData`,
  `Board.coverImageData`, `BoardItem.imageData`). SwiftData spills these to
  CloudKit as `CKAsset`s automatically instead of bloating the record.

## 3. Data model reference

| Model              | Root relationship | Notable relationships                              |
|---------------------|--------------------|-----------------------------------------------------|
| `Household`          | —                  | cascades to everything below                        |
| `HouseholdMember`     | `household`        | `assignedTasks`, `capturedItems`, `createdBoards`, `trips` |
| `Category`            | `household`        | `tasks`, `capturedItems`, `boards`                   |
| `TaskItem`            | `household`        | `assignee`, `category`, `locationReminder`           |
| `CapturedItem`        | `household`        | `addedBy`, `category`, `convertedToTask`             |
| `Board`               | `household`        | `category`, `createdBy`, `items` (`BoardItem`, cascade) |
| `BoardItem`           | via `board`        | `board`, `addedBy`                                   |
| `Trip`                | `household`        | `traveler`, `segments` (`ItinerarySegment`, cascade)  |
| `ItinerarySegment`    | via `trip`         | `trip`                                               |
| `LocationReminder`    | `household`        | `tasks` (many)                                       |

Full source: `Packages/HearthKit/Sources/HearthKit/Models/`.

## 4. Step-by-step build order

Each phase is meant to be independently shippable-to-TestFlight so you two
are actually using the app throughout, not just at the end.

### Phase 0 — Project scaffolding (you are here)
- [x] `HearthKit` package with all models, `HearthSchema`, `CloudSharingCoordinator`.
- [x] `project.yml` describing the app / share extension / widget extension targets.
- [ ] Create the real bundle IDs, App Group, and CloudKit container in your
      Apple Developer account (see §6) and update `HearthIdentifiers` +
      `project.yml` to match.
- [ ] `xcodegen generate`, confirm the app builds and runs on both of your devices.

### Phase 1 — Core data layer & sharing
- Wire `HearthApp` to create the `Household` on first launch.
- Build the Settings "Share with Saral" flow end-to-end using
  `CloudSharingCoordinator` + `CloudSharingView` (already scaffolded).
- Implement share-acceptance: `UIApplicationDelegate
  .window(_:userDidAcceptCloudKitShareWith:)` calling
  `CloudSharingCoordinator.acceptShare`, plus a first-run "Join Household"
  screen for whoever receives the invite.
- Verify sync manually: create a task on device A, confirm it appears on
  device B within a few seconds (CloudKit push-triggered sync, not polling).

### Phase 2 — To-Do List & frictionless assignment
- `TaskListView` + `TaskRowView` + `QuickAddTaskView` are scaffolded with the
  swipe-to-cycle-assignment gesture and the My Tasks / Shared-Unassigned /
  Completed Log segmented filter.
- Remaining: due-date sorting/grouping, priority indicator, swipe-to-delete,
  category picker in quick add.

### Phase 3 — Drop Zone (share extension)
- `HearthDropZone` target scaffolded: `ShareViewController` +
  `ShareExtensionProcessor` extracts URLs/images/text/files from the share
  sheet's `NSItemProvider`s straight into a `CapturedItem` in the shared
  App Group store.
- Remaining: richer preview in the share sheet UI (thumbnail, page title via
  `NSExtensionItem.attributedContentText`), handling large multi-item shares
  (e.g. 10 photos from Photos.app) with a progress state.

### Phase 4 — Smart categorization (Foundation Models / Apple Intelligence)
- `CategorizationService` scaffolded against the `FoundationModels`
  framework (`LanguageModelSession`, `@Generable` structured output),
  guarded by `SystemLanguageModel.default.availability` with a
  `NoOpCategorizationService` fallback for devices/OS versions without Apple
  Intelligence.
- Wire it in: run categorization the moment `ShareExtensionProcessor` saves a
  `CapturedItem` (or lazily when the Inbox tab appears), populate
  `suggestedCategoryName`/`suggestedCategoryConfidence`, and surface a
  one-tap "File under {category}" action in `InboxView`.
- Requires: Apple Intelligence-capable hardware (iPhone 15 Pro or later /
  recent iPad with M-series or A17 Pro+) and iOS 26+ for the on-device model;
  test the fallback path explicitly since not every device you own may
  qualify.

### Phase 5 — Smart visual boards (Vision)
- `Board`/`BoardItem` models done; `VisionExtractionService` scaffolded
  around `VNRecognizeTextRequest` plus a regex pass for dimension/measurement
  strings.
- Build: the pin/canvas UI (`BoardsView` currently just lists boards in a
  grid — add a detail view with a freeform or grid canvas for `BoardItem`s),
  a "review extracted text" confirmation step (OCR is not always right —
  don't silently trust `extractedDimensions`), and photo picker integration
  (`PhotosPicker`) for adding items directly rather than only via Drop Zone.

### Phase 6 — Global View travel hub
- `Trip`/`ItinerarySegment` models and a first-pass `TravelHubView` (active
  trip detection, time zone slider, itinerary list) are scaffolded.
- Build: trip creation/editing UI, multiple concurrent trips (currently only
  the single "active" trip is surfaced), calendar/email itinerary import if
  you want less manual entry, push notification when a segment is starting soon.

### Phase 7 — Location-triggered reminders
- `LocationReminder` model + `LocationMonitorService` (CoreLocation region
  monitoring, up to 20 concurrent geofences) scaffolded.
- Build: UI to create a reminder from a map pin or from an existing task
  ("remind me at the hardware store"), request "Always" location
  authorization with a clear explanation screen (App Store review scrutinizes
  this), wire geofence entry -> `UNUserNotificationCenter` high-priority
  local notification listing that reminder's tasks, and background modes
  (`location` background mode + `UIBackgroundModes` in Info.plist —
  already stubbed as a location usage string in `project.yml`, add the
  background mode capability alongside it).

### Phase 8 — Interactive widgets & StandBy
- `HearthWidgets` extension scaffolded with two widgets:
  - `TaskChecklistWidget` (`.systemSmall`/`.systemMedium`) — interactive
    checkbox via `Button(intent:)` + `ToggleTaskCompletionIntent`
    (`AppIntents`), no app launch required.
  - `TomorrowAgendaWidget` (`.accessoryRectangular`/`.accessoryCircular`) —
    this *is* the StandBy view. StandBy isn't a distinct API surface; it's
    iOS presenting your Lock-Screen-style widget families full-screen while
    charging in landscape. Supporting those families well is the whole
    implementation.
- Build: call `WidgetCenter.shared.reloadTimelines(ofKind:)` after any task
  mutation in the main app (and from `ToggleTaskCompletionIntent` itself) so
  widgets don't wait out their timeline refresh window; consider a
  `Live Activity` for an in-progress trip's next segment as a StandBy
  enhancement once the core widgets are solid.

### Phase 9 — Polish
- Design system pass (see §5) across every screen — most views already use
  `glassSurface`/`HearthBackground`; make sure new screens do too.
- Accessibility: Dynamic Type audit, VoiceOver labels on swipe actions
  (SwiftUI's `.swipeActions` needs explicit `accessibilityLabel`s — icon-only
  buttons don't announce well by default), reduced-motion fallback for any
  custom animation.
- Distribution: this is a 2-person app, so a full App Store listing is
  unnecessary — use **TestFlight internal testing** (no review required for
  internal testers) or ad-hoc/Xcode direct installs. Either way you need a
  paid Apple Developer Program membership for CloudKit containers, App
  Groups, and push entitlements — the free tier doesn't grant these.

## 5. Design system notes

- **Materials, not flat fills.** `GlassSurface` (`.ultraThinMaterial` +
  hairline stroke) is the one primitive; resist introducing a second
  "card style" — consistency is most of what reads as "minimal."
- **Backgrounds carry the color.** Content surfaces stay translucent/neutral;
  color lives in the gradient wash (`HearthBackground`) and in small accents
  (member badges, category tags, SF Symbols) so panels don't compete with
  content.
- **SF Symbols everywhere**, never custom icon assets, for consistency and
  free Dynamic Type/weight scaling.
- **Corner radii**: 20pt for full-screen cards, 14–16pt for list rows, to
  read as one visual language rather than arbitrary per-view choices.
- Respect **Dark Mode** and **Increase Contrast** automatically by sticking
  to system materials/colors instead of hardcoded hex values outside of
  per-member accent colors.

## 6. Renaming — things you must change before building

Search for these and replace before you `xcodegen generate`:

| Placeholder                          | Where |
|---------------------------------------|-------|
| `com.yourteam.hearth` (and `.dropzone`/`.widgets`) | `project.yml` bundle IDs |
| `group.com.yourteam.hearth`           | `HearthIdentifiers.appGroup`, `project.yml` entitlements |
| `iCloud.com.yourteam.hearth`          | `HearthIdentifiers.cloudKitContainer`, `project.yml` entitlements |
| `Hearth` (product/target names)       | Optional — rename the whole scaffold if you want a different app name |

Also create the matching **App Group** and **iCloud Container** under your
Apple ID in Xcode's Signing & Capabilities (or developer.apple.com ->
Certificates, Identifiers & Profiles) before the CloudKit-backed
`ModelContainer` will initialize successfully — `HearthSchema.makeContainer()`
will `fatalError` with a clear message if the App Group isn't provisioned yet.

## 7. Open decisions for you two

1. **App name** — "Hearth" is a placeholder.
2. **Minimum iOS version** — scaffolded at iOS 18 so the core app (tasks,
   sharing, boards, travel, widgets) works on both your devices today;
   Foundation Models categorization additionally requires an Apple
   Intelligence-eligible device on iOS 26+, guarded by a fallback.
3. **CloudKit environment** — start in the Development CloudKit environment
   (default) and only promote the schema to Production once both of you have
   used it for a while; Production schema changes are far more restrictive.
4. **Notification style for location reminders** — decide whether entering a
   store radius should be a normal notification or something louder
   (critical alert requires a special entitlement Apple grants sparingly and
   is usually overkill for a shopping-list reminder).
