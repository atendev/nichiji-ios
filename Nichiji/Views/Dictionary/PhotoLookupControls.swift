import SwiftUI

/*-------------------------------controls---------------------------------*/

/// A round button on dark material, for controls that sit over the camera.
struct CameraChromeButton: View {
    let systemName: String
    let label: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CameraChromeIcon(systemName: systemName, side: LayoutTokens.minHitTarget, isActive: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct CameraChromeIcon: View {
    let systemName: String
    let side: CGFloat
    var isActive = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isActive ? Color.black : Color.white)
            .frame(width: side, height: side)
            .background {
                if isActive {
                    Circle().fill(Color.white)
                } else {
                    Circle().fill(.ultraThinMaterial)
                }
            }
            .environment(\.colorScheme, .dark)
            .contentShape(Circle())
    }
}

struct ShutterButton: View {
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: PhotoLookupLayout.shutterRing)
                    .frame(width: PhotoLookupLayout.shutterOuter, height: PhotoLookupLayout.shutterOuter)
                Circle()
                    .fill(Color.white)
                    .frame(width: PhotoLookupLayout.shutterInner, height: PhotoLookupLayout.shutterInner)
            }
            .contentShape(Circle())
        }
        .buttonStyle(ShutterPressStyle())
        .disabled(isBusy)
        .accessibilityLabel(PhotoLookupCopy.shutter)
        .accessibilityHint(PhotoLookupCopy.shutterHint)
    }
}

struct ShutterPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

/// The square that marks a tap-to-focus point, then fades.
struct FocusSquare: View {
    let trigger: Int

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .stroke(Color.nichijiMustard, lineWidth: 1.5)
            .frame(width: PhotoLookupLayout.focusSide, height: PhotoLookupLayout.focusSide)
            .scaleEffect(scale)
            .opacity(opacity)
            .task(id: trigger) {
                opacity = 1
                scale = 1.25
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { scale = 1 }
                try? await Task.sleep(for: .seconds(0.9))
                withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
            }
            .accessibilityHidden(true)
    }
}

/*---------------------------------button---------------------------------*/

/// The full-width button under "Draw a kanji to search".
struct PhotoLookupButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutTokens.space8) {
                Image(systemName: "camera.viewfinder")
                    .accessibilityHidden(true)
                Text(PhotoLookupCopy.buttonTitle)
            }
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .frame(maxWidth: .infinity)
            .frame(minHeight: LayoutTokens.minHitTarget)
            .padding(.horizontal, LayoutTokens.space16)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                    .stroke(Color.nichijiBorderControl, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PhotoLookupCopy.buttonTitle)
        .accessibilityHint(PhotoLookupCopy.buttonHint)
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.bottom, LayoutTokens.space8)
    }
}
