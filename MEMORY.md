# The Last Key — project memory

iOS app called **The Last Key** — helps the user memorise English sentences/expressions (with Korean meanings) as a 2–3 minute morning ritual. Frontend-only, SwiftUI + SwiftData, iOS 17+, no backend, no cloud, no analytics.

## Current state (as of 2026-04-25)

Swift sources scaffolded under `TheLastKey/` and `TheLastKeyTests/`. **No Xcode `.xcodeproj` yet** — user creates the Xcode project in Xcode and links these files in.

## Confirmed product decisions (do not re-litigate)

| Area | Decision |
|---|---|
| App name | The Last Key |
| Memorisation technique | First-letter cueing + audio (iOS TTS via `AVSpeechSynthesizer`) |
| Unit of study | Full sentences (or shorter expressions) — not separate "phrase + example" |
| Daily session size | 5 cards (configurable 3–15 in Settings) |
| Session ordering | `Review again` first → unseen → least-recently-seen |
| Input | Manual entry in-app only |
| Storage | Local on-device only — SwiftData |
| Platform | iPhone, iOS 17+, SwiftUI, SwiftData, AVFoundation. Zero external dependencies. |

## Explicit out-of-scope (non-goals)

- Backend / cloud sync / iCloud
- Accounts, analytics, third-party services
- Bulk or CSV import
- Streaks, charts, gamification
- AI-generated examples or translations
- Push notifications

## Key references

- **Plan file (read first):** `/Users/sungkyungkim/.claude/plans/context-i-would-like-foamy-crab.md` — full design: data model, screens, technique, verification.
- **Source tree:** `TheLastKey/` (app) and `TheLastKeyTests/` (tests). `find . -name '*.swift'` lists all 15 files. `TheLastKey/PreviewSamples.swift` is a `#if DEBUG`-wrapped helper providing a seeded in-memory `ModelContainer` for SwiftUI `#Preview` blocks; do not ship it in release builds (it's already gated). `TheLastKey/Services/InitialSeed.swift` provides the production first-launch seed (7 starter entries) used by `ContentView.seedIfNeeded()`, gated by `@AppStorage("didSeedInitialEntries")` AND an empty-library check so deleting seeded entries does not re-seed.

## Next steps remaining

1. User creates Xcode project (`File → New → Project → iOS → App`, name `TheLastKey`, SwiftUI, Storage: SwiftData, iOS 17+).
2. Link the scaffolded files in `TheLastKey/` into the project navigator (including `PreviewSamples.swift` and `Services/InitialSeed.swift`).
3. Add a Unit Test target and include `TheLastKeyTests/ClozeFormatterTests.swift`.
4. Run the manual smoke test in the plan's Verification section. (First-launch seed inserts 7 starter entries automatically — sufficient for the SessionPicker check, but the user should still try edit/delete and add-their-own.)
5. Optional polish: app icon.
