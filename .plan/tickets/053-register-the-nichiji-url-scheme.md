---
id: "053"
title: Register the nichiji URL scheme
type: task
mode: AFK
status: open
blocked_by: []
claimed: false
---

## Question

Does entering `nichiji://today` in Safari or a Shortcut open the app on Today, with the Settings sheet closed?

## Notes

Skills: `tdd`, `unslop`.
"Fix the v1.0 scope" put the scheme in. The widgets already deep-link to `nichiji://today` through `.widgetURL` without a registered scheme (see [Open Today from a widget tap](../closed/032-widget-deep-link-to-today.md)); this registers the scheme in `project.yml` and routes the URL through the same Today-selection path so Safari and Shortcuts reach it too.
Patch bump.

## Resolution
