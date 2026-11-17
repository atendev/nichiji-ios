---
id: "077"
title: Find each kanji's box in the photo
type: task
mode: AFK
status: open
blocked_by: ["075"]
claimed: true
---

## Question

Can the photo read return each kanji found with its box on the photo, in reading order?

## Notes

Skills: `tdd`.
The highlights and tap-a-box need a box per kanji. Vision's `VNRecognizedText.boundingBox(for:)` gives a box for a character range. Extend `PhotoTextReading` and `PhotoKanjiExtractor` so each kept kanji carries its boxes in normalized image coordinates (one kanji can appear more than once), keep reading order, and keep the Live Text fallback per 075. The box math and ordering are unit-tested. Vision itself needs a device.

## Resolution

<Filled in at close.>
