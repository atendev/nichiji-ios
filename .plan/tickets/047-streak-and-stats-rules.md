---
id: "047"
title: Decide the streak and stats rules
type: grilling
mode: HITL
status: open
blocked_by: ["039"]
claimed: false
---

## Question

How does the app compute each number on the You tab and the level-complete screen, and what does the history export contain?

## Notes

Skills: `grilling`, `domain-modeling`, `unslop`.
Design: screens 43-51 and the You section of `docs/ui-reference/design-notes.md`.
Decide:

- Day streak and longest streak: what counts as a study day (Today Got it, a review, either), and how streak freeze works ("miss one day a week": which week boundary, does it refill).
- Kanji learned, reviews done, got-it rate (its denominator), and time studying (what starts and stops the clock, or drop the tile).
- The 12-week activity scale.
- Milestones: the design lists first kanji, 10 and 25 kanji, 100 reviews, 7 and 30 day streaks, finish N5. Confirm or change, and how "finish a level" reads under Jōyō.
- Needs attention: the three most-forgotten kanji, ties and minimum counts.
- CSV export columns, file name, and that it goes through the share sheet.
- What the level-complete screen shows (the TODO in `LevelCompleteView`).

## Resolution

