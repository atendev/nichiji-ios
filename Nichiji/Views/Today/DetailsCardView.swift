import SwiftUI

/*--------------------------------details---------------------------------*/

public struct DetailsCardView: View {
    public let onyomi: [KanjiReading]
    public let kunyomi: [KanjiReading]
    public let radical: String
    public let strokeCount: Int
    public let jlptLevel: String?
    public let joyoGrade: String?
    public let showsRomaji: Bool
    @Environment(\.sizeCategory) private var sizeCategory

    public init(
        onyomi: [KanjiReading] = [],
        kunyomi: [KanjiReading] = [],
        radical: String = "",
        strokeCount: Int = 0,
        jlptLevel: String? = nil,
        joyoGrade: String? = nil,
        showsRomaji: Bool = true
    ) {
        self.onyomi = onyomi
        self.kunyomi = kunyomi
        self.radical = radical
        self.strokeCount = strokeCount
        self.jlptLevel = jlptLevel
        self.joyoGrade = joyoGrade
        self.showsRomaji = showsRomaji
    }

    public var body: some View {
        KanjiCard {
            VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                detailRow(label: "Onyomi", readings: onyomi)
                Divider().background(Color.nichijiHairline)

                detailRow(label: "Kunyomi", readings: kunyomi)
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

    private func detailRow(label: String, readings: [KanjiReading]) -> some View {
        detailRow(label: label, value: readings.map(\.kana).joined(separator: ", "), romaji: readings.map(\.romaji).joined(separator: ", "))
    }

    private func detailRow(label: String, value: String) -> some View {
        detailRow(label: label, value: value, romaji: nil)
    }

    private func detailRow(label: String, value: String, romaji: String?) -> some View {
        Group {
            if sizeCategory.isAccessibilityCategory {
                VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                    rowLabel(label)
                    rowValue(value: value, romaji: romaji)
                }
            } else {
                HStack {
                    rowLabel(label)
                    rowValue(value: value, romaji: romaji)
                    Spacer()
                }
            }
        }
    }

    private func rowLabel(_ label: String) -> some View {
        Text(label)
            .font(.nichijiCallout)
            .foregroundColor(.nichijiInkMuted)
            .frame(width: sizeCategory.isAccessibilityCategory ? nil : 80, alignment: .leading)
    }

    private func rowValue(value: String, romaji: String?) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text(value.isEmpty ? "—" : value)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)
                .fixedSize(horizontal: false, vertical: true)
            if showsRomaji, let romaji, !romaji.isEmpty {
                Text(romaji)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
