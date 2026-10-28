---
id: "021"
title: "Slice 7 Deviation Report: Today Tab & Detail Flow"
type: implementation
status: closed
---

## Deviation Report

- **Deviations**: The app uses a no-op reminder scheduler until the reminder
  slice supplies the production notification implementation. Stroke SVG paths
  are rendered by the local KanjiVG path parser rather than a third-party
  renderer.
- **Unanticipated TODOs**: Reminder and WidgetKit refreshes remain deferred;
  foreground refresh only re-runs Today assignment resolution in this slice.
- **Test Results**: `git diff --check` passes. Apple build and test commands
  are unavailable in this environment, so Xcode validation remains pending.
