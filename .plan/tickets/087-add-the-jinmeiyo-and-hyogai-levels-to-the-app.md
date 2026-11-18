---
id: "087"
title: Add the Jinmeiyō and Hyōgai levels to the app
type: task
mode: AFK
status: open
blocked_by: ["086"]
claimed: true
---

## Question

Can a learner pick Jinmeiyō or Hyōgai on either level ladder and study, browse and look up those kanji everywhere the app shows kanji?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Read [Add kanji beyond Jōyō](../closed/085-add-kanji-beyond-joyo.md) first.

- Both ladders end with Jinmeiyō ("Name kanji") then Hyōgai ("Beyond the lists"). On the JLPT ladder, Jinmeiyō holds only kanji with no N-level. On the Jōyō ladder, it holds all 806.
- Update the level pickers in onboarding and Settings (`LevelSettingsView`), the study pool, `AutoKnownLevels`, the known-kanji picker, Dictionary browse grouping, the kanji Details card, the level footers, and Stats progress.
- The Details card shows the classification, with "—" or no row where a JLPT level or Jōyō grade is missing. The JLPT "(est.)" label is unchanged.
- Kanji with no stroke file: detail, Practice and handwriting matching show a clear "No stroke order for this kanji" state, with no empty pad and no crash.
- Measure the widget's peak memory with the new index on a simulator and report it. It must stay well under about 30 MB. If it doesn't, the widget reads only the records it needs.
- Measure how long the Dictionary search index takes to build and how much memory it uses. 044 budgeted about 20 MB.
- Update the Sources screen totals.

## Resolution

## Handoff

Handoff 2. Branch `t3/add-jinmeiyo-hyogai-levels-1` (new branch from the first handoff commit), SHA = the commit that adds this section. Audit rounds used: 0 of 5. Swift not compiled (no toolchain), all code re-read by eye.

**Done (committed, no tests touched yet):**
- `KanjiContent.swift`: `.jinmeiyo`/`.hyogai` on `JLPTLevel` and `JoyoGrade`, `LevelMember`, `isListStep`, `includes(_:)`, `KanjiClassification.listLabel`. `LearnerPreferences.swift`: codeLabel 名/外, displayName, `badgeLabel`, settingsSummary, scheme notes.
- `DailyKanjiService`: `activePool` now returns `[KanjiIndexEntry]` (`PoolCandidate` protocol, generic `selectKanjiID`); `refreshAssignment…` decodes only the head record. `KanjiContentStore`, `TestKanjiContentStore` (passes `classification`), `AutoKnownLevels`, `StudyLog`, `KanjiBrowseGrouping` (no more "Other kanji"/"name-kanji"; `unleveledTitle`/`nameKanjiTitle` removed), `StatsCalculator+Progress.levelGroups`, `KnownKanjiPickerModel.levelLabel`, `CustomKanjiPickerView` (index sections, `KanjiGroupSection` removed).
- Sources: `SourcesCopy.levelFooter(for:)`, `SourcesFooterLink(system:)` on both ladders, `DataSourcesDocument.bundleSummary` shown on `SourcesView`, intro line.
- Detail: `DetailsCardView(classification:)` List row, `StrokeOrderCardView.noStrokeOrderMessage` and Practice hidden when no paths, `PracticeTarget.hasStrokeOrder`, `PracticeSheet` message, `HandwritingSearchCopy.noStrokeOrderNote` in `DrawSearchSheet`.

**Left, in order:**
1. Fix tests: AutoKnownLevelsTests, DictionaryBrowseTests (uses removed `unleveledTitle`/`nameKanjiTitle`), KnownKanjiPickerTests (`jlptGroups`/`joyoGroups` use "unleveled"/"name-kanji"), YouTabTests line ~113 ("name-kanji" bar), StatsProgressTests, KanjiContentStoreTests, OnboardingFlowTests, SettingsPreferencesTests (`activePool` is now index entries), SourcesTests (add `bundleSummary`, `levelFooter(for:)`), KanjiDetailTests, DatasetContractTests (exactly-one-rung per ladder), DailyKanjiServiceTests/KnownKanjiServiceTests (check `activePool` use), StatsFixtures. Add a Swift Testing test that builds `DictionarySearchIndex` from the real bundle and prints build time and resident memory growth, loose ceiling.
2. Check `ServiceContainer` and other callers for `activePool` return type; grep `[KanjiEntry]` users.
3. `docs/CHANGELOG.md` entry and version decision per `docs/workflow.md`; `CONTEXT.md`, `docs/PROGRESS.md`, `docs/DESIGN.md` line 61.
4. Widget memory device check written into the resolution (widget loads index only; `assignment(for:)` now uses index entries, so Hyōgai no longer decodes records).
5. Decision report `.plan/assets/087-...-report.md` (unslop), council audit, commit, push, resolution, remove this section, timing close with `--slug nichiji-v1`.

Read first: this section, `Nichiji/Models/KanjiContent.swift`, `Nichiji/Services/DailyKanjiService.swift`, then the test files above.
