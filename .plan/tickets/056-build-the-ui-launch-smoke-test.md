---
id: "056"
title: Build the UI launch smoke test
type: task
mode: AFK
status: open
blocked_by: []
claimed: false
---

## Question

Does `make test` — and CI — run a UI test that launches the app and finds the shared primary button on any first-screen state?

## Notes

Skills: `tdd`, `unslop`.
"Keep or remove the UI test target" kept the target as a launch smoke test. Replace the stale `"title"` wait in `NichijiUITests/NichijiUITests.swift` with an `app.buttons["primaryButton"]` existence assertion (the shared `PrimaryButton` carries that identifier on onboarding, Today, level-complete and retry screens, so launch state does not matter), and add `NichijiUITests` to the `Nichiji` scheme's build and test targets in `project.yml`. Watch CI for flake; the wait timeout is the flake control.
Patch bump.

## Resolution
