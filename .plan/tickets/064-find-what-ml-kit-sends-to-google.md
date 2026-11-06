---
id: "064"
title: Find what ML Kit sends to Google
type: research
mode: AFK
status: open
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

## Resolution
