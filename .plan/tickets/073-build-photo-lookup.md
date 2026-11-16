---
id: "073"
title: Build photo lookup
type: task
mode: AFK
status: open
blocked_by: []
claimed: false
---

## Question

Can the Dictionary tab take or pick a photo and list every kanji found in it, with a tap opening the kanji detail?

## Notes

Skills: apple. Decided in [Test photo lookup on real signage](../closed/061-test-photo-lookup-on-real-signage.md): capture-then-grid with no live scanning. Run Vision (accurate, `ja-JP` then `en-US`), and use Live Text (VisionKit `ImageAnalyzer`) when Vision reads fewer than 4 characters. Keep only characters in the bundled dictionary, de-duplicated. Show the photo beside the grid. A "New to you" toggle filters to unlearned kanji and is off by default. Gate the entry point on `ProFeature.photoLookup` through `ProAccessModel`, and open `paywallSheet(feature:)` when locked. Reference code: `prototypes/photo-lookup/` (`Recognizer.swift`, `LiveTextReader.swift`, `Trial.combinedText`, `Trial.kanjiFound`).
Before release, follow Guideline 2.3.1 in `assets/app-store-listing.md`, and check the privacy copy still holds for on-device recognition.

## Resolution
