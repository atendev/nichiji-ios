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

Branch `t3/add-jinmeiyo-hyogai-levels`, SHA = the commit that adds this section. No Swift edited yet. Audit round 0. Read-only research used 155k context. The bundle is 6,407 kanji (2,136 Jōyō, 806 Jinmeiyō, 3,465 Hyōgai), 32 Jinmeiyō have no SVG, the 086 report is stale on counts.

**Design (decided):**
- Add `case jinmeiyo, hyogai` to `JLPTLevel` and `JoyoGrade` (`Nichiji/Models/KanjiContent.swift`). `isListStep`, `includes(_ kanji: some LevelMember)`: n-levels and grades match `jlptLevel`/`joyoGrade`, `.jinmeiyo` matches classification (JLPT ladder also needs `jlptLevel == nil`), `.hyogai` matches classification. `LevelMember` protocol on `KanjiEntry` and `KanjiIndexEntry`.
- `LearnerPreferences.swift`: `codeLabel` 名/外, `displayName` "Name kanji"/"Beyond the lists", `groupTitle`, `shortLabel`, settingsSummary, scheme notes. Update the exhaustive switches.
- Use `includes` in `AutoKnownLevels`, `StudyLog` (`StudyLevel.contains/title`, `LevelSequence.next`), `KanjiContentStore` (entries/count, plus the `TestKanjiContentStore` double, which must pass `classification` to the index), `KanjiBrowseGrouping` (drop "Other kanji" and "name-kanji"), `StatsCalculator+Progress.levelGroups`, `YouCopy.levelRow`, `KnownKanjiPickerModel` (`levelLabel`, scope).
- `CustomKanjiPickerView`: build sections from the index via `KanjiBrowseGrouping`, not `entries(for:)`, so Hyōgai does not decode 3,465 records.
- `DefaultDailyKanjiService`: pick from index entries (small `PoolCandidate` protocol); decode only the first record in `refreshAssignment…` (`reassignToday` reads `pool.first` only). This keeps the widget load-on-demand shape.
- `DetailsCardView`: add a "List" row (Jōyō/Jinmeiyō/Hyōgai) and keep JLPT/Grade rows hidden when nil. `StrokeOrderCardView`: "No stroke order for this kanji" and hide Practice when paths are empty. `PracticeSheet`: message instead of the pad. `DrawSearchSheet`: caption that drawing cannot find kanji with no stroke order.
- Sources: `SourcesCopy.levelFooter(for:)` on both ladders (show `SourcesFooterLink` for both); show the "The bundle holds …" line from `DATA-SOURCES.md` on the screen.
- New test: build the search index from the real bundle, print build time and resident memory growth, loose ceiling. Write a widget memory device check into the resolution.

**To fix in tests:** AutoKnownLevelsTests, DictionaryBrowseTests, KnownKanjiPickerTests, YouTabTests, StatsProgressTests, KanjiContentStoreTests, OnboardingFlowTests, SettingsPreferencesTests, SourcesTests, KanjiDetailTests, DatasetContractTests (add the exactly-one-rung check for both ladders).

**Left, in order:** code, tests, CHANGELOG and version note, docs (`CONTEXT.md`, `docs/PROGRESS.md`), report, council audit, commit, push, resolution.
