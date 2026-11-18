---
id: "087"
title: Add the Jinmeiyō and Hyōgai levels to the app
type: task
mode: AFK
status: open
blocked_by: ["086"]
claimed: false
---

## Question

Can a learner pick Jinmeiyō or Hyōgai on either level ladder and study, browse and look up those kanji everywhere the app shows kanji?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Read [Add kanji beyond Jōyō](../closed/085-add-kanji-beyond-joyo.md) first.

- Both ladders end with Jinmeiyō ("Name kanji") then Hyōgai ("Beyond the lists"). On the JLPT ladder, Jinmeiyō holds only kanji with no N-level. On the Jōyō ladder, it holds all 863.
- Update the level pickers in onboarding and Settings (`LevelSettingsView`), the study pool, `AutoKnownLevels`, the known-kanji picker, Dictionary browse grouping, the kanji Details card, the level footers, and Stats progress.
- The Details card shows the classification, with "—" or no row where a JLPT level or Jōyō grade is missing. The JLPT "(est.)" label is unchanged.
- Kanji with no stroke file: detail, Practice and handwriting matching show a clear "No stroke order for this kanji" state, with no empty pad and no crash.
- Measure the widget's peak memory with the new index on a simulator and report it. It must stay well under about 30 MB. If it doesn't, the widget reads only the records it needs.
- Measure how long the Dictionary search index takes to build and how much memory it uses. 044 budgeted about 20 MB.
- Update the Sources screen totals.

## Resolution
