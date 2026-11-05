---
id: "062"
title: Decide the Japanese localization
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

For the Japan release, which parts of Nichiji get a Japanese version in v1.0: the App Store listing, the app UI strings, the widget and notification copy, the paywall and in-app purchase name, and the support and privacy pages? Who is the Japanese-language user, given that kanji meanings and word glosses come from English KANJIDIC2 and JMdict data?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`, `unslop`.
Raised in [Write the App Store metadata](../closed/055-write-the-app-store-metadata.md), whose English copy is in [app-store-listing.md](../assets/app-store-listing.md): the user wants Nichiji released in Japan as well. That ticket writes an English (U.S.) listing and makes the app available in the Japan storefront. This ticket decides what gets translated, the language option (system language only, or an in-app switch), who translates and reviews, and whether any of it waits until after v1.0.
Facts to gather before grilling: how the app's strings are stored today (string literals or a string catalog), and whether `DATA-SOURCES.md` and the Sources screen need Japanese copy.
Blocks [Prepare the v1.0 release build](054-prepare-the-v1-release-build.md), because the localized strings and listing must be in that build. If this ticket moves the Japanese localization past v1.0, remove that blocker.

## Resolution
