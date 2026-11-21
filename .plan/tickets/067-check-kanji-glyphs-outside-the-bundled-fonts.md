---
id: "067"
title: Check kanji glyphs outside the bundled fonts
type: task
mode: HITL
status: open
blocked_by: []
claimed: true
---

## Question

On a simulator whose only preferred language is English, does every surface that shows Japanese text draw kanji with Japanese glyph shapes?

## Notes

Skills: `apple`, `unslop`.
From [Decide the Japanese localization](../closed/062-decide-the-japanese-localization.md): v1.0 ships English only. Without a Japanese language tag, iOS can draw Han characters with Chinese glyph shapes, and some kanji (直, 骨, 角) look visibly different. A phone set to Japanese hides the bug, so check with English as the only preferred language.
`TypographyTokens.swift` sets the kanji display styles to ShipporiMincho-Regular and the interface styles to ZenKakuGothicNew, both Japanese fonts. Text in those fonts is safe. The risk is Japanese text in a system font: `.font(.body)` or no font set, a `Text` that mixes kanji with system-font text, the search field's own typed text, and the widget extension.
- Confirm both fonts are in the widget extension's bundle and registered for it (`UIAppFonts` or the equivalent in `project.yml`). Check the home-screen and lock-screen widgets.
- Compare 直, 骨 and 角 on each surface: Today, kanji detail, example words, the Review session, Dictionary browse and search (results and the search field), Practice, You, Sources, and the widgets.
- Fix any wrong shape with the bundled font, or tag the text as Japanese through one shared modifier (for example `.typesettingLanguage`), so a new view can't miss it. The tag applies to a whole `Text`, so watch for kanji joined with English in one string.
- Notification banners are check-only, since the system draws them. A Chinese shape there is a known limit to record, not a blocker.
- Stroke-order and handwriting paths are drawn paths, not font glyphs, so they are out of the check.
Output: a pass or fix per surface, and the fix commit if any. The fix is agent work; the visual check needs a Mac with a simulator.

## Resolution

## Handoff

Branch `feature/bundle-japanese-fonts`, pushed. Four commits not on `main`: fonts and modifier (`0126cc55`), lint comma (`bd2d20a3`), `UIAppFonts` colon (`8b45587e`), search-field fix (`547b5dd4`). CI run 44898366184 green on `547b5dd4`, TestFlight build uploaded. Council audit approved: round 1 gemini 8, claude 7, gpt failed (no quota); rounds 2 and 3 claude only (user's call), round 3 APPROVE 8. Declined minor: the Zen subset note on the test (the test documents the current no-kanji subset).

Left, in order:
1. The user types 直, 骨 and 角 into the Dictionary search field on the new build, English only. If a shape is wrong, the cascade does not reach the field: try an explicit `UITextField` wrapper and rerun the claude seat.
2. Write the Resolution: pass on every surface checked on an English-only phone after bundling the fonts and adding the shared `japaneseTypesetting()` modifier at the app and widget roots; typed search text fixed with a Hiragino fallback list (`Font.nichijiTypedBody`) and checked on a device, or named unchecked; 骨 example words skipped by the user (same code path as 直 and 角, which were checked); Dictionary browse not checked on its own (same `KanjiGridTile` and font as search results); notification banners a known limit. v0.38.1, untagged.
3. Move this file to `closed/`, add one line to Decisions so far in `map.md`, take the ticket out of Frontier, delete this section. `wf-time.py` does not exist in the repo or `~/tools`, so the time close step was skipped.
4. Ticket 090 is created and in Frontier, not yet grilled.
5. Commit gate: merge `feature/bundle-japanese-fonts` to `main` or not. Tagging is the user's call.
