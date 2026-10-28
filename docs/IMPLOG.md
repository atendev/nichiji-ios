# Implementation Log

Running log of phase history and slices. Each slice gets its Requirements Report and Deviation Report here.

---

## Phase 0: Design

- Approved `docs/DESIGN.md` covering the initial Onboarding + Today scope, bundled offline kanji content, SwiftData + `UserDefaults` persistence split, Washi/Sumi themes, daily reminders, initial WidgetKit support, and future iPhone Duo / iPad two-pane readiness.

## Phase 1: Data

- Defined bundled immutable kanji types (`KanjiEntry`, `KanjiReading`, `KanjiRadical`, `ExampleWord`, `JLPTLevel`, `JoyoGrade`), scalar App Group `UserDefaults` preferences (`LearnerPreferencesSnapshot`, `LearnerPreferenceKey`, `AppearanceMode`, `LevelSystem`, `DailyOrder`), SwiftData learner models (`KanjiProgress`, `DailyAssignment`, `CustomKanjiSelection`, `StudyLogEntry`), and navigation/widget state types (`AppTab`, `OnboardingStep`, `SettingsDestination`, `ReminderNotificationKind`, `DailyKanjiWidgetSnapshot`).
- Specified the missed-day rollover rule: unlearned daily assignments are marked `.missed` at day rollover while their `KanjiProgress.stage` stays `.new` so they remain in the unlearned study pool, and the next day's reminder uses `"You missed yesterday's kanji. That's okay, check it now."`

## Phase 2: Interfaces

- Defined `DayProvider`, `KanjiContentStore`, `LearnerStore`, `DailyKanjiService`, `PronunciationService`, `ReminderScheduler`, `ServiceContainer`, `DailyAssignmentSnapshot`, `ReminderAuthorizationStatus`, and `NichijiError` in `Nichiji/Services/` and `docs/IMPLEMENTATION.md`.
- Updated `docs/DESIGN.md` and `CONTEXT.md` to record lazy idempotent daily rollover, `@ModelActor` write isolation, the rolling 7-day notification window, small and medium interactive widgets, and clock/time-zone change handling.
