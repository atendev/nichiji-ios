# Decision report: Build the frozen photo, scan sweep and highlights

Version v0.28.0 (MINOR). Branch `t3/build-frozen-photo-highlights-1`, picked up from the `wip:` commit `efb991a`.

## Decisions

### 1. What happens to the results panel
- Question: Does the frozen shot keep the old results panel?
- Options: Remove it now. Keep it until the results sheet ticket.
- Choice: Keep it. It covers up to 55% of the photo.
- Made by: Implementer. The map says the results sheet is a later ticket, and photo lookup must keep working in between.
- Audit: No seat raised it.

### 2. Do boxes follow "New to you"?
- Question: Should the "New to you" filter hide boxes of started kanji?
- Options: Filter boxes. Show every box.
- Choice: Show every box. Red and green carry the new or started state, so hiding green boxes would lose information.
- Made by: Implementer.
- Audit: No seat raised it.

### 3. Where the line stops once results land
- Question: Does the sweep restart, or finish the pass in progress?
- Options: Restart a clean pass. Finish the pass in progress.
- Choice: Finish the pass in progress. Each box fades in as the line reaches it, and the line goes at the bottom. Map decision 075 says the sweep loops until the read is done.
- Made by: Implementer.
- Audit: No seat raised it.

### 4. Taps while sweeping
- Question: Can a box be tapped while the sweep runs?
- Options: Yes at once. No, wait until the sweep settles.
- Choice: Wait. Boxes are still fading in. A tap on the empty overlay and the VoiceOver action both honour this.
- Made by: Implementer.
- Audit: The claude seat found that the VoiceOver action skipped the guard. Fixed in round 2.

### 5. Crop and Save
- Question: Does this ticket build them?
- Choice: No. A code comment in `topBar` marks where they join Highlights. Their own tickets own the work.
- Made by: Implementer, from the ticket notes.

### 6. Highlights visibility
- Question: When does the option show?
- Choice: Only in the `.found` state after a Vision read with boxes (`hasBoxes`). Map decision 075: only Vision draws boxes.
- Made by: Implementer, from decisions 075 and 077.

### 7. X on the frozen shot
- Question: What does X at top left do?
- Choice: It calls `model.retake()` and returns to the camera, and its label changes to "Remove photo and go back to the camera". Live, it still closes the screen.
- Made by: Implementer.
- Audit: The claude seat asked whether a late read could overwrite state after a retake mid-read. Rebutted: `retake()` bumps `generation`, and the read drops its result on `guard mine == generation` (`PhotoLookupModel.swift:75,80`).

### 8. Tap targets
- Question: How do small boxes get a usable tap area?
- Choice: The tap region grows each box about its centre to at least 44 x 44 pt. Where regions overlap, the box the point is inside or nearest to wins, then the closest centre. One overlay takes the gesture, so the hit test is a pure function, covered by tests.
- Made by: Implementer.

### 9. File layout
- Choice: `PhotoLookupScreen` moved its helper views into an extension to stay under SwiftLint's type body length. Geometry, hit test and sweep clock live in `PhotoHighlights.swift` as pure types, so they are unit tested.
- Made by: Implementer.

## Audit

- Round 1: claude 7 (DISAPPROVE), gemini 10, gpt 9. The claude seat raised two problems. One was blocking: the VoiceOver action had no sweep guard. Fixed. The other was minor: a retake mid-read. Rebutted with the generation check.
- Round 2: claude 8, gemini 10, gpt 9. COUNCIL APPROVE.
- Declined minor problems: 1. The claude seat's round 2 note says it did not re-read the rebuttal files, since they sit outside the diff. Not a defect. The rebuttal's lines were checked directly.

## Gates and checks

- Test results: not run. The host is Linux with no Swift toolchain or SwiftLint, so CI is the build, lint and test check. The code was reread once for compile and lint risks: symbols and tokens exist, no line is over the 180 limit outside comments, and `PhotoLookupScreen.swift` is 383 lines against the 400 limit.
- Commit gate: committed with no question, per the master's brief. The master merges.
- Jev audit: skipped, per the master's brief.
- Needs a device: the sweep look, the box fade, taps on real Vision boxes and VoiceOver.
