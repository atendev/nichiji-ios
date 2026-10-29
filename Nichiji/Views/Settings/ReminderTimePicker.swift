import SwiftUI

/*------------------------------time-picker-------------------------------*/

/// Preset time chips plus a compact custom `DatePicker`, shared by Settings and onboarding.
struct ReminderTimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    private var selectedTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                let newHour = components.hour ?? hour
                let newMinute = components.minute ?? minute
                guard newHour != hour || newMinute != minute else { return }
                hour = newHour
                minute = newMinute
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space12) {
            Text("Time")
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)

            HStack(spacing: LayoutTokens.space8) {
                ForEach(ReminderPreset.allCases, id: \.self) { preset in
                    let isSelected = hour == preset.hour && minute == preset.minute
                    Button {
                        hour = preset.hour
                        minute = preset.minute
                    } label: {
                        HStack(spacing: 6) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.nichijiVermilion)
                            }
                            Text(preset.label)
                                .font(.uiText(size: 14, weight: .medium))
                                .foregroundColor(.nichijiInk)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .cardBackground(
                            cornerRadius: LayoutTokens.cornerRadiusSmall,
                            fill: isSelected ? .nichijiVermilionWash : .nichijiSurfaceRaised,
                            stroke: isSelected ? .nichijiVermilion : .nichijiBorderControl
                        )
                    }
                    .buttonStyle(.plain)
                    .minTouchTarget()
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            HStack {
                Text("Custom time")
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)

                Spacer()

                DatePicker(
                    "Custom reminder time",
                    selection: selectedTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .tint(.nichijiVermilion)
            }
            .padding(.horizontal, LayoutTokens.space16)
            .frame(minHeight: 56)
            .cardBackground(cornerRadius: LayoutTokens.cornerRadiusSmall, fill: .nichijiSurfaceRaised, stroke: .nichijiHairline)
        }
    }
}

private enum ReminderPreset: CaseIterable {
    case morning
    case midday
    case evening

    var hour: Int {
        switch self {
        case .morning: 8
        case .midday: 12
        case .evening: 20
        }
    }

    var minute: Int { 0 }

    var label: String {
        switch self {
        case .morning: "8:00 am"
        case .midday: "12:00 pm"
        case .evening: "8:00 pm"
        }
    }
}
