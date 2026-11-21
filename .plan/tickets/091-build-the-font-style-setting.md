---
id: "091"
title: Build the font style setting and heavier English text
type: task
mode: AFK
status: open
blocked_by: ["090"]
claimed: true
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

<Filled in at close: the decision and the reason for it.>

## Handoff

Branch `t3/font-style-setting-heavier-english`, SHA in the `wip:` commit just before this section's commit. Audit round 0 (no council yet). Tag `wfm-nichiji-v1-091-1795266250`. Swift is not compiled here; CI is the first compile.

Done (wip commit):
- Fonts: `Fonts/ZenKakuGothicNew-Regular.ttf` is now the large subset (2,093,000 B, `glyphs-shippori.txt`), Medium 70,072 B and new Bold 69,476 B use `glyphs-zen.txt`. Built with fontTools in `/tmp/wf091/venv` (flags per README). `project.yml` lists Bold in both `UIAppFonts`. `Fonts/README.md` rewritten. The font lacks 46 kanji: 俠俱剝卽吞塡巢彐徵戶揭摑擊晚曆步歷每涉淚渴溫焰狀疒瘦禱禸簞緣繡繫萊蔣虛蟬蠟辵醬錄鍊頰顚鷗黃𠮟.
- `KanjiFontStyle` (serif default, gothic) and `kanjiFontStyle` key in `LearnerPreferences.swift`; `KanjiFontStyleStore` (`@Observable`, `shared`, `select`, `reload`) in `Models/`. Re-render works by Observation: tokens read `KanjiFontStyle.current` inside view bodies, so no root `id` and no lost navigation.
- `TypographyTokens.swift` rewritten: `InterfaceFace(weight:)`, `KanjiFontToken`, `Font.kanji(_:style:)`, style-aware `kanjiDisplay`/`kanjiGuide`; Title/Heading Bold, Body/Callout Medium, Caption Regular; clamp removed. Four call sites went `.bold` (You tiles 32, Review due count 64, level-complete figure, scan sheet heading).
- Settings: `KanjiStyleSettingsView.swift` (row, sub screen, shared cards). Onboarding: `KanjiStyleStepView`, `OnboardingStep.kanjiStyle` after Welcome, segments 7 to 8. Widget provider calls `KanjiFontStyleStore.shared.reload()`.

Left, in order:
1. Update `OnboardingFlowTests` (step test: 9 steps, 8 segments, `kanjiStyle` after `welcome`; rename "steps 1 to 7").
2. Extend `BundledFontsTests`: Bold registered; Zen Regular maps 直骨角; the 46 missing kanji pinned (check against `BundledKanjiContentStore().indexEntries()` ids; 𠮟 is a surrogate pair); default style serif; `LearnerPreferencesSnapshot` round-trip with `kanjiFontStyle` (extend `SettingsPreferencesTests`); each token equals `Font.custom(style.postScriptName, ...)`; `InterfaceFace(weight:)` mapping; `KanjiFontStyleStore` select persists to a suite and `withObservationTracking` on `Font.kanjiHero` fires on `shared.select` (serialized suite, restore serif).
3. `nichijiTypedBody` and `JapaneseTypesetting` use Regular, which now holds kanji; check they still work (Hiragino cascade stays).
4. Docs: `docs/DESIGN.md` font paragraph (line ~265), `docs/CHANGELOG.md` entry v0.39.0 (minor bump, "Not tagged"), `PROGRESS.md`/`IMPLOG.md` if the workflow needs it. Size totals: Fonts 4.25 MB before, about 6.3 MB now, in app and widget; Dataset Shared 5.34 MB of 8 MB, app set 17.6 MB of 24 MB (datasets only); fonts add about 6.3 MB to each bundle, so the app is about 23.9 MB with fonts counted, the widget about 11.7 MB. Report these and that the gothic Zen file fits (no system-font fallback needed).
5. Council audit (Claude seat only), decision report at `.plan/assets/091-build-the-font-style-setting-report.md` (unslop), commit, push, PR against `wayfinder/nichiji-v1-master` if the repo uses PRs, `wf-time.py close`, ticket resolution, delete this section.
