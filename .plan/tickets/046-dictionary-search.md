---
id: "046"
title: Build Dictionary search
type: task
mode: AFK
status: open
blocked_by: ["044", "045"]
claimed: false
---

## Question

Does typing in the Dictionary search bar return the kanji and word results the search rules define, fast enough to update per keystroke?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Implement the rules from "Decide how Dictionary search matches and ranks". Matching and ranking are a pure, tested function; the view only renders. Results open kanji detail.
Draw to search is out of v1.0 ([Fix the v1.0 scope](../closed/034-fix-the-v1-scope.md)): the Dictionary ships without the button.
Minor bump.

## Resolution

