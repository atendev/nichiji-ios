---
id: "058"
title: Build the Pro purchase service and feature gating
type: task
mode: AFK
status: open
blocked_by: ["057"]
claimed: false
---

## Question

Does a StoreKit 2 purchase service unlock Pro on the device, restore it, survive relaunch and offline use, and gate every feature "Decide the free/Pro boundary, price and unlock flow" put behind Pro?

## Notes

Skills: `tdd`.
Phase 5 run. StoreKit 2 only, no server and no third-party SDK. Include a StoreKit configuration file for local runs and tests, entitlement caching that works offline, and a shared entitlement value the widget extension can read if lock-screen widgets are gated. Product details are manual App Store Connect work, which "Prepare the v1.0 release build" covers in its `wizard.sh`.
Gating is logic only here; the paywall and locked-state screens come from "Build the paywall and locked states".

## Resolution
