import SwiftUI

/*------------------------------level-select------------------------------*/

struct LevelSelectView: View {
    let flow: OnboardingFlow

    var body: some View {
        OnboardingStepScaffold(
            buttonTitle: "Continue",
            action: { flow.advance() },
            content: {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                OnboardingStepHeader(
                    title: "Choose your level",
                    subtitle: "Your daily kanji come from this level. You can change it any time in Settings.",
                    alignment: .leading
                )

                levelSystemSection(activeLevelSystem: flow.levelSystem) { system in
                    flow.selectLevelSystem(system)
                }

                VStack(spacing: LayoutTokens.space8) {
                    ForEach(flow.levelRows) { row in
                        LevelSelectionRow(
                            code: row.code,
                            title: row.title,
                            countLabel: row.kanjiCount > 0 ? "\(row.kanjiCount) kanji" : nil,
                            isSelected: row.isSelected
                        ) {
                            flow.selectLevel(row.level)
                        }
                    }
                }

                Text("Daily order can be set in Settings.")
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkSubtle)
                    .padding(.horizontal, LayoutTokens.space8)
            }
        })
    }
}
