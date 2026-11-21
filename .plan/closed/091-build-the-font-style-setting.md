---
id: "091"
title: Build the font style setting and heavier English text
type: task
mode: AFK
status: closed
blocked_by: ["090"]
claimed: false
---

## Question

Can the app offer a serif or gothic kanji style, chosen in onboarding and in Settings, with heavier English text, the way [Decide the font style setting](../closed/090-decide-the-font-style-setting.md) decided?

## Notes

Skills: `apple`, `tdd`, `unslop`. Phase 5 run per `docs/workflow.md`. Pick the version bump at the run (a new setting is a minor bump). Swift is compiled only by CI, so the first CI run is the compile check.
Decisions to build (from 090):
- Two kanji styles. Serif (Shippori Mincho) is the default; gothic is Zen Kaku Gothic New Regular with kanji. Existing learners who finished onboarding get serif and change it in Settings.
- The style changes only the big kanji displays: `kanjiHero`, `kanjiHeroCompact`, `kanjiLarge`, `kanjiWidget`, `kanjiWord`, `kanjiDisplay(size:)` and the Practice guide `kanjiGuide(size:)`. Kanji inside interface text (the 辞書 and 今日 headers, example words in a line of text) stay as they are.
- The widgets follow the style, home screen and lock screen. The setting goes in the shared App Group `UserDefaults` (see `LearnerPreferences` and `ReviewPreferences`), and the app reloads the widget timelines when it changes.
- Settings gets one compact row (`Kanji style · Serif`, like the Review and Reminder rows) that opens a sub screen with two cards, each showing 直 in its style. No separate weight setting.
- Onboarding gets a step right after Welcome: 直 in both styles, serif preselected, Continue keeps the default. The step enum is in `OnboardingCoordinator.swift`, the steps in `Views/Onboarding/Steps`.
- English text: Medium for body and callout, Bold for the big numbers and headings. The "weights strictly <= 500" rule and the clamp in `Font.uiText(size:weight:)` go away. A new `ZenKakuGothicNew-Bold` file (about 70 KB, the interface subset) joins the bundle.
Facts the run needs:
- `uiText` asks for `.weight(.medium)` on `ZenKakuGothicNew-Regular`, and SwiftUI cannot change a custom font's weight, so the You tab numbers (`YouStatsSections.swift:23`, 32 pt), the Review due count (`ReviewHomeCards.swift:16`, 64 pt) and the session count draw in Regular. The fix is to pick the font file by weight.
- A measuring run found Zen Kaku Gothic New with every dataset character is about 2.09 MB (Regular), 2.06 MB (Medium) and 2.05 MB (Bold) after the repo's `pyftsubset` flags, and the interface subset (`Fonts/glyphs-zen.txt`) is about 70 KB per weight. The font lacks 46 rare or old-form kanji (俠俱剝卽吞塡巢彐徵戶揭摑擊晚曆步歷每涉淚渴溫焰狀疒瘦禱禸簞緣繡繫萊蔣虛蟬蠟辵醬錄鍊頰顚鷗黃𠮟); they fall back to the system Japanese font under the `japaneseTypesetting()` tag, and a test should pin the list.
- Two files cannot share a PostScript name, so the kanji-bearing Regular replaces the interface Regular: use the large subset for `ZenKakuGothicNew-Regular` and keep Medium and Bold as small subsets. Update `Fonts/README.md` and the glyph lists.
- The fonts are bundled in the app and again in the widget (`project.yml`), so the size cost shows up twice. Check the new total against the budgets (24 MB app, 8 MB Shared) before building. If it does not fit, fall back to the system Japanese font for the gothic style and say so in the report.
- Tokens are static `Font` values read in any view, so a style change must re-render the screens. The run decides how (an environment value or a root `id`) and tests it.
- Extend `BundledFontsTests`: Bold registered, Zen Regular maps 直, 骨 and 角, the missing-kanji list, the default style is serif, the preference round-trips, and each token picks the font for its style.
- `DictionarySearchBar` and `UIFont.nichijiTypedBody` use the interface font with a Hiragino fallback; keep them working with the new Regular.
- 44 pt tap targets and Dynamic Type on the new cards (`apple` skill).
Output: the code, the tests, a green CI run, the version bump and the new size totals. A device check follows in [Check the new fonts on a device](093-check-the-new-fonts-on-a-device.md).

## Resolution

The app now offers a serif or gothic kanji style, chosen in a new onboarding step after Welcome and in a Settings row and sub screen, with heavier English text. Serif is the default and existing learners keep it. The style changes the big kanji displays, the Practice guide and the home screen and lock screen widgets, and is stored in the App Group `UserDefaults` through `KanjiFontStyleStore`, an `@Observable` store the font tokens read, so views re-render without a root `id`. English text picks its font file by weight (`InterfaceFace`): Bold for titles, headings and big numbers, Medium for body and callout, with a new `ZenKakuGothicNew-Bold`. Version v0.39.0, not tagged.

Gothic draws in the system Japanese font (Hiragino Sans W3), not a bundled Zen Kaku Gothic New with kanji. With fonts counted, the large Zen file puts the widget bundle at 11.11 MiB (5.09 data plus 6.02 fonts) against the 8 MiB Shared budget, so the ticket's fallback applies. After it the widget is 9.18 MiB with fonts counted and the app set is 20.90 MiB (16.80 data plus 4.09 fonts). The widget was already 9.12 MiB with fonts counted before this ticket, and `tools/dataset/build.py` counts dataset files only (5.09 of 8 MiB and 16.80 of 24 MiB, both fine). Whether the 8 MiB Shared budget covers fonts is for the master to settle. CI is pending; the master runs it. Audit: Claude seats only, round 2 APPROVE 8, 8, 8. Report: [decision report](../assets/091-build-the-font-style-setting-report.md).

Timing: wall 11m, active 11m, user 0s, wait 0s, blocked 0s | implement 6m, audit 4m (2 rounds) | tools 95 (14 subagent) | limits 0, compactions 0, handoffs 1 | ctx peak 156k | cost $3.19 sonnet-5-5 + $0.08 haiku-5-5
