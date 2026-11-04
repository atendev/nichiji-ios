---
id: "055"
title: Write the App Store metadata
type: task
mode: HITL
status: open
blocked_by: ["051", "052", "057", "058", "059"]
claimed: false
---

## Question

Is the App Store listing — name, subtitle, description, keywords, screenshots and privacy nutrition answers — written and approved?

## Notes

Skills: `unslop`, `apple`.
"Fix the v1.0 scope" put release work in v1.0. The agent drafts the listing copy and privacy answers from `DESIGN.md` (the tagline "One Kanji. One Day. Every Day." is still open to workshopping per the design notes); you approve. Screenshots come from a device run once the app is feature-complete.
No version bump of its own; it rides with the release build.

Settled while grilling (the listing must also describe the Pro in-app purchase once "Decide the free/Pro boundary, price and unlock flow" fixes it):
- Tagline stays in the promotional text and the description's first line. The subtitle is a plain descriptor of at most 30 characters, such as "Learn one kanji a day".
- Name: "Nichiji - Daily Kanji" if available in the store, else "Nichiji".
- Category: Education primary, Reference secondary. Age rating 4+.
- Price: free app with one non-consumable Pro in-app purchase (StoreKit 2, no server). The listing names the in-app purchase and the Pro features once the boundary ticket settles them.
- Privacy label: "Data Not Collected", provisional until the user confirms no analytics or crash reporting is planned. The user confirmed no third-party purchase SDK.
- Support and privacy-policy URLs: a GitHub Pages page under `atendev` with a one-paragraph policy and a support email. The agent drafts both pages.
- Screenshots: iPhone only at 6.9". Lead with Today, Kanji detail, Review session, Dictionary search, You tab and the lock-screen widget, plus the paywall. Light mode, with one dark shot. They come from a device run after the paywall ships.
- Honest claims: write "JLPT-level kanji (unofficial estimate)". End the description with the attribution line "Dictionary data: KANJIDIC2 / JMdict (EDRDG), stroke order: KanjiVG. Full credits in Settings > About > Sources."

## Resolution
