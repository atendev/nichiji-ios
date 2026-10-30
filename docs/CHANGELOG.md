# Changelog

All notable changes, ordered newest-first. Every commit gets a version bump.

---

## v0.6.0

- Add the `NichijiWidget` extension with `systemSmall` and `systemMedium` daily kanji widgets, a single-entry timeline that reloads at the next local midnight, and quiet level-complete and open-app placeholders
- Add the interactive "Got it" `MarkTodaysKanjiLearnedIntent`, which marks today learned, rebuilds reminders, and reloads timelines, via a shared `GotItAction`
- Add `WidgetRefresher` and reload widget timelines after level changes, onboarding completion, time-zone changes, and Today's Got it
- Share one Add Widget step list between onboarding and Settings, render the onboarding preview from the real small widget view, and turn the lock-screen guide into a post-MVP placeholder
- Embed the widget in `project.yml` with the App Group entitlement and shared sources, add `Config/*.entitlements`, and drop the invalid principal class from the widget `Info.plist`
- Extend `WidgetTimelineTests` and `OnboardingFlowTests`; close the Slice 11 implementation ticket (030)

## v0.5.2

- Close Slice 11 requirements ticket (029) via delegated HITL grilling subagent
- Document Slice 11 success criteria, scope boundary, anticipated TODOs, and planned tests for the WidgetKit extension
- Open implementation ticket 030: `Implement Slice 11: WidgetKit Extension`
- Update `docs/PROGRESS.md` marking Slice 11 in progress

## v0.5.1

- Rewrite Phase 5 of `docs/workflow.md` as an autonomous ticket run with subagent reports, a Haiku audit, CI handling, stop conditions, and a merge-before-next-ticket rule
- Limit the user-confirmation commit rule in `AGENTS.md` and `.plan/map.md` to Phases 0-4

## v0.5.0

- Add `ReminderPlanBuilder`, a pure planner for the rolling 7-day reminder window with kanji-led, missed-day, and generic copy
- Implement `SystemReminderScheduler` scheduling and cancelling on `UNUserNotificationCenter`, adding the new window before pruning stale `nichiji.reminder.` requests
- Add `ReminderRefresher` so background rebuilds never prompt for permission
- Rebuild reminders on settings, level, order, pool, onboarding, launch, foreground, Got it, and time-zone changes
- Add planner, refresher, and trigger tests in `ReminderSchedulerTests` and `OnboardingFlowTests`
- Close Slice 10 requirements and implementation tickets (026 and 028), open the Slice 11 requirements ticket (029)

## v0.0.12

- Configure `.swiftlint.yml` rules (`todo`, `line_length`, `identifier_name`, `large_tuple`) for project conventions and Phase 3 scaffolding
- Fix `orphaned_doc_comment`, `multiple_closures_with_trailing_closure`, `implicit_optional_initialization`, `redundant_sendable`, `for_where`, and `line_length` SwiftLint violations across app and test targets

## v0.0.11

- Close Slice 5 requirements and implementation tickets (017 and 018)
- Implement `AVSpeechPronunciationService` with `AVSpeechSynthesizerDelegate` and `@MainActor` isolation
- Implement Japanese voice availability check and kana-preferred utterance synthesis
- Add unit test coverage in `PronunciationServiceTests` verifying speech playback, fallbacks, stops, and error throwing
- Update `docs/PROGRESS.md` marking Slice 5 done and log reports in `docs/IMPLOG.md`

## v0.0.10

- Close Slice 4 requirements and implementation tickets (015 and 016)
- Implement `SystemDayProvider` with date formatting and next-midnight computation
- Implement `DefaultDailyKanjiService` with lazy rollover, pool filtering, and deterministic daily selection
- Make `LearnerPreferencesSnapshot` and `DailyKanjiWidgetSnapshot` public across modules
- Add unit test coverage in `DailyKanjiServiceTests` verifying rollover, idempotency, deterministic ordering, and widget snapshots
- Update `docs/PROGRESS.md` marking Slice 4 done and log reports in `docs/IMPLOG.md`

## v0.0.9

- Close Slice 3 requirements and implementation tickets (013 and 014)
- Implement `SwiftDataLearnerStore` conforming to `LearnerStore` using `@ModelActor`
- Make `LearnerModels` public and implement `DailyAssignmentSnapshot` actor boundaries
- Implement rollover rules marking past assigned rows as missed while keeping stage new
- Add unit test suite in `LearnerStoreTests` with an in-memory `ModelContainer`
- Update `docs/PROGRESS.md` marking Slice 3 done and log reports in `docs/IMPLOG.md`

## v0.0.8

- Close Slice 2 requirements and implementation tickets (011 and 012)
- Implement `BundledKanjiContentStore` with thread-safe caching and offline `SeedKanjiDataset`
- Add `KanjiIndexEntry` summary model to `KanjiContent.swift`
- Align `TestKanjiContentStore` double with `KanjiContentStore` protocol contracts
- Add test coverage in `KanjiContentStoreTests` validating lookups, filtering, stroke paths, and typed errors
- Update `docs/PROGRESS.md` marking Slice 2 done and log reports in `docs/IMPLOG.md`

## v0.0.7

- Close Slice 1 requirements and implementation tickets (009 and 010)
- Implement Washi and Sumi dynamic semantic colors, typography tokens with fallback, and Apple HIG layout metrics
- Add `.minTouchTarget()` and `.continuousCornerRadius(_:)` modifiers
- Add `DesignTokensTests` suite verifying layout targets, font instantiation, hex color parsing, and dynamic traits
- Update `docs/PROGRESS.md` marking Slice 1 done and log reports in `docs/IMPLOG.md`

## v0.0.6

- Close Phase 4 testing suite planning and specification tickets (007 and 008)
- Document Phase 4 verification architecture and test invariants in `docs/IMPLEMENTATION.md`
- Create test doubles (`TestDayProvider`, `TestKanjiContentStore`, `TestPronunciationService`, `TestReminderScheduler`) under `NichijiTests/TestDoubles/`
- Add Swift Testing test suite stubs under `NichijiTests/Suites/` and update `docs/IMPLOG.md`
- Advance Wayfinder map to Phase 5 Slice 1 (Design Tokens & Typography)

## v0.0.5

- Close Phase 3 planning and implementation tickets (005 and 006)
- Add design system tokens and reusable UI components under `Nichiji/DesignSystem/`
- Add view skeletons and navigation coordination under `Nichiji/Views/` for Onboarding, Today, Settings, and tab shell
- Add `NichijiWidget` target stub to `project.yml` and populate in-code TODO comments
- Initialize `docs/PROGRESS.md` with 11 vertical slices for Phase 5 implementation and advance Wayfinder map to Phase 4

## v0.0.4

- Close the Phase 2 service interfaces and reminder-widget contracts tickets
- Define Phase 2 service protocols, `DailyAssignmentSnapshot`, `NichijiError`, and `ServiceContainer` stubs under `Nichiji/Services/`
- Document Phase 2 interfaces in `docs/IMPLEMENTATION.md` and update `docs/DESIGN.md`, `CONTEXT.md`, and `docs/IMPLOG.md`

## v0.0.3

- Close the verified kanji and stroke dataset research ticket

## v0.0.2

- Define Phase 1 data models for bundled kanji content, AppStorage preferences, SwiftData learner records, and navigation/widget snapshots
- Record the missed-day rollover rule returning unlearned daily kanji to the study pool with the missed-day reminder copy
- Initialize the Wayfinder `.plan/` map and close Phase 0 and Phase 1 planning tickets

## v0.0.1

- Approve Phase 0 design in `docs/DESIGN.md`
- Add workflow documentation skeletons (`docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/PROGRESS.md`, `docs/IMPLOG.md`, `docs/CHANGELOG.md`, `CONTEXT.md`)
