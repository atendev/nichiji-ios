import SwiftUI

/*--------------------------------presenter-------------------------------*/

public extension View {
    /// Presents the stroke player while `target` is set. The card, kanji detail, Today and the Practice sheet share it.
    func strokePlayerSheet(target: Binding<PracticeTarget?>) -> some View {
        sheet(item: target) { item in
            StrokePlayerSheet(target: item)
        }
    }
}

/*---------------------------------sheet----------------------------------*/

struct StrokePlayerSheet: View {
    let target: PracticeTarget

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    @State private var playback: StrokePlayback
    private let paths: [Path]

    // Header, counter, controls, spacing and insets at the default text size. The stage gives up height before the controls leave the 0.7 detent.
    private static let fixedRowsHeight: CGFloat = 205
    private static let minStageSide: CGFloat = 160
    private static let maxStageSide: CGFloat = 420
    // The control style pads 12 pt each side, so the symbol needs this much width to reach the 44 pt target.
    private static let iconMinWidth = LayoutTokens.minHitTarget - 2 * LayoutTokens.space12
    private static let autoplayDelay: Duration = .milliseconds(400)

    init(target: PracticeTarget) {
        self.target = target
        self.paths = target.strokePaths.map(StrokePathParser.path(from:))
        _playback = State(initialValue: StrokePlayback(strokePaths: target.strokePaths))
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutTokens.space12) {
                        if target.hasStrokeOrder {
                            let side = stageSide(in: proxy.size)
                            StrokePlayerStageView(paths: paths, playback: playback)
                                .frame(width: side, height: side)
                                .frame(maxWidth: .infinity)

                            Text(playback.counterLabel)
                                .font(.nichijiCallout.monospacedDigit())
                                .foregroundColor(.nichijiInkMuted)
                                .padding(.horizontal, LayoutTokens.screenMarginCompact)
                                .accessibilityHidden(true)

                            controls
                        } else {
                            Text(StrokeOrderCardView.noStrokeOrderMessage)
                                .font(.nichijiBody)
                                .foregroundColor(.nichijiInkMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, LayoutTokens.screenMarginCompact)
                        }
                    }
                    .padding(.top, LayoutTokens.space16)
                    .padding(.bottom, LayoutTokens.space16)
                }
            }
        }
        .background(Color.nichijiSurfaceRaised.ignoresSafeArea())
        // A presented sheet does not follow the root's live scheme change, so it applies its own.
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        .presentationDetents([.fraction(0.7), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.nichijiSurfaceRaised)
        .onChange(of: reduceMotion, initial: true) { _, reduces in
            playback.animates = !reduces
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { playback.pause() }
        }
        .task(id: playback.needsTicks) {
            await runClock()
        }
        .task {
            await autoplay()
        }
    }

    private func stageSide(in size: CGSize) -> CGFloat {
        let side = min(size.width - 2 * LayoutTokens.screenMarginCompact, Self.maxStageSide, size.height - Self.fixedRowsHeight)
        return max(side, Self.minStageSide)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space12) {
            Text("Stroke order")
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
            Text(target.kanji)
                .font(.kanjiDisplay(size: 20))
                .foregroundColor(.nichijiInk)
            Text(target.meaning)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .lineLimit(1)
            Spacer(minLength: LayoutTokens.space8)
            Button("Done") {
                dismiss()
            }
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .padding(.horizontal, LayoutTokens.space12)
            .minTouchTarget()
        }
        .padding(.leading, LayoutTokens.screenMarginCompact)
        .padding(.trailing, LayoutTokens.space4)
        .padding(.top, LayoutTokens.space24)
    }

    private var controls: some View {
        HStack(spacing: LayoutTokens.space8) {
            Button(action: { playback.previous() }, label: {
                Image(systemName: "chevron.backward")
                    .frame(minWidth: Self.iconMinWidth)
            })
            .buttonStyle(PracticeControlStyle(isEnabled: playback.canPrevious))
            .disabled(!playback.canPrevious)
            .accessibilityLabel("Previous stroke")

            Button(action: togglePlay, label: {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .frame(minWidth: Self.iconMinWidth)
            })
            .buttonStyle(PracticeControlStyle(isEnabled: playback.canPlay))
            .disabled(!playback.canPlay)
            .accessibilityLabel(playback.isPlaying ? "Pause" : "Play")

            Button(action: { playback.next() }, label: {
                Image(systemName: "chevron.forward")
                    .frame(minWidth: Self.iconMinWidth)
            })
            .buttonStyle(PracticeControlStyle(isEnabled: playback.canNext))
            .disabled(!playback.canNext)
            .accessibilityLabel("Next stroke")

            Spacer(minLength: LayoutTokens.space8)

            Button(action: { playback.replay(autoplay: !reduceMotion) }, label: {
                Label("Replay", systemImage: "arrow.counterclockwise")
            })
            .buttonStyle(PracticeControlStyle(isEnabled: playback.canReplay))
            .disabled(!playback.canReplay)
            .accessibilityLabel("Replay from the first stroke")
        }
        .padding(.horizontal, LayoutTokens.space4)
    }

    private func togglePlay() {
        if playback.isPlaying {
            playback.pause()
        } else {
            playback.play()
        }
    }

    /// Feeds real time into the playback while it is drawing or resting. It ends when the sheet goes away or time stops.
    private func runClock() async {
        guard playback.needsTicks else { return }
        let clock = ContinuousClock()
        var last = clock.now
        // Reduce Motion only changes which strokes are inked, so it needs no 60 Hz clock.
        let tick: Duration = reduceMotion ? .milliseconds(100) : .milliseconds(16)
        while playback.needsTicks, !Task.isCancelled {
            try? await Task.sleep(for: tick)
            guard !Task.isCancelled else { return }
            let now = clock.now
            playback.advance(by: (now - last).timeInterval)
            last = now
        }
    }

    /// Starts playing once the sheet has finished presenting, except under Reduce Motion.
    private func autoplay() async {
        guard !reduceMotion else { return }
        try? await Task.sleep(for: Self.autoplayDelay)
        guard !Task.isCancelled, playback.phase == .idle else { return }
        playback.play()
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}

/*---------------------------------stage----------------------------------*/

struct StrokePlayerStageView: View {
    let paths: [Path]
    let playback: StrokePlayback

    var body: some View {
        Canvas { context, size in
            StrokePlayerCanvas.draw(in: &context, size: size, paths: paths, playback: playback)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color.nichijiSurface)
        .continuousCornerRadius(LayoutTokens.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .stroke(Color.nichijiBorderControl, lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("Stroke order player")
        .accessibilityValue(playback.counterLabel)
    }
}

/// Draws the stage. The functions are `nonisolated` because `Canvas` calls them off the main actor.
enum StrokePlayerCanvas {
    private static let inset: CGFloat = 12
    private static let crosshairInsetRatio: CGFloat = 6 / 342

    nonisolated static func draw(in context: inout GraphicsContext, size: CGSize, paths: [Path], playback: StrokePlayback) {
        drawCrosshair(in: &context, size: size)

        let side = min(size.width, size.height) - 2 * inset
        let scale = side / StrokePathParser.viewBoxSize
        context.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
        context.scaleBy(x: scale, y: scale)
        let style = StrokeStyle(lineWidth: StrokePathParser.strokeWidth, lineCap: .round, lineJoin: .round)

        for path in paths {
            context.stroke(path, with: .color(.nichijiHairline), style: style)
        }

        let current = playback.currentStrokeIndex
        let earlierColor: Color = playback.phase == .finished ? .nichijiInk : .nichijiInkMuted
        for index in paths.indices where index != current {
            let fraction = playback.fraction(ofStroke: index)
            guard fraction > 0 else { continue }
            context.stroke(trimmed(paths[index], to: fraction), with: .color(earlierColor), style: style)
        }

        if let current, playback.fraction(ofStroke: current) > 0 {
            drawCurrentStroke(in: &context, index: current, path: paths[current], fraction: playback.fraction(ofStroke: current), style: style)
        }
    }

    /// The one place the player draws its current stroke, last so it sits above the others.
    /// The context is already scaled to KanjiVG's 109-unit viewBox. The direction markers from ticket 099 (start dot and arrow) draw from here.
    nonisolated static func drawCurrentStroke(in context: inout GraphicsContext, index: Int, path: Path, fraction: Double, style: StrokeStyle) {
        context.stroke(trimmed(path, to: fraction), with: .color(.nichijiInk), style: style)
    }

    private nonisolated static func trimmed(_ path: Path, to fraction: Double) -> Path {
        fraction >= 1 ? path : path.trimmedPath(from: 0, to: CGFloat(fraction))
    }

    private nonisolated static func drawCrosshair(in context: inout GraphicsContext, size: CGSize) {
        let inset = size.width * crosshairInsetRatio
        var path = Path()
        path.move(to: CGPoint(x: size.width / 2, y: inset))
        path.addLine(to: CGPoint(x: size.width / 2, y: size.height - inset))
        path.move(to: CGPoint(x: inset, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width - inset, y: size.height / 2))
        context.stroke(path, with: .color(.nichijiHairline), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }
}

/*--------------------------------play-entry------------------------------*/

/// The "Stroke order" title with a Play button at its trailing end. At accessibility text sizes the button drops under the title.
struct StrokeOrderTitleRow: View {
    let onPlay: (() -> Void)?

    var body: some View {
        if let onPlay {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: LayoutTokens.space8) {
                    title
                    Spacer(minLength: LayoutTokens.space8)
                    StrokePlayButton(action: onPlay)
                }
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    title
                    StrokePlayButton(action: onPlay)
                }
            }
        } else {
            title
        }
    }

    private var title: some View {
        Text("Stroke order")
            .font(.nichijiTitle)
            .foregroundColor(.nichijiInk)
    }
}

struct StrokePlayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space4) {
                Image(systemName: "play.fill")
                Text("Play")
            }
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .padding(.horizontal, LayoutTokens.space12)
            .frame(minHeight: LayoutTokens.minHitTarget)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(Color.nichijiBorderControl, lineWidth: 1)
            )
        }
        .accessibilityLabel("Play stroke order")
        .accessibilityHint("Draws each stroke in order")
    }
}
