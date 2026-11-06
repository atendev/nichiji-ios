---
id: "065"
title: Mark kanji the learner already knows
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

How does a learner who already reads some kanji skip them, so Today starts at the first kanji they do not know?

## Notes

Skills: `apple` for every screen, `architect` for the store and picker shape, `unslop` for all prose.
Decided with the user before the run:
- A known kanji is stored as stage `.known` with no review date and no study log entry, so it never makes a study day or a streak.
- Known kanji count apart from Learned: the Learned figures, By level bars and the Learned grid leave them out, and You shows a separate known count.
- Entry points: a skippable onboarding step after level selection, a "Known kanji" row in Settings > Learning, and an "I know this" button on kanji detail next to Forget it.
- The picker has a text field. Typing kanji shows exactly those kanji, and typing a reading or meaning searches the whole dataset, so kanji outside the learner's level can be picked.
This reopens the "Customize your kanji" onboarding item in [Fix the v1.0 scope](../closed/034-fix-the-v1-scope.md). The user approved it, so the map's Out of scope line changes.

## Resolution

Learners can now mark kanji they already know from three places: a skippable onboarding step after level selection, a "Known kanji" row in Settings > Learning, and "I know this" on kanji detail. A marked kanji is stored as stage known with a `declaredKnownAt` date, no review date and no log row, so it never makes a study day or a streak. Today skips it because the daily pool already drops non-new kanji.

- Learning, Forget it and any review that changes the stage clear the mark; "Not known after all" and deselecting in the picker return a marked kanji to new and log nothing.
- Known counts apart from Learned: tiles, By level bars, the Learned grid, Needs attention and the level-complete figure leave marked kanji out, and "Your kanji" reads "N learned · M known". Milestones still count logged learning only, so marking a whole level leaves Finish level at 0.
- The picker's text field shows typed kanji exactly (uncapped) or searches readings and meanings across every level (capped at 20 by the search index). Kanji already in study are dimmed.
- `ServiceContainer.setKnown` writes, re-picks today's kanji, reloads widgets and rebuilds reminders, and creates no assignment on a first run.
- Reopens the onboarding "Customize your kanji" item from [Fix the v1.0 scope](034-fix-the-v1-scope.md) at the user's request.
- CI: pending; see Final Report.
