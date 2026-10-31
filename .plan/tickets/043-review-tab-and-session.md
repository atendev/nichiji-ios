---
id: "043"
title: Build the Review tab and session
type: task
mode: AFK
status: open
blocked_by: ["040", "041", "042"]
claimed: false
---

## Question

Can the learner see what is due, run a flashcard session, and finish on a summary, with answers updating progress?

## Notes

From "Build the review engine": drive sessions through `ReviewService` (`startSession`, `answer`), re-queue forgotten cards in the view when `repeatsForgotten` is on, and rebuild reminders when a session ends so the review-due copy stays current.

From "Build the Review settings screen": `ReviewSettingsView` is ready for Session options to push. The engine reads only `order` and `sessionSize`. This ticket is the first reader of `cardTypes` (rotate through the enabled types), `showsExampleWord`, `repeatsForgotten`, `autoplaysAudio` and `audioContent` (autoplay on flip; the speaker button always plays the reading).

Skills: `apple`, `unslop`.
Design: screens 39-42, `Review.dc.html`, `ReviewSession.dc.html`, and the Review section of `docs/ui-reference/design-notes.md`.

- Review home: due count with tiles, Start review, Session options (opens Review settings), stage counts, Coming up, This week dots.
- Session: a settings button inside the session (an open item in the design notes), full-screen cards, tap to flip, swipe or buttons after flipping, the onboarding flashcard tilt and colors (share code with `FlashcardDemoView`), progress bar, close, audio button, next card fades up, Reduce Motion respected.
- The answer side has "Practice this kanji", opening the Practice sheet.
- Summary: reviewed, got it, forgot. Repeat forgotten cards when the setting is on; per [the scheduling decision](../closed/039-review-scheduling-rules.md), only the first answer per kanji moves the schedule, and every answer logs.
- Replace the Review placeholder in `MainTabView`.

Minor bump.

## Resolution

