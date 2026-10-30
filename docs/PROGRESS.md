# Progress

Status per feature: `not started` / `in progress` / `done` / `tested`.

Populated from the Phase 3 TODOs.

| Feature | Status | Notes |
|---|---|---|
| Slice 1: Design Tokens & Typography | done | Washi/Sumi semantic colors, Shippori Mincho & Zen Kaku Gothic New font styling, layout constants, Apple HIG targets. |
| Slice 2: Content Dataset & Bundled JSON Store | done | `KanjiContentStore` loading offline bundled JSON dataset (`kanji-index.json` and per-kanji records) and error handling. |
| Slice 3: SwiftData Learner Store | done | `LearnerStore` `@ModelActor` writes, queries, `DailyAssignmentSnapshot` actor projections, custom pool mutations. |
| Slice 4: DayProvider & Daily Kanji Rollover | done | `DailyKanjiService`, lazy idempotent rollover, missed-day state handling, deterministic daily selection, level-complete state. |
| Slice 5: Japanese Pronunciation Audio | done | `PronunciationService` `@MainActor`, `AVSpeechSynthesizer` with `ja-JP`, kana-to-speech fallback, missing voice handling. |
| Slice 6: Core Design System Components | tested | `HeaderBar` (`漢字 \| English`), Reduce Motion-aware vermilion `PrimaryButton`, continuous `KanjiCard`, and SwiftUI `SealStamp`. |
| Slice 7: Today Tab & Detail Flow | tested | Shared App Group SwiftData container, service injection, real Today assignment/content/audio flow, learned and level-complete states, retry path, romaji gating, and stroke-order grid. |
| Slice 8: Settings Sheet & Preferences | done | Appearance picker (System/Light/Dark mini phone cards), level & order selectors, custom kanji pool picker, Today reassignment on pool change, romaji & streak freeze toggles, reminder settings with inline permission warning, widget guide & privacy sub-screens. |
| Slice 9: Onboarding Flow (7 Screens) | done | `OnboardingFlow` model, 7-step sequence with progress bar and back navigation, interactive flashcard demo, store-backed level rows, reminder permission request, widget mock, completion crossfade, and replay that reassigns today on level change. |
| Slice 10: Reminder Scheduler & Notifications | done | `ReminderPlanBuilder` and `SystemReminderScheduler` keep a 7-day rolling window (specific next copy + generic remaining), rebuilt on settings, level, onboarding, launch, time-zone and Got it. Not yet built or run. |
| Slice 11: WidgetKit Extension | done | `systemSmall` and `systemMedium` widgets with a midnight timeline, interactive Got it AppIntent, `WidgetRefresher` reloads on level change, onboarding completion, time-zone change and Today Got it, shared Add Widget copy. Not yet built or run. |
