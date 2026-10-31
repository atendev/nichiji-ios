---
id: "039"
title: Decide the review scheduling and progress rules
type: grilling
mode: HITL
status: open
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

