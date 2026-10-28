import SwiftUI

/*---------------------------------colors---------------------------------*/

public extension Color {
    // Semantic surfaces adapting to Washi (light) and Sumi (dark) themes.
    static let nichijiSurface = Color("surface", bundle: nil)
    static let nichijiSurfaceRaised = Color("surface-raised", bundle: nil)
    static let nichijiSurfaceSunken = Color("surface-sunken", bundle: nil)

    // Ink text and line hierarchies.
    static let nichijiInk = Color("ink", bundle: nil)
    static let nichijiInkMuted = Color("ink-muted", bundle: nil)
    static let nichijiInkSubtle = Color("ink-subtle", bundle: nil)
    static let nichijiHairline = Color("hairline", bundle: nil)
    static let nichijiBorderControl = Color("border-control", bundle: nil)

    // Brand and functional accent colors.
    static let nichijiVermilion = Color("vermilion", bundle: nil)
    static let nichijiVermilionHover = Color("vermilion-hover", bundle: nil)
    static let nichijiOnVermilion = Color("on-vermilion", bundle: nil)
    static let nichijiVermilionWash = Color("vermilion-wash", bundle: nil)

    // State badges and progress indicators.
    static let nichijiMatcha = Color("matcha", bundle: nil)
    static let nichijiMatchaWash = Color("matcha-wash", bundle: nil)
    static let nichijiMustard = Color("mustard", bundle: nil)
    static let nichijiMustardText = Color("mustard-text", bundle: nil)
    static let nichijiMustardWash = Color("mustard-wash", bundle: nil)
}

/*----------------------------------TODO----------------------------------*/

// TODO: Bind dynamic color asset catalog entries in Slice 1 so colors resolve with exact hex values offline.
