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
| Slice 7: Today Tab & Detail Flow | not started | 260pt hero, readings, details card, example words card, stroke order card, "Got it" action, learned state transition, inline retry state. |
| Slice 8: Settings Sheet & Preferences | not started | Appearance picker (System/Light/Dark), level & order selectors, romaji toggle, streak freeze, inline notification warning. |
| Slice 9: Onboarding Flow (7 Screens) | not started | 7-step sequence (Welcome, Daily Intro, Flashcard Demo, Level Select, Reminder, Widget Intro, Ready), completion flag. |
| Slice 10: Reminder Scheduler & Notifications | not started | `ReminderScheduler`, 7-day rolling window (specific next copy + generic remaining), authorization checks, time-zone rebuild triggers. |
| Slice 11: WidgetKit Extension | not started | `systemSmall` and `systemMedium` widgets, timeline provider using `DailyKanjiService`, interactive "Got it" AppIntent. |
