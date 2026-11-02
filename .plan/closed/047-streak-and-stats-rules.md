---
id: "047"
title: Decide the streak and stats rules
type: grilling
mode: HITL
status: closed
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

From "Build the Review tab and session": the Review tab's This week dots mark days with a review answer (`gotItReview` or `forgotItReview`). Confirm or change that when the streak rules are set.

## Resolution

Settled in a grilling session on 2026-11-02. Glossary terms added to `CONTEXT.md`: Study day, Day streak, Streak freeze, Milestone, Needs attention.

**Study day and streaks**

- A study day is a local calendar day with at least one `learnedDaily`, `gotItReview` or `forgotItReview` row. `resetToNew` doesn't count.
- Day streak: consecutive study days ending yesterday, plus 1 once today is a study day. Today never breaks the streak before it ends.
- Longest streak: the longest run under the same rules, the current streak included.
- Streak freeze: one missed day forgiven per calendar week, with the week starting on the locale's `firstWeekday`. It refills each week and doesn't carry over; a second miss in a week breaks the streak. A forgiven day keeps the streak alive but doesn't add to it. Nothing is stored: streaks are recomputed from the log using the current setting for the whole history, so turning the freeze on can repair a past break.
- Freeze row: "Streak freeze ready" or "Streak freeze used this week". Hidden when the setting is off.
- The Review tab's This week dots switch to study days, so the dots, the streak and the activity grid agree.

**Stat tiles**

- Kanji learned: kanji whose current stage isn't `new`. Forget it lowers it. The "N learned" count on Your kanji uses the same number.
- Reviews done: every review answer row, repeated forgotten cards included.
- Got-it rate: `gotItReview` / (`gotItReview` + `forgotItReview`) over all history, rounded to a whole percent. Shows "–" before the first answer.
- Time studying is dropped. The sixth tile is **Days studied**, the count of study days.
- "Learning since" header: the month of the earliest log entry ("LEARNING SINCE SEP 2026"). Hidden until the first entry.

**Activity grid**

- 12 columns (weeks, oldest on the left, the current week last) by 7 rows in locale weekday order. Days after today are blank.
- Shade from the day's count of study events (learned plus review answers): 0, 1, 2-10, 11-20, 21+.

**By level**

- Bars follow the learner's level system. JLPT: N5-N1, with estimated levels counted in their level. Jōyō: Grades 1-6, Secondary, Name kanji, the same groups as the Dictionary browse. Each bar shows learned (stage not `new`) out of the total.

**Milestones**

- Keep the seven: first kanji, 10 kanji, 25 kanji, 100 reviews, 7-day streak, 30-day streak, finish the first level.
- Sticky without storage: kanji milestones count distinct kanji ever logged as `learnedDaily`, streak milestones use the longest streak, and 100 reviews uses Reviews done. A locked milestone's progress bar uses the same measure.
- The level milestone reads "Finish N5" under JLPT and "Finish Grade 1" under Jōyō (Custom gets the JLPT label). It is earned when every kanji in that level appears among the kanji ever learned.

**Needs attention**

- Kanji past `new` with `forgotItCount` >= 1, ranked by `forgotItCount`, ties broken by the lower got-it ratio and then by the most recent Forgot it. Up to three tiles reading "Forgot 1 time" / "Forgot N times".
- When none qualify: "Nothing yet. Kanji you forget often show up here."

**Your kanji**

- Learned: the grid of learned kanji, newest `firstLearnedAt` first.
- History: days newest first, rows within a day oldest first. One row per log entry, repeats included: "Learned", "Reviewed, got it", "Reviewed, forgot", "Reset to new", each with its time. Day headings: TODAY, YESTERDAY, then "MON, OCT 26", with the year added for past years. Covers all history, loaded lazily.
- Every kanji tap opens kanji detail.

**CSV export**

- One row per log entry, oldest first. Columns `date,time,kanji,meaning,action`: `date` is the `calendarDay`, `time` is the local ISO 8601 timestamp with offset, and `meaning` is the first English meaning. `action` is one of `learned`, `got_it`, `forgot_it`, `forget_it`.
- UTF-8 with a BOM, named `nichiji-history-YYYY-MM-DD.csv`, shared through `ShareLink` at the end of History. Disabled when the log is empty.

**Level-complete screen**

- Seal, then "<level> complete" ("N5 complete", "Grade 1 complete").
- Three figures for the level: kanji learned, days taken (first to last `learnedDaily` in the level) and got-it rate on the level's kanji.
- A primary "Start <next level>" button switches the study pool in one tap, with "Open Settings" as a secondary action. After N1 or the last Jōyō group, only "Open Settings". Custom pools keep the current copy and get no switcher.

