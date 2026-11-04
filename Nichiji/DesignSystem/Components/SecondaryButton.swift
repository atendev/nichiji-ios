import SwiftUI

/*--------------------------------button----------------------------------*/

/// Bordered, transparent button for the action beside a primary one.
public struct SecondaryButton: View {
    public let title: String
    public let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

/*---------------------------------style----------------------------------*/

/// Shared look for `SecondaryButton`, also applied straight to controls like `ShareLink`.
public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nichijiCallout.weight(.medium))
            .foregroundColor(.nichijiInk)
            .frame(maxWidth: .infinity, minHeight: LayoutTokens.minHitTarget)
            .padding(.horizontal, LayoutTokens.space16)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .fill(configuration.isPressed ? Color.nichijiSurfaceSunken : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(Color.nichijiBorderControl, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.9),
                value: configuration.isPressed
            )
    }
}
