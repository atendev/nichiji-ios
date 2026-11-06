---
id: "070"
title: Remove ML Kit from handwriting search
type: task
mode: AFK
status: open
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
