---
id: "071"
title: Improve the handwriting matcher's accuracy
type: task
mode: AFK
status: closed
blocked_by: ["070"]
claimed: false
---

## Question

Can the KanjiVG matcher raise its top-1 and top-5 accuracy, mainly on drawings whose stroke count differs from KanjiVG, without slowing search?

## Notes

Skills: `tdd`.
From [Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md): the matcher now carries handwriting search alone. It scored 79.8% top-1 and 92.3% top-5 on the 104-drawing fixture, against ML Kit's 89.4% and 99.0%. Its CI floor is 76% and 89%.
- 30 of the 104 drawings differ from KanjiVG in stroke count, and learners drift there most. Candidates are kept within 2 strokes of the drawn count.
- Not in the top 10: 弓 包 飽 糾. Ranked 2-9: 天 後 始 特 辺 宙 抑 棄 到 斜 缶 媒 侮 入 大 午 己 ([Choose the handwriting recognizer](../closed/060-choose-the-handwriting-recognizer.md)).
- Score any change on the 104-drawing fixture and on the drawings from [Collect handwriting drawings from other learners](072-collect-handwriting-drawings-from-other-learners.md) if they exist, and raise the CI floor to match. Avoid tuning only to the fixture.
This doesn't block v1.0. Run it when the frontier reaches it.

## Resolution

Yes, partly. A stroke with no partner now costs 0.35 in the matcher's stroke assignment, down from 0.6, so a drawing with a stroke too many or too few ranks its kanji higher.

- Fixture (104 drawings), top-1/top-5: 79.8/92.3 to 85.6/94.2. The 30 drawings whose stroke count differs from KanjiVG go from 53% to 77% top-1 and from 80% to 87% top-5.
- Measured in a Node port that reproduces the old baseline exactly, then confirmed by CI (build-test passed with the new floors). A search does the same work per drawing, since the stroke window and assignment size are unchanged. Swift was not timed.
- CI floors: 82% top-1 and 91% top-5 on the fixture, plus 70% and 80% on the 30 mismatched drawings.
- Tried and dropped: a whole-shape chamfer term (six times slower, no better), a missing-stroke cost that grows with stroke length, and a wider stroke window. Points per stroke, the reversal penalty and the window did not help.
- Still missed: 弓, 飽 and 糾 stay out of the top 10, and 包 sits at rank 6. They need the matcher to join or split strokes, a larger change than this ticket.
- Not confirmed on other learners: the 0.35 value was picked on one learner's fixture (it sits on a 0.3 to 0.45 plateau), and the drawings from [Collect handwriting drawings from other learners](072-collect-handwriting-drawings-from-other-learners.md) do not exist yet. Re-score and raise the floors when they do.
- Version v0.26.2. Decision report: `.plan/assets/071-improve-the-handwriting-matchers-accuracy-report.md`. PR 53.
