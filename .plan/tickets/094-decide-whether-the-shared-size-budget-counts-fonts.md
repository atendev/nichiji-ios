---
id: "094"
title: Decide whether the Shared size budget counts fonts
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

Does the 8 MiB Shared (widget) budget count the bundled fonts, and if not, should the gothic kanji style ship Zen Kaku Gothic New with kanji instead of the Hiragino Sans fallback?

## Notes

Skills: `grilling`, `domain-modeling`. Facts from [Build the font style setting and heavier English text](../closed/091-build-the-font-style-setting.md):
- `tools/dataset/build.py` counts dataset files only: Shared 5.09 of 8 MiB, app set 16.80 of 24 MiB. Both hold.
- With fonts counted, the widget bundle was already 9.12 MiB before 091 (Shippori Mincho is bundled in the widget), so the 8 MiB figure was already over if fonts count. After 091 it is 9.18 MiB and the app is 20.90 MiB.
- Bundling the large Zen Kaku Gothic New Regular (about 2.09 MB) would take the widget to 11.11 MiB and the app to 22.83 MiB. 091 chose the ticket's fallback instead: gothic draws in the system Japanese font (Hiragino Sans W3).
- Decide what the budget means (dataset only, or everything in the widget), whether a real limit exists on widget memory or install size ([Measure widget memory and the search index on a device](088-measure-widget-memory-and-search-index-on-a-device.md) may inform this), and whether the gothic style should get the bundled Zen file after all. If it should, name the ticket that builds it. Update the budget wording in `tools/dataset/build.py` and `docs` to match.

## Resolution

<Filled in at close: the decision and the reason for it.>
