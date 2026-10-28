import SwiftUI

/*---------------------------------layout---------------------------------*/

public enum LayoutTokens {
    // Minimum interactive hit target size per Apple HIG (44x44 pt).
    public static let minHitTarget: CGFloat = 44.0

    // Standard 8pt spacing grid multiples.
    public static let space4: CGFloat = 4.0
    public static let space8: CGFloat = 8.0
    public static let space12: CGFloat = 12.0
    public static let space16: CGFloat = 16.0
    public static let space24: CGFloat = 24.0
    public static let space32: CGFloat = 32.0
    public static let space48: CGFloat = 48.0

    // Continuous corner radii for cards, buttons, and sheets.
    public static let cornerRadiusSmall: CGFloat = 8.0
    public static let cornerRadiusMedium: CGFloat = 16.0
    public static let cornerRadiusLarge: CGFloat = 24.0

    // Screen padding margins.
    public static let screenMarginCompact: CGFloat = 16.0
    public static let screenMarginRegular: CGFloat = 24.0
}

/*--------------------------------modifiers-------------------------------*/

public struct MinTouchTargetModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .frame(minWidth: LayoutTokens.minHitTarget, minHeight: LayoutTokens.minHitTarget)
            .contentShape(Rectangle())
    }
}

public extension View {
    // Enforces the Apple HIG 44x44 pt touch target and interactive shape.
    func minTouchTarget() -> some View {
        modifier(MinTouchTargetModifier())
    }

    // Applies a continuous rounded rectangle clip shape.
    func continuousCornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
