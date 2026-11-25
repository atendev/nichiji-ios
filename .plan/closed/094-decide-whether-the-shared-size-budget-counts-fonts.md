---
id: "094"
title: Decide whether the Shared size budget counts fonts
type: grilling
mode: HITL
status: closed
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

The 8 MiB Shared budget and the 24 MiB app budget count generated dataset files only. They guard against accidental dataset growth and were never tied to a platform limit ([Add kanji beyond Jōyō](085-add-kanji-beyond-joyo.md)); a widget's real limit is runtime memory, which [Bring the widget peak memory under 30 MB](../tickets/095-bring-the-widget-peak-memory-under-30-mb.md) owns. Fonts and the total bundle are reported, not enforced: `tools/dataset/build.py` prints a "with fonts" line (widget 9.18 MiB, app 20.90 MiB at decision time), and the budget comments, error messages and `docs/DESIGN.md` now say "dataset". Gothic keeps the system Japanese font (Hiragino Sans W3) for v1.0 and no Zen Kaku Gothic New build ticket is filed: 095 is still chasing widget memory spikes, and [Check the new fonts on a device](../tickets/093-check-the-new-fonts-on-a-device.md) has not shown how the fallback looks. If 093 shows it looks bad, file a ticket then; it must re-measure widget memory with the probe.
