# Decision report: Build the stroke player

Ticket 101, a task ticket. The design came from ticket 100, so this report lists only the choices made while building. Swift was not compiled and no tests ran, because the machine has no Xcode. The master runs CI on the merged batch. The audit was council-audit in single mode, with a Claude seat on Haiku. It approved in round 2 with a score of 8.

## Decisions

The main thread made each one unless it says otherwise.

1. **Playback state type.** Options were a class with a timer, a Combine publisher, or a plain value type like `PracticePad`. The choice is `StrokePlayback`, a `Sendable` struct with five phases (idle, drawing, resting, paused, finished). It takes stroke durations as input and moves on `advance(by:)`, so tests need no clock. The project sets no default actor isolation, so the struct and its members are nonisolated like `PracticePad`.
2. **Who drives time.** Options were `TimelineView(.animation)` or a `Task` loop. The choice is a `.task(id: playback.needsTicks)` loop on `ContinuousClock` that calls `advance(by:)` every 16 ms, or every 100 ms under Reduce Motion. `TimelineView` would mutate state from inside `body`. The loop ends when the sheet goes away or when time stops. The scene leaving `.active` pauses playback.
3. **Stroke length.** `StrokePathParser.length(of:)` walks `Path.forEach` and flattens each curve into 16 straight pieces. It lives in `StrokePlayback.swift` as an extension, so the file shared with ticket 099 gets no edit. Duration is length ÷ 100, clamped to 0.3 to 1.0 s, with an ease-in-out curve on the trim value.
4. **Pause and resume.** Pausing in a rest resumes the rest. Pausing mid-stroke keeps the stroke's progress. Play during a Next step turns it into continuous play.
5. **Next onto the last stroke.** The design says Next stops after the stroke it draws and is disabled once every stroke is drawn. It does not say what the last stroke looks like when reached by stepping. The choice is that the last stroke finishing by stepping goes straight to the finished state, with every stroke in ink. The other option leaves a paused last stroke and no way to reach the finished look except Play. In autoplay, the last stroke rests 0.35 s and then finishes.
6. **Previous.** It removes the stroke that is drawing, or else the last whole one. From a finished kanji it removes the last stroke. From stroke 1 it returns to the empty stage.
7. **Reduce Motion.** Durations count as 0, so a stroke appears whole on the next tick. Play shows one stroke every 0.8 s, Replay clears the stage and stays paused, and the sheet does not auto-start. `animates` is a property that the view sets from the environment, so the same value type serves both modes.
8. **Counter.** It reads "8 strokes" until a stroke starts, then "Stroke n of total". The total is `strokePaths.count`, as 100 decides. It also feeds the stage's VoiceOver value.
9. **Where the current stroke is drawn.** `StrokePlayerCanvas.drawCurrentStroke(in:index:path:fraction:style:)` is the single place. The context is already scaled to KanjiVG's 109-unit viewBox there, so ticket 099's start dot and arrow can draw from it. The player has no markers.
10. **Canvas isolation.** The drawing code is a nonisolated enum, not a method on the `View`, because the earlier batch failed when a helper on a `View` was main-actor isolated and `Canvas` called it.
11. **Entry points.** `StrokeOrderCardView` gets `onPlay` and a `StrokeOrderTitleRow` that puts a Play button at the trailing end, or under the title when it does not fit (`ViewThatFits`). The card edit is the new property, its init parameter, and one line in the body, to stay clear of 099's edits. Today and kanji detail pass `onPlay` and present the player. The Practice sheet header gets a `play.circle` button when the kanji has a stroke file, and it stacks the player on top. The card inside Practice passes no `onPlay`. A kanji with no stroke file gets no Play button anywhere.
12. **New files.** `project.yml` lists the `Nichiji` and `NichijiTests` folders as sources, so xcodegen picks up the new files without an edit.

## Audit

- Round 1, score 6, two blocking problems. (a) `trimmedPath(from:to:)` was given a `Double`. It compiles on Swift 5.5 and later, but the call now converts explicitly. Fixed. (b) `StrokePlayback` is not marked `nonisolated`. Rebutted: `project.yml` sets no default actor isolation, and `PracticePad` is a plain struct in the same position.
- Round 2, APPROVE, score 8, two minor problems, both declined.
  - The sheet's `init` parses the paths on every parent re-render. Declined: the parse takes microseconds, the sheet's parent seldom re-renders while it is open, and a lazy cache would add state for no visible gain.
  - Symbols outside the diff were not checked, and nothing was compiled. Declined: the main thread read each of them (`StrokePathParser.path(from:)`, `viewBoxSize`, `strokeWidth`, `PracticeControlStyle`, `minHitTarget`, `continuousCornerRadius`) in the repo before using it. The compile gap is real, so the report says it.

## Left for the master

- Wire 099's markers into `StrokePlayerCanvas.drawCurrentStroke` after both branches merge.
- Run CI on the merged batch. Nothing here has been compiled or run, so a compile error or a failing test is possible.
- The 8 to 13 second playback times in the design are formula estimates. Nobody has timed them on a device.
