---
id: "068"
title: Decide whether handwriting search keeps ML Kit
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

Does v1.0 keep ML Kit for handwriting search and ship a "Data Collected" privacy label, or drop it for the KanjiVG matcher and keep "Data Not Collected"?

## Notes

Skills: `grilling` and `domain-modeling`.
From [Find what ML Kit sends to Google](../closed/064-find-what-ml-kit-sends-to-google.md): ML Kit sends Google diagnostics by default with no documented opt-out. See [ml-kit-privacy.md](../assets/ml-kit-privacy.md).
On the user's 104 drawings ML Kit scored 89.4% top-1 and 99.0% top-5, the matcher 79.8% and 92.3% ([Choose the handwriting recognizer](../closed/060-choose-the-handwriting-recognizer.md)). The listing and Pro copy lean on "Data Not Collected".
Weigh accuracy against the label, the listing's privacy promise and the extra SDK. Also decide whether to ask Google about an undocumented opt-out first.

## Resolution
