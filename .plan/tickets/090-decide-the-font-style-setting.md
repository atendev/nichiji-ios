---
id: "090"
title: Decide the font style setting
type: grilling
mode: HITL
status: open
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

<Filled in at close: the decision and the reason for it.>
