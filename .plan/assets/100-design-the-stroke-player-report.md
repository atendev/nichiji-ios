# Decision report: Design the stroke player

Ticket 100, a grilling ticket resolved in auto mode. The parent's brief told the main thread to take its own recommendation on every open item, so no grilling subagent ran and the user was not interviewed. The ticket's Resolution has the full design. The audit was council-audit in single mode, with a Claude seat on Haiku. It approved in round 4 with a score of 8.

## Decisions

Each decision was made by the main thread unless it says otherwise. "Reversible" means changing it alters one value or one view in the build ticket and leaves the playback state type alone.

1. **Scope.** In v1.0 or later? Options were v1.0 or after v1.0. The choice is v1.0, because map stage 11 includes the player and the build ticket 101 is already on the map.
2. **Card Play button.** Options were a full-width button beside "Practice this kanji" or a compact button in the title row. The choice is a "Play" button with `play.fill` at the trailing end of the "Stroke order" title row, labelled "Play stroke order" for VoiceOver. A second full-width button would make every card taller. Reversible.
3. **Practice sheet Play button.** Options were a text button or an icon button. The choice is an icon-only `play.circle` button, 44 by 44 pt, between the meaning and Done, because the header already truncates the meaning. The card inside the Practice sheet hides its own Play through a nil `onPlay`. Reversible.
4. **Presentation.** The choice is a `strokePlayerSheet(target:)` presenter that reuses `PracticeTarget`. From Practice it stacks, so Done returns the learner to the pad.
5. **Layout.** It mirrors the Practice sheet, with a header, a square stage, a counter and a control row. It has no stroke order grid, because the learner just came from one. Reversible.
6. **Margins.** Options were Practice's 24 pt token or the HIG's 16 or 20 pt. The choice is 16 pt, `screenMarginCompact`, to meet the user's `apple` rule. The seat's round 2 and round 3 objections drove this. Changing Practice's own margin is an app-wide token change and is not part of this ticket. Reversible.
7. **Stage size.** The stage side is the smallest of the width inside the margins, 420 pt, and the sheet height minus about 205 pt of fixed rows. This keeps the controls on screen at the 0.7 detent on an iPhone SE, where the stage shrinks to about 262 pt. The seat's round 3 objection drove this.
8. **Detents.** The choice is `[.fraction(0.7), .large]`, the same as Practice, with a scroll view for large text sizes. Reversible.
9. **Colours.** The player uses the card's three tiers: hairline for the faint kanji, muted ink for earlier strokes and ink for the current stroke, which is drawn last as in 097. At the end every stroke turns ink. Reversible.
10. **Controls.** The leading group is Previous, Play or Pause, and Next, and a "Replay" button sits at the trailing end. All of them use `PracticeControlStyle`, with a 44 pt minimum width on the icon buttons. There is no scrubber, because a slider fights the sheet's drag gesture and stepping already covers it. There is no tap-to-pause on the stage. Both are reversible.
11. **Auto-play or step.** Play runs every stroke. Next or Previous pauses and steps one stroke. Next finishes a stroke that is drawing, and Previous shows the earlier stroke whole with no reverse animation.
12. **Auto-start.** The sheet starts playing 0.4 s after it opens, because the learner tapped Play to open it. Reduce Motion changes this, as item 15 describes. Reversible.
13. **Speed.** Each stroke takes its length divided by a pen speed of 100 viewBox units per second, clamped to 0.3 to 1.0 s, with ease-in-out. Stroke length is a tested value next to `StrokePathParser`. There is no speed setting. Reversible.
14. **Pause between strokes.** The rest is 0.35 s. By the formula, a 10-stroke kanji takes 6.5 to 13.5 s. These figures come from the formula and were not timed on a device. Reversible.
15. **Reduce Motion.** Strokes appear whole with no fade, and the sheet opens paused on the empty stage. Play then shows one whole stroke every 0.8 s. The first draft kept auto-start. The seat cited `design-notes.md:14`, "All motion is disabled", so this version follows the stricter reading. If the user reads the rule as covering the timer too, Play shows one stroke per tap. Reversible.
16. **Direction markers.** The player draws whatever 098 decides for the card's current stroke and designs no markers of its own. Whichever of 099 and 101 merges second wires them into the player.
17. **Playback state.** A value type holds the stroke count, the completed strokes, the progress and the phase. Its operations are play, pause, next, previous, replay and `advance(by:)`. `TimelineView` drives it while playing. Playback pauses when the scene goes inactive and stops when the sheet closes.
18. **Counter total.** The total is `strokePaths.count`, which matches the grid labels. The card's "N strokes" line still uses `strokeCount`. That mismatch predates the player and stays out of 101.

## Audit

| Round | Verdict | Score | What changed after it |
| --- | --- | --- | --- |
| 1 | DISAPPROVE | 6 | Wrote out the Reduce Motion reasoning, kept the 24 pt margins with a reason, stopped presuming a 098 marker, fixed the timing figures, the SE fit sum and the counter note |
| 2 | DISAPPROVE | 6 | Reduce Motion now opens paused, the file count is corrected, the header and timing sums are fixed, and the 097 dependency is named |
| 3 | DISAPPROVE | 6 | Moved to 16 pt margins and sized the stage to fit the sheet height |
| 4 | APPROVE | 8 | None |

## Minor problems declined in round 4

- The shipped header's trailing padding is 12 pt. The Done button adds 12 pt of its own padding, so its label sits 24 pt in from the edge. Only the hit area reaches 12 pt from the edge, and a hit area is not content.
- The seat noted that "length ÷ 100 viewBox units per second" reads as a division by a speed. It is a division by a speed: duration equals length over a 100 units per second pen speed. The seat confirmed that the 6.5 to 13.5 s range matches this reading.
- The scope evidence was outside the seat's read set. The evidence is `map.md:26`, which covers stage 11, and `map.md:89`, the 034 entry, which does not list the player.

## Gates

The brief removed the user prompt from the commit gate. CI is skipped and the build is deferred to the master's batch build, so no build or test ran.
