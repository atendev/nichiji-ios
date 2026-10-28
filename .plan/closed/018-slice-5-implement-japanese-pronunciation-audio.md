---
id: "018"
title: "Implement Slice 5: Japanese Pronunciation Audio"
type: task
mode: AFK
status: closed
blocked_by: ["017"]
claimed: false
---

## Question

Implement Slice 5 on feature branch `feat/slice-5-japanese-pronunciation-audio`: implement `AVSpeechPronunciationService`, delegate hooks, voice checks, write comprehensive tests in `PronunciationServiceTests.swift`, and write the Deviation Report.

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Source of truth: [Slice 5 Requirements Report](../closed/017-slice-5-japanese-pronunciation-audio-requirements.md).
Follow `docs/workflow.md` slice execution steps.

## Resolution

- Implemented `AVSpeechPronunciationService` in `Nichiji/Services/PronunciationService.swift` conforming to `@MainActor PronunciationService` and `AVSpeechSynthesizerDelegate`.
- Implemented `isJapaneseVoiceAvailable` detecting installed `ja-JP` speech voices via `AVSpeechSynthesisVoice`.
- Implemented `speak(_:reading:)` preferring kana reading with natural rate and throwing `NichijiError.speechUnavailable` when no voice is present.
- Implemented instant playback cancellation via `stop()`.
- Added unit tests in `NichijiTests/Suites/PronunciationServiceTests.swift`.
- Updated `docs/PROGRESS.md` marking Slice 5 `done`, logged reports in `docs/IMPLOG.md`, and bumped version to `v0.0.11` in `docs/CHANGELOG.md`.
