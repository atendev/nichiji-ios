import SwiftUI

/*---------------------------------button---------------------------------*/

public struct PrimaryButton: View {
    public let title: String
    public let action: () -> Void
    public var isEnabled: Bool = true

    public init(title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.nichijiBody)
                .foregroundColor(.nichijiOnVermilion)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LayoutTokens.minHitTarget)
                .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusMedium, style: .continuous))
        }
        .disabled(!isEnabled)
        .buttonStyle(NichijiPrimaryButtonStyle(isEnabled: isEnabled))
        .accessibilityIdentifier("primaryButton")
        .accessibilityLabel(title)
    }
}

private struct NichijiPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isEnabled ? (configuration.isPressed
                ? Color.nichijiVermilionHover
                : Color.nichijiVermilion) : Color.nichijiBorderControl)
            .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusMedium, style: .continuous))
            .opacity(isEnabled ? 1 : 0.6)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.9),
                value: configuration.isPressed
            )
    }
}
