import SwiftUI

/*--------------------------------presenter-------------------------------*/

public extension View {
    /// Presents the Practice sheet while `target` is set. Today, the review answer side and kanji detail share it.
    func practiceSheet(target: Binding<PracticeTarget?>) -> some View {
        sheet(item: target) { item in
            PracticeSheet(target: item)
        }
    }
}

/*---------------------------------sheet----------------------------------*/

public struct PracticeSheet: View {
    public let target: PracticeTarget

    @Environment(\.dismiss) private var dismiss
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    @State private var pad = PracticePad()
    @State private var showsGuide = true

    public init(target: PracticeTarget) {
        self.target = target
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                    PracticePadView(pad: $pad, kanji: target.kanji, showsGuide: showsGuide)
                        .padding(.horizontal, LayoutTokens.screenMarginRegular)

                    Text(pad.countLabel(total: target.strokeCount))
                        .font(.nichijiCallout.monospacedDigit())
                        .foregroundColor(.nichijiInkMuted)
                        .padding(.horizontal, LayoutTokens.screenMarginRegular)
                        .accessibilityHidden(true)

                    controls

                    // The card adds its own 16 pt inset, which brings it to the 24 pt sheet margin.
                    StrokeOrderCardView(strokeCount: target.strokeCount, strokePaths: target.strokePaths)
                        .padding(.horizontal, LayoutTokens.space8)
                        .padding(.top, LayoutTokens.space24)
                }
                .padding(.top, LayoutTokens.space16)
                .padding(.bottom, LayoutTokens.space32)
            }
            .scrollDisabled(pad.currentStroke != nil)
        }
        .background(Color.nichijiSurfaceRaised.ignoresSafeArea())
        // A presented sheet does not follow the root's live scheme change, so it applies its own.
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        .presentationDetents([.fraction(0.7), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.nichijiSurfaceRaised)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space12) {
            Text("Practice")
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
        .padding(.leading, LayoutTokens.screenMarginRegular)
        .padding(.trailing, LayoutTokens.space12)
        .padding(.top, LayoutTokens.space24)
    }

    private var controls: some View {
        HStack(spacing: LayoutTokens.space8) {
            Button(action: { pad.undo() }, label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            })
            .buttonStyle(PracticeControlStyle(isEnabled: pad.canUndo))
            .disabled(!pad.canUndo)
            .accessibilityLabel("Undo last stroke")

            Button("Clear") {
                pad.clear()
            }
            .buttonStyle(PracticeControlStyle(isEnabled: !pad.isEmpty))
            .disabled(pad.isEmpty)
            .accessibilityLabel("Clear all strokes")

            Spacer(minLength: LayoutTokens.space8)

            Toggle("Guide", isOn: $showsGuide)
                .font(.uiText(size: 14, weight: .medium))
                .foregroundColor(.nichijiInk)
                .tint(.nichijiInk)
                .fixedSize()
                .frame(minHeight: LayoutTokens.minHitTarget)
                .accessibilityHint("Shows a faint kanji to trace over")
        }
        .padding(.leading, LayoutTokens.space12)
        .padding(.trailing, LayoutTokens.screenMarginRegular)
    }
}

/*----------------------------------pad-----------------------------------*/

struct PracticePadView: View {
    @Binding var pad: PracticePad
    let kanji: String
    let showsGuide: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Proportions of the 342 pt pad in the design.
    private static let inkWidthRatio: CGFloat = 7 / 342
    private static let guideSizeRatio: CGFloat = 270 / 342
    private static let crosshairInsetRatio: CGFloat = 6 / 342

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width
            ZStack {
                Color.nichijiSurface

                Text(kanji)
                    .font(.kanjiGuide(size: side * Self.guideSizeRatio))
                    .foregroundColor(.nichijiHairline)
                    .opacity(showsGuide ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: showsGuide)
                    .accessibilityHidden(true)

                Canvas { context, size in
                    drawCrosshair(in: &context, size: size)
                    drawStrokes(in: &context, size: size)
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(drawGesture(side: side))
        }
        .aspectRatio(1, contentMode: .fit)
        .continuousCornerRadius(LayoutTokens.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .stroke(Color.nichijiBorderControl, lineWidth: 1)
        )
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel("Writing pad")
        .accessibilityValue("\(pad.strokeCount) strokes drawn")
        .accessibilityHint("Draw the kanji with your finger")
    }

    private func drawGesture(side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = CGPoint(x: value.location.x / side, y: value.location.y / side)
                if pad.currentStroke == nil {
                    pad.begin(at: point)
                } else {
                    pad.extend(to: point)
                }
            }
            .onEnded { _ in
                pad.end()
            }
    }

    private func drawCrosshair(in context: inout GraphicsContext, size: CGSize) {
        let inset = size.width * Self.crosshairInsetRatio
        var path = Path()
        path.move(to: CGPoint(x: size.width / 2, y: inset))
        path.addLine(to: CGPoint(x: size.width / 2, y: size.height - inset))
        path.move(to: CGPoint(x: inset, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width - inset, y: size.height / 2))
        context.stroke(path, with: .color(.nichijiHairline), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    private func drawStrokes(in context: inout GraphicsContext, size: CGSize) {
        let style = StrokeStyle(lineWidth: size.width * Self.inkWidthRatio, lineCap: .round, lineJoin: .round)
        for stroke in pad.allStrokes {
            guard let first = stroke.first else { continue }
            let start = CGPoint(x: first.x * size.width, y: first.y * size.height)
            var path = Path()
            path.move(to: start)
            if stroke.count == 1 {
                // A zero-length segment still draws a round dot for a tap.
                path.addLine(to: CGPoint(x: start.x + 0.1, y: start.y))
            }
            for point in stroke.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
            }
            context.stroke(path, with: .color(.nichijiInk), style: style)
        }
    }
}

/*--------------------------------controls--------------------------------*/

struct PracticeControlStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .padding(.horizontal, LayoutTokens.space12)
            .frame(minHeight: LayoutTokens.minHitTarget)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
    }
}
