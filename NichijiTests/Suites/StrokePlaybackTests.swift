import CoreGraphics
import Testing
@testable import Nichiji

/*----------------------------playback-tests-----------------------------*/

@Suite("Stroke Playback Tests")
struct StrokePlaybackTests {
    // Three strokes of 1 s each. A rest takes 0.35 s, or 0.8 s when the playback does not animate.
    private func make(strokes: Int = 3, duration: TimeInterval = 1) -> StrokePlayback {
        StrokePlayback(durations: Array(repeating: duration, count: strokes))
    }

    @Test("A new playback is idle with nothing drawn")
    func newPlaybackIsIdle() {
        let playback = make()
        #expect(playback.phase == .idle)
        #expect(playback.completed == 0)
        #expect(playback.currentStrokeIndex == nil)
        #expect(playback.counterLabel == "3 strokes")
        #expect(!playback.canPrevious)
        #expect(!playback.canReplay)
        #expect(playback.canNext)
        #expect(playback.canPlay)
    }

    @Test("Time does nothing until Play")
    func advanceIdleDoesNothing() {
        var playback = make()
        playback.advance(by: 5)
        #expect(playback == make())
    }

    @Test("Play draws the first stroke over its duration")
    func playDrawsFirstStroke() {
        var playback = make()
        playback.play()
        playback.advance(by: 0.5)

        #expect(playback.phase == .drawing)
        #expect(playback.isPlaying)
        #expect(playback.progress == 0.5)
        #expect(playback.currentStrokeIndex == 0)
        #expect(playback.counterLabel == "Stroke 1 of 3")
        #expect(playback.fraction(ofStroke: 0) == 0.5)
        #expect(playback.fraction(ofStroke: 1) == 0)
    }

    @Test("A finished stroke rests, then the next one starts")
    func restBetweenStrokes() {
        var playback = make()
        playback.play()
        playback.advance(by: 1)
        #expect(playback.phase == .resting)
        #expect(playback.completed == 1)
        #expect(playback.currentStrokeIndex == 0)

        playback.advance(by: StrokePlayback.restInterval - 0.01)
        #expect(playback.phase == .resting)
        playback.advance(by: 0.02)
        #expect(playback.phase == .drawing)
        #expect(playback.progress > 0)
        #expect(playback.currentStrokeIndex == 1)
    }

    @Test("One long tick crosses several strokes and rests")
    func longTickCrossesBoundaries() {
        var playback = make()
        playback.play()
        playback.advance(by: 100)

        #expect(playback.phase == .finished)
        #expect(playback.completed == 3)
        #expect(playback.currentStrokeIndex == nil)
        #expect(!playback.isPlaying)
    }

    @Test("The kanji finishes after the last stroke and a rest")
    func finishesAfterRest() {
        var playback = make(strokes: 1)
        playback.play()
        playback.advance(by: 1)
        #expect(playback.phase == .resting)
        #expect(playback.counterLabel == "Stroke 1 of 1")

        playback.advance(by: StrokePlayback.restInterval)
        #expect(playback.phase == .finished)
        #expect(playback.fraction(ofStroke: 0) == 1)
    }

    @Test("Pause freezes the stroke mid-draw and Play carries on")
    func pauseAndResume() {
        var playback = make()
        playback.play()
        playback.advance(by: 0.25)
        playback.pause()
        playback.advance(by: 10)

        #expect(playback.phase == .paused)
        #expect(playback.progress == 0.25)
        #expect(!playback.needsTicks)

        playback.play()
        #expect(playback.phase == .drawing)
        playback.advance(by: 0.25)
        #expect(playback.progress == 0.5)
    }

    @Test("Pausing in a rest resumes the rest")
    func pauseInRest() {
        var playback = make()
        playback.play()
        playback.advance(by: 1.1)
        playback.pause()
        playback.play()
        #expect(playback.phase == .resting)
    }

    @Test("Next while a stroke draws completes it and pauses")
    func nextCompletesDrawingStroke() {
        var playback = make()
        playback.play()
        playback.advance(by: 0.4)
        playback.next()

        #expect(playback.phase == .paused)
        #expect(playback.completed == 1)
        #expect(playback.progress == 0)
        #expect(playback.currentStrokeIndex == 0)
        #expect(playback.fraction(ofStroke: 0) == 1)
    }

    @Test("Next from rest draws the next stroke with its animation, then stops")
    func nextDrawsOneStroke() {
        var playback = make()
        playback.next()
        #expect(playback.phase == .drawing)
        #expect(!playback.isPlaying)
        #expect(playback.needsTicks)

        playback.advance(by: 0.5)
        #expect(playback.progress == 0.5)
        playback.advance(by: 0.5)
        #expect(playback.phase == .paused)
        #expect(playback.completed == 1)
        #expect(!playback.needsTicks)
    }

    @Test("Play during a Next step carries on past that stroke")
    func playAfterNextStep() {
        var playback = make()
        playback.next()
        playback.play()
        #expect(playback.isPlaying)
        playback.advance(by: 1)
        #expect(playback.phase == .resting)
    }

    @Test("Stepping onto the last stroke finishes the kanji, and Next is then disabled")
    func nextOntoLastStroke() {
        var playback = make(strokes: 2)
        playback.next()
        playback.advance(by: 1)
        playback.next()
        playback.advance(by: 1)

        #expect(playback.phase == .finished)
        #expect(!playback.canNext)

        playback.next()
        #expect(playback.completed == 2)
    }

    @Test("Previous drops the current stroke and shows the one before whole")
    func previousStepsBack() {
        var playback = make()
        playback.play()
        playback.advance(by: 100)
        playback.replay(autoplay: false)
        playback.next()
        playback.advance(by: 1)
        playback.next()
        playback.advance(by: 1)
        #expect(playback.completed == 2)
        #expect(playback.currentStrokeIndex == 1)

        playback.previous()
        #expect(playback.phase == .paused)
        #expect(playback.completed == 1)
        #expect(playback.currentStrokeIndex == 0)
        #expect(playback.fraction(ofStroke: 0) == 1)
        #expect(playback.fraction(ofStroke: 1) == 0)
    }

    @Test("Previous mid-stroke drops the partial stroke only")
    func previousMidStroke() {
        var playback = make()
        playback.next()
        playback.advance(by: 1)
        playback.play()
        playback.advance(by: 0.5)
        #expect(playback.currentStrokeIndex == 1)

        playback.previous()
        #expect(playback.completed == 1)
        #expect(playback.progress == 0)
        #expect(playback.currentStrokeIndex == 0)
        #expect(playback.phase == .paused)
    }

    @Test("Previous from the first stroke returns to the empty stage")
    func previousToEmptyStage() {
        var playback = make()
        playback.next()
        playback.advance(by: 1)
        playback.previous()

        #expect(playback.phase == .idle)
        #expect(playback.completed == 0)
        #expect(playback.currentStrokeIndex == nil)
        #expect(!playback.canPrevious)
        #expect(playback.counterLabel == "3 strokes")
    }

    @Test("Previous from the finished kanji removes the last stroke")
    func previousFromFinished() {
        var playback = make(strokes: 2)
        playback.play()
        playback.advance(by: 100)
        playback.previous()

        #expect(playback.phase == .paused)
        #expect(playback.completed == 1)
        #expect(playback.currentStrokeIndex == 0)
    }

    @Test("Replay clears the stage and plays from the first stroke")
    func replayPlays() {
        var playback = make()
        playback.play()
        playback.advance(by: 100)
        #expect(playback.canReplay)

        playback.replay()
        #expect(playback.phase == .drawing)
        #expect(playback.completed == 0)
        #expect(playback.progress == 0)
    }

    @Test("Replay without autoplay stays on the empty stage")
    func replayStaysPaused() {
        var playback = make()
        playback.next()
        playback.advance(by: 1)
        playback.replay(autoplay: false)

        #expect(playback.phase == .idle)
        #expect(playback.completed == 0)
        #expect(!playback.canReplay)
    }

    @Test("Play on a finished kanji replays it")
    func playAfterFinishedReplays() {
        var playback = make(strokes: 1)
        playback.play()
        playback.advance(by: 100)
        #expect(playback.phase == .finished)

        playback.play()
        #expect(playback.phase == .drawing)
        #expect(playback.completed == 0)
    }

    @Test("Under Reduce Motion a stroke appears whole and the next follows after 0.8 s")
    func reduceMotionShowsWholeStrokes() {
        var playback = make()
        playback.animates = false
        playback.play()
        playback.advance(by: 0.01)

        #expect(playback.completed == 1)
        #expect(playback.progress == 0)
        #expect(playback.fraction(ofStroke: 0) == 1)
        #expect(playback.phase == .resting)

        playback.advance(by: 0.7)
        #expect(playback.completed == 1)
        playback.advance(by: 0.1)
        #expect(playback.completed == 2)
    }

    @Test("Under Reduce Motion Next shows the next stroke whole and pauses")
    func reduceMotionNext() {
        var playback = make()
        playback.animates = false
        playback.next()
        playback.advance(by: 0.01)

        #expect(playback.completed == 1)
        #expect(playback.phase == .paused)
        #expect(playback.currentStrokeIndex == 0)
    }

    @Test("An empty kanji cannot play")
    func emptyKanji() {
        var playback = StrokePlayback(durations: [])
        playback.play()
        playback.next()
        #expect(playback.phase == .idle)
        #expect(!playback.canPlay)
        #expect(!playback.canNext)
    }

    @Test("A negative tick is ignored")
    func negativeTick() {
        var playback = make()
        playback.play()
        playback.advance(by: -3)
        #expect(playback.progress == 0)
    }

    @Test("The stroke that is drawing is the current one and the earlier stroke is whole")
    func currentStrokeTracksTheTiers() {
        var playback = make()
        playback.play()
        playback.advance(by: 1 + StrokePlayback.restInterval + 0.2)
        #expect(playback.currentStrokeIndex == 1)
        #expect(playback.fraction(ofStroke: 0) == 1)
    }
}

/*------------------------------timing-tests-----------------------------*/

@Suite("Stroke Timing Tests")
struct StrokeTimingTests {
    @Test("Duration is length over 100 units per second, clamped to 0.3 to 1.0 s")
    func durationClamps() {
        #expect(StrokePlayback.duration(forLength: 0) == 0.3)
        #expect(StrokePlayback.duration(forLength: 10) == 0.3)
        #expect(abs(StrokePlayback.duration(forLength: 60) - 0.6) < 0.0001)
        #expect(StrokePlayback.duration(forLength: 400) == 1.0)
    }

    @Test("Easing runs from 0 to 1 and is symmetric")
    func easing() {
        #expect(StrokePlayback.ease(0) == 0)
        #expect(StrokePlayback.ease(1) == 1)
        #expect(StrokePlayback.ease(0.5) == 0.5)
        #expect(StrokePlayback.ease(0.25) < 0.25)
        #expect(StrokePlayback.ease(0.75) > 0.75)
        #expect(StrokePlayback.ease(-1) == 0)
        #expect(StrokePlayback.ease(2) == 1)
    }

    @Test("A straight path measures its length")
    func lineLength() {
        #expect(abs(StrokePathParser.length(of: "M10,10 L40,50") - 50) < 0.0001)
        #expect(abs(StrokePathParser.length(of: "M0,0 H30 V40") - 70) < 0.0001)
    }

    @Test("A flattened curve is longer than its chord and shorter than its control polygon")
    func curveLength() {
        let length = StrokePathParser.length(of: "M0,0 C0,50 50,50 50,0")
        #expect(length > 50)
        #expect(length < 150)
    }

    @Test("A curve through collinear points measures the straight distance")
    func collinearCurve() {
        let length = StrokePathParser.length(of: "M0,0 C10,0 20,0 30,0")
        #expect(abs(length - 30) < 0.001)
    }

    @Test("Playback built from path data takes its durations from stroke length")
    func playbackFromPaths() {
        let playback = StrokePlayback(strokePaths: ["M0,0 L10,0", "M0,0 L60,0", "M0,0 L300,0"])
        #expect(playback.strokeCount == 3)
        #expect(playback.durations[0] == 0.3)
        #expect(abs(playback.durations[1] - 0.6) < 0.0001)
        #expect(playback.durations[2] == 1.0)
    }

    @Test("A bad path counts as a short stroke instead of crashing")
    func emptyPathData() {
        let playback = StrokePlayback(strokePaths: [""])
        #expect(playback.durations == [0.3])
    }
}
