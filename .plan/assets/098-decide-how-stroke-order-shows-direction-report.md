# Decision report: Decide how stroke order shows direction

Ticket type prototype, run in auto mode as a child of wayfinder-master. The main thread made every decision below. The audit was council-audit in single mode, with one Claude seat on haiku. Rounds 1 to 3 returned DISAPPROVE and round 4 returned APPROVE with a score of 8. The full resolution is in the ticket file.

## Decisions

1. **Does the path start mark the pen-down point?**
   Options were to trust KanjiVG or to add start data. The main thread chose to trust it. The dataset matches KanjiVG in all 6,375 files, and no stroke ends up and to the left of its start. The per-type endpoint check finds 37 strokes whose label doesn't fit their drawn shape, and none of them is reversed. All 253 strokes in the animCJK comparison run the same way, and the 60 hand-checked strokes follow the school stroke order.

2. **Which value gives the arrow's direction?**
   The options were the first tangent, a chord at 6, 10 or 15 units, or a chord at 20% of the length. The main thread chose the 10-unit chord, which misses on 15 strokes. The first tangent misses on 2,318 because of the brush-press tick. Ticket 099 stores the start point and the unit vector.

3. **Dot, arrow, or both, and on which strokes?**
   The prototype compared four options: dot only, dot with a chevron on the stroke, dot with an arrow beside the stroke, and arrows on every stroke. The main thread chose the dot with an arrow beside the stroke, on the current stroke only.

4. **Draw order.** This decision is new in this run. On the short-stroke render, the dot's halo hid every current stroke under 6 units. The main thread changed the order to draw the current stroke above the dot, so the dot shows as a vermilion ring. The arrow still draws last.

5. **Arrow on short strokes.** The main thread kept the arrow on every stroke. The render covers the dataset's shortest stroke (鹽 s16, 3.99 units), and the arrow reads in light and dark.

6. **Colour.** The main thread chose the existing `.nichijiVermilion` token with a `.nichijiSurfaceSunken` halo. It measures 4.64:1 in light and 5.71:1 in dark. The token set has no Increase Contrast variants, and that gap covers the whole palette.

7. **Size.** The dot has radius 4.5 viewBox units, or about 11 pt at 1.25 pt per unit on a 393 pt iPhone. The arrow is an 11-unit shaft that sits 8 units to the left of travel. The report cites the source lines for the cell scale, including the Practice sheet's narrower cell.

8. **Dot on the Practice pad guide?** No. The guide is a font glyph, so a dot taken from the paths would sit off its strokes.

9. **Does the stroke player reuse the markers?** Yes. They are one shared marker built from the start point and the direction. Ticket 100 decides when it shows.

10. **VoiceOver.** Each cell label adds one of eight direction words.

## Audit rounds

- Round 1 (previous thread): DISAPPROVE, score 5. The seat found the short-stroke evidence and scale sources missing, and the check results left out of the Resolution.
- Round 2: DISAPPROVE, score 7. The seat found a wrong breakdown of the 37 endpoint failures, which it marked blocking. It also found five minor problems: 輾 s15's 49° arrow, an unsupported cause for the animCJK gaps, the generic check's scope, an unexplained gap of 179 strokes, and the renderer drawing at 112 pt. The main thread fixed all six.
- Round 3: DISAPPROVE, score 7. The seat questioned animCJK's independence and the drawing size, and noted that lengths from 4.0 to 4.7 units were never rendered. The main thread fixed the first and third. It rebutted the second, because the HTML prototype draws on a 136 px content box.
- Round 4: APPROVE, score 8, with three minor problems, all declined:
  - The whole of 鹽 s16 sits inside the dot, so its ink meets vermilion at 2.86:1. Declined because it is 1 stroke of 78,775 and the render still shows it.
  - The 1958 school stroke-order guide was cited from memory, with no copy fetched. Declined because the 20 kanji are first-grade kanji with well-known orders. The main thread checked all 60 rows by hand.
  - "The first point is the pen-down point" goes beyond the checked sets, because 179 strokes have no type. Declined because those strokes still pass the file-match check and the generic check.

## Skipped gates

The Jev audit ran in the parent session. The master's brief set the commit gate to commit without a question, and CI steps 6 and 7 are skipped. No build or tests ran, because this ticket changes no app code.
