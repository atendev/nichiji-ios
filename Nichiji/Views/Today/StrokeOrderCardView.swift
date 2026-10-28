import SwiftUI

/*---------------------------------stroke---------------------------------*/

public struct StrokeOrderCardView: View {
    public let strokeCount: Int
    public let strokePaths: [String]
    public let onPractice: () -> Void

    public init(
        strokeCount: Int = 0,
        strokePaths: [String] = [],
        onPractice: @escaping () -> Void = {}
    ) {
        self.strokeCount = strokeCount
        self.strokePaths = strokePaths
        self.onPractice = onPractice
    }

    public var body: some View {
        KanjiCard {
            VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                Text("Stroke order")
                    .font(.nichijiTitle)
                    .foregroundColor(.nichijiInk)

                Text("\(strokeCount) strokes")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LayoutTokens.space8) {
                    ForEach(Array(strokePaths.enumerated()), id: \.offset) { index, path in
                        VStack(spacing: LayoutTokens.space4) {
                            StrokePathShape(pathData: path)
                                .stroke(Color.nichijiInk, lineWidth: 2)
                                .aspectRatio(1, contentMode: .fit)
                                .padding(LayoutTokens.space8)
                                .background(Color.nichijiSurface)
                                .continuousCornerRadius(LayoutTokens.cornerRadiusSmall)
                            Text("\(index + 1)")
                                .font(.nichijiCaption)
                                .foregroundColor(.nichijiInkMuted)
                        }
                    }
                }

                Button(action: onPractice) {
                    HStack(spacing: LayoutTokens.space8) {
                        Image(systemName: "pencil")
                        Text("Practice this kanji")
                    }
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                    .opacity(0.6)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LayoutTokens.minHitTarget)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                            .stroke(Color.nichijiBorderControl, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    )
                }
                .disabled(true)
                .accessibilityLabel("Practice this kanji")
                .accessibilityHint("Handwriting practice is not available yet")
            }
        }
        .padding(.horizontal, LayoutTokens.space16)
    }
}

private struct StrokePathShape: Shape {
    let pathData: String

    func path(in rect: CGRect) -> Path {
        let values = pathData
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: { $0 == " " || $0 == "\n" })
        var index = 0
        var command = ""
        var current = CGPoint.zero
        var path = Path()

        func number() -> CGFloat? {
            guard index < values.count, let value = Double(values[index]) else { return nil }
            index += 1
            return CGFloat(value)
        }

        while index < values.count {
            let token = String(values[index])
            if token.count == 1, token.first?.isLetter == true {
                command = token
                index += 1
            }

            switch command {
            case "M", "m":
                guard let x = number(), let y = number() else { break }
                let point = command == "m"
                    ? CGPoint(x: current.x + x, y: current.y + y)
                    : CGPoint(x: x, y: y)
                path.move(to: point)
                current = point
                command = command == "m" ? "l" : "L"
            case "L", "l":
                guard let x = number(), let y = number() else { break }
                let point = command == "l"
                    ? CGPoint(x: current.x + x, y: current.y + y)
                    : CGPoint(x: x, y: y)
                path.addLine(to: point)
                current = point
            case "C", "c":
                guard let x1 = number(), let y1 = number(),
                      let x2 = number(), let y2 = number(),
                      let x = number(), let y = number() else { break }
                let control1 = command == "c"
                    ? CGPoint(x: current.x + x1, y: current.y + y1)
                    : CGPoint(x: x1, y: y1)
                let control2 = command == "c"
                    ? CGPoint(x: current.x + x2, y: current.y + y2)
                    : CGPoint(x: x2, y: y2)
                let point = command == "c"
                    ? CGPoint(x: current.x + x, y: current.y + y)
                    : CGPoint(x: x, y: y)
                path.addCurve(to: point, control1: control1, control2: control2)
                current = point
            default:
                index += 1
            }
        }

        let scale = min(rect.width, rect.height) / 109
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}
