import SwiftUI

/*--------------------------------details---------------------------------*/

public struct DetailsCardView: View {
    public let onyomi: [String]
    public let kunyomi: [String]
    public let radical: String
    public let strokeCount: Int
    public let jlptLevel: String?
    public let joyoGrade: String?

    public init(
        onyomi: [String] = [],
        kunyomi: [String] = [],
        radical: String = "",
        strokeCount: Int = 0,
        jlptLevel: String? = nil,
        joyoGrade: String? = nil
    ) {
        self.onyomi = onyomi
        self.kunyomi = kunyomi
        self.radical = radical
        self.strokeCount = strokeCount
        self.jlptLevel = jlptLevel
        self.joyoGrade = joyoGrade
    }

    public var body: some View {
        KanjiCard {
            VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                detailRow(label: "Onyomi", value: onyomi.joined(separator: ", "))
                Divider().background(Color.nichijiHairline)

                detailRow(label: "Kunyomi", value: kunyomi.joined(separator: ", "))
                Divider().background(Color.nichijiHairline)

                detailRow(label: "Radical", value: radical)
                Divider().background(Color.nichijiHairline)

                detailRow(label: "Strokes", value: "\(strokeCount)")
                if let jlptLevel {
                    Divider().background(Color.nichijiHairline)
                    detailRow(label: "JLPT", value: jlptLevel.uppercased())
                }
                if let joyoGrade {
                    Divider().background(Color.nichijiHairline)
                    detailRow(label: "Grade", value: joyoGrade)
                }
            }
        }
        .padding(.horizontal, LayoutTokens.space16)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
                .frame(width: 80, alignment: .leading)

            Text(value.isEmpty ? "—" : value)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)

            Spacer()
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Bind decoded KanjiEntry metadata and conditionally display romaji sub-labels in Slice 7.
