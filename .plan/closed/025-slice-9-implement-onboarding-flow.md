---
id: "025"
title: "Implement Slice 9: Onboarding Flow"
type: task
mode: AFK
status: closed
blocked_by: ["024"]
claimed: false
---

## Question

Implement Slice 9 on feature branch `feature/slice-9-onboarding-flow`: add `OnboardingFlow`, build the seven onboarding steps and the `RootView` completion transition, extract the shared level-change helper from the Slice 8 level screens, add `OnboardingFlowTests.swift`, and write the Deviation Report.

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Source of truth: [Slice 9 Requirements Report](../closed/024-slice-9-onboarding-flow-requirements.md).
Follow `docs/workflow.md` slice execution steps. Run the Slice 8 tests after the helper extraction.

## Resolution

Implemented `OnboardingFlow`, the coordinator step bar with spring and Reduce Motion transitions, all seven step views, the `RootView` crossfade, and `OnboardingFlowTests` (8 tests). Extracted `LevelChangeCoordinator`, `LevelSelectionRow`, the level system switch, and `ReminderTimePicker` from Slice 8 so Settings and onboarding share them. The Deviation Report is in `docs/IMPLOG.md`. Xcode build and tests were not run because the tools are unavailable here. Waiting on diff approval and commit.
