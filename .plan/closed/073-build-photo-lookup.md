---
id: "073"
title: Build photo lookup
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

Can the Dictionary tab take or pick a photo and list every kanji found in it, with a tap opening the kanji detail?

## Notes

Skills: apple. Decided in [Test photo lookup on real signage](../closed/061-test-photo-lookup-on-real-signage.md): capture-then-grid with no live scanning. Run Vision (accurate, `ja-JP` then `en-US`), and use Live Text (VisionKit `ImageAnalyzer`) when Vision reads fewer than 4 characters. Keep only characters in the bundled dictionary, de-duplicated. Show the photo beside the grid. A "New to you" toggle filters to unlearned kanji and is off by default. Gate the entry point on `ProFeature.photoLookup` through `ProAccessModel`, and open `paywallSheet(feature:)` when locked. Reference code: `prototypes/photo-lookup/` (`Recognizer.swift`, `LiveTextReader.swift`, `Trial.combinedText`, `Trial.kanjiFound`).
Before release, follow Guideline 2.3.1 in `assets/app-store-listing.md`, and check the privacy copy still holds for on-device recognition.

## Resolution

Yes. A Pro button under "Draw a kanji to search" opens the photo lookup sheet; locked, it opens the paywall. The sheet takes a photo with the camera or picks one from the library, reads it on device with Vision (`ja-JP` then `en-US`, accurate), and uses Live Text when Vision reads under 4 characters. It lists each bundled kanji found once, in order of first appearance, in a grid under the photo and its found count, and a tile opens kanji detail. "New to you" is off by default and hides kanji past `new`. The photo is never saved. `project.yml` gains `NSCameraUsageDescription`. Pure text rules and the model are tested; the Vision and Live Text readers run only on a device. CI: pending; see Final Report.

Left for the release build: Guideline 2.3.1 and the listing's "point the camera at a sign" line (capture-then-grid, not live), which still reads true enough but is worth rewording. The privacy copy still holds: the photo is read on device and nothing is stored or sent.
