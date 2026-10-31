---
id: "056"
title: Build the UI launch smoke test
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

Does `make test` — and CI — run a UI test that launches the app and finds the shared primary button on any first-screen state?

## Notes

Skills: `tdd`, `unslop`.
"Keep or remove the UI test target" kept the target as a launch smoke test. Replace the stale `"title"` wait in `NichijiUITests/NichijiUITests.swift` with an `app.buttons["primaryButton"]` existence assertion (the shared `PrimaryButton` carries that identifier on onboarding, Today, level-complete and retry screens, so launch state does not matter), and add `NichijiUITests` to the `Nichiji` scheme's build and test targets in `project.yml`. Watch CI for flake; the wait timeout is the flake control. The Resolution replaces the button-only check, because Today after Got it has no `PrimaryButton`.
Patch bump.

## Resolution

Yes. `testLaunchShowsPrimaryAction` replaces the stale `"title"` wait. It launches the app and asserts that some element with identifier `primaryButton` or label "Learned today" appears within 15 s. The label branch is there because once today's kanji is learned, Today shows the `SealStamp` instead of a `PrimaryButton`, so a button-only check would fail on a dev simulator. A fresh CI simulator opens on onboarding (`hasCompletedOnboarding` defaults to false), so CI covers only the button branch.

The `Nichiji` scheme now builds `NichijiUITests` for testing and lists it next to `NichijiTests`, so `make test` and CI run it. The 15 s timeout covers a cold simulator boot and is the flake control. v0.9.2. CI is pending; see the Final Report.
