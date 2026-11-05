---
id: "055"
title: Write the App Store metadata
type: task
mode: HITL
status: closed
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

Settled in the 2026-11-05 grilling, round 1:
- Privacy label is final: "Data Not Collected". v1.0 has no analytics or crash reporting; the code has no networking.
- Tagline stays "One Kanji. One Day. Every Day.", matching the onboarding welcome screen.
- Subtitle: "Learn Japanese writing daily" if the name "Nichiji - Daily Kanji" is granted, else "Learn one kanji a day". A public search found no "Nichiji" app; reserving the name in App Store Connect confirms it.
- Pro features: the copy names all four. [Prepare the v1.0 release build](../tickets/054-prepare-the-v1-release-build.md) cuts any that did not ship.
- No price in the copy: "Nichiji Pro, a one-time purchase. No subscription."
- Support and privacy pages live in a new public repo `atendev/nichiji-site` (`atendev.github.io/nichiji-site`) with a dedicated support alias.
- Copyright: "© 2026 <legal name>", matching the seller name.
- Listing language: English (U.S.) for this ticket. The user wants a Japan release too, so the app is available in the Japan storefront and [Decide the Japanese localization](../tickets/062-decide-the-japanese-localization.md) decides the Japanese listing and app translation.
- Privacy manifest: a checklist item on the release build ticket, not its own ticket.

## Resolution

Yes for the text. The user approved every field in the 2026-11-05 grilling. Screenshots come later from the release build.

- The listing is in [app-store-listing.md](../assets/app-store-listing.md): name and fallback, subtitle, categories, 4+, keywords (97 of 100 characters, none repeating the name or subtitle), promotional text (159 of 170), the description, the in-app purchase strings ("Nichiji Pro", "Lock Screen widgets, export and lookup tools"), App Review notes and the screenshot list.
- The description leads with the tagline, says "unofficial estimate" for JLPT levels, gives no price ("a one-time purchase. No subscription."), lists all four Pro features, and ends with the EDRDG and KanjiVG attribution line. It says "spoken readings" because audio comes from on-device speech synthesis.
- The support page and the one-paragraph privacy policy are in [support-site.md](../assets/support-site.md). They will live in a new public repo `atendev/nichiji-site`, which the release wizard creates. Publishing stays a human step.
- The support email and the copyright holder's legal name stay as placeholders (`<support email>`, `<legal name>`) for the release wizard.
- The privacy label is "Data Not Collected". The app has no analytics, crash reporting or networking code.
- Handed to [Prepare the v1.0 release build](../tickets/054-prepare-the-v1-release-build.md): the privacy manifest, the screenshots, the placeholders, the site repo, Japan storefront availability, and cutting any Pro feature that did not ship from the description and review notes.
- New ticket: [Decide the Japanese localization](../tickets/062-decide-the-japanese-localization.md), because the user wants a Japan release.
