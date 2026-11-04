# Changelog

All notable changes, ordered newest-first. Every commit gets a version bump.

---

## v0.19.0

- Add the Sources screen: Settings > About gets a Sources row below Privacy, and the Level screen's JLPT footer opens the same screen. It shows the note that the JLPT has published no official kanji lists since 2010, one card per attribution with a 44 pt link row for each source and licence, and the snapshot dates, all read from the bundled `DATA-SOURCES.md`
- `DATA-SOURCES.md` ships in the app and the widget. The generator now writes markdown links for every source and licence, links Waller's CC BY to the tanos sharing page because it states no version, names Waller's vocabulary lists, counts the OpenJLPT-estimated kanji from the built records and adds a Snapshots section with ISO dates
- Close ticket 052

## v0.18.0

- Add the You tab: a "LEARNING SINCE" caption, six stat tiles (day streak, longest streak, kanji learned, reviews done, got-it rate, days studied), the streak freeze row (ready or used this week, hidden when the setting is off), the 12-week activity grid, By level bars for the active level system, the seven milestones with a seal or a lock and progress bar, and Needs attention
- Add Your kanji: a Learned grid and a lazily loaded History list by day, both opening the shared `KanjiDetailView`, and an "Export history" `ShareLink` that shares the CSV from a temp file once it is ready
- The level-complete screen shows "<level> complete", kanji learned, days taken and got-it rate, with "Start <next level>" switching the study pool in one tap and "Open Settings" beside it. Custom pools keep the old copy
- The Review header shows "N DAY STREAK", and the This week dots read "studied" to VoiceOver
- Add `SecondaryButton` and `SecondaryButtonStyle`, `HeaderCaption`, `StudyLevel.title` and `LevelSequence.preferences(starting:from:)`
- Close ticket 049

## v0.17.0

- Add the stats service: `StatsService` and a pure `StatsCalculator` compute every You tab number from the study log and progress. That covers the day streak and longest streak with the streak freeze (one forgiven miss per locale week, recomputed, never stored), the freeze row, kanji learned, reviews done, got-it rate, days studied, learning since, the 12-week activity grid, By level bars, the seven milestones, Needs attention and the learned list
- Add history grouped by day, the history CSV export (`nichiji-history-YYYY-MM-DD.csv`, UTF-8 with a BOM), level-complete figures and `LevelSequence` for the "Start <next level>" button
- `LearnerStore` gains `studyLog()` and `allProgress()`. Older rows with an empty day count under their timestamp's day through `StudyLogRecord.day(using:)`
- The Review tab's This week dots now mark study days (learned or reviewed) through the shared `StudyDay` rule
- The level milestone follows the level system with a Custom pool too, so a Custom Jōyō pool reads "Finish Grade 1"
- Close ticket 048

## v0.16.0

- Add the lock-screen widgets: `accessoryCircular` (kanji glyph, small check once learned), `accessoryRectangular` (kanji, meaning, featured word and kana, "Learned" row) and `accessoryInline` (`学 study, learning`). They join the existing widget, so they share its midnight timeline and `WidgetRefresher` reloads. The kanji is `widgetAccentable`; the rest is vibrant monochrome
- Every state is covered: assigned, learned, level complete and before onboarding. Taps are read-only and open Today through `nichiji://today`
- Replace the Settings widget guide's lock-screen placeholder with previews of the three families and a lock-screen step list
- Close ticket 051

## v0.15.0

- Add Dictionary search: a search bar above the browse grid reads the query by script (kanji, then kana, then Latin as romaji plus English), folds both sides with one `SearchFolding`, and ranks Kanji and Words by tier, field, frequency and the new JMdict `rank`. It runs about 150 ms after the last keystroke, off the main actor, over an in-memory `DictionarySearchIndex` built once on first Dictionary open ("Preparing search…" while it builds)
- Add the "Which kanji?" sheet for word rows with two or more distinct kanji; a word with one kanji opens its detail directly, and a word with none is not tappable
- Generator: add `rank` to each `words.json` record and the app-only `kanji-search.json` (full readings, romaji and meanings per kanji); the app set is now 8.14 MB of its 8 MiB budget, and `project.yml` bundles the new file
- Draw to search stays out of v1.0, so the Dictionary has no draw button
- Close ticket 046

## v0.14.0

- Replace the Dictionary placeholder with a browse grid of all 2,383 kanji, grouped by the active level system (N5 to N1, or grade 1 to Secondary plus a "Name kanji" group for the 247 jinmeiyō kanji). It is built from the index through `KanjiContentStore.indexEntries()` and `KanjiBrowseGrouping`, so no records are decoded
- Add the shared `KanjiDetailView`, pushed from a Dictionary tile: hero, Details, Example words, Stroke order and "Practice this kanji"
- Add Forget it on kanji detail and Today: a quiet control for kanji past `new` that confirms, then calls `ServiceContainer.forgetIt`, which resets through `ReviewService` and rebuilds reminders
- Share `KanjiGridTile` between the Dictionary grid and the custom kanji picker, and the Grade label between Today and detail
- Close ticket 045

## v0.13.3

- Fix the empty stroke order grid: a new `StrokePathParser` reads compact KanjiVG path data (packed commands and minus signs, `S`/`s` smooth curves), and each cell draws the whole kanji faintly, earlier strokes muted and the current stroke in ink, with the number inside the cell as in the mockup

## v0.13.2

- Make CI manual only: drop the push-to-`main` and version-tag triggers, keeping `workflow_dispatch`, and update `docs/workflow.md` and the README IPA note

## v0.13.1

- Set the Dictionary search rules: the query's script picks the mode, romaji folds on both sides, exact/prefix/substring tiers with English at word starts only, Kanji and Words sections ranked by tier, field and frequency, a "Which kanji?" sheet for word rows, and an in-memory index built on first Dictionary open from `words.json` and a new app-only `kanji-search.json`
- Add a Dictionary search paragraph to `DESIGN.md`; point ticket 046 at the decision, including the generator change
- Close ticket 044

## v0.13.0

- Add the Review tab: the due count with up to six due kanji tiles and an "About N minutes" estimate, Start review, a Session options link to Review settings, Your kanji stage counts with a stage bar, Coming up (tomorrow, in 2 to 3 days, next week) and This week review dots
- Add the full-screen review session: tap to flip, swipe or buttons after flipping, card types rotating through the enabled types, the example word, a speaker that plays the reading, autoplay on flip, "Practice this kanji" on the answer side, a settings button, forgotten cards repeated once at the end, and a "Review complete" summary. Finishing or closing after an answer rebuilds reminders
- Move the flashcard flip, tilt, swipe, badges and answer buttons into a shared `SwipeFlashcard`, which the onboarding demo now uses too
- Add `ReviewDeck`, `ReviewHomeSummary` and `ReviewSessionModel` with their tests; close ticket 043

## v0.12.1

- Remove the live `AVSpeechPronunciationService` unit test: CI's simulator has a broken voice database, so the voice lookup stalled for 94 to 257 seconds before passing. The mocked pronunciation tests still cover the service contract

## v0.12.0

- Add the Practice sheet: "Practice this kanji" on Today opens a bottom sheet (70% and large detents) with a tracing pad, a faint guide kanji behind a Guide toggle, Undo, Clear, a "N strokes drawn · M in the kanji" counter and the stroke order grid; dismiss by drag, tapping outside or Done
- Add `PracticePad` (unit-coordinate stroke recorder) and `PracticeTarget`, plus the shared `practiceSheet(target:)` presenter that the review session and kanji detail will reuse
- Make `StrokeOrderCardView.onPractice` optional: nil hides the button, and the button is now enabled when set
- Add `Font.kanjiGuide(size:)` and `PracticeSheetTests`; close ticket 042

## v0.11.0

- Load the generated dataset: `BundledKanjiContentStore` reads `kanji-index.json` once, decodes `kanji/<hex>.json` on demand with caching and reads `stroke-order/<hex>.svg` lazily in the app; a missing record or SVG throws `contentMissing`, and Today shows a "stroke diagram is unavailable" line instead of failing
- Add `count(for:)` to `KanjiContentStore` so onboarding and the Level screen count from the index; drop the hardcoded grade-count fallback
- Drop `KanjiEntry.strokePaths` and the `ExampleWord` `max*` fields; move `SeedKanjiDataset` into `NichijiTests`
- Show "N1 (est.)" in the Details row for estimated levels and add the Level footer "JLPT levels are unofficial community lists."
- Wire `Dataset/` into `project.yml` (index and records in the app and widget, SVGs and `words.json` in the app only) and remove the three "from memory" caveats from `design-notes.md`; close ticket 038

## v0.10.0

- Add the dataset generator in `tools/dataset/`: `make dataset-fetch` downloads pinned KANJIDIC2, JMdict, KanjiVG and N-level inputs into untracked `.cache/` and writes `sources.lock.json`; `make dataset` builds the committed `Dataset/` bundle offline and deterministically
- Commit the first bundle: 2,383 kanji records, the index, minified stroke-order SVGs, an app-only `words.json` and a generated `DATA-SOURCES.md`; budgets are checked at 2.2 MB shared and 7.0 MB for the app
- Add `KanjiEntry.isJLPTLevelEstimated`, `KanjiIndexEntry.frequencyRank` and the `KanjiIndex` wrapper, plus `DatasetContractTests` that decode the bundle and assert the grade and N-level counts
- Add `make dataset-test` to CI; close ticket 037

## v0.9.3

- Register the `nichiji` URL scheme: the Nichiji target gains an `info:` block (`Config/Nichiji-Info.plist`) with `CFBundleURLTypes`, so Safari and Shortcuts can open `nichiji://today` on Today through the existing `onOpenURL` (device check still due)
- Add `AppDeepLinkTests.bundleRegistersScheme`; close ticket 053

## v0.9.2

- Fix the UI launch smoke test: `testLaunchShowsPrimaryAction` waits up to 15 s for the shared `primaryButton` or Today's "Learned today" seal, replacing the stale `"title"` wait
- Add `NichijiUITests` to the `Nichiji` scheme so `make test` and CI run it; close ticket 056

## v0.9.1

- Doc: automate the Phase 5 ticket flow with a Haiku audit of the Requirements Report, a subagent grilling run with a click-to-approve answer check, and a one-click merge question that merges and deletes the branch

## v0.9.0 — ✅ Released
---

- Add the Review settings screen: a Settings row summarizing cards per session and order opens `ReviewSettingsView` with card types, order, session size, example word, repeat forgotten, and audio settings, saved to shared `UserDefaults` on every change
- Add display copy, chip labels and `settingsSummary` to the review preference types; share the settings section header, divider and toggle row helpers
- Extend `SettingsPreferencesTests` for the review settings round trip, the last-card-type rule, and the saved order and size driving the due queue; close ticket 041

## v0.8.0

- Add the review engine: `ReviewService` (in `ServiceContainer`) over a pure `ReviewScheduler` with the Leitner table, a day-granular due queue ordered and capped by review preferences, first-answer-per-session verdicts, and `gotItReview` / `forgotItReview` log rows under the session day
- Add `ReviewPreferencesSnapshot` in shared `UserDefaults` with the mock defaults; the last card type cannot be turned off
- Today's and the widget's Got it schedule the first review for tomorrow through `GotItAction`; Forget it clears `nextReviewAt` and `lastReviewedAt`, keeps counts, and logs its calendar day
- Reminder window: a learned day's first reminder reads "N kanji due for review" when kanji are due that day
- Add `ReviewServiceTests` and `TestReviewService`; close ticket 040

## v0.7.2

- Set the review scheduling rules: Leitner table (learning +1d, familiar +3d, `known` graduates out of the due queue), day-granular due, first answer per session decides, Forget it lives on kanji detail and returns the kanji to the pool, review settings adopt the mock defaults in shared `UserDefaults`, and the reminder window gains review-due copy
- Update `CONTEXT.md` (Review session, Due, known graduates) and the `DESIGN.md` reminder paragraph
- Decide the lock-screen widgets: all three accessory families (circular kanji glyph, rectangular adds meaning and featured word, inline one line), read-only with taps opening Today, and a lock-screen section with previews and steps in the Settings widget guide
- Update the `DESIGN.md` widget section; point tickets 040, 041, 043 and 051 at their closed decisions
- Close tickets 039 and 050

## v0.7.1

- Fix the v1.0 feature boundary: release work (App Store metadata, privacy manifest, signing, TestFlight), per-release dataset regeneration, the `nichiji` URL scheme and the You CSV export are in; handwriting recognition, stroke-order checking, Duo/two-pane, configurable widgets, the onboarding Custom option, review cap and furigana toggle are out
- Rewrite `DESIGN.md` Non-goals to the v1.0 boundary; chart tickets 053-056 (URL scheme, release build, App Store metadata, UI launch smoke test)
- Keep the UI test target as a state-independent launch smoke test wired into the scheme and CI
- Close tickets 034 and 035

## v0.7.0

- Open the app on Today when the learner taps either widget: `AppDeepLink` builds and parses `nichiji://today`, the widgets set it with `.widgetURL`, and `MainTabView` selects Today and closes Settings in `onOpenURL`. The medium widget's Got it button keeps its AppIntent
- Add `AppDeepLinkTests`; close ticket 032

## v0.6.2

- Mark Slices 1-5 and 8-11 `tested` in `PROGRESS.md` and drop the stale "Not yet built or run" notes
- Point the `DESIGN.md` status line at v0.6.0 and the v1.0 map
- Retarget stale TODOs in `LevelCompleteView`, `MainTabView`, `SettingsSheet`, `SettingsSupportViews` and `NichijiWidgetBundle` to the v1.0 tickets that replace them; close ticket 031

## v0.6.1

- Archive the finished MVP map to `.plan/archive/` and chart the v1.0 map: 22 tickets across housekeeping, the real dataset, Review and Practice, Dictionary, You, and lock-screen widgets
- Close the JLPT list research ticket (033): Jonathan Waller's CC BY lists, pinned through OpenJLPT, labelled as an unofficial estimate

## v0.6.0 — ✅ Released
---

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
