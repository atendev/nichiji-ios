---
id: "070"
title: Remove ML Kit from handwriting search
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

Does handwriting search run on the KanjiVG matcher alone, with ML Kit, CocoaPods and the on-device seam gone from the code, the build, CI and the docs?

## Notes

Skills: `tdd`, `unslop`.
Decided in [Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md): v1.0 drops ML Kit and keeps "Data Not Collected".
- Delete `MLKitHandwritingModel.swift` and `OnDeviceHandwritingModel.swift` (the seam and its factory). Don't keep the protocol for a later recognizer: a protocol with one implementation is a guess. The code stays in git history and on the `prototype/handwriting-recognizer` branch.
- `HandwritingSearchModel`: remove the on-device model, the download request, the ML Kit filtering and candidate limit, and the recognizer source. Opening the sheet only loads the matcher's templates.
- `HandwritingSearchEntry.swift` and `HandwritingSearchEntryTests.swift` mention ML Kit. Drop the Debug "Recognizer" footnote and any test of the source, and keep the rest.
- Keep `HandwritingTemplateMatcher`, `HandwritingTemplateBuilder`, the shipped-kanji filter, the 104-drawing fixture and the CI floor (76% top-1, 89% top-5).
- Build: delete the `Podfile`, the `pod install` step in `make generate` and CI, and the switch to `Nichiji.xcworkspace`, so builds use the `.xcodeproj` that XcodeGen writes again. Remove the CocoaPods lines from `.gitignore` and the CocoaPods install in `.github/workflows/ci.yml`.
- Docs: remove the ML Kit exception and the on-device recognizer from `docs/DESIGN.md` (lines 16-20, 48-51, 63-64, 89-97, 155, 249-251 as of v0.24.5), and update `docs/PROGRESS.md`. Leave `.plan/assets/ml-kit-privacy.md` as the record of why.
- Run the matcher accuracy test and the full suite through CI. The host is Linux, so CI is the build check.
This is a Phase 5 run.

## Resolution

Yes. Handwriting search runs on the KanjiVG matcher alone, and opening the sheet only loads its templates.

- Code: `MLKitHandwritingModel.swift` and `OnDeviceHandwritingModel.swift` are deleted, with no protocol kept. `HandwritingRecognizerSource`, `HandwritingRecognitionError`, the factory and `TestOnDeviceHandwritingModel` went with them. `HandwritingSearchModel` takes only `loadMatcher` and lost the download, the ML Kit filtering and candidate limit, and the `source` property. The Debug "Recognizer" footnote and its copy are gone.
- Kept: `HandwritingTemplateMatcher`, `HandwritingTemplateBuilder`, the shipped-kanji filter, the 104-drawing fixture and the CI floor (76% top-1, 89% top-5). `HandwritingInk` and the point timestamps stay too, since the pad and its tests use them.
- Tests: the download, model-switch, filtering, throwing-model, Simulator-factory and footnote tests are deleted. `staleResultDropped` now drops a matcher result, and `templatesLoadOnce` and `liveLoadsBundledTemplates` are new.
- Build: the `Podfile` is deleted, `make generate` runs only XcodeGen, `build`, `test` and `ipa` use `-project Nichiji.xcodeproj`, `.gitignore` drops `*.xcworkspace` and `Pods/`, and CI installs no CocoaPods and no longer prints `Podfile.lock`.
- Docs: `DESIGN.md` drops the ML Kit privacy exception, the on-device seam, the model download, the device-only CocoaPods note, the third-party SDK line and the constraint's exception. `PROGRESS.md` describes the matcher-only feature. `.plan/assets/ml-kit-privacy.md` stays as the record of why.
- CI: pending; see Final Report. The host is Linux, so nothing was built or run locally.
- Unblocked: "Update the privacy copy and label", "Improve the handwriting matcher's accuracy" and "Collect handwriting drawings from other learners". "Prepare the v1.0 release build" stays blocked by other tickets.
