# The Last Key — project memory

iOS app called **The Last Key** — helps the user memorise English sentences/expressions (with Korean meanings) as a 2–3 minute morning ritual. Frontend-only, SwiftUI + SwiftData, iOS 17+, no backend, no cloud, no analytics.

## Current state (as of 2026-04-25)

Xcode project exists at `TheLastKey/TheLastKey.xcodeproj`, **Xcode 16 format with `PBXFileSystemSynchronizedRootGroup`** — meaning any `.swift` file dropped into `TheLastKey/TheLastKey/` (app) or `TheLastKey/TheLastKeyTests/` (tests) is automatically a member of the corresponding target. No drag-into-navigator step needed when adding new files. Build settings (deployment target, display name) still require explicit edits to `project.pbxproj`. Display name is "The Last Key"; deployment target is iOS 17.0 on all targets. UI test target `TheLastKeyUITests` exists from the template but contains only Apple's stubs — leave it alone for now.

`xcodebuild` works headlessly: build with `xcodebuild -project TheLastKey/TheLastKey.xcodeproj -scheme TheLastKey -destination 'platform=iOS Simulator,name=iPhone 17' build`; tests with `... -only-testing:TheLastKeyTests test`. The newest available simulator on this machine is iPhone 17 (iOS 26.4.1) — `iPhone 16` is NOT installed.

As of commit `243662f`: BUILD SUCCEEDED and all 8 `ClozeFormatterTests` pass on iPhone 17 / iOS 26.4.1. The morning-ritual UX (reveal animation, TTS, Got it / Review again, cross-day session ordering) has NOT been smoke-tested in the simulator yet — that's the only remaining verification step.

**TTS-on-simulator gotcha:** if `▶ Listen` plays nothing on the iOS Simulator, check (a) Mac system volume isn't muted, (b) Simulator menu → **Device → Audio Output** is set to a real output (not "None"). This trips people up because the silence looks like a TTS bug.

Hosted on GitHub at **[Sung-13/the-last-key](https://github.com/Sung-13/the-last-key)** (default branch `main`). Initial commit `986e74b` was authored as `Sungkyung Kim <sungkyungkim@Sungkyungs-Mac-mini.local>` because no global git identity was configured at init time. Identity has since been set to `Sung Kim <207924699+Sung-13@users.noreply.github.com>` so future commits link properly to the GitHub profile.

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
- **Source tree:** App sources at `TheLastKey/TheLastKey/`, tests at `TheLastKey/TheLastKeyTests/`. `find . -name '*.swift'` lists all 15 files. `TheLastKey/TheLastKey/PreviewSamples.swift` is a `#if DEBUG`-wrapped helper providing a seeded in-memory `ModelContainer` for SwiftUI `#Preview` blocks; do not ship it in release builds (it's already gated). `TheLastKey/TheLastKey/Services/InitialSeed.swift` provides the production first-launch seed (7 starter entries) used by `ContentView.seedIfNeeded()`, gated by `@AppStorage("didSeedInitialEntries")` AND an empty-library check so deleting seeded entries does not re-seed.
- **xcodeproj editing:** Use the `xcodeproj` Ruby gem (already installed at `~/.gem/ruby/2.6.0/`) for any future programmatic `.pbxproj` changes. Synchronized groups mean file additions don't need pbxproj edits, but build settings, target additions, and capabilities do.

## Next steps remaining

1. **Manual smoke test in the iOS Simulator** (plan's Verification section). Build/test pass headlessly via `xcodebuild`, but the morning-ritual UX (cued cards, reveal, TTS, Got it / Review again, session picker ordering across days) still needs human eyes. First-launch seed inserts 7 starter entries automatically.
2. Optional polish: app icon.
