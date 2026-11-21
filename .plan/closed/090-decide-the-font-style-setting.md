---
id: "090"
title: Decide the font style setting
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

Which font styles can the learner choose between, where does the setting live, and what does each choice change across the app, the widgets and the Practice guide?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`, `unslop`.
Source: the user's feedback after the first TestFlight build with bundled fonts ([Check kanji glyphs outside the bundled fonts](067-check-kanji-glyphs-outside-the-bundled-fonts.md)). English text looks too thin, most of all the numbers on the You tab. The serif kanji (Shippori Mincho) is disliked. The user wants a setting that switches font styles.
Facts from the code:
- `TypographyTokens.swift` hard-codes Shippori Mincho Regular for every kanji style (`kanjiHero`, `kanjiHeroCompact`, `kanjiLarge`, `kanjiWidget`, `kanjiWord`, `kanjiDisplay(size:)`, `kanjiGuide(size:)`) and Zen Kaku Gothic New Regular or Medium for the interface styles.
- `Font.uiText(size:weight:)` clamps any weight above Medium to Medium, and the comment on the interface styles says "weights strictly <= 500". Only Regular and Medium are bundled, so a bolder English style needs new font files or a different font.
- Zen Kaku Gothic New is subset to Latin, kana and punctuation (`Fonts/glyphs-zen.txt`), so kanji in interface text come from the system font under the `japaneseTypesetting()` tag. A gothic kanji style needs either a new subset with kanji or the system Japanese font.
- Shippori Mincho is subset to every character in the dataset and is 4 MB. The app budget is 24 MB and the widget's is 8 MB shared, so a second kanji face has a size cost.
- The widget reads the same tokens through `Nichiji/DesignSystem/Tokens`, and settings reach it only through shared `UserDefaults` (the App Group), as the review preferences do.
- The Practice guide draws the kanji as a font glyph (`kanjiGuide(size:)`) under the learner's strokes. A gothic or system face changes the shape the learner traces, and it can differ from the KanjiVG stroke order diagram beside it.
Questions to grill:
1. Kanji: serif only, gothic only, or a choice? If a choice, which gothic (system Japanese font or a bundled face)?
2. English text: how much heavier, and for which styles (numbers only, body, everything)? One heavier weight for all, or a "Bolder text" switch?
3. Where the setting lives: Settings sheet, a new screen, or onboarding too? One switch or two (kanji style, text weight)?
4. Does the widget follow it, including the lock-screen widgets?
5. What the Practice guide shows when the kanji style is gothic: keep the serif guide, follow the setting, or draw it from the KanjiVG strokes?
6. Interaction with the system Bold Text and Dynamic Type settings.
7. Which tab or sheet carries the scope: is this v1.0 or after? The Review and Sources screens and the paywall all use the tokens.
Output: the options, the default, the setting's home, the widget rule and the Practice rule, written so a task ticket can build it.

## Resolution

Two kanji styles, serif and gothic, with serif the default, and heavier English text. The user dislikes the serif but keeps it as the default and asked for gothic as a second choice. Gothic is Zen Kaku Gothic New Regular bundled with kanji (about 2.1 MB, the same family as the English text), not the system Japanese font. The 46 kanji it lacks fall back to the system font. The size must be checked against the budgets before the build, and the system font is the fallback if it does not fit.

The learner picks in a new onboarding step right after Welcome (serif preselected), and in one compact Settings row that opens a sub screen with two cards. Learners who already finished onboarding keep serif. There is no separate weight setting.

The style changes only the big kanji displays (hero, large, tile, widget, word, Practice guide). Kanji inside interface text stay in the system Japanese font. The home-screen and lock-screen widgets follow the style. The Practice guide follows it too, since a gothic glyph has no serif feet and is closer to handwriting; the KanjiVG stroke diagram never changes.

English text gets Medium for body and Bold for numbers and headings, with a new Bold file of about 70 KB, and the "weights at most Medium" rule goes away. The thin numbers had one cause: `uiText` asked for Medium on the Regular file and SwiftUI cannot change a custom font's weight. A device check of the new weights is a TODO after the build. The iPhone's Bold Text setting is deferred to its own ticket.

This lands before the release build. Builds: [Build the font style setting and heavier English text](../tickets/091-build-the-font-style-setting.md), [Check the new fonts on a device](../tickets/093-check-the-new-fonts-on-a-device.md), and the deferred [Honour the iPhone's Bold Text setting](../tickets/092-honour-the-bold-text-setting.md).
