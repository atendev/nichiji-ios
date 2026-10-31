# Progress

Status per feature: `not started` / `in progress` / `done` / `tested`.

Populated from the Phase 3 TODOs.

| Feature | Status | Notes |
|---|---|---|
| Slice 1: Design Tokens & Typography | tested | Washi/Sumi semantic colors, Shippori Mincho & Zen Kaku Gothic New font styling, layout constants, Apple HIG targets. |
| Slice 2: Content Dataset & Bundled JSON Store | tested | `KanjiContentStore` loading offline bundled JSON dataset (`kanji-index.json` and per-kanji records) and error handling. |
| Slice 3: SwiftData Learner Store | tested | `LearnerStore` `@ModelActor` writes, queries, `DailyAssignmentSnapshot` actor projections, custom pool mutations. |
| Slice 4: DayProvider & Daily Kanji Rollover | tested | `DailyKanjiService`, lazy idempotent rollover, missed-day state handling, deterministic daily selection, level-complete state. |
| Slice 5: Japanese Pronunciation Audio | tested | `PronunciationService` `@MainActor`, `AVSpeechSynthesizer` with `ja-JP`, kana-to-speech fallback, missing voice handling. |
| Slice 6: Core Design System Components | tested | `HeaderBar` (`漢字 \| English`), Reduce Motion-aware vermilion `PrimaryButton`, continuous `KanjiCard`, and SwiftUI `SealStamp`. |
| Slice 7: Today Tab & Detail Flow | tested | Shared App Group SwiftData container, service injection, real Today assignment/content/audio flow, learned and level-complete states, retry path, romaji gating, and stroke-order grid. |
| Slice 8: Settings Sheet & Preferences | tested | Appearance picker (System/Light/Dark mini phone cards), level & order selectors, custom kanji pool picker, Today reassignment on pool change, romaji & streak freeze toggles, reminder settings with inline permission warning, widget guide & privacy sub-screens. |
| Slice 9: Onboarding Flow (7 Screens) | tested | `OnboardingFlow` model, 7-step sequence with progress bar and back navigation, interactive flashcard demo, store-backed level rows, reminder permission request, widget mock, completion crossfade, and replay that reassigns today on level change. |
| Slice 10: Reminder Scheduler & Notifications | tested | `ReminderPlanBuilder` and `SystemReminderScheduler` keep a 7-day rolling window (specific next copy + generic remaining), rebuilt on settings, level, onboarding, launch, time-zone and Got it. |
| Slice 11: WidgetKit Extension | tested | `systemSmall` and `systemMedium` widgets with a midnight timeline, interactive Got it AppIntent, `WidgetRefresher` reloads on level change, onboarding completion, time-zone change and Today Got it, shared Add Widget copy. Tapping a widget opens Today through `nichiji://today`. |
| Review engine | done | `ReviewService` over a pure Leitner `ReviewScheduler` (learning +1d, familiar +3d, `known` leaves the queue), day-granular due queue ordered and capped by `ReviewPreferencesSnapshot` in shared `UserDefaults`, first answer per session decides, Forget it clears the schedule and logs its day, Got it from Today or the widget schedules the first review, and review-due reminder copy. No UI yet. |
| Review settings | done | Settings gains a Review row (`10 cards · Due first`) that opens `ReviewSettingsView`: card types (one always stays on), order, cards per session, example word, repeat forgotten, audio autoplay and what audio plays. Every change saves to shared `UserDefaults` through `ReviewPreferencesSnapshot`. Only order and session size have a reader until the Review session ticket. |
| UI launch smoke test | done | `NichijiUITests` launches the app and waits for the shared `primaryButton` or Today's "Learned today" seal. It runs in the `Nichiji` scheme under `make test` and CI. |
| nichiji URL scheme | done | The Nichiji target registers `nichiji` through `Config/Nichiji-Info.plist`, so Safari and Shortcuts open `nichiji://today` on Today through `onOpenURL`. `AppDeepLinkTests` checks the registration; the device check is still due. |
| Dataset generator | done | `tools/dataset/` (standard-library Python) builds `Dataset/` from pinned KANJIDIC2, JMdict, KanjiVG and Waller/OpenJLPT inputs: 2,383 kanji, minified stroke-order SVGs and an app-only `words.json`. `make dataset-fetch` pins the inputs, `make dataset` is offline and deterministic. The app does not read the bundle yet. |
