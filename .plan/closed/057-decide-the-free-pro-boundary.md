---
id: "057"
title: Decide the free/Pro boundary, price and unlock flow
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

Which features are free and which sit behind Pro, what does Pro cost, and how does a person meet, buy and restore it?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`.
Settled while grilling "Write the App Store metadata": freemium is in v1.0 scope, as a one-time Pro unlock (a non-consumable in-app purchase) built on StoreKit 2 directly, with no server and no third-party purchase SDK. The app keeps its "no accounts, analytics or backend" line.
Open here: which features are gated (the candidate split was free = Today, kanji detail, reminders, home widget, Dictionary browse and search; Pro = Review, Practice, You stats with CSV export, lock-screen widgets, and possibly Custom level pools); the price point and product name; whether there is a trial or preview; where the paywall appears; what a free person sees on a locked tab; restore and Family Sharing; and what happens to the daily habit if Pro is never bought. Resolve "Pro" as a glossary term in `CONTEXT.md`.
Unblocks the purchase service, the paywall screens and the App Store metadata.

## Resolution

Decided in grilling, with the user's explicit confirmation of each point:

- **Pro list:** lock-screen widgets, CSV export, photo lookup and handwriting search. Everything else is free: the whole You tab (streak, activity grid, milestones, By level, Needs attention, History), Today, kanji detail, reminders, the home widget, Dictionary browse and search, Review (Leitner), Practice, and Custom pools.
- **Price and name:** "Nichiji Pro", a one-time non-consumable at $4.99 USD, on StoreKit 2 with no server and no third-party purchase SDK.
- **Trial:** none. The free tier is the trial.
- **Paywall:** shown only where a Pro feature is tapped (the lock-screen widget option, the CSV export, and the two lookup entry points). Never on Today, in Settings, during onboarding, or on a timer.
- **Restore:** automatic on launch from StoreKit 2 entitlements, plus a Restore Purchases action in Settings. Family Sharing on.
- **Free loop:** complete without Pro, with no time limit, nag or review cap.
- **Dev unlock:** a hidden developer toggle compiled only into Debug and internal TestFlight builds, stripped from the App Store build, plus App Store Connect offer codes for gifting and promotion. No self-issued codes in any shipped build (App Review Guideline 3.1.1).
- **Scope change:** photo lookup and handwriting search move into v1.0. This reopens the handwriting exclusion in [Fix the v1.0 scope](closed/034-fix-the-v1-scope.md).
- **Value check:** ship with the four Pro items, then decide whether the $4.99 price holds after the on-device photo test, [Test photo lookup on real signage](../tickets/061-test-photo-lookup-on-real-signage.md).

Follow-up tickets: [Choose the handwriting recognizer](../tickets/060-choose-the-handwriting-recognizer.md) (prototype).

Glossary: "Pro" is in `CONTEXT.md` under Access.
