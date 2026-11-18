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

Yes, in code, with Swift uncompiled. Both level ladders (onboarding, Settings, known-kanji picker, `AutoKnownLevels`, Dictionary browse, footers, Stats) end with Jinmeiyō ("Name kanji") then Hyōgai ("Beyond the lists"). On the JLPT ladder Jinmeiyō holds the 559 kanji with no N-level; on the Jōyō ladder it holds all 806; Hyōgai holds 3,465 on both. Every kanji sits on exactly one rung per ladder, checked against the real index. The study pool reads index entries and decodes one record for the assignment, so the widget never loads a level's records. The Details card has a List row. The 32 Jinmeiyō kanji with no stroke SVG show "No stroke order for this kanji" in detail and Practice, and Draw to search explains why they cannot match. Sources totals follow the bundle. Version v0.36.0, untagged. Council approved in round 2 (Claude 8, Gemini 10, GPT 9). Not done on this host: Swift was not compiled, the widget memory check needs a device, and the search-index time and memory come from the `SEARCH-INDEX build:` line in the CI test log. Report: [087 report](../assets/087-add-the-jinmeiyo-and-hyogai-levels-to-the-app-report.md).

Timing: wall 23m, active 22m, user 0s, wait 0s, blocked 0s | setup 1m, implement 14m, audit 7m (2 rounds) | tools 173 (3 subagent) | limits 0, compactions 0, handoffs 3 | ctx peak 161k | cost $6.08 sonnet-5-5 + $0.03 haiku-5-5
