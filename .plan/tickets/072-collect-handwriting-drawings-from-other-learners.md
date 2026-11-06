---
id: "072"
title: Collect handwriting drawings from other learners
type: task
mode: HITL
status: open
blocked_by: ["070"]
claimed: false
---

## Question

How does the KanjiVG matcher score on drawings from 3-5 people other than the user, ideally learners?

## Notes

Skills: none. The user gathers the drawings. The agent scores them.
From [Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md): every accuracy figure so far comes from the user's 104 drawings. Learners may draw worse, and the matcher is weakest when the stroke count is off.
- Each person draws a subset of the 104 test kanji. Collect them with the prototype harness on the `prototype/handwriting-recognizer` branch, or add a Debug-only export to the draw sheet that writes the `handwriting-testset.json` format.
- Output: top-1 and top-5 per person and pooled, compared with the user's 79.8% and 92.3%. If the matcher falls well below its 76% / 89% CI floor, flag it to [Test photo lookup on real signage](061-test-photo-lookup-on-real-signage.md)'s price check and to [Improve the handwriting matcher's accuracy](071-improve-the-handwriting-matchers-accuracy.md).
This doesn't block v1.0.

## Resolution
