---
id: "067"
title: Check kanji glyphs outside the bundled fonts
type: task
mode: HITL
status: open
blocked_by: []
claimed: false
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
