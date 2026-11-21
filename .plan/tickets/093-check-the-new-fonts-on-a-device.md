---
id: "093"
title: Check the new fonts on a device
type: task
mode: HITL
status: open
blocked_by: ["091"]
claimed: false
---

## Question

On a TestFlight build, does the heavier English text look right, and does each kanji style draw correctly on every surface?

## Notes

Skills: `apple`, `unslop`.
Needs a TestFlight build of [Build the font style setting and heavier English text](091-build-the-font-style-setting.md) (`gh workflow run ci.yml --ref <branch> -f testflight=true`, only on request). The user has no Mac, so this is an on-phone check with English as the only preferred language (Japanese removed from the language list, or the glyph shapes are hidden; see [Check kanji glyphs outside the bundled fonts](../closed/067-check-kanji-glyphs-outside-the-bundled-fonts.md)).
Check:
- The English text weight: the You tab numbers, the Review due count and session count, body text and headings. Too heavy, too light, or right.
- Both kanji styles, switched in Settings and chosen in onboarding, on Today, kanji detail, tiles, Review cards, Practice (guide and stroke diagram), the widgets (home and lock screen), and the search field.
- 直, 骨 and 角 still match the stroke diagrams in both styles.
- A fallback kanji from the 46 the gothic font lacks (for example 每 or 黃) in gothic draws in the system Japanese font and looks acceptable.
- The new size totals are inside the budgets.
Output: a pass or a list of fixes.

## Resolution

<Filled in at close: the decision and the reason for it.>
