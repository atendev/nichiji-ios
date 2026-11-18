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

Handoff 3. Branch `t3/add-jinmeiyo-hyogai-levels-3` (new branch from handoff 2), SHA = the commit that adds this section. Audit rounds used: 0 of 5. Swift not compiled (no toolchain); all code and tests re-read by eye.

**Done:** All app code (see handoff-2 list: ladders, pool on index entries, browse, stats, picker, Sources, Details List row, no-stroke-order states). Tests (commit `test: cover the Jinmeiyō...`): StatsFixtures.entry takes `classification:`; AutoKnownLevels, DictionaryBrowse, KnownKanjiPicker, YouTab, StatsProgress, KanjiContentStore, Onboarding, SettingsPreferences, Sources, KanjiDetail, PracticeSheet and DailyKanjiService tests updated or added; new `NichijiTests/Suites/DictionarySearchIndexCostTests.swift` prints `SEARCH-INDEX build: N ms, resident growth: X MB` (ceilings 10 s, 150 MB). `activePool` callers checked: none left outside DailyKanjiService and tests. Real data: JLPT ladder Jinmeiyō = 559 (no N-level), Hyōgai 3,465; Jōyō ladder Jinmeiyō = 806. Every kanji on exactly one rung per ladder.

**Left, in order:**
1. `CHANGELOG.md` (root and/or `docs/CHANGELOG.md`; check which `docs/workflow.md` names) entry and version decision (new user-visible feature: minor bump, do not tag). Update `CONTEXT.md`, `docs/PROGRESS.md`, `docs/DESIGN.md` line ~61 (Jinmeiyō and Hyōgai on both ladders, no "Other kanji"/"Name kanji" group).
2. Optional DatasetContractTests addition: exactly-one-rung per ladder over the real index (use `JLPTLevel.allCases.filter { $0.includes(e) }.count == 1`).
3. Decision report `.plan/assets/087-add-the-jinmeiyo-and-hyogai-levels-to-the-app-report.md` (unslop). Include a widget device check: widget loads the index only (about 6.4k summary rows); `assignment(for:)` uses index entries, so Hyōgai decodes one record. Measure peak memory on a simulator/device, expect well under 30 MB. Also the search-index CI-log line.
4. Council audit (`council-audit` skill), up to 5 rounds, then commit, push (no force, no PR, no CI), resolution in the ticket (remove this section, Decisions line, Surfaced list), timing close with `--slug nichiji-v1`, commit, push, return DONE.

Read first: this section, `git diff wayfinder/nichiji-v1-master...HEAD --stat`, `docs/workflow.md` changelog rules.
