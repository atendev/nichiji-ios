---
id: "039"
title: Decide the review scheduling and progress rules
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

How does a learned kanji move through the study stages, when is it due, and what do Got it and Forgot it do in a review session?

## Notes

Skills: `grilling`, `domain-modeling`, `unslop`.
Design reference: `docs/ui-reference/design-notes.md` (Review), screens 30-31 and 39-42. Glossary: `CONTEXT.md` (Study stage, Got it, Forgot it, Forget it).
Decide:

- Intervals per stage (`new`, `learning`, `familiar`, `known`) and what promotes or demotes a kanji. A Leitner-style table keyed by stage is one option; SM-2 is another.
- What Today's Got it does to `KanjiProgress` (today it leaves the `new` stage) and when that kanji first comes due.
- Where the learner triggers "Forget it" and what it resets.
- Review settings and their storage: card types (at least one on), order, cards per session, example word on the answer side, repeat forgotten, autoplay audio, and whether audio plays the reading or the reading and the word.
- What each review writes to the existing `StudyLogEntry` log (`LearnerStore` already writes rows for Today's Got it and for Forget it), since You stats read it.
- Whether due reviews affect the reminder copy or the widget. The design lists a review reminder as not built.

Graduates the review implementation tickets' requirements.

## Resolution

Leitner table, day-granular: a kanji is due when its due day is today or earlier.

- Today's Got it (app or widget): `new` → `learning`, first due tomorrow (+1d).
- Review Got it: `learning` → `familiar` (+3d); `familiar` → `known`.
- Review Forgot it: `familiar` → `learning` (+1d); `learning` stays learning (+1d).
- `known` graduates: it leaves the due queue entirely. Forget it is the self-correction hatch.

Sessions: the first answer per kanji per session is the verdict — only it changes stage and schedule. Repeat answers under "repeat forgotten" are practice: they log entries and bump counts, nothing else.

Forget it: one quiet entry point on the kanji detail screen, reachable wherever detail opens (Today, Dictionary, You Learned). It resets the stage to `new`, clears `nextReviewAt` and `lastReviewedAt`, keeps `firstLearnedAt` and both counts, and returns the kanji to the study pool. It confirms first, since it is destructive to progress. No view calls it today; this adds the first.

Review settings adopt the mock defaults: card types Kanji→meaning and Kanji→reading on, Meaning→kanji off, at least one stays on; order Due first; 10 cards per session; example word on the answer side on; repeat forgotten on; autoplay audio off; audio plays Reading; the card speaker button always plays the reading regardless. Scalars persist in shared App Group `UserDefaults` alongside the other preferences.

Logging: every answer writes `gotItReview` / `forgotItReview` with `calendarDay` set to the session day. `resetToNew` today logs an empty `calendarDay`; that gets fixed so History days stay complete. No per-session log row — You summaries derive from entries.

Reminder: when today's kanji is learned and reviews are due, the window's next-upcoming request uses review-due copy (`"3 kanji due for review"`) instead of generic copy. Widgets stay today-only: no due count. This settles the "review reminder" fog item; `DESIGN.md`'s reminder paragraph is updated.

Graduates the requirements of tickets "Build the review engine", "Build the Review settings screen" and "Build the Review tab and session".

