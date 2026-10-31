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
Includes draw to search only if the scope ticket put handwriting recognition in v1.0; otherwise it graduates as its own ticket.
Minor bump.

## Resolution

