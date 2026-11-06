---
id: "064"
title: Find what ML Kit sends to Google
type: research
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

What does ML Kit Digital Ink Recognition send to Google, can the app turn any of it off, and what App Store privacy label does it require in place of the approved "Data Not Collected"?

## Notes

Skills: `research`.
On device, the harness in [Choose the handwriting recognizer](../closed/060-choose-the-handwriting-recognizer.md) contacted dl.google.com once (model download), then play.googleapis.com and www.googleapis.com once each, a minute later. That is one logging contact per session; the App Privacy Report doesn't show what was sent.
Use Google's ML Kit privacy and data disclosure pages and the iOS SDK docs as primary sources. Check whether drawn ink or recognition results ever leave the device.
Output: what is sent and when, any opt-out, and the exact label answers for `.plan/assets/app-store-listing.md` and the App Store Connect questionnaire.
From [Build handwriting search](../closed/063-build-handwriting-search.md): the in-app privacy copy is yours too. Welcome says "No account needed. Nichiji does not collect any data." (`WelcomeView.swift`), and Settings says "Data not collected" (`SettingsSheet.swift`, `SettingsSupportViews.swift`) and "The app does not collect any data about you." Say whether each line still holds with ML Kit, and the replacement if not.

## Resolution

ML Kit Digital Ink keeps handwriting on the device (recognition is offline after the `ja` model downloads), but the iOS SDK sends Google diagnostics and usage analytics by default: device model, OS and available ML accelerators, bundle ID and app version, a per-install ID, latency, API configuration, event types, error codes and the `ja` language. Google documents no iOS opt-out, so "Data Not Collected" no longer holds. The label becomes Data Collected: Diagnostics (Performance Data, Other Diagnostic Data) plus Identifiers (Device ID, the cautious call), not used for tracking, purposes Analytics and App Functionality. Only removing ML Kit restores "Data Not Collected".

None of the five in-app privacy lines holds (`WelcomeView.swift:15`, `SettingsSheet.swift:262`, `SettingsSupportViews.swift:288/300/304`), and the privacy policy's "no analytics", the listing description and `DESIGN.md:16` are stale too. Replacements, the questionnaire rows and the unconfirmed points (Device ID and linkage calls, host-to-purpose mapping, ink never leaving the device, pod privacy manifests) are in [ml-kit-privacy.md](../assets/ml-kit-privacy.md). Nothing in the app was edited. Surfaced [Decide whether handwriting search keeps ML Kit](../tickets/068-decide-whether-handwriting-search-keeps-ml-kit.md) and [Update the privacy copy and label](../tickets/069-update-the-privacy-copy-and-label.md).
