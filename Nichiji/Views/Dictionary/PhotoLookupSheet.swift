import PhotosUI
import SwiftUI
import UIKit

/*----------------------------------copy----------------------------------*/

enum PhotoLookupCopy {
    static let buttonTitle = "Look up kanji in a photo"
    static let buttonHint = "Opens a photo to find kanji in"
    static let sheetTitle = "Photo lookup"
    static let takePhoto = "Take a photo"
    static let choosePhoto = "Choose from library"
    static let intro = "Take or pick a photo of a sign, menu or page. Nichiji lists every kanji it finds, and a tap opens the kanji."
    static let reading = "Reading the photo\u{2026}"
    static let newToYou = "New to you"
    static let noKanji = "No kanji found. Try a closer, sharper photo."
    static let allStarted = "You have started every kanji found here."
    static let failed = "That photo could not be read."
    static let photoLabel = "The photo being read"

    static func foundCount(_ count: Int) -> String {
        count == 1 ? "1 kanji found" : "\(count) kanji found"
    }
}

/*---------------------------------layout---------------------------------*/

enum PhotoLookupLayout {
    static let thumbnailSide: CGFloat = 120
}

/*---------------------------------sheet----------------------------------*/

/// "Photo lookup": capture or pick a photo, then a grid of every bundled kanji in it. A tile hands its kanji to the Dictionary.
struct PhotoLookupSheet: View {
    @Bindable var model: PhotoLookupModel
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    @State private var libraryItem: PhotosPickerItem?
    @State private var isCameraOpen = false
    @State private var thumbnail: UIImage?

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                    switch model.state {
                    case .empty:
                        emptyContent
                    case .reading:
                        readingContent
                    case .found, .noKanji, .failed:
                        resultContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LayoutTokens.screenMarginRegular)
                .padding(.top, LayoutTokens.space16)
                .padding(.bottom, LayoutTokens.space32)
            }
        }
        .background(Color.nichijiSurfaceRaised.ignoresSafeArea())
        // A presented sheet does not follow the root's live scheme change, so it applies its own.
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.nichijiSurfaceRaised)
        .fullScreenCover(isPresented: $isCameraOpen) {
            CameraPicker { data in
                isCameraOpen = false
                if let data { start(data) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: libraryItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    start(data)
                }
                libraryItem = nil
            }
        }
    }

    private func start(_ data: Data) {
        thumbnail = UIImage(data: data)
        Task { await model.lookUp(imageData: data) }
    }

    /*------------------------------parts-------------------------------*/

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.space12) {
            Text(PhotoLookupCopy.sheetTitle)
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: LayoutTokens.space8)
            Button("Done") {
                dismiss()
            }
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .padding(.horizontal, LayoutTokens.space12)
            .minTouchTarget()
        }
        .padding(.leading, LayoutTokens.screenMarginRegular)
        .padding(.trailing, LayoutTokens.space12)
        .padding(.top, LayoutTokens.space24)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space16) {
            Text(PhotoLookupCopy.intro)
                .font(.nichijiBody)
                .foregroundColor(.nichijiInkMuted)
            sourceButtons
        }
    }

    @ViewBuilder private var sourceButtons: some View {
        VStack(spacing: LayoutTokens.space12) {
            if isCameraAvailable {
                PrimaryButton(title: PhotoLookupCopy.takePhoto) {
                    isCameraOpen = true
                }
            }
            PhotosPicker(selection: $libraryItem, matching: .images) {
                Text(PhotoLookupCopy.choosePhoto)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var readingContent: some View {
        photoSummary {
            HStack(spacing: LayoutTokens.space12) {
                ProgressView()
                Text(PhotoLookupCopy.reading)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space24) {
            photoSummary { resultSummary }

            switch model.state {
            case .found:
                if model.filterHidesEverything {
                    note(PhotoLookupCopy.allStarted)
                } else {
                    kanjiGrid
                }
            case .noKanji:
                note(PhotoLookupCopy.noKanji)
            case .failed:
                note(PhotoLookupCopy.failed)
            case .empty, .reading:
                EmptyView()
            }

            sourceButtons
        }
    }

    /// The photo beside what was found and the "New to you" toggle.
    private func photoSummary<Content: View>(@ViewBuilder status: () -> Content) -> some View {
        HStack(alignment: .top, spacing: LayoutTokens.space16) {
            PhotoThumbnail(image: thumbnail)
            VStack(alignment: .leading, spacing: LayoutTokens.space12) {
                status()
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private var resultSummary: some View {
        if model.state == .found {
            Text(PhotoLookupCopy.foundCount(model.kanji.count))
                .font(.nichijiHeading)
                .foregroundColor(.nichijiInk)
            Toggle(PhotoLookupCopy.newToYou, isOn: $model.showsNewOnly)
                .font(.nichijiCallout)
                .tint(.nichijiVermilion)
                .frame(minHeight: LayoutTokens.minHitTarget)
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
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.nichijiCallout)
            .foregroundColor(.nichijiInkMuted)
    }
}

/*-------------------------------thumbnail--------------------------------*/

private struct PhotoThumbnail: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.nichijiSurfaceSunken
            }
        }
        .frame(width: PhotoLookupLayout.thumbnailSide, height: PhotoLookupLayout.thumbnailSide)
        .clipped()
        .continuousCornerRadius(LayoutTokens.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                .stroke(Color.nichijiBorderControl, lineWidth: 1)
        )
        .accessibilityLabel(PhotoLookupCopy.photoLabel)
    }
}

/*--------------------------------camera----------------------------------*/

/// The system camera, returning the shot as JPEG data, or nil when the learner cancels.
struct CameraPicker: UIViewControllerRepresentable {
    let onFinish: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    @MainActor
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (Data?) -> Void

        init(onFinish: @escaping (Data?) -> Void) {
            self.onFinish = onFinish
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            onFinish(image?.jpegData(compressionQuality: 0.9))
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
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
