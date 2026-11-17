# Decide the camera scan open questions: decision report

Ticket: `.plan/tickets/075-decide-the-camera-scan-open-questions.md` (grilling, auto mode).

## How it ran

The main thread asked the user the first three rounds (fifteen questions) with AskUserQuestion. The user picked the recommended option every time, then asked for auto mode. From there a grilling subagent (Sonnet) decided every question in two rounds: Q1 to Q11, then Q12 to Q16. Its picks match the user's earlier answers. The main thread added three HIG rules from the `apple` skill: box tap targets, the Reduce Motion path and VoiceOver announcements. The council audited the resolution.

## Decisions

Each entry gives the question, the options, the choice, and who made it.

1. **Where the camera lives.** Options: push onto the Dictionary stack and toggle the tab bar; keep a full-screen cover with no tab bar on the full grid; a cover that draws its own tab bar. **Push.** User and grilling subagent. The subagent added that peek, half and full must be a custom overlay, not a system `.sheet`, because a sheet covers the stack and blocks the detail push.
2. **Save to Photos.** Options: keep it with add-only access and new privacy copy; drop it. **Keep.** User and grilling subagent.
3. **Highlights after a Live Text read.** Options: hide Highlights; show it dimmed; draw partial Vision boxes. **Hide.** User and grilling subagent.
4. **Sweep against read time.** Options: loop until done; one pass, then wait; no sweep. **Loop until done**, with no line under Reduce Motion. User and grilling subagent.
5. **What "learned" means.** Options: any stage past new, known included; a third look for known; learning stays red. **Past new is green.** The toggle becomes "New only". User and grilling subagent. The council later asked for the wording to say that this is a scan-only label (see Audit).
6. **Missing states.** Options: reuse 074's copy; the same plus a blur hint; new copy in a design pass. **Reuse 074's copy.** User and grilling subagent.
7. **Tile meaning.** Options: first one or two meanings on one line; first meaning only; up to two lines. **First one or two, one line.** User and grilling subagent.
8. **Crop.** Options: the crop replaces the photo and rescans; read only the region; the crop plus undo. **Crop replaces the photo.** User and grilling subagent.
9. **Entry.** Options: both Pro with an unchanged look; a lock glyph; a PRO tag. **Unchanged look**, stacked at accessibility sizes. User and grilling subagent.
10. **Kanji only inside words.** Options: kanji tiles only; add a row of words. **Kanji only.** Word results go to Out of scope. User and grilling subagent.
11. **Vertical text.** Options: nothing special; a hint pill. **Nothing special.** User and grilling subagent.
12. **The saved image.** Options: the plain photo; the photo with boxes drawn in. **The plain photo** (the crop after Crop). User and grilling subagent.
13. **Save on a library photo.** Options: hide it unless cropped; always show it. **Hide unless cropped.** User and grilling subagent.
14. **Save with access off.** Options: a toast with Open Settings; hide Save. **Toast with Open Settings**, plus "The photo couldn't be saved." for write errors. User and grilling subagent.
15. **Leaving the scan.** Options: keep the stack across tab switches; reset it. **Keep it.** The camera session runs only while the viewfinder is on screen. User and grilling subagent.
16. **The "Scan results" back label.** Options: give the camera screen the navigation title "Scan results" with the bar hidden; a custom back button on detail. **The navigation title.** Check it on a device. Grilling subagent.
17. **HIG additions.** Box tap regions are at least 44 × 44 pt, and the nearest box wins where regions overlap. Reduce Motion crossfades. VoiceOver announces the found count and toasts. Main thread.

## Audit

Round 1: gemini APPROVE 10, gpt APPROVE 9, claude DISAPPROVE 6. The claude seat raised five problems:

- Blocking: counting known as learned conflicts with 065. Rebutted with `camera-design-notes.md:76` ("unseen vs learned or known") and fixed in the wording, which now says this is a scan-only label that leaves the You tab's split alone.
- Minor: the usage string says "never leaves", not "never saved". Fixed: the resolution quotes both strings as they read.
- Minor: this report did not exist yet. Fixed: it is written before round 2.
- Minor: kanji only inside words were left open. Fixed: each one gets its own tile and box.
- Minor: "Scan results" against the "Scan" header. Fixed: the header is drawn in the overlay, and "Scan results" is only the back label.

Round 2: claude APPROVE 9 and dropped all five problems. Round 3, the confirming round on the changed hunks: gemini APPROVE 10, gpt APPROVE 9. **COUNCIL APPROVE, round 3.** No minor problems were declined.

## Gates skipped

This run skips the runner's commit question, because the master's brief says to commit every time. It leaves `map.md` alone, and the master adds the Decisions line.
