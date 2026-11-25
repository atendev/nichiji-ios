---
id: "100"
title: Design the stroke player
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

What do the stroke player's layout and controls look like, and where does it open from?

## Notes

Skills: `apple`, `grilling`, `unslop`. Already decided by the user:
- A "Play" option on both the stroke order card and the Practice sheet opens a player sheet laid out like the Practice sheet.
- The whole kanji sits faintly in the background, and each stroke animates over it, so the learner watches the kanji fill in.
- The learner can step through stroke by stroke.

Each stroke can animate along its KanjiVG path with `trim(from:to:)`. Draw the background from the same paths in a faint colour, not from a font glyph, so the strokes line up with it exactly. Still to decide:
- controls (play/pause, previous and next stroke, replay, scrub)
- whether playback runs all strokes automatically or waits at each step
- stroke speed, and whether it scales with stroke length
- the pause between strokes
- whether the direction markers from 098 appear
- Reduce Motion behaviour, such as showing each stroke whole instead of animating it
- sheet detents
- the Play button's placement and label on the card and in the Practice sheet header

Read `Nichiji/Views/Practice/PracticeSheet.swift` for the sheet it mirrors. Is this in v1.0 or after? The map's scope ticket (034) did not cover it.

## Resolution

The stroke player is in v1.0, built by [Build the stroke player](101-build-the-stroke-player.md). It is a sheet laid out like the Practice sheet. Playback starts on its own 0.4 s after the sheet opens, except under Reduce Motion. Each stroke draws on over a faint copy of the kanji drawn from the same KanjiVG paths, and Previous and Next step one stroke at a time. The user decided the entry points, the faint background and stepping. Auto mode settled the rest, and every item marked *(cheap to reverse)* changes one value or one view in 101 without touching the state type.

**Entry points**
- Stroke order card: a "Play" button with `play.fill` at the trailing end of the "Stroke order" title row, with at least a 44 × 44 pt hit area. Accessibility label "Play stroke order", hint "Draws each stroke in order". The full-width "Practice this kanji" button stays the card's main action at the bottom. A second full-width button would make every card taller, and a play control in the title row reads as "play this card". At accessibility text sizes the title row stacks, with the button under the title. *(cheap to reverse)*
- `StrokeOrderCardView` gains `onPlay: (() -> Void)?`, which works like `onPractice`: when it is nil the card has no Play button. Today and kanji detail pass it. The card inside the Practice sheet passes nil, because the sheet header already has Play.
- Practice sheet header: an icon-only `play.circle` button between the meaning and Done, 44 × 44 pt, accessibility label "Play stroke order". Icon-only, because the header already truncates the meaning to one line and a second text button would squeeze it further. The review answer side reaches the player through its Practice button and this header. *(cheap to reverse)*
- A kanji with no stroke file gets no Play button in either place, as 101 says.
- A `strokePlayerSheet(target: Binding<PracticeTarget?>)` presenter mirrors `practiceSheet(target:)` and reuses `PracticeTarget`. From the Practice sheet it stacks on top, so Done returns the learner to the pad.

**Layout** (top to bottom, the Practice sheet's metrics)
- Header: "Stroke order", the kanji and its first meaning, then Done. It uses the same fonts, top padding and 44 pt Done target as the shipped Practice header (`PracticeSheet.swift:78-102`), which also puts its title first with no divider. The player matches the shipped sheet, not the mockup.
- Margins: the player uses 16 pt side margins (`LayoutTokens.screenMarginCompact`) for the header, stage, counter and controls. This follows the HIG's iPhone margin that the user's `apple` rule requires. It is the one place where the player departs from the Practice sheet, which uses the app's 24 pt `screenMarginRegular`. Moving Practice and the rest of the app to 16 or 20 pt is an app-wide token change and outside this ticket. *(cheap to reverse)*
- Stage: the Practice pad's frame (square, `.nichijiSurface` fill, 8 pt continuous corners, `.nichijiBorderControl` border, dashed crosshair). Its side is the smallest of three values: the width inside the margins, 420 pt, and the sheet's height minus the fixed rows (header, counter, controls, spacing and insets, about 205 pt at the default text size). This keeps the controls on screen at the 0.7 detent on every iPhone. On an iPhone SE, 0.7 gives 467 pt, so the stage shrinks to about 262 pt. On an iPhone 16, 0.7 gives 596 pt, so the width limit of 361 pt applies instead. 101 reads the height from the sheet's `GeometryReader`. The strokes are scaled from KanjiVG's 109-unit viewBox with the card's 12 pt inset and `StrokePathParser.strokeWidth`, so the player matches the grid cells.
- Counter: in the Practice counter's place, `.nichijiCallout` monospaced digits in `.nichijiInkMuted`. It reads "8 strokes" before the first stroke starts and "Stroke 3 of 8" after that. The total is `strokePaths.count`, not `PracticeTarget.strokeCount`, because the 102 allow-listed kanji have counts that differ from their files. The card's grid labels already count this way ("Stroke n of \(paths.count)", `StrokeOrderCardView.swift:46`). The card's "N strokes" line above the grid uses `strokeCount`, so it can disagree with both for those kanji. That mismatch predates the player and is out of 101's scope.
- Controls: the Practice control row, described below.
- No stroke order grid. The learner came from the card, or from the Practice sheet with the grid right below, so a third copy adds nothing. *(cheap to reverse)*
- Detents `[.fraction(0.7), .large]` with the drag indicator, the same as Practice. Because the stage shrinks to fit (above), the whole player fits at 0.7 at the default text size. At large text sizes the fixed rows grow past what the height allows, so the content sits in a scroll view, and dragging to `.large` gives more room. *(cheap to reverse)*
- The sheet uses `.nichijiSurfaceRaised` and applies its own `preferredColorScheme`, like Practice.

**Colours.** The player uses the card's three tiers, so a paused stroke N looks like grid cell N once 097 lands, since 097 makes the card draw its current stroke last too. The whole kanji is drawn first in `.nichijiHairline`, earlier strokes are drawn in `.nichijiInkMuted`, and the current stroke is drawn last in `.nichijiInk`, following 097. Once the last stroke finishes, every stroke turns `.nichijiInk`, so the learner sees the finished kanji. *(cheap to reverse)*

**Controls.** The row is laid out like Practice's: a leading group of Previous (`chevron.backward`), Play/Pause (`play.fill` / `pause.fill`) and Next (`chevron.forward`), a spacer, then a trailing "Replay" text button with `arrow.counterclockwise`. All of them use `PracticeControlStyle`. The icon-only buttons add `minWidth: 44`, because the style's 12 pt padding around a 17 pt symbol only reaches about 41 pt. Accessibility labels: "Previous stroke", "Play" or "Pause", "Next stroke", "Replay from the first stroke".
- Play runs every remaining stroke automatically. At the end it changes to Play again, and tapping it replays from the start. Stepping is still possible because any step pauses playback.
- Next pauses playback. If a stroke is drawing, it completes that stroke at once. If not, it draws the next stroke with its animation and stops. It is disabled when every stroke is drawn.
- Previous pauses playback, removes the current stroke and makes the stroke before it current, shown whole. There is no reverse animation. From stroke 1 it goes back to the empty stage. It is disabled there.
- Replay clears the stage and plays from the first stroke. It is disabled only on the empty stage while paused.
- No scrubber. Previous and Next already give stroke-level control, and a horizontal slider in a sheet fights the drag-to-dismiss gesture and adds a second way to do the same thing. *(cheap to reverse)*
- No tap-to-pause on the stage, so there is no hidden gesture. *(cheap to reverse)*

**Timing**
- Outside Reduce Motion, the sheet starts playing 0.4 s after it opens, which gives the 0.35 s sheet presentation time to finish. The learner tapped Play to get here, so starting playback for them is what they asked for. *(cheap to reverse)*
- Stroke duration scales with length: length ÷ 100 viewBox units per second, clamped to 0.3 to 1.0 s, with an ease-in-out curve on the `trim(from: 0, to: progress)` value. A dot-like stroke stays visible, and a long sweep still reads as one motion. *(cheap to reverse)*
- A 0.35 s rest comes between strokes, with the same rest before the finished state. By the formula, a 10-stroke kanji takes 6.5 to 13.5 s, and 7.5 to 9.5 s if every stroke is 40 to 60 units long. These figures come from the formula and were not timed on a device. *(cheap to reverse)*
- There is no speed setting in v1.0. *(cheap to reverse)*
- Stroke length is a tested value worked out next to `StrokePathParser`, by flattening each curve, like 099's start point. The view never measures a `Path`.

**Reduce Motion.** `docs/ui-reference/design-notes.md:14` says "All motion is disabled under reduced-motion", and the app snaps instead of animating (the Practice guide toggle drops its animation). The player follows that rule:
- Nothing draws on. A stroke appears whole with no fade.
- The sheet does not start playing by itself. It opens on the empty stage with the faint kanji, and the counter reads "8 strokes".
- Previous, Next and Replay work as in the default mode, with whole strokes. Replay clears the stage and stays paused.
- Play shows one whole stroke every 0.8 s until the learner pauses it or the kanji is finished. Nothing moves across the screen. The timer only changes which strokes are inked, and it runs only after the learner asks for it. If the user reads the rule as covering this too, Play shows one stroke per tap instead. *(cheap to reverse)*

**Direction markers.** The player designs no markers of its own. It draws whatever [Decide how stroke order shows direction](098-decide-how-stroke-order-shows-direction.md) chooses for the card's current stroke, on the player's current stroke, and follows 098's rule for when the markers show. If 098 picks no markers, the player has none. Whichever of 099 and 101 merges second wires the markers into the player, so neither build waits for the other.

**Playback state and lifecycle.** For 101 to build: a value type like `PracticePad` holds `strokeCount`, `completed` (strokes fully shown), `progress` (0 to 1 of the stroke drawing) and the phase (idle, drawing, resting, paused, finished). It offers `play`, `pause`, `next`, `previous`, `replay` and `advance(by: TimeInterval)` and takes the stroke durations as input, so tests need no clock. The view drives `advance` from `TimelineView(.animation(paused:))` while playing. Playback pauses when the scene leaves `.active` and stops when the sheet is dismissed. The stage is one VoiceOver element, "Stroke order player", whose value matches the counter. The counter itself is hidden from VoiceOver, as in Practice. There are no haptics.

**Scope.** This is in v1.0. The map's stroke order stage (11) includes the player, and 101 already sits on the map to build it. 034 predates the request and did not exclude it.

Surfaced nothing new. 101 covers the build. The marker hand-off between 099 and 101 is a note for those two tickets, not a ticket of its own.

Timing: wall 11m, active 11m, user 0s, wait 0s, blocked 0s | grill 2m, audit 8m (4 rounds), gate 31s | tools 46 (17 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 133k | cost $2.17 opus-5-5 + $0.06 haiku-5-5
