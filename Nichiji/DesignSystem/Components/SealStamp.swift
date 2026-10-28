import SwiftUI

/*----------------------------------seal----------------------------------*/

public struct SealStamp: View {
    public let text: String

    public init(text: String = "Got it") {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            Image(systemName: "checkmark")
                .font(.nichijiCaption.bold())
            Text(text)
                .font(.nichijiCallout)
        }
        .foregroundColor(.nichijiMatcha)
        .padding(.horizontal, LayoutTokens.space12)
        .padding(.vertical, LayoutTokens.space8)
        .background(Color.nichijiMatchaWash)
        .clipShape(Capsule())
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Render the authentic hanko seal SVG asset alongside the matcha status badge in Slice 6.
