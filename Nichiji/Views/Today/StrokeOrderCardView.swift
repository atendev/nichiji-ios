import SwiftUI

/*---------------------------------stroke---------------------------------*/

public struct StrokeOrderCardView: View {
    public let strokeCount: Int
    public let onPractice: () -> Void

    public init(strokeCount: Int = 0, onPractice: @escaping () -> Void = {}) {
        self.strokeCount = strokeCount
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

                Button(action: onPractice) {
                    HStack(spacing: LayoutTokens.space8) {
                        Image(systemName: "pencil")
                        Text("Practice this kanji")
                    }
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LayoutTokens.minHitTarget)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                            .stroke(Color.nichijiBorderControl, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    )
                }
            }
        }
        .padding(.horizontal, LayoutTokens.space16)
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Render the 2-column numbered SVG stroke sequence grid from KanjiVG vector data in Slice 7.
