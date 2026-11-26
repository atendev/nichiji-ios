---
id: "093"
title: Check the new fonts on a device
type: task
mode: HITL
status: closed
blocked_by: ["091"]
claimed: false
---

## Question

On a TestFlight build, does the heavier English text look right, and does each kanji style draw correctly on every surface?

## Notes

Skills: `apple`, `unslop`.
Needs a TestFlight build of [Build the font style setting and heavier English text](091-build-the-font-style-setting.md) (`gh workflow run ci.yml --ref <branch> -f testflight=true`, only on request). The user has no Mac, so this is an on-phone check with English as the only preferred language (Japanese removed from the language list, or the glyph shapes are hidden; see [Check kanji glyphs outside the bundled fonts](067-check-kanji-glyphs-outside-the-bundled-fonts.md)).
Check:
- The English text weight: the You tab numbers, the Review due count and session count, body text and headings. Too heavy, too light, or right.
- Both kanji styles, switched in Settings and chosen in onboarding, on Today, kanji detail, tiles, Review cards, Practice (guide and stroke diagram), the widgets (home and lock screen), and the search field.
- 直, 骨 and 角 still match the stroke diagrams in both styles.
- A fallback kanji from the 46 the gothic font lacks (for example 每 or 黃) in gothic draws in the system Japanese font and looks acceptable.
- The new size totals are inside the budgets. Gothic ships as the system Japanese font (Hiragino Sans W3), not bundled Zen Kaku Gothic New, per the 091 resolution; judge how gothic looks as that fallback, and see [Decide whether the Shared size budget counts fonts](094-decide-whether-the-shared-size-budget-counts-fonts.md).
- Bold Text ([Honour the iPhone's Bold Text setting](092-honour-the-bold-text-setting.md)): with Settings > Accessibility > Display & Text Size > Bold Text on, interface text steps one weight up in the app and the widgets. Toggle it with the app closed, then open the home screen: the widget should redraw bold. Dynamic Type still scales with the heavier faces, and the search field keeps its Zen face. The widget modifier (`WidgetBoldTextModifier`, sets the store while its body runs) has no unit test: two `ImageRenderer` attempts in CI never saw Bold Text turn on, so only a device can show the widget honours it.
Output: a pass or a list of fixes.

## Resolution

Pass, no fixes. The user checked the TestFlight build from CI run 45536104929 (commit 5520004b) on an iPhone with English as the only language. Every item on the checklist passed:

- English weight is right on the You tab numbers, the Review due and session counts, body text and headings.
- Serif and gothic both draw right, whether switched in Settings or picked in onboarding, on Today, kanji detail, tiles, Review cards, Practice (guide and stroke diagram), the home and lock screen widgets, and the search field. 直, 骨 and 角 match their stroke diagrams in both styles.
- Gothic draws in the system Japanese font (Hiragino Sans), and the fallback kanji 每 and 黃 look acceptable.
- With Bold Text on, app text steps one weight up, the widgets redraw bold after a toggle with the app closed, Dynamic Type still scales, and the search field keeps its Zen face. That covers the widget case the CI tests could not reach.
- Sizes are inside the budgets: the Shared dataset is 5.09 of 8 MiB and the app dataset is 16.80 of 24 MiB. Fonts add 4.09 MiB on top, which is reported but not budgeted.

Since that build, `main` has only removed the widget memory probe and added a size line to `build.py`, so the result applies to current `main`. Decision report: [093 report](../assets/093-check-the-new-fonts-on-a-device-report.md).

Timing: wall 6m, active 2m, user 3m, wait 0s, blocked 0s | implement 4m, audit 1m (2 rounds) | tools 40 (4 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 84k | cost $0.93 sonnet-5-5 + $0.01 haiku-5-5
