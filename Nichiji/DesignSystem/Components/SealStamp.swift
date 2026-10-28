import SwiftUI

/*----------------------------------seal----------------------------------*/

public struct SealStamp: View {
    public let text: String

    public init(text: String = "Got it") {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            ZStack {
                Circle()
                    .stroke(Color.nichijiMatcha, lineWidth: 1.5)
                Image(systemName: "checkmark")
                    .font(.nichijiCaption.weight(.semibold))
            }
            .frame(width: LayoutTokens.space16, height: LayoutTokens.space16)
            Text(text)
                .font(.nichijiCallout)
        }
        .foregroundColor(.nichijiMatcha)
        .padding(.horizontal, LayoutTokens.space12)
        .padding(.vertical, LayoutTokens.space8)
        .background(Color.nichijiMatchaWash)
        .clipShape(Capsule())
        .frame(minHeight: LayoutTokens.minHitTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
