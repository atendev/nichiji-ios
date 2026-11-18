---
id: "089"
title: Stagger marked-known kanji reviews ten a day
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

When a learner marks many kanji as known at once, can their first reviews come due ten a day instead of all on the same day?

## Notes

Skills: `tdd`, `unslop`.
From [Mark kanji the learner already knows](../closed/065-mark-known-kanji.md) and the later fix `3bf1cfdb` on `main`: a marked kanji starts as learning, so it skips Today and joins flashcards, and every mark is due on the day it is marked (`row.nextReviewAt = date` in `SwiftDataLearnerStore+Known.swift`). Marking a whole level (the picker, onboarding, or a level pick) therefore buries one review day.
The abandoned branch `feature/known-kanji-into-learning` (commits `2d18cc79`, `4d12d50b`, Nov 10, 111 commits behind `main`) did this and is being deleted. Its full diff against its merge-base is saved in [089-stagger-known-kanji-reference.patch](../assets/089-stagger-known-kanji-reference.patch). Port the idea, not the patch: `main` has moved, and the patch also changes things `main` already does differently (`declaredKnown` is already `declaredKnownAt != nil`).
The idea from that branch:
- `static let marksPerDay = 10` on `SwiftDataLearnerStore`.
- `declareKnown` and `syncAutoKnown` loop over `kanjiIDs.sorted()` and pass each newly marked kanji its position among the kanji that actually got marked (skip rows already past `.new`).
- `mark` sets `nextReviewAt` to `ReviewScheduler.dueDate(addingDays: position / marksPerDay, to: date, calendar: .current)`, so the first ten are due on the day they are marked, then ten a day after.
Open details for the resolver to settle and note in the report: whether the ordering should be the sorted ID or the dataset's study order (frequency first would put common kanji first); how the order behaves when a level pick adds to an existing set; and that a single hand mark from kanji detail (position 0) stays due today.
Check that the Review tab's due count, Coming up and the stats treat staggered dates correctly, and update the tests in `KnownKanjiStoreTests` plus `docs/CHANGELOG.md` and `docs/PROGRESS.md`. Follow `docs/workflow.md` Phase 5.

## Resolution

Yes. A batch of marked-known kanji now comes due ten a day, starting on the day it is marked. `declareKnown` and `syncAutoKnown` walk the IDs in sorted order and give each kanji that actually gets marked the next position (rows already past new take no slot). `mark` sets `nextReviewAt` to the start of the day `position / marksPerDay` days later, with `SwiftDataLearnerStore.marksPerDay` at 10. Settled details: the order is the sorted ID, since the store has no dataset access and frequency order would change the `LearnerStore` protocol; a later level pick starts its own batch at position 0, so picks on the same few days can stack (k picks put up to 10k kanji on one day); a single hand mark is position 0 and stays due today. The Review tab due count and queue go through `ReviewScheduler.isDue`, which compares days, and Coming up buckets learning and familiar kanji one to seven days out, so staggered dates land correctly; stats never read the due date. Version v0.36.1, untagged. Council approved in round 2 (Claude 8, Gemini 10, GPT 9). CI green: run 44295640739 on `t3/stagger-known-kanji-reviews`, TEST SUCCEEDED (workflow_dispatch, started by hand); Swift was not compiled on the Linux host. Report: [089 report](../assets/089-stagger-marked-known-kanji-reviews-report.md).

Timing: wall 53m, active 4m, user 0s, wait 49m, blocked 0s | setup 32s, implement 52s, audit 3m (2 rounds), ci 49m | tools 45 (10 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 122k | cost $1.24 sonnet-5-5 + $0.02 haiku-5-5
