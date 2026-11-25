---
id: "098"
title: Decide how stroke order shows direction
type: prototype
mode: HITL
status: open
blocked_by: []
claimed: true
---

## Question

How does the stroke order card show where each stroke starts and which way it goes: a start dot, an arrow, or both, and on which strokes?

## Notes

Skills: `apple`, `prototype`, `unslop`. Each KanjiVG path is stored in writing direction, so its first point is the pen-down point and its first curve segment gives the starting direction. No new data is needed. The user suggested a red dot at the pen-down point, or arrows. Suggested starting point: a dot on the current stroke in every cell, plus a small arrow on the current stroke only, because arrows on every stroke crowd kanji with many strokes. Also decide:
- the dot colour, which must pass 4.5:1 contrast on `.nichijiSurfaceSunken` in light and dark mode
- the dot size at the cell's scale
- whether the Practice pad guide shows the dot too
- whether the stroke player (ticket 100) reuses the markers

Before deciding, compare about 20 kanji with a known stroke-order reference, such as the KanjiVG viewer, to confirm the path start is always the pen-down end.

## Resolution

Each cell marks its current stroke with a vermilion start dot and a small arrow beside the stroke that shows the starting direction. Earlier and later strokes get no markers. Decided in auto mode. The user can reverse every choice below cheaply (one constant or one view each) unless it says otherwise.

**Path start check.** `.plan/assets/098-path-start-check.py` runs over the raw KanjiVG zip and `Dataset/AppOnly/stroke-order`, and its output is in `098-path-start-check.txt`.
- All 6,375 dataset SVGs match KanjiVG's path data exactly, so the generator never reverses a path.
- 0 of 78,775 strokes end up and to the left of their start. That is the only shape a reversed horizontal, vertical or falling stroke would take.
- In the 20-kanji hand check (一十口木人大小山川水子九入力手心日目上下, 61 strokes), every stroke starts at the standard pen-down end and runs in the standard direction.
- The first point is the pen-down point.

**Direction value.** The arrow points along the chord from the start point to the point 10 viewBox units along the path, or to the end on shorter strokes. It does not use the first curve's control point. KanjiVG strokes open with a short brush-press tick, so the first tangent misses the expected direction for the stroke's `kvg:type` on 2,318 of 78,596 strokes. Rising strokes (㇀) are the worst case: 1,758 of 1,821 have a first tangent pointing down-right. The 10-unit chord misses on 15. Each of those 15 is a stroke whose type label doesn't fit its shape (for example 邨 s1, labelled ㇒ but drawn as a left-to-right horizontal), and the chord still follows the drawn stroke. Chords at 6, 15 and 20% of length scored 24, 16 and 26 misses. Ticket 099 stores the start point and this unit vector as tested values beside each `Path`.

**Which strokes.** Every cell shows the dot and the arrow on its current stroke only. The prototype (`098-direction-prototype.html`) compared four options on 十 水 以 心 鬱 議 九 手 at the 136 pt cell size, in light and dark. These were dot only, dot with a chevron on the stroke, dot with an arrow beside the stroke, and arrows on every stroke. Arrows on every stroke turned 鬱 and 議 into noise. A chevron on the stroke was too small to read and broke up the ink line. The arrow beside the stroke read clearly. A dot alone leaves rising strokes such as 以 s2 and short dots such as 心 s1 ambiguous. Strokes of every length get the arrow.

**Colour.** `.nichijiVermilion`, an existing token, is the "red dot" the user suggested. It measures 4.64:1 on `.nichijiSurfaceSunken` in light (`#b8321d` on `#eae2d1`) and 5.71:1 in dark (`#e8603f` on `#0f0d0a`). It only reaches 2.86:1 against the `.nichijiInk` stroke it sits on, and 1.22:1 against `.nichijiInkMuted`. So the dot and the arrow each get a `.nichijiSurfaceSunken` halo, which separates them from any stroke beneath (13.3:1 in light, 15.9:1 in dark against ink). The colour tokens in `ColorTokens.swift` have no Increase Contrast variants, and vermilion does not reach 7:1 in light mode. That gap covers the whole palette, not only this marker.

**Size.** Sizes are in KanjiVG's 109-unit viewBox, so they scale with the cell. That is about 1.25 pt per unit on a 393 pt iPhone and 1.17 on a 375 pt one.
- Dot: radius 4.5 (about 11 pt across, a little over twice the 4-unit stroke), centred on the start point.
- Dot halo: out to radius 6.
- Arrow: an 11-unit shaft ending in a chevron, with 4-unit arms at ±43°, line width 1.8 and round caps.
- Arrow halo: 1.5 units each side, the same width as the dot halo.
- Arrow position: parallel to the direction vector, 8 units off the start point to the left of travel (above a stroke heading right, to the right of a stroke heading down), and starting 2 units ahead of the start point.
- Draw order: the markers go last, above the current stroke that ticket 097 moves to the top.

**Practice pad guide.** No dot. The guide is the `.kanjiGuide` font glyph, not the KanjiVG paths, so a path-based dot would sit off the glyph's strokes. The pad is also a free recorder, with the stroke order card below it at the large detent. Reversing this means drawing the guide from paths first, which costs more than the other reversals.

**Stroke player (ticket 100).** Build the dot and the arrow as one shared marker drawn from the start point and the direction, so the player can reuse it for the stroke about to animate. Ticket 100's grilling decides when the marker shows.

**VoiceOver.** The markers stay inside each cell's single accessibility element. The cell label adds the starting direction in one of eight words: "Stroke 2 of 4, starts going down". The word comes from the same direction vector.

## Handoff

Branch `feature/098-stroke-direction` (from `wayfinder/nichiji-master`), wip commit below. Auto-mode child of wayfinder-master, council single-mode (Claude seat, haiku). Audit round 1 used: DISAPPROVE, score 5. Next is round 2.

Done: Resolution drafted above. `098-path-start-check.py` now has per-type endpoint checks, composite-label chord checks, a tick check and an animCJK comparison. Its output is `098-path-start-check.txt`, from a run with animCJK svgsJa files in `/tmp/098-animcjk` (refetch from `raw.githubusercontent.com/parsimonhi/animCJK/master/svgsJa/<decimal>.svg` for 一十口木人大小山川水子九入力手心日目上下拜柊毋湃禱繁羸臺螽蟬輾邨鐶頃). Prototype screenshot saved as `098-direction-prototype.png`. Prototype shaft halo set to 1.5.

Results to write into the Resolution (replace the Path start check and Direction paragraphs):
- animCJK, an independent dataset: 253 of 253 strokes run the same way, 246 of 253 arrows within 45°. The 7 misses are animCJK's longer entry ticks.
- Endpoint check: 37 of 78,596 fail, all heading right (horizontal-shaped strokes labelled ㇔ or ㇒).
- Chord misses with any composite label part: 10, and all 10 pass animCJK.
- Tick: 2,311 of 2,318 first-tangent misses have an in-range 10-unit chord, and the first segment's median length is 4.0 units.
- Hand check is 60 strokes, not 61. Rising: say "outside the rising range", not "down-right".

Open round-1 problems still to fix:
1. Add a short-stroke row to the prototype (鬱 steps 18-21, 4.7-6.5 units; 議 step 0, 10.8), render it, save a PNG, and confirm or limit "every length gets the arrow".
2. Cite scale sources: `KanjiCard.swift:16`, `StrokeOrderCardView.swift:42,71,92`, `ColorTokens.swift:22,42`.

Then: audit round 2, report `.plan/assets/098-decide-how-stroke-order-shows-direction-report.md` (unslop), Timing close, commit, push, PR against `wayfinder/nichiji-master`. Surfaced: none.
