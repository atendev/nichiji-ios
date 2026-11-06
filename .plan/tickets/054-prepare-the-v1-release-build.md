---
id: "054"
title: Prepare the v1.0 release build
type: task
mode: HITL
status: open
blocked_by: ["051", "052", "053", "055", "058", "059", "063", "064", "067", "068", "069", "070"]
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
- [Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md) dropped ML Kit, so the label stays "Data Not Collected" and no third-party SDK needs a privacy manifest. Check that the build links no ML Kit or CocoaPods code.
- Before upload, check the listing's Nichiji Pro lines and App Review notes against the shipped build. Cut any feature that did not ship (Guideline 2.3.1), and add the photo and handwriting entry points to the review notes if they did.
- Take the seven 6.9" screenshots from this build, in the listing's order.
- The `wizard.sh` asks for the support email and the copyright holder's legal name, creates the public repo `atendev/nichiji-site`, turns on GitHub Pages, publishes both pages, and pastes the support and privacy URLs into App Store Connect.
- From [Build handwriting search](../closed/063-build-handwriting-search.md): check handwriting search on a device with a Debug build and the dev unlock: 日, 学 and 右 each appear in the top five, and matches appear in airplane mode. The `Podfile.lock` and ML Kit checks went with ML Kit ([Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md)). The first tap on "Draw a kanji to search" must open the full sheet, not an empty one ([Fix known kanji levels and the blank draw sheet](../closed/066-fix-known-kanji-levels-and-draw-sheet.md)); no automated test opens it. Also check that marks survive the store migration: install v0.23.x, mark a kanji by hand, update, pick an easier level, and confirm the mark stays. Then confirm the draw pad is empty when the sheet reopens, and that the onboarding Known kanji step's buttons are dimmed only briefly.
- Make the app available in all storefronts, including Japan. [Decide the Japanese localization](../closed/062-decide-the-japanese-localization.md) ships v1.0 in English only: no `ja` localization in the build, App Store Connect or the in-app purchase. [Check kanji glyphs outside the bundled fonts](067-check-kanji-glyphs-outside-the-bundled-fonts.md) must close first.

## Resolution
