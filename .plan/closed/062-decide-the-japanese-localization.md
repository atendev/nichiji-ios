---
id: "062"
title: Decide the Japanese localization
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

For the Japan release, which parts of Nichiji get a Japanese version in v1.0: the App Store listing, the app UI strings, the widget and notification copy, the paywall and in-app purchase name, and the support and privacy pages? Who is the Japanese-language user, given that kanji meanings and word glosses come from English KANJIDIC2 and JMdict data?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`, `unslop`.
Raised in [Write the App Store metadata](../closed/055-write-the-app-store-metadata.md), whose English copy is in [app-store-listing.md](../assets/app-store-listing.md): the user wants Nichiji released in Japan as well. That ticket writes an English (U.S.) listing and makes the app available in the Japan storefront. This ticket decides what gets translated, the language option (system language only, or an in-app switch), who translates and reviews, and whether any of it waits until after v1.0.
Facts to gather before grilling: how the app's strings are stored today (string literals or a string catalog), and whether `DATA-SOURCES.md` and the Sources screen need Japanese copy.
Blocks [Prepare the v1.0 release build](../tickets/054-prepare-the-v1-release-build.md), because the localized strings and listing must be in that build. If this ticket moves the Japanese localization past v1.0, remove that blocker.

## Resolution

Settled on 2026-11-06 in an auto-mode grilling: a subagent answered three rounds of questions, and the user approved the answers. Glossary term added to `CONTEXT.md`: Learner. CI: pending; see the Final Report.

**Who the Japanese-language user is**

- An English-reading learner of Japanese who shops in the Japan storefront: someone living, studying or working in Japan, or anyone with a Japan Apple ID. They study from English meanings, and their phone may be set to English or Japanese.
- A native Japanese reader (a school child, or an adult relearning handwriting) is a non-goal. Serving them needs Japanese definitions, which KANJIDIC2 and JMdict don't have. That would be a different content source, not a translation.

**What ships in v1.0**

Nothing Japanese, and Japanese work never holds up v1.0. From v1.0 the Japan storefront will sell the English app to a learner who reads English. A missing translation costs little there, and holding the release would cost all of v1.0.

| Surface | Answer |
| --- | --- |
| App Store listing, ja localization | After v1.0. It needs a native writer, and a Japanese listing over an English app could mislead. |
| App UI strings | After v1.0 |
| Widget copy | After v1.0, with the UI strings |
| Notification copy | After v1.0, with the UI strings |
| Paywall copy | After v1.0, with the UI strings |
| "Nichiji Pro" ja display name and description (App Store Connect and `Config/Nichiji.storekit`) | After v1.0, with the listing |
| Support page | After v1.0 |
| Privacy page | After v1.0, with a reviewed translation, because it states legal commitments. This holds whatever [Find what ML Kit sends to Google](../tickets/064-find-what-ml-kit-sends-to-google.md) finds. |
| Sources screen title and back label | After v1.0, with the UI strings |
| Sources screen body and `DATA-SOURCES.md` | Not planned. It attributes English-language sources and licences, and a translation could misstate the terms. |

- The approved English (U.S.) listing and keywords stay unchanged.
- The v1.0 build declares English only, with no `ja` localization. The App Store lists English, and a phone set to Japanese shows the English UI.
- `CONTEXT.md`, not `DESIGN.md`, records the learner. `DESIGN.md` gets no change, since no language behaviour ships.

**Later Japanese work**

- Language choice: the system language, plus the per-app Language setting iOS shows once an app has two localizations. No in-app switch, which would add state, a restart path and a second source of truth.
- Translator and reviewer: not applicable for v1.0. The follow-up work names a native reviewer before any Japanese ships, and machine-only translation never ships. Hiring a reviewer is the user's spending call.
- Groundwork: the follow-up work starts by adding a string catalog with development region `en` and moving String-typed copy to `String(localized:)` or `LocalizedStringResource`. Today there is no catalog, no `.strings` or `.lproj` file, and no region in `project.yml`. `Text("literal")` strings extract on their own, but `YouCopy`, `AccessoryWidgetCopy`, `AddWidgetCopy`, `PaywallModel`, `ReminderPlanBuilder`, `SettingsProSection`, `HandwritingSearchEntry` and `DataSourcesDocument` hold String-typed copy. No v1.0 ticket and no map rule for new copy: the only open v1.0 build tickets add almost none.
- The order and the non-goal are in the map's Out of scope, so the next map starts from them. There is no deferred ticket, since it would sit on the frontier of a map it cannot finish.

**Blocking**

- The grilling surfaced one v1.0 bug. Without a Japanese language tag, iOS can draw Han characters with Chinese glyph shapes, and a kanji app would then teach wrong shapes. The bundled Shippori Mincho (kanji display) and Zen Kaku Gothic New (interface) fonts already give Japanese shapes, so the risk sits in system-font text. [Check kanji glyphs outside the bundled fonts](../tickets/067-check-kanji-glyphs-outside-the-bundled-fonts.md) checks it.
- [Prepare the v1.0 release build](../tickets/054-prepare-the-v1-release-build.md) is blocked by that ticket in place of this one.
