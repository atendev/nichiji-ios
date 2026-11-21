---
id: "067"
title: Check kanji glyphs outside the bundled fonts
type: task
mode: HITL
status: closed
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

Pass on every surface, after two fixes. The check ran on a phone with English as the only preferred language, on TestFlight builds from CI runs 44894835544 and 44898366184. The first pass ran with Japanese still in the phone's language list, which hides the bug, so it was repeated after removing it. 直, 骨 and 角 match the KanjiVG stroke diagrams on kanji detail, Practice and example words. Today, the Review tab and session, Dictionary browse, search results, the typed text in the search field, You, the home-screen widgets and the lock-screen widget all draw Japanese shapes. Sources has no Japanese text. Another app on the same phone (T3) draws the same three kanji with Chinese shapes, which is the bug the fix prevents.

The fix has three parts. Shippori Mincho Regular and Zen Kaku Gothic New Regular and Medium are bundled as subset files in the app and the widget extension, and `UIAppFonts` registers them in both. A shared `japaneseTypesetting()` modifier tags system-font text as Japanese at the app root and the widget root, so a new view can't miss it. The one UIKit-backed field, the Dictionary search bar, uses `Font.nichijiTypedBody`, whose fallback list names Hiragino Sans, because a text field takes its kanji fallback from the device language. `BundledFontsTests` fails when a face is not registered, since `Font.custom` falls back to the system font without a word, and checks typed kanji fall back to Hiragino Sans.

Notification banners are drawn by the system, so a Chinese shape there is a known limit, not a blocker. The Zen subset has no kanji, so adding a kanji to interface text goes through the system fallback. Council audit: round 3 APPROVE (claude 8) after gemini 8 and claude 7 in round 1; the user ran the claude seat alone because the other providers had no quota.

Shipped as v0.38.1, untagged. [Decide the font style setting](../tickets/090-decide-the-font-style-setting.md) takes the user's feedback on the serif kanji and thin English text.
