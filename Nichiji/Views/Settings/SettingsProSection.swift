import SwiftUI

/*--------------------------------copy------------------------------------*/

enum SettingsProCopy {
    static let header = "NICHIJI PRO"
    static let title = "Nichiji Pro"
    static let features = "Lock screen widgets, history export, photo lookup and handwriting search."
    static let devUnlockTitle = "Developer unlock"
    static let devUnlockSubtitle = "Debug builds only. Unlocks Pro without a purchase."

    static func status(_ access: ProAccess) -> String {
        if access.isPurchased { return "Unlocked" }
        return access.isDevUnlocked ? "Dev unlock" : "Not purchased"
    }
}

/*-------------------------------section----------------------------------*/

/// Pro status and Restore purchases. It never opens the paywall; only a tapped Pro feature does.
struct SettingsProSection: View {
    @Environment(ProAccessModel.self) private var proAccess: ProAccessModel?

    @State private var isRestoring = false
    @State private var restoreMessage: PaywallMessage?

    var body: some View {
        if let proAccess {
            VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                sectionHeader(SettingsProCopy.header)

                VStack(spacing: 0) {
                    statusRow(proAccess.access)
                    dividerLine
                    restoreRow(proAccess)
                    #if DEBUG
                    dividerLine
                    settingsToggleRow(
                        title: SettingsProCopy.devUnlockTitle,
                        subtitle: SettingsProCopy.devUnlockSubtitle,
                        isOn: Binding(
                            get: { proAccess.access.isDevUnlocked },
                            set: { proAccess.setDevUnlocked($0) }
                        )
                    )
                    #endif
                }
                .settingsGroupBackground()

                if let restoreMessage {
                    Text(PaywallCopy.text(for: restoreMessage))
                        .font(.nichijiCaption)
                        .foregroundColor(.nichijiInkMuted)
                        .padding(.horizontal, LayoutTokens.space8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func statusRow(_ access: ProAccess) -> some View {
        HStack(spacing: LayoutTokens.space12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(SettingsProCopy.title)
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                Text(SettingsProCopy.features)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(SettingsProCopy.status(access))
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
        }
        .padding(.horizontal, LayoutTokens.space16)
        .padding(.vertical, LayoutTokens.space8)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }

    private func restoreRow(_ proAccess: ProAccessModel) -> some View {
        Button {
            Task {
                isRestoring = true
                restoreMessage = nil
                restoreMessage = await ProRestore.run(proAccess)
                isRestoring = false
            }
        } label: {
            HStack(spacing: LayoutTokens.space12) {
                Text(isRestoring ? PaywallCopy.restoring : PaywallCopy.restore)
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isRestoring {
                    ProgressView()
                }
            }
            .padding(.horizontal, LayoutTokens.space16)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isRestoring)
    }
}
