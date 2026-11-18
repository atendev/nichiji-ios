import Foundation
import Observation
import Photos

/*---------------------------------origin---------------------------------*/

/// Where the frozen photo came from. Crop sets `.cropped` when it replaces the photo.
enum PhotoOrigin: Equatable, Sendable {
    case camera
    case library
    case cropped

    /// A library photo is already in Photos, so Save only shows for a shot or a crop.
    var isSavable: Bool { self != .library }
}

/*--------------------------------library---------------------------------*/

enum PhotoSaveOutcome: Equatable, Sendable {
    case saved
    /// Photos access is off or restricted, so nothing was written.
    case denied
    case failed
}

protocol PhotoLibrarySaving: Sendable {
    func save(imageData: Data) async -> PhotoSaveOutcome
}

/// Writes to Photos with add-only access, asked for on the first save.
struct SystemPhotoLibrarySaver: PhotoLibrarySaving {
    func save(imageData: Data) async -> PhotoSaveOutcome {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return .denied }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: imageData, options: nil)
            }
            return .saved
        } catch {
            return .failed
        }
    }
}

/*---------------------------------toast----------------------------------*/

enum PhotoSaveToast: Equatable, Sendable {
    case saved
    case denied
    case failed

    /// Seconds on screen. The design's "Saved to Photos" lasts about 1.8; the problems stay longer to be read.
    var duration: Double { self == .saved ? 1.8 : 5 }

    var message: String {
        switch self {
        case .saved: PhotoSaveCopy.saved
        case .denied: PhotoSaveCopy.denied
        case .failed: PhotoSaveCopy.failed
        }
    }
}

enum PhotoSaveCopy {
    static let save = "Save"
    static let hint = "Saves the photo to Photos"
    static let saved = "Saved to Photos"
    static let denied = "Photos access is off"
    static let failed = "The photo couldn\u{2019}t be saved."
}

/*---------------------------------model----------------------------------*/

/// One Save at a time, and the toast that reports it. The image comes from the caller, so it is whichever photo is current.
@MainActor
@Observable
final class PhotoSaveModel {
    private(set) var toast: PhotoSaveToast?
    private(set) var isSaving = false
    /// Changes with every toast, so a view can time each one on its own.
    private(set) var toastID = 0

    private let library: any PhotoLibrarySaving

    init(library: any PhotoLibrarySaving) {
        self.library = library
    }

    func save(imageData: Data?) async {
        guard !isSaving else { return }
        guard let imageData else {
            show(.failed)
            return
        }
        isSaving = true
        let outcome = await library.save(imageData: imageData)
        isSaving = false
        switch outcome {
        case .saved: show(.saved)
        case .denied: show(.denied)
        case .failed: show(.failed)
        }
    }

    /// Clears the toast, unless a newer one has replaced the one a timer was set for.
    func dismissToast(id: Int? = nil) {
        guard id == nil || id == toastID else { return }
        toast = nil
    }

    private func show(_ next: PhotoSaveToast) {
        toastID += 1
        toast = next
    }
}
