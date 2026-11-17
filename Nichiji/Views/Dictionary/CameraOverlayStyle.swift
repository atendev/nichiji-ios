import SwiftUI

/*--------------------------------overlay---------------------------------*/

/// The camera's overlay colors. They stay the same in Light and Dark, because they sit over the live feed.
extension Color {
    static let cameraInk = Color(red: 21 / 255, green: 19 / 255, blue: 15 / 255, opacity: 0.55)
    static let cameraOutline = Color(red: 239 / 255, green: 232 / 255, blue: 216 / 255, opacity: 0.25)
    static let cameraText = Color(red: 239 / 255, green: 232 / 255, blue: 216 / 255)
    /// The backdrop behind the feed, and the base of the edge gradients.
    static let cameraBase = Color(red: 21 / 255, green: 19 / 255, blue: 15 / 255)
}

/*--------------------------------reticle---------------------------------*/

/// Four corner brackets that frame where to aim.
struct ViewfinderReticle: Shape {
    static let lineWidth: CGFloat = 3
    private static let arm: CGFloat = 34
    private static let radius: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        let frame = rect.insetBy(dx: Self.lineWidth / 2, dy: Self.lineWidth / 2)
        let arm = Self.arm
        let radius = Self.radius
        var path = Path()

        path.move(to: CGPoint(x: frame.minX, y: frame.minY + arm))
        path.addArc(tangent1End: CGPoint(x: frame.minX, y: frame.minY), tangent2End: CGPoint(x: frame.minX + arm, y: frame.minY), radius: radius)
        path.addLine(to: CGPoint(x: frame.minX + arm, y: frame.minY))

        path.move(to: CGPoint(x: frame.maxX - arm, y: frame.minY))
        path.addArc(tangent1End: CGPoint(x: frame.maxX, y: frame.minY), tangent2End: CGPoint(x: frame.maxX, y: frame.minY + arm), radius: radius)
        path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY + arm))

        path.move(to: CGPoint(x: frame.maxX, y: frame.maxY - arm))
        path.addArc(tangent1End: CGPoint(x: frame.maxX, y: frame.maxY), tangent2End: CGPoint(x: frame.maxX - arm, y: frame.maxY), radius: radius)
        path.addLine(to: CGPoint(x: frame.maxX - arm, y: frame.maxY))

        path.move(to: CGPoint(x: frame.minX + arm, y: frame.maxY))
        path.addArc(tangent1End: CGPoint(x: frame.minX, y: frame.maxY), tangent2End: CGPoint(x: frame.minX, y: frame.maxY - arm), radius: radius)
        path.addLine(to: CGPoint(x: frame.minX, y: frame.maxY - arm))

        return path
    }
}

/*---------------------------------shade----------------------------------*/

/// The vignette and the top and bottom fades that keep the controls readable over any feed.
struct ViewfinderShade: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [.clear, .black.opacity(0.5)],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 260,
                endRadius: 620
            )
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.cameraBase.opacity(0.6), Color.cameraBase.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                Spacer(minLength: 0)
                LinearGradient(colors: [Color.cameraBase.opacity(0), Color.cameraBase.opacity(0.78)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 250)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/*----------------------------------pill----------------------------------*/

/// The hint pill above the shutter.
struct ViewfinderHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.uiText(size: 14))
            .foregroundStyle(Color.cameraText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, LayoutTokens.space16)
            .padding(.vertical, LayoutTokens.space8)
            .frame(minHeight: 36)
            .background(Capsule().fill(Color.cameraInk))
            .overlay(Capsule().stroke(Color.cameraOutline, lineWidth: 1))
    }
}
