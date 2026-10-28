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
                .background(isEnabled ? Color.nichijiVermilion : Color.nichijiBorderControl)
                .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusMedium, style: .continuous))
        }
        .disabled(!isEnabled)
        .accessibilityIdentifier("primaryButton")
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Add interactive press scale feedback and vermilion-hover color transitions respecting Reduce Motion in Slice 6.
