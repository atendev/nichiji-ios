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

Branch `feature/bundle-japanese-fonts`. Commits not on `main`: bundle fonts and typesetting modifier (`0126cc55`), lint comma (`bd2d20a3`), `UIAppFonts` colon (`8b45587e`), and a search-field fix (this session). The first TestFlight build passed the phone check on every surface except typed search text, which the user skipped. Council audit: round 1 gemini APPROVE 8, claude DISAPPROVE 7, gpt failed (no quota); the user said run the claude seat only from here. Both seats raised the unchecked typed search text, so it got a fix: `DictionarySearchBar` now uses `Font.nichijiTypedBody` (Zen Kaku Gothic New with a Hiragino Sans fallback list, `UIFont.nichijiTypedBody`), plus a `BundledFontsTests` case. CI and a new TestFlight build for it are the next step. Changelog entry v0.38.1 is written.

Left, in order:
1. Confirm CI is green on the fix, then the user checks typed 直, 骨 and 角 in the Dictionary search field on the new TestFlight build, English only. If a shape is wrong, the cascade does not reach the field: try an explicit `UITextField` wrapper.
2. Run the claude seat once more (round 3, cap 5) with the CI result. Rebuttals the seat has not yet accepted: browse tiles use the same `KanjiGridTile` and `kanjiDisplay` font as the verified search results; 骨 example words use the same tokens as the verified 直 and 角 ones; the Zen subset has no kanji (`Fonts/glyphs-zen.txt`).
3. Write the Resolution from this draft: pass on every surface checked on an English-only phone after bundling the fonts and adding the shared `japaneseTypesetting()` modifier at the app and widget roots; typed search text fixed with the Hiragino fallback list and checked on a device (or named unchecked); 骨 example words skipped by the user (same code path as 直 and 角); notification banners are a known limit. v0.38.1, untagged.
4. Move this file to `closed/`, add one line to Decisions so far in `map.md`, update Frontier, delete this section. `wf-time.py` does not exist in the repo or `~/tools`, so the time close step was skipped.
5. Ticket 090 (grilling): the user finds English text too thin (the You tab numbers), dislikes the serif kanji (Shippori Mincho) and wants a font style setting. Ask: kanji serif or gothic, text weight, where the setting lives, whether the widget follows it, what happens to the stroke guide in Practice. Note `Font.uiText` clamps weight to Medium and the interface fonts bundle only Regular and Medium.
6. Commit gate: commit and merge to `main`, commit only, or neither. Tagging is the user's call.

Read first: `.plan/map.md`, `Nichiji/DesignSystem/Tokens/TypographyTokens.swift`, `Nichiji/DesignSystem/Tokens/JapaneseTypesetting.swift`, `Fonts/README.md`.
