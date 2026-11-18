# Report. Add the Jinmeiyō and Hyōgai levels to the app

Both level ladders now end with Jinmeiyō ("Name kanji") and Hyōgai ("Beyond the lists"). A learner can pick either rung in onboarding or Settings and study, browse and look up those kanji. Swift was not compiled. This host has no Swift toolchain, so every Swift edit and test was read by eye, and the master's CI run is the first compile. Nothing was run on a simulator or device.

## Result

| Ladder | Jinmeiyō rung | Hyōgai rung |
| --- | --- | --- |
| JLPT | 559 kanji with no N-level (the other 247 are N1) | 3,465 |
| Jōyō | all 806 | 3,465 |

- The bundle holds 6,407 kanji. Every kanji sits on exactly one rung per ladder. A Python recount of `kanji-index.json` found 0 kanji with zero or two rungs on the JLPT ladder, 559 Jinmeiyō kanji with no N-level, and no Hyōgai kanji with an N-level.
- 32 Jinmeiyō kanji have no stroke SVG. Detail, Practice and handwriting matching show "No stroke order for this kanji" for them, with no empty pad.
- Version v0.36.0 in `docs/CHANGELOG.md`, a minor bump for a user-visible feature. It is not tagged. The root `CHANGELOG.md` stops at v0.4.1 and `docs/workflow.md` names the `docs/` one.
- Docs updated: `CONTEXT.md` (new "Level ladder" term, study pool), `docs/PROGRESS.md` (new row, browse row), `docs/DESIGN.md` (Dictionary browse paragraph).

## What changed in the app

- **Ladders.** `JLPTLevel` and `JoyoGrade` gain `jinmeiyo` and `hyogai` cases, with `includes(_:)` over a shared `LevelMember` protocol, so full records and index entries use one rule. Badges are 名 and 外. The Settings summary reads "Name kanji · Jinmeiyō".
- **Study pool.** `activePool` now returns `KanjiIndexEntry` values filtered from the index. It no longer decodes a record per kanji. Only the head of the ordered pool is decoded to create the assignment.
- **Pickers.** Onboarding, `LevelSettingsView`, `AutoKnownLevels`, the known-kanji picker and the custom picker read the new rungs. The custom picker is built from the index.
- **Browse and Stats.** Dictionary browse groups end with the two new rungs, and Stats progress counts them. The old "Name kanji" group for no-grade kanji and the "Other kanji" group are gone.
- **Details card.** It shows a List row with the classification. JLPT keeps its "(est.)" label.
- **Sources.** The totals and footer follow the bundle.

## Widget memory check

Not measured. There is no simulator or device here, so the figure the ticket asks for is still open and needs a device run.

What the code does, read from the diff and from `DailyKanjiTimeline.swift`.

- The widget timeline calls `dailyKanjiService.widgetSnapshot(for:)`. It does not build the pool itself.
- The pool is now index summaries. `kanji-index.json` is 948,283 bytes on disk for 6,407 rows, so the decoded index is a few MB at most.
- Creating a new assignment decodes one `KanjiEntry` (the head of the ordered pool), whatever level the learner picked. A Hyōgai learner costs one record, not 3,465.
- Before this ticket the pool decoded a full record for every kanji in the level. The index-only path is the lighter one.

Expectation is well under the 30 MB budget. If a device run shows otherwise, the widget needs a narrower read, and that becomes a new ticket.

## Search index cost

Not measured here. `DictionarySearchIndexCostTests` builds the real index from the 6,407-kanji bundle and prints one line.

`SEARCH-INDEX build: N ms, resident growth: X MB, kanji: 6407`

CI's test log is the substitute for a simulator measurement. The master should copy that line into the Decisions entry. The test fails only if the build takes over 10 s or resident growth passes 150 MB. Both ceilings are loose on purpose. 044 budgeted about 20 MB, so the printed figure is the real check.

## Decisions

| Question | Options | Choice | Who |
| --- | --- | --- | --- |
| Which kanji does JLPT Jinmeiyō hold? | All 806, or only the 559 with no N-level | The 559. The 247 N1 Jinmeiyō kanji stay on N1, so no kanji is on two rungs. | Ticket notes |
| Which kanji does Jōyō-ladder Jinmeiyō hold? | Only no-grade kanji, or all 806 | All 806. Every Jinmeiyō kanji has no Jōyō grade. | Ticket notes |
| How does the pool avoid decoding thousands of records? | Keep `[KanjiEntry]`, or use index entries | `[KanjiIndexEntry]` through a small `PoolCandidate` protocol. Decode only the head record. | Implementer |
| Where does the rung test live? | In each caller, or one shared `includes` | One `includes` on each level enum over `LevelMember`. | Implementer |
| How are the new rungs labelled in compact spaces? | Reuse N-code, or new glyphs | 名 and 外 for badges, and the full name for list and search rows (`badgeLabel`). | Implementer |
| How is a kanji with no stroke file shown? | Empty pad, hide the action, or a clear state | "No stroke order for this kanji" in detail, Practice and handwriting matching. | Ticket notes |
| Add the exactly-one-rung dataset check? | Skip, or add if under 15 lines | Added, 12 lines in `DatasetContractTests`. | Master brief |
| Version bump | Patch, minor, none | Minor, v0.36.0, untagged. | Implementer, per `docs/workflow.md` |
| Widget memory and search-index cost | Simulator run, or CI log | Search index from the CI test log. Widget figure stays open for a device. | Master brief |

## Audit

COUNCIL APPROVE, round 2 of 5. Claude 8, Gemini 10, GPT 9.

- Round 1. Claude 8 (approve), GPT 9 (approve), Gemini 7 (disapprove). Gemini raised one blocking problem, that `mach_task_self()` in `DictionarySearchIndexCostTests` does not compile. Rebutted. Swift's Darwin overlay declares `mach_task_self()`, and the `mach_task_self_` global would fail under Swift 6 strict concurrency, which `project.yml` sets. No code changed.
- Round 2. Gemini re-checked the rebuttal and approved with 10.

Minor problems declined, each raised by one seat.

- Claude. The Draw to search sheet shows a note ("Drawing cannot find kanji that have no stroke order. Search those by reading or meaning.") instead of the exact "No stroke order for this kanji" line. Declined. A drawn match can never be one of these kanji, so the sheet explains why. Detail and Practice use the exact line.
- Claude. `KanjiDetailTests` covers the no-stroke-file case through `TestKanjiContentStore`, not the bundled store. Declined. `DatasetContractTests.strokeFileCoverage` checks the real bundle's 32 missing files, and the view state does not depend on the store type.
- Claude. `SourcesTests` asserts "3465" without a separator and might not match. Not a problem. `tools/dataset/build.py:294` and `Dataset/Shared/DATA-SOURCES.md` write the totals without separators.

Swift was not compiled. The seats read the diff for compile and concurrency problems and found none that held up. CI is the first compile.
