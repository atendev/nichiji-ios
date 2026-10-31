---
id: "053"
title: Register the nichiji URL scheme
type: task
mode: AFK
status: closed
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

Yes in code, pending a device check. v0.9.3, patch.

- The Nichiji target gets an `info:` block in `project.yml` that writes `Config/Nichiji-Info.plist` with one `CFBundleURLTypes` entry (name `com.aten.nichiji`, scheme `nichiji`). Xcode merges the generated `INFOPLIST_KEY_*` values into that file, so the display name and launch screen keys stay. This corrects the earlier claim that registering would replace the generated plist ([Open Today from a widget tap](032-widget-deep-link-to-today.md)).
- `onOpenURL` and `AppDeepLink` are unchanged: the same path that serves the widget now serves Safari and Shortcuts. Before onboarding finishes the URL only opens the app.
- `AppDeepLinkTests.bundleRegistersScheme` checks the hosted app bundle. Nothing was built locally (Linux host). CI: pending; see Final Report.
- Left for a device check: typing `nichiji://today` in Safari and running it from a Shortcut, warm and cold launch. A missed cold-launch URL would need a new ticket.
