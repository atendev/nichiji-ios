---
id: "054"
title: Prepare the v1.0 release build
type: task
mode: HITL
status: open
blocked_by: ["051", "052", "053", "055", "058", "059", "062", "063", "064"]
claimed: false
---

## Question

Is there a signed, TestFlight-uploadable v1.0.0 build with its privacy manifest in place?

## Notes

Skills: `unslop`, `wizard`.
"Fix the v1.0 scope" put release work in v1.0. The privacy manifest (`PrivacyInfo.xcprivacy`) and the XcodeGen release/signing configuration are agent work, driven by the privacy answers "Write the App Store metadata" settles. The Apple account steps — App Store Connect record, signing, upload — are manual: write a `wizard.sh` for them and stop. "Build the Sources screen" must ship first, since it is a license requirement.
Bump to v1.0.0.
The Pro in-app purchase needs its App Store Connect product, price and review screenshot; add those steps to the `wizard.sh`. The product ID is `com.aten.nichiji.pro`, a non-consumable with Family Sharing on, matching `Config/Nichiji.storekit`.
From "Build the Pro purchase service and feature gating": the dev unlock compiles only under `#if DEBUG`. "Decide the free/Pro boundary, price and unlock flow" also wants it in internal TestFlight builds, which needs an internal build configuration or compilation flag. Add that, and check that the App Store (Release) build ignores `proIsDevUnlocked`.

From [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md): the release checklist includes re-running `make dataset-fetch` and `make dataset` for every App Store release. A data-only patch release is due if the bundled EDRDG snapshot is more than 6 months old.

From [Write the App Store metadata](../closed/055-write-the-app-store-metadata.md): the approved copy is in [app-store-listing.md](../assets/app-store-listing.md) and the site drafts are in [support-site.md](../assets/support-site.md).
- The privacy manifest goes on both the app and widget targets and declares the App Group `UserDefaults` required reason.
- Handwriting search ships ML Kit, which logs to Google. Take the privacy manifest and label answers from [Find what ML Kit sends to Google](064-find-what-ml-kit-sends-to-google.md); the approved "Data Not Collected" may no longer hold.
- Before upload, check the listing's Nichiji Pro lines and App Review notes against the shipped build. Cut any feature that did not ship (Guideline 2.3.1), and add the photo and handwriting entry points to the review notes if they did.
- Take the seven 6.9" screenshots from this build, in the listing's order.
- The `wizard.sh` asks for the support email and the copyright holder's legal name, creates the public repo `atendev/nichiji-site`, turns on GitHub Pages, publishes both pages, and pastes the support and privacy URLs into App Store Connect.
- From [Build handwriting search](../closed/063-build-handwriting-search.md): commit `Podfile.lock` (CI prints it, or take it from the first Mac `pod install`). Then check ML Kit on a device with a Debug build and the dev unlock: the model downloads, 日, 学 and 右 each appear in the top five with the Debug footnote reading "Recognizer: ML Kit", and matches still appear in airplane mode. The first tap on "Draw a kanji to search" must open the full sheet, not an empty one ([Fix known kanji levels and the blank draw sheet](../closed/066-fix-known-kanji-levels-and-draw-sheet.md)); no automated test opens it.
- Make the app available in all storefronts, including Japan. [Decide the Japanese localization](062-decide-the-japanese-localization.md) decides what gets translated.

## Resolution
