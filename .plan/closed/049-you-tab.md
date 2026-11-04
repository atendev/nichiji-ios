---
id: "049"
title: Build the You tab
type: task
mode: AFK
status: closed
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

From "Build the Review tab and session": also fill the Review header's "N DAY STREAK" subtitle from the stats service (TODO in `ReviewView.swift`).

From [Decide the streak and stats rules](../closed/047-streak-and-stats-rules.md): the sixth tile is Days studied, not Time studying. Copy for the freeze row, needs attention, history rows and day headings, milestones and the level-complete screen is in its Resolution.

From [Build kanji detail and the Dictionary browse grid](../closed/045-kanji-detail-and-dictionary-browse.md): open the shared `KanjiDetailView(kanjiID:)` from You Learned. Forget it comes with it, which covers the You Learned entry point the review-rules decision lists.

From "Build the study log and stats service": read `services.statsService`. `stats(preferences:)` gives every number. `history()` loads apart from it for the lazy History list. `historyExport()` gives the `ShareLink` file. `levelComplete(level:)` runs only when `LevelSequence.current(preferences:)` is non-nil, and `LevelSequence.next(after:)` names the "Start <next level>" target. Copy for the freeze row and milestones (apart from `StudyLevel.finishLabel`) is yours. The Review tab's This week dots now mark study days, but their VoiceOver label still says "reviewed"; change it to match.

## Resolution

Resolved on 2026-11-04 as a Phase 5 run. The requirements report needed four audit rounds (the user approved a third and continuation). CI was pending at commit time; see the final report.

**You tab**: `YouView` replaces the placeholder. It reloads `stats(preferences:)` when the study log count, the streak freeze or level system setting, or the scene phase changes, and keeps the last stats on screen while it reloads. The copy and fractions live in a pure, tested `YouCopy`. Choices made where the ticket left them open:
- Freeze row: "Streak freeze ready" / "Miss one day this week and keep your streak." and "Streak freeze used this week" / "It refills when the next week starts." It is hidden when the setting is off, per 047, not shown as the design's "is off" row.
- Milestones: "First kanji", "10 kanji learned", "25 kanji learned", "100 reviews", "7-day streak", "30-day streak", then `finishLabel`. Earned rows show a matcha check mark, since there is no hanko asset; locked rows show "16 / 25" and a bar.
- By level maps `LevelBar.id` back to `JLPTLevel` or `JoyoGrade` for code and name; Name kanji has no code. Any progress shows at least 2% of bar.
- Activity uses five steps from the sunken surface to matcha, and VoiceOver reads one summary ("Studied on N of M days", up to today).
- History loads the first time it opens and again when the log changes; times read "8:02 am" in the day provider's zone. Export writes the CSV to the temp folder in the same load, and the `ShareLink` (styled by the new `SecondaryButtonStyle`) stays a disabled button until the file is ready or while the log is empty. The design's "Saved" confirmation is dropped, since the share sheet is the feedback.
- Kanji taps push `KanjiDetailRoute` onto the You stack, so detail's back button reads "You".

**Level complete**: "<level> complete" (`StudyLevel.title`: "N5", "Grade 1", "Secondary"), the seal "All learned", three figures with "–" for nil, and "Start <next level>" plus a secondary "Open Settings". After N1 or Secondary, "Open Settings" is the only button. `LevelSequence.preferences(starting:from:)` sets the level and turns the custom pool off, then `applyLevelChange` re-picks today. Custom pools keep the old copy.

**Review tab**: "N DAY STREAK" under the header, hidden at 0, reloaded on the same signals; the This week dots read "studied".

**Concern**: streak milestones read the longest streak, which 047 recomputes under the current freeze setting, so turning the freeze off can take back a streak milestone that only a forgiven miss earned. That contradicts the "Earned stays earned" comment on `Milestone`. This ticket leaves the 047 rule alone.
