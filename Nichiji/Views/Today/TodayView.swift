import SwiftUI

/*----------------------------------today---------------------------------*/

public struct TodayView: View {
    public let onOpenSettings: () -> Void

    @State private var isLearned: Bool = false
    @State private var isLevelComplete: Bool = false
    @State private var errorMessage: String?

    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            HeaderBar(kanjiTitle: "今日", englishTitle: "Today") {
                Button(action: onOpenSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.nichijiInk)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
            }

            if isLevelComplete {
                LevelCompleteView(onOpenSettings: onOpenSettings)
            } else if let error = errorMessage {
                VStack(spacing: LayoutTokens.space16) {
                    Spacer()
                    Text("Could not load today's kanji")
                        .font(.nichijiTitle)
                        .foregroundColor(.nichijiInk)
                    Text(error)
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                    PrimaryButton(title: "Retry") {
                        errorMessage = nil
                    }
                    .padding(.horizontal, LayoutTokens.space32)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutTokens.space24) {
                        KanjiHeroView(kanji: "日", primaryMeaning: "day, sun") {
                            // Audio action
                        }

                        if isLearned {
                            SealStamp(text: "Learned today")
                                .padding(.bottom, LayoutTokens.space8)
                        } else {
                            PrimaryButton(title: "Got it") {
                                isLearned = true
                            }
                            .padding(.horizontal, LayoutTokens.space24)
                            .padding(.bottom, LayoutTokens.space8)
                        }

                        DetailsCardView(
                            onyomi: ["ニチ", "ジツ"],
                            kunyomi: ["ひ", "-び", "-か"],
                            radical: "日",
                            strokeCount: 4,
                            jlptLevel: "N5",
                            joyoGrade: "1"
                        )

                        ExampleWordsCardView(words: [
                            ExampleWord(
                                id: "today-1",
                                word: "今日",
                                kana: "きょう",
                                romaji: "kyou",
                                meaning: "today",
                                maxJLPTLevel: .n5,
                                maxJoyoGrade: .grade1
                            ),
                            ExampleWord(
                                id: "today-2",
                                word: "毎日",
                                kana: "まいにち",
                                romaji: "mainichi",
                                meaning: "every day",
                                maxJLPTLevel: .n5,
                                maxJoyoGrade: .grade1
                            )
                        ])

                        StrokeOrderCardView(strokeCount: 4)
                    }
                    .padding(.bottom, LayoutTokens.space32)
                }
            }
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Bind DailyKanjiService for lazy idempotent rollover and SwiftData query observations in Slice 4 and Slice 7.
