# Find each kanji's box in the photo: decision report

Ticket: `.plan/tickets/077-find-each-kanjis-box-in-the-photo.md` (task, Phase 5 run, child of wayfinder-master).

## Decisions

Each entry gives the question, the options, the choice, and who made it.

1. **Where the boxes travel.** Options: a parallel `visionBoxes: [[CGRect?]]` on `PhotoTextReading`; change `visionLines` to a line struct that holds text and boxes. **Parallel array, with a default of `[]`.** It keeps every existing `PhotoTextReading(visionLines:liveTextLines:)` call and test valid. Implementer.
2. **Box granularity.** Options: one box per Vision line; one per character. **One per `Character`.** The tile and box rule needs a box per kanji, and `boundingBox(for:)` takes a character range. A character Vision cannot box is `nil`, so one failure drops one box, not the kanji. Implementer.
3. **Coordinate space.** Options: keep Vision's bottom-left origin; flip to a top-left origin when reading. **Flip once, in `PhotoBox.topLeftOrigin(fromVision:)`.** Vision hands back boxes relative to the upright image, because the handler gets the EXIF orientation. The overlay in 078 measures from the top left, so the flip lives next to the reader and has a unit test. Implementer.
4. **Result type.** Options: return `[String]` plus a dictionary of boxes; a `ScannedKanji {id, boxes}` value. **`ScannedKanji`.** One kanji can appear more than once, so it carries all its boxes in reading order. First-appearance order stays the tile order. Implementer.
5. **Reading order.** Options: sort boxes by position; keep Vision's line order and the text order inside each line. **Keep Vision's order.** 075 says vertical text gets nothing special, and Vision already returns lines top to bottom. Decided in 075.
6. **Live Text.** Options: estimate boxes for Live Text; give none. **None.** 075: only Vision draws boxes. `usesLiveText` and `combinedBoxes` route this in one place, and `PhotoLookupModel.hasBoxes` tells 078 whether to show Highlights. A sparse Vision read with no Live Text keeps Vision's boxes. Decided in 075; wiring by implementer.
7. **The old `kanji(in:bundled:)`.** Options: keep beside `scanned`; replace it. **Replace.** Only the model and tests called it, so its tests moved to `scanned`. The model keeps `kanji` as `scanned.map(\.id)`, so every view reads as before. Implementer.

## Tests

Extractor and model tests were added or ported. They cover: bundled kanji kept once in first-appearance order; no kanji; a repeated kanji carrying both boxes in order; a skipped character still using its box slot; a missing `nil` box; short or empty box rows; a Live Text read giving no boxes; a sparse Vision read with no Live Text keeping boxes; the origin flip; the model keeping boxes and `hasBoxes`. The Vision call itself needs a device. This environment has no Swift toolchain, so nothing was compiled or run here. CI is the first compile and run.

## Audit

Round 1: claude APPROVE 8, gemini APPROVE 10, gpt APPROVE 9. **COUNCIL APPROVE, round 1.** The claude seat raised one minor problem: the removed `kanji(in:bundled:)` might have other callers. A grep over the repo found none outside the model and tests, so the main thread rebutted it. Its approval of 8 stands. No problems were declined.

## Version

No bump. This is internal groundwork with no visible change; the camera scan ships over later tickets. Tagging stays with the user.

## Gates skipped

The commit question, because the master's brief says to commit every time. The runner's council gate ran in place of any other. `map.md` is untouched; the master adds the Decisions line.
