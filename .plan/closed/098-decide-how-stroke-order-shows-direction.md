---
id: "098"
title: Decide how stroke order shows direction
type: prototype
mode: HITL
status: closed
blocked_by: []
claimed: false
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
- 0 of 78,775 strokes end more than 1 unit up and more than 1 unit left of their start. That is where a reversed falling stroke (㇏) or any other reversed down-right stroke would end. It does not catch reversed horizontals or verticals, so the next check covers those.
- Endpoint check by stroke type: each stroke's end must sit where its `kvg:type` puts it (a ㇐ ends right of its start, a ㇑ below it, a ㇒ below and left, a ㇀ above and right). It covers the 78,596 strokes whose first `kvg:type` character is in the script's tables. The other 179 have no type or one the tables don't list. 37 strokes fail. 36 of them run left to right and are horizontal-shaped strokes labelled ㇔, ㇒, ㇑ (臺 s6) or ㇀ (薤 s11). The 37th, 誡 s11, is labelled ㇒ but runs straight down. A reversed horizontal would run right to left and a reversed vertical would run up, so none of the 37 is reversed. The 9 of them that are also in the animCJK set (拜 s3, 毋 s4, 湃 s6, 禱 s12, 繁 s6, 羸 s19, 臺 s6, 蟬 s9, 邨 s1) run the same way there.
- animCJK, a second dataset, on the 20 hand-check kanji plus the 14 kanji behind the 15 chord misses below: 253 of 253 strokes run the same way as KanjiVG. animCJK's paths and medians are its own, derived from Makemeahanzi and the Arphic fonts, so this confirms the geometry. Its stroke order is only partly independent: its README says it was cross-checked against Kakijun, Jitenon and KanjiVG. So the hand check below is the reference for stroke order.
- In the 20-kanji hand check (一十口木人大小山川水子九入力手心日目上下, 60 strokes), every stroke starts at the standard pen-down end and runs in the standard direction. The reference is the standard Japanese school stroke order (Ministry of Education, 筆順指導の手びき, 1958), checked by hand against each stroke's start, first direction and end in the output file.
- The first point is the pen-down point.

**Direction value.** The arrow points along the chord from the start point to the point 10 viewBox units along the path, or to the end on shorter strokes. It does not use the first curve's control point. KanjiVG strokes open with a short brush-press tick, so the first tangent falls outside the expected range for the stroke's `kvg:type` on 2,318 of 78,596 strokes. Rising strokes (㇀) are the worst case: 1,758 of 1,821 have a first tangent outside the rising range. In 2,311 of those 2,318 strokes the 10-unit chord lands in range, and the first curve segment there has a median length of 4.0 units, so 10 units clears the tick.
- The 10-unit chord misses on 15 strokes. Checked against every part of a composite label (such as ㇀/㇏), 10 remain. Each is a stroke whose label doesn't fit its drawn shape (for example 邨 s1, labelled ㇒ but drawn as a left-to-right horizontal). All 10 run the same way in animCJK, and 9 of the 10 arrows agree within 45°. The tenth, 輾 s15, is 49° off. The chord follows the drawn stroke.
- Chords at 6 units, 15 units and 20% of length scored 24, 16 and 26 misses.
- Against animCJK, 246 of 253 arrows agree within 45°. The other 7 (大 s2, 手 s1, 水 s3, 湃 s3, 湃 s4, 羸 s1, 輾 s15) are 46° to 68° off, and all 7 still run the same way. The check does not measure why they differ. On these strokes the arrow can sit up to 68° off another dataset's first direction, but it never points backwards.
- Ticket 099 stores the start point and this unit vector as tested values beside each `Path`.

**Which strokes.** Every cell shows the dot and the arrow on its current stroke only. The prototype (`098-direction-prototype.html`, screenshot `098-direction-prototype.png`) compared four options on 十 水 以 心 鬱 議 九 手 on a 136 pt drawing square (each SVG is 136 px wide plus 12 px of CSS padding), in light and dark. These were dot only, dot with a chevron on the stroke, dot with an arrow beside the stroke, and arrows on every stroke. Arrows on every stroke turned 鬱 and 議 into noise. A chevron on the stroke was too small to read and broke up the ink line. The arrow beside the stroke read clearly. A dot alone leaves rising strokes such as 以 s2 and short dots such as 心 s1 ambiguous.

**Short strokes.** `098-short-stroke-row.mjs` renders the arrow-beside option at the app's 136 pt drawing size on the shortest strokes: 鹽 s16 (3.99 units, the dataset's shortest), 鬱 s19 to s22 (4.7 to 6.5 units; s22 is the second shortest), 議 s1 (10.8), 心 s3 (15.3), with 十 s2 (88.3) for comparison. The screenshot is `098-short-stroke-row.png`. Dataset strokes have a 5th percentile of 12.0 units and a median of 32.5. Only 鹽 s16 is shorter than 4.7 units, and 23 strokes are shorter than 6.
- The arrow reads at every one of these lengths and points the right way. That covers the whole dataset's range, from its shortest stroke up, so strokes of every length get the arrow.
- With the markers drawn above the current stroke, the dot's halo (radius 6) covered most of every stroke under 6 units and all of 鬱 s22. The cell then hid the stroke it was meant to show.
- So the current stroke draws above the dot. The dot reads as a vermilion ring about 2.5 units wide around the stroke's start, and the whole stroke stays visible at every length. On 十 s2 the ring still marks the start clearly.

**Colour.** `.nichijiVermilion` (`ColorTokens.swift:22`), an existing token, is the "red dot" the user suggested. It measures 4.64:1 on `.nichijiSurfaceSunken` (`ColorTokens.swift:12`) in light (`#b8321d` on `#eae2d1`) and 5.71:1 in dark (`#e8603f` on `#0f0d0a`). It only reaches 2.86:1 against the `.nichijiInk` stroke and 1.22:1 against `.nichijiInkMuted` (`ColorTokens.swift:15-16`). So the dot and the arrow each get a `.nichijiSurfaceSunken` halo, which separates them from the other strokes beneath (13.3:1 in light, 15.9:1 in dark against ink). Where the current stroke crosses the dot, the stroke stays legible against the sunken surface beyond the ring, so the ink-on-vermilion edge carries no meaning on its own. The colour tokens in `ColorTokens.swift` have no Increase Contrast variants, and vermilion does not reach 7:1 in light mode. That gap covers the whole palette, not only this marker.

**Size.** Sizes are in KanjiVG's 109-unit viewBox (`StrokePathParser.viewBoxSize`, `StrokeOrderCardView.swift:106`), so they scale with the cell. The cell width comes from the screen width minus the card's 16 pt horizontal padding (`StrokeOrderCardView.swift:71`), the `KanjiCard` 16 pt padding (`KanjiCard.swift:16`), the 8 pt gap between two grid columns (`StrokeOrderCardView.swift:42`) and the cell's own 12 pt padding (`StrokeOrderCardView.swift:92`). On Today and Kanji detail the card sits straight in a `ScrollView` with no other horizontal padding (`TodayView.swift:125`, `KanjiDetailView.swift:82`). That gives a 136.5 pt drawing square on a 393 pt iPhone, about 1.25 pt per unit, and 127.5 pt (1.17 per unit) on a 375 pt one. In the Practice sheet the card gets another 8 pt each side (`PracticeSheet.swift:61`), so the square is 128.5 pt (1.18 per unit) on a 393 pt iPhone and 119.5 pt (1.10) on a 375 pt one.
- Dot: radius 4.5 (about 11 pt across, a little over twice the 4-unit stroke from `StrokeOrderCardView.swift:107`), centred on the start point.
- Dot halo: out to radius 6.
- Arrow: an 11-unit shaft ending in a chevron, with 4-unit arms at ±43°, line width 1.8 and round caps.
- Arrow halo: 1.5 units each side, the same width as the dot halo.
- Arrow position: parallel to the direction vector, 8 units off the start point to the left of travel (above a stroke heading right, to the right of a stroke heading down), and starting 2 units ahead of the start point.
- Draw order: other strokes, then the dot halo and the dot, then the current stroke (which ticket 097 moves above the other strokes), then the arrow halo and the arrow.

**Practice pad guide.** No dot. The guide is the `.kanjiGuide` font glyph (`PracticeSheet.swift:156`), not the KanjiVG paths, so a path-based dot would sit off the glyph's strokes. The pad is also a free recorder, with the stroke order card below it at the large detent. Reversing this means drawing the guide from paths first, which costs more than the other reversals.

**Stroke player (ticket 100).** Build the dot and the arrow as one shared marker drawn from the start point and the direction, so the player can reuse it for the stroke about to animate. Ticket 100's grilling decides when the marker shows.

**VoiceOver.** The markers stay inside each cell's single accessibility element (`StrokeOrderCardView.swift:45-46`). The cell label adds the starting direction in one of eight words: "Stroke 2 of 4, starts going down". The word comes from the same direction vector.

Timing: wall 26m, active 25m, user 0s, wait 0s, blocked 0s | implement 7m, audit 13m (4 rounds), fix 3m | tools 102 (18 subagent) | limits 0, compactions 0, handoffs 1 | ctx peak 149k | cost $5.63 opus-5-5 + $0.09 haiku-5-5
