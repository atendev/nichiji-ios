---
id: "063"
title: Build handwriting search
type: task
mode: AFK
status: closed
blocked_by: []
claimed: true
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

Yes. Dictionary has a Pro "Draw a kanji to search" button under the search bar. Locked, it opens `paywallSheet(feature:)` for `.handwritingSearch`, and no recognizer is made. The "Draw to search" sheet has a pad, five matches after each finished stroke, Undo and Clear. A match fills the search bar.

- `HandwritingTemplateMatcher` ports the prototype's "bbox + free order" variant. `HandwritingTemplateBuilder` builds its templates at runtime from the bundled stroke SVGs, so no data file ships. A CI test holds it to at least 76% top-1 and 89% top-5 on the 104 drawings in `NichijiTests/Fixtures/handwriting-testset.json`.
- `OnDeviceHandwritingModel` is the seam. `MLKitHandwritingModel` (ML Kit Digital Ink `ja`, CocoaPods 8.0.0) compiles for devices only, and the Simulator factory returns none. `HandwritingSearchModel` requests the download when the sheet opens and the model is missing, one request at a time, and asks again on the next open after a failure. It keeps ML Kit output to single shipped kanji, and falls back to the matcher on an error or an empty filtered result.
- The root `Podfile` strips the pods' Simulator `EXCLUDED_ARCHS` and makes their linker flags `iphoneos`-only. `make generate` runs `pod install`, builds use `Nichiji.xcworkspace`, and CI installs CocoaPods.
- DESIGN drops the handwriting non-goal and names ML Kit as the one third-party SDK and network exception.
- CI: pending; see the Final Report. Left for release: the privacy label and in-app privacy copy (064), a committed `Podfile.lock`, and an on-device ML Kit check (054).

