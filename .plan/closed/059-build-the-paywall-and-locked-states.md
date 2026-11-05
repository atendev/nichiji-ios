---
id: "059"
title: Build the paywall and locked states
type: task
mode: AFK
status: closed
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

Yes, in code. CI pending; see the Final Report.

- `PaywallView` is a sheet built from the existing design system, opened through `paywallSheet(feature:)` only when a locked Pro feature is tapped. It names the tapped feature, lists all four Pro features with that one first, says what stays free, and offers "Unlock for <price>" (StoreKit `displayPrice`), "Restore purchases" and a Family Sharing note. `PaywallModel` drives it over `ProAccessModel`: pending, unavailable product (with "Try again"), unverified and other failures each get a note, cancelled shows nothing, and the sheet closes once Pro unlocks.
- Entry points: History's locked "Export history" (`YouCopy.exportAction`), the widget guide's "Unlock lock screen widgets", and locked lock-screen widgets. Those now read "Nichiji Pro" / "Tap to unlock" and open `nichiji://pro`. `MainTabView` closes Settings first, then shows the paywall over Today, and skips it once Pro is unlocked. This replaces the read-only "a tap opens Today" rule from "Decide what the lock-screen widgets show" for locked families only. The user chose that after the requirements audit stopped on it; unlocked taps still open Today.
- Settings has a Nichiji Pro section: status, "Restore purchases" with its result, and a Debug-only "Developer unlock" toggle. It shows status only and never opens the paywall. The internal TestFlight dev unlock stays with "Prepare the v1.0 release build".
- Photo lookup and handwriting search have no entry points yet. The paywall already accepts their `ProFeature` cases, so their build tickets only need to set `paywallSheet(feature:)` when locked.
- A real purchase and the sheet's look still need a device or simulator check, since the StoreKit session tests are skipped in CI.
