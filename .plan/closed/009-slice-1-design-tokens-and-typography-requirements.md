---
id: "009"
title: "Slice 1 Requirements Report: Design Tokens & Typography"
type: grilling
mode: HITL
status: closed
blocked_by: ["008"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 1 (Design Tokens & Typography) before creating the feature branch?

## Notes

Skills: `apple`, `domain-modeling`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/design-system/tokens.json`, `docs/design-system/README.md`.

## Resolution

- **Slice Name**: `slice-1-design-tokens-and-typography`.
- **Success Criteria**:
  1. Full semantic color token palette matching `tokens.json` in Washi and Sumi modes with accessible contrast.
  2. Dynamic Type typography scale using Shippori Mincho and Zen Kaku Gothic New with system `.serif` and `.default` fallbacks, adhering to weight <= 500.
  3. Layout tokens establishing 8pt grid metrics, continuous corner radii, and a reusable `.minTouchTarget()` modifier enforcing Apple HIG 44x44 pt minimums.
  4. Swift Testing suite `DesignTokensTests` in `NichijiTests/Suites/` verifying tokens and invariants.
- **Scope Boundary**: Tokens, layout metrics, and unit tests in scope; custom view components (`HeaderBar`, `PrimaryButton`, `KanjiCard`, `SealStamp`) deferred to Slice 6.
- **Approved**: User gave explicit approval to proceed to implementation branch.
