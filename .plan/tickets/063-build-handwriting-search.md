---
id: "063"
title: Build handwriting search
type: task
mode: AFK
status: open
blocked_by: []
claimed: false
---

## Question

Can a Pro learner draw a kanji in Dictionary and get the right one among the candidates, with ML Kit on device and the KanjiVG matcher everywhere else?

## Notes

Skills: `tdd` for the matcher and the recognizer seam, `apple` for the drawing pad and candidate row.
Decided in [Choose the handwriting recognizer](../closed/060-choose-the-handwriting-recognizer.md): ML Kit Digital Ink (`ja`) on device, the KanjiVG matcher in the Simulator, in tests, and until the model has downloaded.
- One recognizer protocol, two implementations. Keep only candidates the app ships (`kanji-index.json`).
- Port the prototype matcher from `prototypes/handwriting-recognizer/matcher.js` on the prototype branch: 12 points per stroke, bounding-box normalization, best stroke assignment (Hungarian), candidates within 2 strokes of the drawn count. Copy the 104-drawing `handwriting-testset.json` from that branch into the tests and test against it; the prototype scored 79.8% top-1 and 92.3% top-5.
- ML Kit comes through CocoaPods (no SPM route). Its pods exclude arm64 for the Simulator, so link it for `iphoneos` only and compile its implementation behind `#if !targetEnvironment(simulator)`. `make`, CI and xcodegen need the pod install step and the workspace. The pods' deployment targets need the post_install fix from the harness Podfile.
- Model download: start it when a Pro learner first opens handwriting search, show the matcher's results meanwhile, and switch once it lands.
- Gate the entry point on `ProFeature.handwritingSearch` through `ProAccessModel` and open `paywallSheet(feature:)` when locked. Draw to search was hidden by [Decide how Dictionary search matches and ranks](../closed/044-dictionary-search-rules.md); this shows it.
- Update the `docs/DESIGN.md` non-goal that handwriting recognition replaced.
- The privacy label follows [Find what ML Kit sends to Google](064-find-what-ml-kit-sends-to-google.md), which must close before release, not before this build.

## Resolution
