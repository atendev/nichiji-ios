import PhotosUI
import SwiftUI
import UIKit

/*----------------------------------copy----------------------------------*/

enum PhotoLookupCopy {
    static let buttonTitle = "Look up kanji in a photo"
    static let buttonHint = "Opens the camera to find kanji in a photo"
    static let aimHint = "Fill the frame with the text"
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
    static let shutterOuter: CGFloat = 72
    static let shutterInner: CGFloat = 60
    static let shutterRing: CGFloat = 4
    static let controlSide: CGFloat = 52
    static let focusSide: CGFloat = 72
    /// The results panel never covers more than this share of the screen, so the photo stays in view.
    static let panelMaxShare: CGFloat = 0.55
}

/*---------------------------------screen---------------------------------*/

/// "Photo lookup": a full-screen camera. One shutter tap reads the shot, which stays frozen behind a panel of every bundled kanji in it.
struct PhotoLookupScreen: View {
    @Bindable var model: PhotoLookupModel
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

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
                    Color.black
                    backdrop
                    // A quick blink, as the system camera does on each shot.
                    Color.black
                        .phaseAnimator([0.0, 0.85, 0.0], trigger: shutterCount) { flash, opacity in
                            flash.opacity(opacity)
                        } animation: { _ in .easeOut(duration: 0.1) }
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: LayoutTokens.space16)
                    if isLive {
                        captureControls
                            .transition(.opacity)
                    } else {
                        resultsPanel(maxHeight: proxy.size.height * PhotoLookupLayout.panelMaxShare)
                            .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    }
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.9), value: isLive)
        }
        .statusBarHidden()
        // A presented cover does not follow the root's live scheme change, so it applies its own.
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        .sensoryFeedback(.impact(weight: .medium), trigger: shutterCount)
        .task { await camera.start() }
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
                Color.black
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
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityHidden(true)
            Text(title)
                .font(.nichijiHeading)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.nichijiCallout)
                .foregroundStyle(.white.opacity(0.75))
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
                    systemName: camera.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
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
                Text(captureFailed ? PhotoLookupCopy.captureFailed : PhotoLookupCopy.aimHint)
                    .font(.nichijiCaption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, LayoutTokens.space12)
                    .padding(.vertical, LayoutTokens.space8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
            }

            HStack {
                PhotosPicker(selection: $libraryItem, matching: .images) {
                    CameraChromeIcon(systemName: "photo.on.rectangle", side: PhotoLookupLayout.controlSide)
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

    /*-------------------------------results------------------------------*/

    private func resultsPanel(maxHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space16) {
            HStack(alignment: .center, spacing: LayoutTokens.space12) {
                panelStatus
                Spacer(minLength: LayoutTokens.space8)
                Button {
                    model.retake()
                } label: {
                    Label(PhotoLookupCopy.retake, systemImage: "arrow.counterclockwise")
                        .font(.nichijiCallout.weight(.medium))
                        .foregroundColor(.nichijiInk)
                        .padding(.horizontal, LayoutTokens.space16)
                        .frame(minHeight: LayoutTokens.minHitTarget)
                        .background(Capsule().fill(Color.nichijiSurfaceSunken))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint(PhotoLookupCopy.retakeHint)
            }

            if model.state == .found {
                Toggle(PhotoLookupCopy.newToYou, isOn: $model.showsNewOnly)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInk)
                    .tint(.nichijiVermilion)
                    .frame(minHeight: LayoutTokens.minHitTarget)
            }

            panelBody
        }
        .padding(.horizontal, LayoutTokens.screenMarginCompact)
        .padding(.top, LayoutTokens.space24)
        .padding(.bottom, LayoutTokens.space16)
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: LayoutTokens.cornerRadiusLarge,
                topTrailingRadius: LayoutTokens.cornerRadiusLarge,
                style: .continuous
            )
            .fill(Color.nichijiSurfaceRaised)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder private var panelStatus: some View {
        switch model.state {
        case .reading, .empty:
            HStack(spacing: LayoutTokens.space12) {
                ProgressView()
                Text(PhotoLookupCopy.reading)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }
            .accessibilityElement(children: .combine)
        case .found:
            Text(PhotoLookupCopy.foundCount(model.kanji.count))
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)
        case .noKanji:
            note(PhotoLookupCopy.noKanji)
        case .failed:
            note(PhotoLookupCopy.failed)
        }
    }

    @ViewBuilder private var panelBody: some View {
        if model.state == .found {
            if model.filterHidesEverything {
                note(PhotoLookupCopy.allStarted)
            } else {
                // The panel hugs a short grid and scrolls a long one.
                ViewThatFits(in: .vertical) {
                    kanjiGrid
                    ScrollView(showsIndicators: false) {
                        kanjiGrid
                    }
                }
            }
        }
    }

    private var kanjiGrid: some View {
        LazyVGrid(columns: KanjiGridTile.columns, spacing: KanjiGridTile.spacing) {
            ForEach(model.visibleKanji, id: \.self) { id in
                Button {
                    onPick(id)
                } label: {
                    KanjiGridTile(kanji: id)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(id)
                .accessibilityHint("Opens kanji details")
            }
        }
        .padding(.bottom, LayoutTokens.space8)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.nichijiCallout)
            .foregroundColor(.nichijiInkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/*-------------------------------controls---------------------------------*/

/// A round button on dark material, for controls that sit over the camera.
private struct CameraChromeButton: View {
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

private struct CameraChromeIcon: View {
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

private struct ShutterButton: View {
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

private struct ShutterPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

/// The square that marks a tap-to-focus point, then fades.
private struct FocusSquare: View {
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
