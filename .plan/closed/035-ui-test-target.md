---
id: "035"
title: Keep or remove the UI test target
type: grilling
mode: HITL
status: closed
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

Keep. The target becomes a launch smoke test: launch the app and assert `app.buttons["primaryButton"]` exists within a timeout. The shared `PrimaryButton` carries that identifier on every first-screen state (onboarding steps, Today's Got it, level complete, retry), so the test is state-independent and stays low-flake. `NichijiUITests` gets added to the `Nichiji` scheme's build and test targets in `project.yml`, so `make test` and CI run it. The cost — simulator boot minutes on the `xcode-27` runner — is accepted: it guards crash-on-first-launch, the one failure class unit tests cannot see, through TestFlight. Graduates "Build the UI launch smoke test".

