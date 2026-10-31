---
id: "049"
title: Build the You tab
type: task
mode: AFK
status: open
blocked_by: ["045", "048"]
claimed: false
---

## Question

Does the You tab show the learner's stats, activity, level progress, milestones, needs-attention kanji, and learned and history lists, with a working CSV export?

## Notes

Skills: `apple`, `dataviz`, `unslop`.
Design: screens 43-51, `You.dc.html`, `YouHistory.dc.html`.

- Stat tiles, streak freeze row, 12-week activity grid, by-level bars for the active level system (JLPT or Jōyō), milestones with seal or lock, needs attention, Learned / History toggle.
- Tapping any kanji opens kanji detail.
- Export history through `ShareLink`.
- Fill in the level-complete screen per the stats rules and remove the `LevelCompleteView` TODO.
- Replace the You placeholder and its TODO in `MainTabView`.

Minor bump.

## Resolution

