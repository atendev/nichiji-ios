import SwiftUI

/*---------------------------------stroke---------------------------------*/

public struct StrokeOrderCardView: View {
    public let strokeCount: Int
    public let strokePaths: [String]
    public let onPractice: (() -> Void)?

    // Without `onPractice` the card hides its practice button, as it does inside the Practice sheet.
    public init(
        strokeCount: Int = 0,
        strokePaths: [String] = [],
        onPractice: (() -> Void)? = nil
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

                if strokePaths.isEmpty {
                    Text("The stroke diagram is unavailable for this kanji.")
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                }

                let paths = strokePaths.map(StrokePathParser.path(from:))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LayoutTokens.space8) {
                    ForEach(paths.indices, id: \.self) { index in
                        StrokeStepView(paths: paths, step: index)
                            .accessibilityElement()
                            .accessibilityLabel("Stroke \(index + 1) of \(paths.count)")
                    }
                }

                if let onPractice {
                    Button(action: onPractice) {
                        HStack(spacing: LayoutTokens.space8) {
                            Image(systemName: "pencil")
                            Text("Practice this kanji")
                        }
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: LayoutTokens.minHitTarget)
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                                .stroke(Color.nichijiBorderControl, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        )
                    }
                    .accessibilityLabel("Practice this kanji")
                    .accessibilityHint("Opens a pad to trace the kanji")
                }
            }
        }
        .padding(.horizontal, LayoutTokens.space16)
    }
}

private struct StrokeStepView: View {
    let paths: [Path]
    let step: Int

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let scale = side / StrokePathParser.viewBoxSize
            context.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
            context.scaleBy(x: scale, y: scale)
            let style = StrokeStyle(lineWidth: StrokePathParser.strokeWidth, lineCap: .round, lineJoin: .round)
            for (index, path) in paths.enumerated() {
                let color: Color = index == step ? .nichijiInk : index < step ? .nichijiInkMuted : .nichijiHairline
                context.stroke(path, with: .color(color), style: style)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(LayoutTokens.space12)
        .background(Color.nichijiSurfaceSunken)
        .overlay(alignment: .topLeading) {
            Text("\(step + 1)")
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkMuted)
                .padding(LayoutTokens.space8)
        }
        .continuousCornerRadius(LayoutTokens.cornerRadiusSmall)
    }
}

/// Builds a `Path` in KanjiVG's 109-unit viewBox from one SVG path `d` attribute.
struct StrokePathParser {
    static let viewBoxSize: CGFloat = 109
    static let strokeWidth: CGFloat = 4

    static func path(from data: String) -> Path {
        var parser = StrokePathParser(tokens: tokenize(data))
        parser.run()
        return parser.path
    }

    private enum Token {
        case command(Character)
        case number(CGFloat)
    }

    private let tokens: [Token]
    private var index = 0
    private var path = Path()
    private var current = CGPoint.zero
    private var subpathStart = CGPoint.zero
    private var lastControl: CGPoint?

    private init(tokens: [Token]) {
        self.tokens = tokens
    }

    private mutating func run() {
        var command: Character = " "
        while index < tokens.count {
            let start = index
            if case let .command(letter) = tokens[index] {
                command = letter
                index += 1
            }
            guard apply(command), index > start else { return }
            if command == "M" {
                command = "L"
            } else if command == "m" {
                command = "l"
            }
        }
    }

    private mutating func apply(_ command: Character) -> Bool {
        let relative = command.isLowercase
        let previousControl = lastControl
        lastControl = nil

        switch command.uppercased() {
        case "M":
            guard let end = point(relative: relative) else { return false }
            path.move(to: end)
            current = end
            subpathStart = end
        case "L":
            guard let end = point(relative: relative) else { return false }
            lineTo(end)
        case "H":
            guard let x = number() else { return false }
            lineTo(CGPoint(x: relative ? current.x + x : x, y: current.y))
        case "V":
            guard let y = number() else { return false }
            lineTo(CGPoint(x: current.x, y: relative ? current.y + y : y))
        case "C":
            guard let control1 = point(relative: relative) else { return false }
            return curve(control1: control1, relative: relative)
        case "S":
            let control1 = previousControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
            return curve(control1: control1, relative: relative)
        case "Z":
            path.closeSubpath()
            current = subpathStart
        default:
            return false
        }
        return true
    }

    private mutating func lineTo(_ end: CGPoint) {
        path.addLine(to: end)
        current = end
    }

    private mutating func curve(control1: CGPoint, relative: Bool) -> Bool {
        guard let control2 = point(relative: relative), let end = point(relative: relative) else { return false }
        path.addCurve(to: end, control1: control1, control2: control2)
        current = end
        lastControl = control2
        return true
    }

    private mutating func number() -> CGFloat? {
        guard index < tokens.count, case let .number(value) = tokens[index] else { return nil }
        index += 1
        return value
    }

    private mutating func point(relative: Bool) -> CGPoint? {
        guard let x = number(), let y = number() else { return nil }
        return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
    }

    private static func tokenize(_ data: String) -> [Token] {
        var tokens: [Token] = []
        var buffer = ""

        func flush() {
            if let value = Double(buffer) {
                tokens.append(.number(CGFloat(value)))
            }
            buffer = ""
        }

        for character in data {
            if character == "," || character.isWhitespace {
                flush()
            } else if character.isLetter, character != "e", character != "E" {
                flush()
                tokens.append(.command(character))
            } else {
                if startsNumber(character, after: buffer) {
                    flush()
                }
                buffer.append(character)
            }
        }
        flush()
        return tokens
    }

    private static func startsNumber(_ character: Character, after buffer: String) -> Bool {
        let hasExponent = buffer.contains { $0 == "e" || $0 == "E" }
        switch character {
        case "-", "+":
            return buffer.last != "e" && buffer.last != "E"
        case ".":
            return buffer.contains(".") && !hasExponent
        default:
            return false
        }
    }
}
