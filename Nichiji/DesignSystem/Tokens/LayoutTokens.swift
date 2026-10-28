import SwiftUI

/*---------------------------------layout---------------------------------*/

public enum LayoutTokens {
    // Minimum interactive hit target size per Apple HIG.
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
}

/*----------------------------------TODO----------------------------------*/

// TODO: Enforce continuous corner radii and minimum hit target padding modifiers in Slice 1.
