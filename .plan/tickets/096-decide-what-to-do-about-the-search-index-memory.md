---
id: "096"
title: Decide what to do about the search index memory
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

The search index grows memory by 24.1 MB against a 20 MB budget. Do we accept it, raise the budget, or trim the index?

## Notes

Skills: `grilling`, `domain-modeling`. Surfaced by [Measure widget memory and the search index on a device](../closed/088-measure-widget-memory-and-search-index-on-a-device.md): build 292 ms, +24.1 MB on a device. The index lives only in the app, built on first Dictionary open, so the app's limit is far higher than a widget's. Weigh the cost of trimming (fewer folded fields, lazy word index) against keeping the 20 MB figure as a soft target. Update the budget wording in `docs` to match.

## Resolution

<Filled in at close: the decision and the reason for it.>
