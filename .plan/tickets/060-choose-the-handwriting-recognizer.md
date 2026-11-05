---
id: "060"
title: Choose the handwriting recognizer
type: prototype
mode: HITL
status: open
blocked_by: []
claimed: true
---

## Question

Which recognizer reads a learner's drawn kanji more accurately on a drawn test set: a matcher against the bundled KanjiVG stroke data, or Google ML Kit Digital Ink Recognition?

## Notes

Skills: `prototype`, `tdd`.
Settled while grilling "Decide the free/Pro boundary, price and unlock flow": handwriting search is a Pro feature in v1.0. Apple documents no handwritten kanji recognizer, so the choice is between the two options above.
Prototype both against the same drawn test set. Pick by accuracy. Privacy is a tiebreaker only, since the app keeps data private as a guideline, not a hard requirement.
ML Kit: no published fee; model downloads at runtime (about 20 MB per language); CocoaPods only, with no Swift Package Manager route; the SDK documents sending performance and usage metrics to Google. Measure its actual network traffic on a device before deciding. If it's adopted, update `docs/DESIGN.md` and the privacy label to match.
KanjiVG matcher: no SDK. Uses the stroke-order data already in the app.
Output: the chosen recognizer, its accuracy figures, and the list of kanji it fails on.

## Resolution
