---
id: "077"
title: Find each kanji's box in the photo
type: task
mode: AFK
status: closed
blocked_by: ["075"]
claimed: false
---

## Question

Can the photo read return each kanji found with its box on the photo, in reading order?

## Notes

Skills: `tdd`.
The highlights and tap-a-box need a box per kanji. Vision's `VNRecognizedText.boundingBox(for:)` gives a box for a character range. Extend `PhotoTextReading` and `PhotoKanjiExtractor` so each kept kanji carries its boxes in normalized image coordinates (one kanji can appear more than once), keep reading order, and keep the Live Text fallback per 075. The box math and ordering are unit-tested. Vision itself needs a device.

## Resolution

Yes. The photo read now returns each bundled kanji with every box it appears in (full record in `assets/077-find-each-kanjis-box-in-the-photo-report.md`; council APPROVE in round 1; CI green):

- **Shape.** `PhotoTextReading` gains `visionBoxes`, one optional box per character of each Vision line, so the existing `PhotoTextReading(visionLines:liveTextLines:)` calls still work. `PhotoKanjiExtractor.scanned(_:bundled:)` replaces `kanji(in:bundled:)` and returns `[ScannedKanji]`: the id plus every box, in reading order, one tile per distinct kanji in first-appearance order. A character Vision cannot box keeps its kanji and adds no box.
- **Coordinates.** Boxes are normalized to the upright image with a top-left origin; `PhotoBox.topLeftOrigin(fromVision:)` flips Vision's bottom-left boxes once, in the reader.
- **Live Text.** A Live Text read lists its kanji with no boxes. `PhotoTextReading.usesLiveText` routes this, and `PhotoLookupModel.hasBoxes` is the flag 078 reads to hide Highlights. A sparse Vision read with no Live Text keeps Vision's boxes.
- **Model.** `PhotoLookupModel` stores `scanned`; `kanji` is derived, so existing views read as before.
- **Tests.** Ordering, repeats, a nil box, short box rows, Live Text, the flip and the model are unit-tested. Vision's per-character boxes themselves need a device check, and nothing was compiled locally (no Swift toolchain here); CI built and tested it.
- **Version.** No bump; tagging stays with the user.
