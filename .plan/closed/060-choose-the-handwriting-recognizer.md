---
id: "060"
title: Choose the handwriting recognizer
type: prototype
mode: HITL
status: closed
blocked_by: []
claimed: false
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

Progress (2026-11-05), prototype on branch `prototype/handwriting-recognizer`:
- The user drew all 104 test kanji (`prototypes/handwriting-recognizer/handwriting-testset.json`): 80 spread across the frequency list plus 24 confusables.
- KanjiVG matcher, primary variant fixed before drawing (bbox + free stroke order): 79.8% top-1, 92.3% top-5, 96.2% top-10, about 40 ms per drawing in Node. Not in the top 10: 弓 包 飽 糾. Ranked 2-9: 天 後 始 特 辺 宙 抑 棄 到 斜 缶 媒 侮 入 大 午 己. Strict stroke order scores only 42.3% top-1, because 30 of the 104 drawings differ from KanjiVG in stroke count, so order-free matching is required.
- ML Kit: the harness builds as a device IPA, but it can't run in the Simulator. MLKitDigitalInkRecognition 8.0.0 and MLKitCommon 14.0.0 exclude arm64 for the Simulator, and the Xcode 27 runner offers no x86_64 simulator destinations even with Rosetta installed. Its figures need a run on a physical device. Adopting it would also keep any code that calls it out of Simulator tests and CI.
- ML Kit on the user's iPhone, same 104 drawings, candidates pooled to the app's 2,383 kanji: 89.4% top-1, 99.0% top-5, 99.0% top-10, 6 ms per drawing (raw: 87.5 / 98.1 / 99.0). Not in the top 10: 凄. Ranked 2-4: 侮 泌 之 洵 士 末 入 千 夫 鳥.
- Paired on the same drawings: top-1, the matcher alone is wrong on 19 and ML Kit alone on 9 (exact McNemar p ≈ 0.09); top-5, 8 against 1 (p ≈ 0.04).
- App Privacy Report for the harness: dl.google.com once (model download), then play.googleapis.com and www.googleapis.com once each a minute later. One logging contact per session, not per recognition; the contents aren't visible.

## Resolution

Use ML Kit Digital Ink Recognition (`ja`) for handwriting search, with the KanjiVG matcher as its fallback. It was the more accurate on the user's 104 drawings, and the ticket picks by accuracy.

- ML Kit, candidates kept only if the app ships them: 89.4% top-1, 99.0% top-5, 99.0% top-10. Not in the top 10: 凄. Ranked 2-4: 侮 泌 之 洵 士 末 入 千 夫 鳥.
- KanjiVG matcher (bounding-box normalization, best stroke assignment): 79.8% top-1, 92.3% top-5, 96.2% top-10. Not in the top 10: 弓 包 飽 糾. Ranked 2-9: 天 後 始 特 辺 宙 抑 棄 到 斜 缶 媒 侮 入 大 午 己.
- The top-5 gap is the one that holds up on paired drawings (8 against 1, p ≈ 0.04). Top-5 is what a candidate row in search shows.

How it ships, as the user chose:
- ML Kit links for device builds only. Its pods exclude arm64 for the Simulator, and the Xcode 27 Simulator has no x86_64 destinations, so it can't run there.
- The KanjiVG matcher answers in the Simulator, in tests, and on device until the 20 MB `ja` model has downloaded. It has to match strokes in any order, since 30 of the 104 drawings had a different stroke count from KanjiVG.
- CocoaPods joins the project for ML Kit, which has no Swift Package Manager route.
- On the device, the harness contacted dl.google.com once (model download), then play.googleapis.com and www.googleapis.com once each. That's one logging contact per session, not one per drawing, and the report can't show what was sent. The approved listing says "Data Not Collected", so what ML Kit sends and the label it needs are now a research ticket.

The prototype, drawn test set and both scorers are on the `prototype/handwriting-recognizer` branch, which stays out of `main`.
