---
id: "059"
title: Build the paywall and locked states
type: task
mode: AFK
status: open
blocked_by: ["057", "058"]
claimed: false
---

## Question

Do the paywall, the locked-feature screens and Restore Purchases run on the purchase service, in line with the decisions in "Decide the free/Pro boundary, price and unlock flow"?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Phase 5 run. The design comes from the boundary ticket; if it leaves a visual question open, add a prototype ticket first. Settings gets a Pro row and Restore Purchases. Copy goes through `unslop`. Update `DESIGN.md` and the UI reference only as the shipped app needs.
From "Build the Pro purchase service and feature gating": read `ProAccessModel` from the environment (`access`, `allows(_:)`, `productInfo()`, `purchase()`, `restorePurchases()`). Replace the minimal lock-screen placeholder (`AccessoryLockedWidgetView`) and make the locked History export open the paywall; both carry TODOs. Add the hidden dev-unlock toggle UI on `ProAccessModel.setDevUnlocked(_:)`, Debug only. Until this ships, the Debug dev unlock is the only way to unlock in the UI. Purchase can throw `PurchaseError.productUnavailable` or `.unverified`; the paywall needs copy for both.

## Resolution
