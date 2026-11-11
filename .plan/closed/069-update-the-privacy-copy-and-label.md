---
id: "069"
title: Update the privacy copy and label
type: task
mode: AFK
status: closed
blocked_by: ["068", "070"]
claimed: false
---

## Question

Which in-app lines, listing rows, policy text and docs change once the ML Kit decision is made, and are they all updated?

## Notes

Skills: `unslop`, `apple`.
[Decide whether handwriting search keeps ML Kit](../closed/068-decide-whether-handwriting-search-keeps-ml-kit.md) dropped ML Kit, so the replacements in [ml-kit-privacy.md](../assets/ml-kit-privacy.md) are not applied. The current lines stand: the five in-app lines, the listing's `Privacy label` row ("Data Not Collected") and description, and the privacy policy in `assets/support-site.md`. Once [Remove ML Kit from handwriting search](070-remove-ml-kit-from-handwriting-search.md) lands, check each line against the shipped app, confirm that no app text, listing text, policy text or doc still mentions ML Kit or Google, and fix any that does. `docs/DESIGN.md` belongs to the removal ticket.
This is a Phase 5 run. Repo text only: entering the label in App Store Connect belongs to [Prepare the v1.0 release build](054-prepare-the-v1-release-build.md).

## Resolution

No copy changes. With ML Kit removed, the five in-app lines (Settings > Privacy row and screen, Welcome footnote, You export note), the listing's `Privacy label` row ("Data Not Collected") and PRIVACY paragraph, and the privacy policy in `assets/support-site.md` all still match the shipped app: the matcher runs on device, nothing downloads, and the app has no SDK. A search of app code, listing, policy and live docs found no ML Kit, Google or CocoaPods mention except one stale comment in `DictionaryView.swift` about a model download, now reworded. History logs (`CHANGELOG.md`, `IMPLOG.md`) and closed tickets keep their ML Kit text as record. Entering the label in App Store Connect stays with [Prepare the v1.0 release build](054-prepare-the-v1-release-build.md). Version v0.24.7.
