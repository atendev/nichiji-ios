import PhotosUI
import SwiftUI
import UIKit

/*----------------------------------copy----------------------------------*/

enum PhotoLookupCopy {
    static let buttonTitle = "Scan a kanji"
    static let buttonHint = "Opens the camera to find kanji in a photo"
    /// The title the pushed detail screen's back button shows.
    static let backTitle = "Scan results"
    static let aimHint = "Point at a kanji, then tap the shutter"
    static let captureFailed = "The photo didn\u{2019}t take. Try again."
    static let reading = "Reading the photo\u{2026}"
    static let newToYou = "New to you"
    static let noKanji = "No kanji found. Try a closer, sharper photo."
    static let allStarted = "You have started every kanji found here."
    static let failed = "That photo could not be read."
    static let photoLabel = "The photo being read"

    static let close = "Close"
    static let shutter = "Take photo"
    static let shutterHint = "Takes a photo and finds the kanji in it"
    static let library = "Choose from library"
    static let torchOn = "Turn on flashlight"
    static let torchOff = "Turn off flashlight"
    static let retake = "Retake"
    static let retakeHint = "Goes back to the camera"
    static let focusHint = "Double-tap to focus on the middle of the view"

    static let deniedTitle = "Camera access is off"
    static let deniedBody = "Turn on the camera for Nichiji in Settings, or choose a photo from your library."
    static let openSettings = "Open Settings"
    static let noCameraTitle = "No camera here"
    static let noCameraBody = "Choose a photo from your library instead."

    static func foundCount(_ count: Int) -> String {
        count == 1 ? "1 kanji found" : "\(count) kanji found"
    }
}

/*---------------------------------layout---------------------------------*/

enum PhotoLookupLayout {
    static let shutterOuter: CGFloat = 76
    static let shutterInner: CGFloat = 58
    static let shutterRing: CGFloat = 4
    static let controlSide: CGFloat = 52
    static let focusSide: CGFloat = 72
    /// The reticle's box on the design's 390 x 844 artboard.
    static let reticleInset: CGFloat = 29
    static let reticleHeight: CGFloat = 360
    static let reticleTopShare: CGFloat = 160 / 844
    /// The shutter's white flash, in seconds.
    static let flashDuration: Double = 0.2
    /// The results panel never covers more than this share of the screen, so the photo stays in view.
    static let panelMaxShare: CGFloat = 0.55
}

/*---------------------------------screen---------------------------------*/

/// "Scan a kanji": a full-screen camera pushed onto the Dictionary stack. One shutter tap reads the shot, which stays frozen behind a panel of every bundled kanji in it.
struct PhotoLookupScreen: View {
    @Bindable var model: PhotoLookupModel
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var camera = CameraSession()
    @State private var frozenImage: UIImage?
    @State private var libraryItem: PhotosPickerItem?
    @State private var isCapturing = false
    @State private var shutterCount = 0
    @State private var captureFailed = false
    @State private var focusPoint: CGPoint?
    @State private var focusCount = 0
    @State private var previewSize: CGSize = .zero

    private var isLive: Bool { model.state == .empty }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ZStack {
                    Color.cameraBase
                    backdrop
                    if isLive, camera.access == .authorized {
                        ViewfinderShade()
                    }
                    if !reduceMotion {
                        shutterFlash
                    }
                }
                .ignoresSafeArea()

                if isLive, camera.access == .authorized {
                    reticle(in: proxy.size)
                }

                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: LayoutTokens.space16)
                    if isLive {
                        captureControls
                            .transition(.opacity)
                    } else {
                        PhotoLookupResultsPanel(model: model, maxHeight: proxy.size.height * PhotoLookupLayout.panelMaxShare, onPick: onPick)
                            .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    }
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.9), value: isLive)
        }
        .statusBarHidden()
        // The stack's own bars stay away, but the title is what detail's back button reads.
        .navigationTitle(PhotoLookupCopy.backTitle)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sensoryFeedback(.impact(weight: .medium), trigger: shutterCount)
        .task {
            if isLive { await camera.start() }
        }
        .onDisappear { camera.stop() }
        .onChange(of: isLive) { _, live in
            if live {
                Task { await camera.start() }
            } else {
                camera.stop()
            }
        }
        .onChange(of: model.photoData, initial: true) { _, data in
            frozenImage = data.flatMap(UIImage.init(data:))
        }
        .onChange(of: libraryItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await model.lookUp(imageData: data)
                }
                libraryItem = nil
            }
        }
    }

    /*-----------------------------actions------------------------------*/

    private func shoot() {
        guard !isCapturing else { return }
        isCapturing = true
        shutterCount += 1
        captureFailed = false
        Task {
            let data = await camera.capture()
            isCapturing = false
            if let data {
                await model.lookUp(imageData: data)
            } else {
                captureFailed = true
            }
        }
    }

    private func focus(at point: CGPoint) {
        camera.focus(atLayerPoint: point)
        focusPoint = point
        focusCount += 1
    }

    /*------------------------------viewfinder----------------------------*/

    /// A white blink of about 0.2 s on each shot.
    private var shutterFlash: some View {
        Color.white
            .phaseAnimator([0.0, 0.9, 0.0], trigger: shutterCount) { flash, opacity in
                flash.opacity(opacity)
            } animation: { _ in .easeOut(duration: PhotoLookupLayout.flashDuration / 2) }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func reticle(in size: CGSize) -> some View {
        let height = min(PhotoLookupLayout.reticleHeight, size.height * 0.42)
        return ViewfinderReticle()
            .stroke(Color.cameraText, style: StrokeStyle(lineWidth: ViewfinderReticle.lineWidth, lineCap: .round))
            .frame(width: max(0, size.width - PhotoLookupLayout.reticleInset * 2), height: height)
            .position(x: size.width / 2, y: size.height * PhotoLookupLayout.reticleTopShare + height / 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /*------------------------------backdrop------------------------------*/

    @ViewBuilder private var backdrop: some View {
        if let frozenImage, !isLive {
            Image(uiImage: frozenImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityLabel(PhotoLookupCopy.photoLabel)
        } else {
            switch camera.access {
            case .authorized:
                livePreview
            case .notDetermined:
                Color.cameraBase
            case .denied:
                accessMessage(title: PhotoLookupCopy.deniedTitle, message: PhotoLookupCopy.deniedBody, showsSettings: true)
            case .unavailable:
                accessMessage(title: PhotoLookupCopy.noCameraTitle, message: PhotoLookupCopy.noCameraBody, showsSettings: false)
            }
        }
    }

    private var livePreview: some View {
        CameraPreview(camera: camera)
            .overlay {
                GeometryReader { _ in
                    if let focusPoint {
                        FocusSquare(trigger: focusCount)
                            .position(focusPoint)
                    }
                }
                .allowsHitTesting(false)
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { previewSize = $0 }
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { point in
                focus(at: point)
            }
            .accessibilityElement()
            .accessibilityLabel("Camera view")
            .accessibilityHint(PhotoLookupCopy.focusHint)
            .accessibilityAction {
                focus(at: CGPoint(x: previewSize.width / 2, y: previewSize.height / 2))
            }
    }

    private func accessMessage(title: String, message: String, showsSettings: Bool) -> some View {
        VStack(spacing: LayoutTokens.space16) {
            Image(systemName: "camera")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Color.cameraText.opacity(0.7))
                .accessibilityHidden(true)
            Text(title)
                .font(.nichijiHeading)
                .foregroundStyle(Color.cameraText)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.nichijiCallout)
                .foregroundStyle(Color.cameraText.opacity(0.75))
                .multilineTextAlignment(.center)
            if showsSettings, let url = URL(string: UIApplication.openSettingsURLString) {
                PrimaryButton(title: PhotoLookupCopy.openSettings) {
                    openURL(url)
                }
                .padding(.top, LayoutTokens.space8)
            }
        }
        .padding(.horizontal, LayoutTokens.space32)
        .frame(maxWidth: 420)
    }

    /*-------------------------------chrome-------------------------------*/

    private var topBar: some View {
        HStack {
            CameraChromeButton(systemName: "xmark", label: PhotoLookupCopy.close) {
                dismiss()
            }
            Spacer()
            if isLive, camera.access == .authorized, camera.hasTorch {
                CameraChromeButton(
                    systemName: camera.isTorchOn ? "bolt.fill" : "bolt",
                    label: camera.isTorchOn ? PhotoLookupCopy.torchOff : PhotoLookupCopy.torchOn,
                    isActive: camera.isTorchOn
                ) {
                    camera.toggleTorch()
                }
            }
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.top, LayoutTokens.space8)
    }

    private var captureControls: some View {
        VStack(spacing: LayoutTokens.space24) {
            if camera.access == .authorized {
                ViewfinderHint(text: captureFailed ? PhotoLookupCopy.captureFailed : PhotoLookupCopy.aimHint)
            }

            HStack {
                PhotosPicker(selection: $libraryItem, matching: .images) {
                    CameraLibraryIcon()
                }
                .accessibilityLabel(PhotoLookupCopy.library)

                Spacer()

                if camera.access == .authorized {
                    ShutterButton(isBusy: isCapturing, action: shoot)
                }

                Spacer()

                Color.clear
                    .frame(width: PhotoLookupLayout.controlSide, height: PhotoLookupLayout.controlSide)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, LayoutTokens.space32)
        }
        .padding(.bottom, LayoutTokens.space24)
    }
}
