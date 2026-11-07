import SwiftUI

/*---------------------------------sheet----------------------------------*/

/// "Draw to search": a pad, five matches refreshed after each stroke, Undo and Clear. Picking a match hands it to the search bar.
struct DrawSearchSheet: View {
    let model: HandwritingSearchModel
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                    HandwritingPadView(model: model)
                        .padding(.horizontal, LayoutTokens.screenMarginRegular)

                    matchesHeader
                        .padding(.top, LayoutTokens.space8)
                        .padding(.horizontal, LayoutTokens.screenMarginRegular)

                    DrawSearchMatchesRow(state: model.matchState) { kanji in
                        if let chosen = model.choose(kanji) {
                            onPick(chosen)
                        }
                    }
                    .padding(.horizontal, LayoutTokens.screenMarginRegular)

                    controls
                }
                .padding(.top, LayoutTokens.space16)
                .padding(.bottom, LayoutTokens.space32)
            }
            .scrollDisabled(model.pad.currentStroke != nil)
        }
        .background(Color.nichijiSurfaceRaised.ignoresSafeArea())
        // A presented sheet does not follow the root's live scheme change, so it applies its own.
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.nichijiSurfaceRaised)
        .task {
            await model.open()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space12) {
            Text(HandwritingSearchCopy.sheetTitle)
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)
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

    private var matchesHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space8) {
            Text(HandwritingSearchCopy.matchesHeader)
                .textCase(.uppercase)
                .font(.uiText(size: 12, weight: .medium))
                .tracking(0.7)
                .foregroundColor(.nichijiInkSubtle)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: LayoutTokens.space8)
            Text(model.pad.note)
                .font(.nichijiCaption.monospacedDigit())
                .foregroundColor(.nichijiInkMuted)
                .multilineTextAlignment(.trailing)
        }
    }

    private var controls: some View {
        HStack(spacing: LayoutTokens.space8) {
            Button(action: { model.undo() }, label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            })
            .buttonStyle(PracticeControlStyle(isEnabled: model.pad.canUndo))
            .disabled(!model.pad.canUndo)
            .accessibilityLabel("Undo last stroke")

            Button("Clear") {
                model.clear()
            }
            .buttonStyle(PracticeControlStyle(isEnabled: !model.pad.isEmpty))
            .disabled(model.pad.isEmpty)
            .accessibilityLabel("Clear all strokes")

            Spacer(minLength: 0)
        }
        .padding(.leading, LayoutTokens.space12)
        .padding(.trailing, LayoutTokens.screenMarginRegular)
    }
}

/*----------------------------------pad-----------------------------------*/

struct HandwritingPadView: View {
    let model: HandwritingSearchModel

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width
            ZStack {
                Color.nichijiSurface

                if model.pad.isEmpty {
                    Text(HandwritingSearchCopy.placeholder)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkSubtle)
                        .accessibilityHidden(true)
                }

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
        .frame(maxWidth: HandwritingSearchLayout.padMaxSide)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(HandwritingSearchCopy.padLabel(strokeCount: model.pad.strokeCount))
        .accessibilityHint("Draw a kanji with your finger")
    }

    private func drawGesture(side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = CGPoint(x: value.location.x / side, y: value.location.y / side)
                let time = value.time.timeIntervalSinceReferenceDate
                if model.pad.currentStroke == nil {
                    model.beginStroke(at: point, time: time)
                } else {
                    model.extendStroke(to: point, time: time)
                }
            }
            .onEnded { _ in
                model.endStroke()
            }
    }

    private func drawCrosshair(in context: inout GraphicsContext, size: CGSize) {
        let inset = size.width * HandwritingSearchLayout.crosshairInsetRatio
        var path = Path()
        path.move(to: CGPoint(x: size.width / 2, y: inset))
        path.addLine(to: CGPoint(x: size.width / 2, y: size.height - inset))
        path.move(to: CGPoint(x: inset, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width - inset, y: size.height / 2))
        context.stroke(path, with: .color(.nichijiHairline), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    private func drawStrokes(in context: inout GraphicsContext, size: CGSize) {
        let style = StrokeStyle(lineWidth: size.width * HandwritingSearchLayout.inkWidthRatio, lineCap: .round, lineJoin: .round)
        for stroke in model.pad.allStrokes {
            guard let first = stroke.first else { continue }
            let start = CGPoint(x: CGFloat(first.x) * size.width, y: CGFloat(first.y) * size.height)
            var path = Path()
            path.move(to: start)
            if stroke.count == 1 {
                // A zero-length segment still draws a round dot for a tap.
                path.addLine(to: CGPoint(x: start.x + 0.1, y: start.y))
            }
            for point in stroke.dropFirst() {
                path.addLine(to: CGPoint(x: CGFloat(point.x) * size.width, y: CGFloat(point.y) * size.height))
            }
            context.stroke(path, with: .color(.nichijiInk), style: style)
        }
    }
}

/*--------------------------------matches---------------------------------*/

struct DrawSearchMatchesRow: View {
    let state: HandwritingMatchState
    let onPick: (String) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: LayoutTokens.space8),
        count: HandwritingSearchLayout.tileCount
    )

    var body: some View {
        Group {
            switch state {
            case .preparing:
                HStack(spacing: LayoutTokens.space12) {
                    ProgressView()
                    Text(HandwritingSearchCopy.preparing)
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                }
                .accessibilityElement(children: .combine)
            case .unavailable:
                message(HandwritingSearchCopy.unavailable)
            case .waiting:
                tiles([])
            case .matches(let kanji):
                if kanji.isEmpty {
                    message(HandwritingSearchCopy.noMatches)
                } else {
                    tiles(kanji)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: HandwritingSearchLayout.tileMinSide, alignment: .leading)
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.nichijiCallout)
            .foregroundColor(.nichijiInkMuted)
    }

    /// Always five slots, so the row keeps its height; empty slots are decoration.
    private func tiles(_ kanji: [String]) -> some View {
        LazyVGrid(columns: columns, spacing: LayoutTokens.space8) {
            ForEach(0..<HandwritingSearchLayout.tileCount, id: \.self) { slot in
                if slot < kanji.count {
                    matchTile(kanji[slot])
                } else {
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                        .stroke(Color.nichijiHairline, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func matchTile(_ kanji: String) -> some View {
        Button(action: { onPick(kanji) }, label: {
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .fill(Color.nichijiSurfaceRaised)
                .aspectRatio(1, contentMode: .fit)
                .frame(minWidth: HandwritingSearchLayout.controlMinSide, minHeight: HandwritingSearchLayout.controlMinSide)
                .overlay(
                    Text(kanji)
                        .font(.kanjiDisplay(size: 28))
                        .foregroundColor(.nichijiInk)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(LayoutTokens.space4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                        .stroke(Color.nichijiBorderControl, lineWidth: 1)
                )
                .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        .accessibilityLabel(HandwritingSearchCopy.tileLabel(kanji: kanji))
    }
}
