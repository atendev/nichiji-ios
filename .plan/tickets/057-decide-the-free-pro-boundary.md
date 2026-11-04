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
