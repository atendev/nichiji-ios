---
id: "071"
title: Improve the handwriting matcher's accuracy
type: task
mode: AFK
status: open
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
