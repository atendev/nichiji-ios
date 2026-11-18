import SwiftUI
import UIKit

/*---------------------------------toast----------------------------------*/

/// The pill under the top bar that reports Save: "Saved to Photos" with a green check, or the denied and failed notes. Denied also offers Open Settings.
struct PhotoSaveToastView: View {
    let model: PhotoSaveModel

    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            if let toast = model.toast {
                pill(for: toast)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .padding(.top, LayoutTokens.minHitTarget + LayoutTokens.space24)
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.9), value: model.toast)
        .task(id: model.toastID) {
            guard let toast = model.toast else { return }
            let id = model.toastID
            AccessibilityNotification.Announcement(toast.message).post()
            try? await Task.sleep(for: .seconds(toast.duration))
            if !Task.isCancelled { model.dismissToast(id: id) }
        }
    }

    private func pill(for toast: PhotoSaveToast) -> some View {
        HStack(spacing: LayoutTokens.space12) {
            Image(systemName: toast == .saved ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(toast == .saved ? Color.cameraLearned : Color.cameraNew)
                .accessibilityHidden(true)
            Text(toast.message)
                .font(.uiText(size: 14, weight: .medium))
                .foregroundStyle(Color.cameraText)
                .fixedSize(horizontal: false, vertical: true)
            if toast == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
                Button(PhotoLookupCopy.openSettings) { openURL(url) }
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundStyle(Color.cameraText)
                    .underline()
                    .frame(minHeight: LayoutTokens.minHitTarget)
            }
        }
        .padding(.horizontal, LayoutTokens.space16)
        .padding(.vertical, LayoutTokens.space8)
        .background(Capsule().fill(Color.cameraInk))
        .overlay(Capsule().stroke(Color.cameraOutline, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}

/*---------------------------------option---------------------------------*/

/// The labelled Save option at the top right. It saves the image it is given and waits for a write in progress.
struct SavePhotoOption: View {
    let saver: PhotoSaveModel
    let imageData: Data?

    var body: some View {
        PhotoOptionButton(
            systemName: "square.and.arrow.down",
            label: PhotoSaveCopy.save,
            hint: PhotoSaveCopy.hint
        ) {
            Task { await saver.save(imageData: imageData) }
        }
        .disabled(saver.isSaving)
    }
}
