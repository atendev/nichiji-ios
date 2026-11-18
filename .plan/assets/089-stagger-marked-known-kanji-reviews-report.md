# Report. Stagger marked-known kanji reviews ten a day

Marking many kanji as known now spreads their first reviews out. A batch comes due ten kanji a day, starting on the day it is marked. Swift was not compiled. This host has no Swift toolchain, so the code and tests were checked by reading, and CI is the first compile and test run.

## Result

- `SwiftDataLearnerStore.marksPerDay` is 10.
- `declareKnown` and `syncAutoKnown` walk `kanjiIDs.sorted()`. Each kanji that actually gets marked takes the next position. A kanji already past `.new` is skipped and takes no slot.
- `mark` sets `nextReviewAt` to `ReviewScheduler.dueDate(addingDays: position / marksPerDay, to: date, calendar: .current)`. Positions 0 to 9 are due on the day of the mark, 10 to 19 the next day, and so on.
- Due dates are now start-of-day dates, as every other scheduled date is. Before, a mark stored the exact `date`. The due check already compares days, so nothing reads the time of day.
- Version v0.36.1, a patch bump: it refines how a feature that already worked schedules its reviews. Not tagged. Tagging is the user's call.
- Docs: `docs/CHANGELOG.md`, `docs/PROGRESS.md` (the Known kanji row) and the `LearnerStore` doc comments.

## Decisions

| Question | Options | Choice | Made by |
| --- | --- | --- | --- |
| What order do kanji take in the batch? | Sorted ID; the dataset's study order (frequency first) | Sorted ID. | Implementer |
| How does a level pick that adds to an existing set behave? | Offset by the marks still pending; start each call at position 0 | Each call starts its own batch at position 0. | Implementer |
| Does a single hand mark stay due today? | Yes (position 0); push it back | Yes. | Implementer |
| Which calendar sets the due day? | `.current`; pass the day provider's calendar down | `.current`, as the ticket's idea says. | Implementer |

### Order: sorted ID

The store takes a `Set<String>` and has no access to the dataset, so study order would mean changing the `LearnerStore` protocol and every caller, or giving the store the content store. Sorted ID is deterministic, so the same batch always lands the same way. The learner already knows every kanji in the batch, so which ten come first costs little. Frequency-first would put common kanji first and is a clean follow-up if it matters.

### A later level pick

`syncAutoKnown` only marks kanji still at `.new`. A learner who picks N4 after N5 gets N4's new kanji at positions 0, 1, 2 and so on, so the first ten of that second batch are due the same day as whatever the first batch still has pending. Picks made on the same few days can stack: k picks put up to 10k kanji on one day, though that is still a handful of days' worth, not a whole level. Offsetting by the marks still pending would flatten that, but it needs a fetch of pending declared rows and a rule for how stale a pending mark is. The ticket's idea does not do it, and a learner usually changes level rarely. I kept each call as its own batch and stated it in the `LearnerStore` doc comment and the test `syncStaggersBatches`. This is the one behaviour a reviewer may want changed.

### A single mark

Position 0 is due today, so "Start learning this kanji" on the detail page behaves as it did. `singleMarkIsDueToday` covers it.

## Review tab check

- **Due count and queue.** `ReviewHomeSummary` builds the queue through `ReviewScheduler.dueQueue`, which uses `isDue`. That compares `startOfDay(nextReviewAt)` to `startOfDay(now)`, so a future-dated mark is not due until its day.
- **Coming up.** The summary buckets learning and familiar rows by whole days from today: tomorrow, 2 to 3 days, and 4 to 7 days. A staggered mark falls in the right bucket. Marks more than 7 days out are not listed in Coming up, which is how every later-dated kanji already behaves. They still count in the stage counts.
- **Other readers.** A search for `nextReviewAt` across `Nichiji/` finds only `ReviewScheduler.isDue` (`ReviewScheduler.swift:100`) and `dueFirst` (`:141`), which `ReviewService.swift:65` and `:99` and `ReviewHomeSummary.swift:68` reach through `dueQueue` and `isDue`, the Coming up buckets in `ReviewHomeSummary.swift:96-111`, and the write sites in the store and `GotItAction`. `StatsCalculator.swift` does not mention it, so stats are unchanged by staggering. All the day-granular readers compare start-of-day dates, so the start-of-day change is safe.

## Tests

In `KnownKanjiStoreTests`:

- `declareStaggersBatch`: 25 kanji get three due days, with positions 9 and 10 on either side of the day line.
- `staggerSkipsStudiedKanji`: a kanji already in study takes no slot, so ten marked kanji are all due today.
- `singleMarkIsDueToday`.
- `syncStaggersBatches`: a 12-kanji sync splits 10 and 2, and a later sync of 2 new kanji starts at today.
- `declareStartsLearning` now expects the start-of-day date.

None ran here.

## Not done

- Swift was not compiled and no test ran on this host. CI is the check.
- Nothing was run on a device.

## Audit

The council approved in round 2: Claude 8, Gemini 10, GPT 9.

- Round 1: Gemini 10 and GPT 9 approved with no problems. Claude scored 7 and raised one blocking problem (a later level pick restarts at position 0), plus two minor ones.
- Rebutted: the per-call batch is what the ticket prescribes, and an offset would defer a single hand mark past today. Claude approved at 8 in round 2 and kept only a minor note that the worst case is 10k kanji for k picks on one day, which the report now states.
- Fixed: the stats claim now cites file and line for every reader of `nextReviewAt`.
- Declined (minor, one seat): Coming up shows only days 1 to 7. That is how every future-dated kanji already behaves, and changing the buckets is a separate UI decision.
- Gemini and GPT approved before the citation edit. That edit touched only the report, so I did not re-dispatch them.
