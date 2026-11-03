import SwiftUI

/*--------------------------------due-card--------------------------------*/

struct ReviewDueCard: View {
    let summary: ReviewHomeSummary
    let optionsSummary: String
    let onStart: () -> Void
    let onOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space16) {
            VStack(alignment: .leading, spacing: LayoutTokens.space4) {
                HStack(alignment: .lastTextBaseline, spacing: LayoutTokens.space12) {
                    Text("\(summary.dueCount)")
                        .font(.uiText(size: 64, weight: .medium))
                        .monospacedDigit()
                        .foregroundColor(.nichijiInk)
                    Text("kanji due today")
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInkMuted)
                }
                .accessibilityElement(children: .combine)

                Text(detailLine)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkSubtle)
            }

            if summary.dueCount > 0 {
                tiles
                PrimaryButton(title: "Start review", action: onStart)
            }

            Button(action: onOptions) {
                Label("Session options · \(optionsSummary)", systemImage: "slider.horizontal.3")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInk)
                    .frame(maxWidth: .infinity, minHeight: LayoutTokens.minHitTarget)
            }
            .buttonStyle(.plain)
            .minTouchTarget()
        }
        .padding(LayoutTokens.space24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private var detailLine: String {
        guard summary.dueCount > 0 else { return "Nothing to review. Kanji you learn come back here." }
        let minutes = summary.estimatedMinutes
        return minutes == 1 ? "About 1 minute" : "About \(minutes) minutes"
    }

    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: LayoutTokens.space8)], alignment: .leading, spacing: LayoutTokens.space8) {
            ForEach(summary.tiles, id: \.self) { kanji in
                tile(Text(kanji).font(.kanjiDisplay(size: 22)))
            }
            if summary.overflowCount > 0 {
                tile(Text("+\(summary.overflowCount)").font(.nichijiCallout))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Due: \(summary.dueKanjiIDs.joined(separator: ", "))")
    }

    private func tile(_ label: Text) -> some View {
        label
            .foregroundColor(.nichijiInk)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .fill(Color.nichijiSurfaceSunken)
            )
    }
}

/*-------------------------------stages-card------------------------------*/

struct ReviewStagesCard: View {
    let summary: ReviewHomeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your kanji")
                    .font(.nichijiHeading)
                    .foregroundColor(.nichijiInk)
                Spacer()
                Text("\(summary.totalKanji) total")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkSubtle)
            }

            if summary.totalKanji > 0 {
                stageBar
            }

            ForEach(StudyStage.allCases, id: \.self) { stage in
                HStack(spacing: LayoutTokens.space12) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(stage.swatch)
                        .frame(width: 12, height: 12)
                    Text(stage.title)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)
                    Spacer()
                    Text("\(summary.count(for: stage))")
                        .font(.nichijiBody)
                        .monospacedDigit()
                        .foregroundColor(.nichijiInk)
                }
                .frame(minHeight: LayoutTokens.minHitTarget)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(LayoutTokens.space24)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private var stageBar: some View {
        GeometryReader { proxy in
            let stages = StudyStage.allCases.filter { summary.count(for: $0) > 0 }
            let gaps = CGFloat(max(stages.count - 1, 0)) * 2
            HStack(spacing: 2) {
                ForEach(stages, id: \.self) { stage in
                    Rectangle()
                        .fill(stage.swatch)
                        .frame(width: (proxy.size.width - gaps) * CGFloat(summary.count(for: stage)) / CGFloat(summary.totalKanji))
                }
            }
        }
        .frame(height: 12)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

extension StudyStage {
    var title: String {
        switch self {
        case .new: "New"
        case .learning: "Learning"
        case .familiar: "Familiar"
        case .known: "Known"
        }
    }

    var swatch: Color {
        switch self {
        case .new: .nichijiHairline
        case .learning: .nichijiBorderControl
        case .familiar: Color.nichijiMatcha.opacity(0.45)
        case .known: .nichijiMatcha
        }
    }
}

/*-----------------------------coming-up-card-----------------------------*/

struct ReviewComingUpCard: View {
    let summary: ReviewHomeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            Text("Coming up")
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)

            ForEach(Array(ReviewComingUpBucket.allCases.enumerated()), id: \.offset) { index, bucket in
                if index > 0 {
                    Divider().overlay(Color.nichijiHairline)
                }
                HStack {
                    Text(bucket.title)
                        .font(.nichijiBody)
                        .foregroundColor(.nichijiInk)
                    Spacer()
                    Text("\(summary.count(for: bucket)) kanji")
                        .font(.nichijiCallout)
                        .monospacedDigit()
                        .foregroundColor(.nichijiInkMuted)
                }
                .frame(minHeight: LayoutTokens.minHitTarget)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(LayoutTokens.space24)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }
}

/*--------------------------------week-card-------------------------------*/

struct ReviewWeekCard: View {
    let week: [ReviewWeekDay]

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            Text("This week")
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)

            HStack(spacing: 0) {
                ForEach(week, id: \.calendarDay) { day in
                    VStack(spacing: LayoutTokens.space8) {
                        Text(day.label)
                            .font(.nichijiCaption)
                            .foregroundColor(.nichijiInkSubtle)
                        dot(for: day)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.label), \(day.isStudyDay ? "reviewed" : "not yet")")
                }
            }
        }
        .padding(LayoutTokens.space24)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusLarge, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
    }

    private func dot(for day: ReviewWeekDay) -> some View {
        Circle()
            .fill(day.isStudyDay ? Color.nichijiMatchaWash : Color.clear)
            .overlay(
                Circle().stroke(
                    day.isStudyDay ? Color.nichijiMatcha : (day.isToday ? Color.nichijiInk : Color.nichijiHairline),
                    lineWidth: 1
                )
            )
            .overlay {
                if day.isStudyDay {
                    Image(systemName: "checkmark")
                        .font(.nichijiCaption.weight(.medium))
                        .foregroundColor(.nichijiMatcha)
                }
            }
            .frame(width: 32, height: 32)
    }
}
