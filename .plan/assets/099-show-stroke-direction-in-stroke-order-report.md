# Ticket 099: Show stroke direction in stroke order

Built the direction markers ticket 098 chose. Each cell now draws a vermilion start dot and a small arrow on its current stroke. Swift was not compiled or run. There is no Xcode on this machine, so the tests were written and checked by reading, and the master's CI run on the merged batch is the first compile.

## Decisions

**1. Where the start point and direction come from.**
- Question: read them from the `Path`, or record them while parsing.
- Options: read back from `Path`; record while parsing; a second parser.
- Choice: record while parsing. The parser keeps the first move point and each line or curve segment it adds, and `StrokePathParser.parse(_:)` returns the path with a `StrokeMarker?`. `path(from:)` is now `parse(data).path`, so its other callers (the handwriting template builder, the existing tests) behave as before. The ticket said not to read values back out of the `Path`.
- Made by: implementer.

**2. Direction value.**
- Question: how to compute the direction.
- Choice: the 098 rule. A unit vector along the chord from the start to the point 10 viewBox units along the path, or to the end on shorter strokes. Curves are sampled at 64 steps, the same as the 098 check script, so the tested numbers match that script. A stroke with no length keeps its start and has no direction, so it gets a dot and no arrow, and its VoiceOver label is unchanged.
- Made by: 098 design, implementer for the zero-length case.

**3. Where the marker code lives.**
- Choice: a new file, `StrokeMarker.swift`, holding the value type, the shapes, the draw calls and the label. `StrokeOrderCardView.swift` gets only the parser recording, the marker passed into `StrokeStepView`, and two draw calls. The stroke player ticket changes the same file, so the edits there stay small and sit in different hunks.
- Made by: implementer.

**4. Draw order.** Other strokes, then the dot, then the current stroke, then the arrow. The loop in `StrokeStepView` draws the dot just before the current stroke, using the existing `drawOrder` helper, and the arrow after the loop. This is the 098 order, so a short stroke is never hidden by the dot's halo.
- Made by: 098 design.

**5. Swift 6 isolation.** `StrokeMarker` is a plain `Sendable` struct with no `View` conformance, so none of its members inherit main-actor isolation. This is the failure the previous batch hit with a helper on a `View`.
- Made by: implementer.

**6. VoiceOver.** The label is `Stroke N of M, starts going <word>`. The word is one of right, down-right, down, down-left, left, up-left, up, up-right, from the same direction vector. The markers stay inside each cell's single accessibility element. With no marker or no direction the label stays `Stroke N of M`.
- Made by: 098 design.

**7. Tests.** `StrokeMarkerTests.swift` covers `M…c` (一 s1, 十 s2), `M…C` (小 s3), a relative first `m` (0504f s6), `M…l` and `S` starts, a long line, a stroke shorter than the chord, a short first segment, zero-length and no-move data, the arrow and dot geometry, the eight words and the labels. The expected values were computed with an independent Python script using the same sampling and chord rule, and checked by hand against each stroke's shape. KanjiVG has no stroke that starts `M…l` or `M…S`, so those two are synthetic strings. The rest are real strokes.
- Made by: implementer.

## Audit

Council audit, single mode (Claude seat only). Gemini and GPT were skipped, out of quota.
- Round 1: APPROVE, 8. Three minor problems.
  - `parsed.map(\.path)` uses a key path into a tuple element, and the seat could not confirm the toolchain accepts it. Fixed: `parsed.map { $0.path }`.
  - The short-first-segment test had a wrong comment (6 units, not 10) and a weak assertion. Fixed: the comment is right and the test pins the direction.
  - Closepath segments are not recorded in the chord walk. Declined: KanjiVG strokes are single open subpaths, so it has no effect.
- Round 2: APPROVE, 9. No problems.

## Left for the master

The markers are not wired into the stroke player. The player can use `StrokeMarker.drawDot` and `drawArrow`, or the shape methods, for the stroke about to animate. Ticket 100's design decides when the marker shows.
