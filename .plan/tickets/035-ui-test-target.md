---
id: "035"
title: Keep or remove the UI test target
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

Should `NichijiUITests` become a real launch smoke test that runs in CI, or be removed?

## Notes

Skills: `grilling`, `unslop`.
The target holds one test that waits for a `"title"` label the app no longer has, and the `Nichiji` scheme's test action lists only `NichijiTests`, so it never runs.
Keeping it means fixing the test, adding the target to the scheme, and paying extra minutes on the `xcode-27` runner per CI run. Removing it deletes files, which needs your go-ahead either way.
The answer graduates one small task ticket.

## Resolution

