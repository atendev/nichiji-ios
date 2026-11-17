# Improve the handwriting matcher's accuracy: decision report

Ticket: `.plan/tickets/071-improve-the-handwriting-matchers-accuracy.md` (task, run as a child of the wayfinder master).

## How it ran

There was no Swift toolchain on the host. I ported the matcher and the SVG path builder to Node line by line, checked that the port reproduces the shipped baseline exactly (79.8% top-1, 92.3% top-5, 96.2% top-10), scored each idea there, and then made the one winning change in Swift. The Node harness only stands in for the Swift, so CI is the real check.

Scores were taken on the 104-drawing fixture and on a seeded synthetic set of 300 distorted KanjiVG drawings. The synthetic set applies affine drift, wobble, and merged, split and omitted strokes to 35% of drawings. It comes from the same templates the matcher uses, so it shows robustness to stroke-count drift but is not independent evidence. The ticket's other-learner drawings (ticket 072) do not exist yet.

## Decisions

1. **Which lever to pull.** Options: points per stroke (8, 10, 12, 16, 20); missing-stroke cost (0.2 to 1.0); reversal penalty (0.04, 0.08, 0.15); stroke window (1 to 4). **Missing-stroke cost.** Implementer. A missing or extra stroke costs 0.6 in the assignment, which is high enough that a drawing with one stroke too many loses to a wrong kanji with the right count. Lowering it was the only lever that moved the mismatched drawings. Points per stroke, the reversal penalty and the window did not help once cost was fixed.
2. **The value.** Options: 0.2, 0.3, 0.35, 0.4, 0.45, 0.5. **0.35.** Implementer. Fixture top-1 is 83.7 to 86.5 across 0.3 to 0.45 and falls off at 0.2 and from 0.5. 0.35 is the middle of the plateau and beats the baseline on both halves of the fixture. It also gives 94.3 top-1 on the synthetic set, against 81.7 at 0.6.
3. **Results at 0.35.** Fixture 79.8/92.3 to 85.6/94.2 (top-1/top-5). On the 30 drawings whose stroke count differs from KanjiVG, top-1 goes from 53.3% to 76.7% and top-5 from 80.0% to 86.7%. Synthetic set 81.7/93.7 to 94.3/99.3.
4. **Ideas tried and dropped.** A whole-shape chamfer term added to the cost: six times slower and no better on the fixture. A missing-stroke cost that grows with the stroke's length: no better than a flat cost. Wider stroke windows: no accuracy gain and slower (35 to 44 ms against 26 ms in Node). Implementer.
5. **Not fixed.** 弓 (drawn in 2 strokes, KanjiVG 3), 飽 (11 against 13) and 糾 (11 against 9) stay out of the top 10, and 包 stays at rank 6. A cost change cannot reach them. The matcher would have to join or split strokes, which is a larger change than this ticket. Worth a later ticket if testers hit it.
6. **Speed.** Options: add a faster prefilter; leave the work unchanged. **Leave it unchanged.** Implementer. The stroke window and the assignment size are the same, so a search does the same work per drawing. Node showed 34 ms before and 26 ms after, but Swift was not timed, so the claim is about the code path.
7. **CI floor.** Options: keep 76%/89%; raise to 82%/91%; raise to the measured score. **82% and 91%.** Implementer. That keeps a margin of 3.6 and 3.2 points under the Node result, matching the old margin (3.8 and 3.3). A second test holds the 30 mismatched drawings to 70% top-1 and 80% top-5. With 30 drawings each is 3.3 points, so the floor allows two or three drawings of noise under 76.7%/86.7%.
8. **Unit test.** A new test checks that a stroke with no partner costs `missingStrokeCost` shared across the larger stroke count, so a later edit to the constant or the padding fails a small test as well as the 104-drawing gate. Implementer.
9. **Version.** PATCH, v0.26.2: it refines a feature that already works. Tagging stays the user's call.

## Audit

Council round 1: claude (haiku) DISAPPROVE 6, gemini APPROVE 10, gpt APPROVE 9.

The claude seat raised one blocking problem: the constant and the floors are tuned and checked on one fixture, and the ticket asks to avoid tuning only to the fixture. I could not fix that with data, since ticket 072 is a human task that has not run. I ran a split-half check and told the seat the result as it came out. Tuning on the even drawings picks 0.4 and lifts the odd half from 78.8/92.3 to 86.5/96.2. Tuning on the odd drawings picks 0.2, the edge of the cliff, and drops the even half from 80.8/92.3 to 75.0/90.4. So picking a value from half the data is noisy at the low end, and the shipped 0.35 comes from the whole fixture and sits inside the plateau. The changelog now says the constant was picked on one learner's fixture and awaits other learners' drawings.

Council round 2 (claude seat only, since the other two had approved and no source line changed): APPROVE 8.

Declined minor problems, with reasons:
- The mismatch floor's margin was not explained (claude). Explained here in decision 7.
- "Search time is unchanged" rests on Node timing (claude, twice). Reworded in the changelog to say each search does the same work per drawing. Swift was not timed.
- The split-half picks and the synthetic set are not held-out evidence (claude, round 2). The changelog sentence that said the constant "holds on the odd and even halves" was reworded. The synthetic set is named in this report as same-template.

Final: COUNCIL APPROVE | round 2 | claude 8 | gemini 10 | gpt 9.

## Gates and caveats

- Repo rules say one auditor per ticket and a stop after two rounds. The wayfinder master's brief asked for the three-seat council and its five-round cap, so I ran the council only and did not run both gates.
- No Swift was built or run. CI is the check, and it may disagree with the Node port in the last point or two, since floating point and the fixture decode differ.
- The CI floor was set against the Node figure. If CI reports a score under 82%/91% or 70%/80%, the floors, not the matcher, are the first thing to look at.
- Re-score and raise the floors once ticket 072's drawings exist.
