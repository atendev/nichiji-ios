# Build the scan results sheet, decision report

Branch `t3/scan-results-sheet-2`, continued from the earlier attempt at `8e38fa4`. The council approved in round 2 with Claude 8, Gemini 9 and GPT 9. The host has no Swift toolchain, so nothing was compiled or run. CI is the compile, lint and test check, and the drag, snap, tab bar and photo pose need a device check.

## Decisions

1. Where the sheet state lives. Options were `@State` fields on `PhotoLookupScreen`, or one `@Observable ScanSheetModel`. The implementer chose the model, with the pure numbers in `ScanSheetGeometry`, so heights, the snap rule, the photo pose and the rise delay are unit tested without a view. The model keeps `state` nil until the sheet first rises, which lets one value mean "no sheet yet".
2. How the 40 pt rule works. A drag ends in the nearest rest state, except that a drag longer than 40 pt must move one state from where it began. The implementer made `snap` take the start state and take the nearer of the nearest state and the neighbour, so a 41 pt drag can never land back at the start. A drag of exactly 40 pt may return.
3. Where the screen wiring lives. The master asked for minimal edits to `PhotoLookupScreen.swift` because Crop and Save edit the same file and SwiftLint caps files at 400 lines. The implementer put the tab bar toggle, the screen metrics, the rise task and the reset in a new view modifier, `ScanSheetHost`. The screen gained one state, one layer, one modifier call and two photo modifiers, and lost the old panel code. It ends at 379 lines.
4. Screen height. The sheet needs the full screen height, but the tab bar shows and hides. The implementer stores size plus both safe-area insets as `ScanScreenMetrics.screenHeight`. The tab bar counts in the bottom inset, so the sum stays the same whether it shows or not.
5. Rise timing. The sheet rises 1.9 s after the read began, not after results exist. The rise task waits for `sweep.resultsAt`, then sleeps `riseDelay(readStart:now:)`, which is zero when 1.9 s has already passed. A sheet already up keeps its state, so Back from detail restores it.
6. Per-kanji meanings. Tiles need a short meaning. The read already loads the content index, so `PhotoReadOutcome` now returns the scanned kanji and a `meanings` map from `primaryMeaning` in one pass, with no second store call.
7. Retake. The old panel had a Retake button and the design's results screens have none. The top-left X already calls `model.retake()` in every result state, so the sheet keeps Retake only inside the no-kanji and failed notes, where there is no grid.
8. Old code. `PhotoLookupResultsPanel.swift`, `PhotoLookupCopy.allStarted`, `panelMaxShare` and, after the audit, the unused `newToYou` line were deleted.
9. Version. The bump is MINOR after v0.28.1. Save (PR #55) already claims v0.29.0, so the entries in `CHANGELOG.md` and `IMPLOG.md` use the placeholder `v0.X.0` and the master renumbers at the batch merge.

## Audit

Round 1.

- Claude seat (haiku): DISAPPROVE, 6, one blocking problem and six minor ones.
- Gemini seat: APPROVE, 9, no problems.
- GPT seat: APPROVE, 9, no problems.

The Claude seat's blocking problem said a found scan cannot be retaken. The main thread rebutted it with the X at `PhotoLookupScreen.swift:325`. Of the six minor problems, two led to changes, in the table below.

| Problem | Raised by | Outcome |
| --- | --- | --- |
| Found-state sheet has no Retake (blocking) | Claude | Rebutted, the X retakes in every result state |
| Pill may stay if a failed read never sets `resultsAt` | Claude | Rebutted, `updateSweep` calls `finishRead` for found, no-kanji and failed |
| Empty full-screen `Color.clear` may block photo taps | Claude | Fixed, `.allowsHitTesting(false)` |
| `screenHeight` assumes `proxy.size` excludes the safe area | Claude | Rebutted, the host attaches to the screen's `GeometryReader`, and the insets are added back |
| Symbols and fixtures not visible in the diff | Claude | Rebutted, checked by grep |
| `newToYou` unused | Claude | Fixed, removed |
| Placeholder version in the docs | Claude | Declined, the master renumbers |

Round 2 covered the two small fixes and the rebuttals, sent to all three seats.

- Claude seat: APPROVE, 8, one minor problem. The X above the sheet is not shown to stay visible at peek and half. The main thread declined it. The sheet is bottom-aligned and the X sits at the top of the screen, so only full covers it, and the chevron returns the sheet to peek.
- Gemini seat: APPROVE, 9, no problems.
- GPT seat: APPROVE, 9, no problems.

Minor problems declined, 2. The placeholder version in the docs (round 1) and the X visibility note (round 2).

## Gates the skill overrode

- No requirements-report audit before implementing, since the master's brief and the ticket's Notes already fix the criteria.
- The commit gate asked no question. The master asked for a commit every time and merges the branch itself.
- The repo's `docs/workflow.md` names a single haiku auditor. The master's brief asked for the runner's three-seat council, so only the council ran.
