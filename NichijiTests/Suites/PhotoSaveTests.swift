import Foundation
import Testing
@testable import Nichiji

/*---------------------------photo-save-tests-----------------------------*/

/// Records what it was asked to save and answers with a set outcome, optionally held until the test opens it.
private actor StubPhotoLibrary: PhotoLibrarySaving {
    private(set) var saved: [Data] = []
    private let outcome: PhotoSaveOutcome
    private var waiter: CheckedContinuation<Void, Never>?
    private var isHeld: Bool

    init(outcome: PhotoSaveOutcome, held: Bool = false) {
        self.outcome = outcome
        self.isHeld = held
    }

    func save(imageData: Data) async -> PhotoSaveOutcome {
        saved.append(imageData)
        if isHeld {
            await withCheckedContinuation { waiter = $0 }
        }
        return outcome
    }

    func release() {
        isHeld = false
        waiter?.resume()
        waiter = nil
    }
}

@MainActor
@Suite("Photo Save Tests")
struct PhotoSaveTests {
    private let photo = Data([1, 2, 3])

    @Test("A library photo cannot be saved, a shot or a crop can")
    func originRule() {
        #expect(PhotoOrigin.camera.isSavable)
        #expect(PhotoOrigin.cropped.isSavable)
        #expect(!PhotoOrigin.library.isSavable)
    }

    @Test("A saved photo shows the Saved to Photos toast for about 1.8 s")
    func savedToast() async {
        let library = StubPhotoLibrary(outcome: .saved)
        let model = PhotoSaveModel(library: library)

        await model.save(imageData: photo)

        #expect(model.toast == .saved)
        #expect(model.toast?.message == "Saved to Photos")
        #expect(model.toast?.duration == 1.8)
        #expect(await library.saved == [photo])
        #expect(!model.isSaving)
    }

    @Test("Denied access reports it and saves nothing")
    func deniedToast() async {
        let model = PhotoSaveModel(library: StubPhotoLibrary(outcome: .denied))

        await model.save(imageData: photo)

        #expect(model.toast == .denied)
        #expect(model.toast?.message == "Photos access is off")
    }

    @Test("A write error reads The photo couldn't be saved")
    func failedToast() async {
        let model = PhotoSaveModel(library: StubPhotoLibrary(outcome: .failed))

        await model.save(imageData: photo)

        #expect(model.toast == .failed)
        #expect(model.toast?.message == "The photo couldn\u{2019}t be saved.")
    }

    @Test("With no photo there is nothing to write, so it fails without asking Photos")
    func noPhoto() async {
        let library = StubPhotoLibrary(outcome: .saved)
        let model = PhotoSaveModel(library: library)

        await model.save(imageData: nil)

        #expect(model.toast == .failed)
        #expect(await library.saved.isEmpty)
    }

    @Test("A second tap while one save runs is ignored")
    func oneAtATime() async {
        let library = StubPhotoLibrary(outcome: .saved, held: true)
        let model = PhotoSaveModel(library: library)

        let first = Task { await model.save(imageData: photo) }
        while !model.isSaving { await Task.yield() }
        await model.save(imageData: photo)
        await library.release()
        await first.value

        #expect(await library.saved.count == 1)
        #expect(model.toast == .saved)
    }

    @Test("A timer only clears the toast it was set for")
    func staleTimer() async {
        let model = PhotoSaveModel(library: StubPhotoLibrary(outcome: .saved))
        await model.save(imageData: photo)
        let firstID = model.toastID
        await model.save(imageData: photo)

        model.dismissToast(id: firstID)
        #expect(model.toast == .saved)

        model.dismissToast(id: model.toastID)
        #expect(model.toast == nil)
    }

    @Test("Dismissing with no id clears any toast")
    func dismissAny() async {
        let model = PhotoSaveModel(library: StubPhotoLibrary(outcome: .denied))
        await model.save(imageData: photo)

        model.dismissToast()

        #expect(model.toast == nil)
    }
}
