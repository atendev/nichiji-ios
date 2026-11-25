---
id: "096"
title: Decide what to do about the search index memory
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

The search index grows memory by 24.1 MB against a 20 MB budget. Do we accept it, raise the budget, or trim the index?

## Notes

Skills: `grilling`, `domain-modeling`. Surfaced by [Measure widget memory and the search index on a device](../closed/088-measure-widget-memory-and-search-index-on-a-device.md): build 292 ms, +24.1 MB on a device. The index lives only in the app, built on first Dictionary open, so the app's limit is far higher than a widget's. Weigh the cost of trimming (fewer folded fields, lazy word index) against keeping the 20 MB figure as a soft target. Update the budget wording in `docs` to match.

## Resolution

Accept the +24.1 MB. The index is app-only, built on first Dictionary open, and the app's memory limit is far above a widget's, so trimming (fewer folded fields, lazy word index) costs real work for no gain. The 20 MB figure becomes a soft target of about 25 MB, measured as `phys_footprint` growth on a device; 088 read `resident_size`, which is not what the system limit counts, and the CI runner reported +0.9 MB against +24.1 MB on the device, so the CI log line stays a smoke check only. Dictionary (`DictionaryView`) and the Known kanji picker (`KnownKanjiPickerView`) each build their own copy, so both open at once is about 48 MB; no sharing ticket is filed, and this is the lead if a device ever shows memory warnings on Dictionary search. Reopen only on such a warning. The budget wording is in `docs/DESIGN.md`.
