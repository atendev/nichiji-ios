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

## Phase 3: TODOs

- Created view and design-system file skeletons under `Nichiji/DesignSystem/` and `Nichiji/Views/` covering Onboarding (7 screens), Today (hero, cards, quiet level complete, retry), Settings sheet (appearance, level, reminders), and the 4-tab app shell.
- Populated specific in-code TODO comments across views, design tokens, components, app lifecycle, and widget extension stubs.
- Added `NichijiWidget` target skeleton to `project.yml` with shared App Group container setup.
- Structured `docs/PROGRESS.md` with 11 ordered vertical slices mapping the roadmap to MVP release.

## Phase 4: Verification/Testing

- Standardized on Apple Swift Testing framework (`import Testing`) with in-memory SwiftData containers (`isStoredInMemoryOnly: true`) for deterministic local execution under Swift 6 strict concurrency.
- Created test doubles under `NichijiTests/TestDoubles/` (`TestDayProvider`, `TestKanjiContentStore`, `TestPronunciationService`, `TestReminderScheduler`).
- Documented testing suite architecture and invariants across 6 feature areas in `docs/IMPLEMENTATION.md` and established test suite stubs under `NichijiTests/Suites/`.

## Phase 5: Slices

### Slice 1: Design Tokens & Typography

#### Requirements Report
- **Success Criteria**:
  1. Full semantic color token palette matching `tokens.json` in Washi and Sumi modes with accessible contrast.
  2. Dynamic Type typography scale using Shippori Mincho and Zen Kaku Gothic New with system `.serif` and `.default` fallbacks, adhering to weight <= 500.
  3. Layout tokens establishing 8pt grid metrics, continuous corner radii, and a reusable `.minTouchTarget()` modifier enforcing Apple HIG 44x44 pt minimums.
  4. Swift Testing suite `DesignTokensTests` in `NichijiTests/Suites/` verifying tokens and invariants.
- **Scope Boundary**: Tokens, layout metrics, and unit tests in scope; custom view components (`HeaderBar`, `PrimaryButton`, `KanjiCard`, `SealStamp`) deferred to Slice 6.
- **Anticipated TODOs**: Resolves Slice 1 font fallback and layout modifier TODOs.
- **Planned Tests**: Verified in `DesignTokensTests`.

#### Deviation Report
- **Deviations**: None. Implemented self-contained dynamic UIKit color resolution for light/dark traits to support offline preview and test execution without asset catalogs.
- **Unanticipated TODOs**: None.
- **Test Results**: All 4 tests in `DesignTokensTests` passing (layout targets, typography instantiation, hex color parsing, dynamic trait resolution).
