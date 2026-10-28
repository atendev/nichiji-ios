---
id: "017"
title: "Slice 5 Requirements Report: Japanese Pronunciation Audio"
type: grilling
mode: HITL
status: closed
blocked_by: ["016"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 5 (Japanese Pronunciation Audio) before creating the feature branch?

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/IMPLEMENTATION.md`, `Nichiji/Services/PronunciationService.swift`.

## Resolution

- **Slice Name**: `slice-5-japanese-pronunciation-audio`.
- **Success Criteria**:
  1. `AVSpeechPronunciationService` conforming to `@MainActor PronunciationService` and `AVSpeechSynthesizerDelegate`.
  2. Detection of installed `ja-JP` speech voices via `AVSpeechSynthesisVoice`.
  3. Kana-preferred utterance playback with speech rate calibrated for pronunciation study.
  4. Instant playback cancellation via `stop()`.
  5. Accurate tracking of `isSpeaking` state via synthesizer and delegate callbacks.
  6. Swift Testing suite in `PronunciationServiceTests.swift`.
- **Approved**: User approved Requirements Report on trunk; proceeding to feature branch implementation.
