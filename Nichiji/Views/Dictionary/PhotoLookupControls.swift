import SwiftUI

/*-------------------------------controls---------------------------------*/

/// A round button on the camera overlay's dark ink, for controls that sit over the feed.
struct CameraChromeButton: View {
    let systemName: String
    let label: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.cameraText)
                .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                .background(Circle().fill(Color.cameraInk))
                .overlay(Circle().stroke(Color.cameraOutline, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// The library button's face: a rounded square, as in the design.
struct CameraLibraryIcon: View {
    var body: some View {
        Image(systemName: "photo")
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(Color.cameraText)
            .frame(width: PhotoLookupLayout.controlSide, height: PhotoLookupLayout.controlSide)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.cameraInk))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.cameraText.opacity(0.3), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// The neutral shutter: a light ring around a light disc.
struct ShutterButton: View {
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.cameraText, lineWidth: PhotoLookupLayout.shutterRing)
                    .frame(width: PhotoLookupLayout.shutterOuter, height: PhotoLookupLayout.shutterOuter)
                Circle()
                    .fill(Color.cameraText)
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
