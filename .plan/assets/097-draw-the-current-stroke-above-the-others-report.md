# Ticket 097 decision report: draw the current stroke above the others

Question: in each stroke order cell, can the highlighted stroke draw on top of every other stroke?

Answer: yes. `StrokeStepView` now paints every other stroke first and the current stroke last, so crossings never cover it.

## Decisions

1. **How to reorder.**
   - Options: a second loop in the Canvas closure, a `zIndex`-style sort, or a small paint-order helper.
   - Choice: a static `StrokeStepView.drawOrder(count:step:)` that returns the other indices in order, then the current index. The Canvas loops over it.
   - Why: the order is testable without rendering, and the colours and per-stroke logic stay as they were.
   - Made by: implementer (main thread).

2. **Order of the other strokes.**
   - Choice: keep index order, so earlier and later strokes still stack as before. Only the current stroke moves.
   - Made by: implementer.

3. **Visibility of `StrokeStepView`.**
   - Options: keep it `private` and test only through a view, or make it internal.
   - Choice: internal, so `@testable import Nichiji` reaches `drawOrder`. Its only user is `StrokeOrderCardView` in the same file.
   - Made by: implementer.

4. **Test.** Added `currentStrokeDrawsLast` to `StrokePathParserTests`. It covers the first, middle and last step and a one-stroke kanji.

5. **Colours.** Unchanged: `.nichijiInk` current, `.nichijiInkMuted` earlier, `.nichijiHairline` later. Both modes use semantic colours, so the fix holds in light and dark mode.

## Audit

Single-mode council, Claude seat only (the other providers are out of quota). Round 1: APPROVE, score 8, one minor problem.

- Minor, fixed: the `///` comment on the internal `drawOrder` helper. Removed per the repo's comment rule.
- Declined: none.

## Not verified

Swift was not compiled and the tests were not run, by instruction. The master builds and tests the merged batch. I did not check 十 or 木 by eye in light and dark mode. The ticket asks for that, so it is left for the master's build or the user.
