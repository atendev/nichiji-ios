---
id: "095"
title: Bring the widget peak memory under 30 MB
type: task
mode: HITL
status: open
blocked_by: []
claimed: true
---

## Question

What drives the widget's 35.5 MB peak, and what change brings it under about 30 MB?

## Notes

Skills: `tdd`, `unslop`. Surfaced by [Measure widget memory and the search index on a device](../closed/088-measure-widget-memory-and-search-index-on-a-device.md): peak 35.5 MB, last run 26.1 MB, on a device with the 6,407-kanji bundle. The widget reads index entries and decodes one record; the ticket 087 fallback is to read only the records it needs. Find the spike first (fonts, index load, record decode), then cut it. Re-measure with the memory probe (on `main`, gated to `DEBUG || DEV_UNLOCK`; Settings > MEASURE in a TestFlight Internal build) and record the new peak. When this ticket closes, remove the probe: follow the REMOVE note in `Nichiji/Widget/WidgetMemoryProbe.swift` (`grep -rn MEASURE-PROBE Nichiji NichijiWidget`). Also informs [Decide whether the Shared size budget counts fonts](094-decide-whether-the-shared-size-budget-counts-fonts.md).

## Resolution

<Filled in at close: the decision and the reason for it.>
