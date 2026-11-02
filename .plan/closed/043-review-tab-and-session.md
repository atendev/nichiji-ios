---
id: "043"
title: Build the Review tab and session
type: task
mode: AFK
status: closed
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

Yes. The Review tab replaces the placeholder in `MainTabView`. `ReviewView` builds a `ReviewHomeSummary` from the progress rows and the study log. It shows the due count, up to six tiles plus "+N", and "About N minutes" at 20 seconds a card, capped by the session size. Start review opens the session full screen, and a Session options link pushes `ReviewSettingsView`. Below sit stage counts with a bar, Coming up and This week. Coming up counts learning and familiar kanji due tomorrow, in 2 to 3 days, and in 4 to 7 days. This week dots mark days with a review answer in the log.

`ReviewSessionView` runs full screen. `ReviewSessionModel` starts the session through `ReviewService` and records each answer. The deck advances only after the card has flown off. `ReviewDeck` rotates card types through the enabled types in `allCases` order. It repeats a forgotten kanji once at the end when the setting is on, which grows the counter total. Summary counts use each kanji's first answer. The engine's `ReviewSession` verdicts keep a repeat from moving the schedule.

The speaker always speaks the reading. Autoplay on flip follows the audio setting. "Practice this kanji" opens the shared Practice sheet. A settings button in the session opens Review settings in a sheet; card types, example word, autoplay and repeats apply to cards not shown yet. Finishing, or closing after an answer, rebuilds reminders once.

Flip, tilt, swipe, badges and answer buttons now live in a shared `SwipeFlashcard`, which the onboarding demo uses too. Its swipe rules are pure and tested.

The "N DAY STREAK" subtitle waits for the stats service; a TODO in `ReviewView.swift` points at "Build the You tab". The design notes now list the session settings button.

CI: pending; see Final Report.

