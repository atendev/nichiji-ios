import SwiftUI
import UIKit

/*---------------------------------layer----------------------------------*/

/// Holds the results sheet at the bottom of the screen, over the photo and under nothing. It rises from the bottom when the sheet model first gets a state.
struct ScanSheetLayer: View {
    @Bindable var model: PhotoLookupModel
    let sheet: ScanSheetModel
    let image: UIImage?
    let onPick: (String) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            if sheet.isVisible {
                ScanResultsSheet(model: model, sheet: sheet, image: image, onPick: onPick)
                    .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea()
    }
}

/*---------------------------------sheet----------------------------------*/

/// The sheet over the frozen photo: peek, half and full, with a header you drag and a grid of every kanji found.
struct ScanResultsSheet: View {
    @Bindable var model: PhotoLookupModel
    let sheet: ScanSheetModel
    let image: UIImage?
    let onPick: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var screenHeight: CGFloat { sheet.metrics.screenHeight }
    private var isFound: Bool { model.state == .found }

    var body: some View {
        let height = sheet.height
        let radius = ScanSheetGeometry.cornerRadius(forHeight: height, screenHeight: screenHeight)
        let shape = UnevenRoundedRectangle(topLeadingRadius: radius, topTrailingRadius: radius, style: .continuous)
        VStack(spacing: 0) {
            header(for: ScanSheetGeometry.presentation(forHeight: height, screenHeight: screenHeight))
                .contentShape(Rectangle())
                .gesture(headerDrag)
            if height > ScanSheetGeometry.bodyMinHeight {
                results
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .clipShape(shape)
        .background(shape.fill(Color.nichijiSurface).shadow(color: .black.opacity(0.55), radius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(PhotoLookupCopy.sheetLabel)
    }

    /// The drag runs in screen space, because the header moves under the finger.
    private var headerDrag: some Gesture {
        DragGesture(minimumDistance: ScanSheetGeometry.dragSlop, coordinateSpace: .global)
            .onChanged { sheet.drag(translation: $0.translation.height) }
            .onEnded { sheet.endDrag(translation: $0.translation.height, reduceMotion: reduceMotion) }
    }

    /*------------------------------headers-------------------------------*/

    @ViewBuilder private func header(for mode: ScanSheetState) -> some View {
        switch mode {
        case .peek: peekHeader
        case .half: halfHeader
        case .full: fullHeader
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Color.nichijiHairline)
            .frame(width: 36, height: 4)
            .padding(.top, LayoutTokens.space8)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(PhotoLookupCopy.sheetSize)
            .accessibilityValue(PhotoLookupCopy.sheetValue(sheet.state ?? .half))
            .accessibilityAdjustableAction { direction in
                sheet.step(up: direction == .increment, reduceMotion: reduceMotion)
            }
    }

    private var peekHeader: some View {
        VStack(spacing: 0) {
            handle
            HStack(spacing: LayoutTokens.space12) {
                titleBlock(headingFont: .uiText(size: 16, weight: .medium), subtitle: PhotoLookupCopy.newLine(model.newCount))
                Spacer(minLength: LayoutTokens.space8)
                Text(PhotoLookupCopy.swipeUp)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.nichijiInkMuted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, LayoutTokens.space24)
            .padding(.top, LayoutTokens.space12)
            .padding(.bottom, LayoutTokens.space12)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(PhotoLookupCopy.peekHint)
            .accessibilityAction { sheet.move(to: .half, reduceMotion: reduceMotion) }
            .onTapGesture { sheet.move(to: .half, reduceMotion: reduceMotion) }
        }
    }

    private var halfHeader: some View {
        VStack(spacing: 0) {
            handle
            titleRow
        }
    }

    private var fullHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderBar(kanjiTitle: PhotoLookupCopy.scanKanji, englishTitle: PhotoLookupCopy.scanTitle) {
                Button {
                    sheet.move(to: .peek, reduceMotion: reduceMotion)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.nichijiInkMuted)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(PhotoLookupCopy.backToPhoto)
            }
            photoRow
                .padding(.top, LayoutTokens.space16)
            titleRow
                .padding(.top, LayoutTokens.space12)
        }
        .padding(.top, sheet.metrics.topInset)
    }

    private var photoRow: some View {
        HStack(spacing: LayoutTokens.space12) {
            thumbnail
            VStack(alignment: .leading, spacing: 0) {
                Text(PhotoLookupCopy.yourPhoto)
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiInk)
                Text(PhotoLookupCopy.scannedJustNow)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            }
            Spacer(minLength: LayoutTokens.space8)
            Button {
                sheet.move(to: .peek, reduceMotion: reduceMotion)
            } label: {
                Text(PhotoLookupCopy.viewPhoto)
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiInk)
                    .padding(.horizontal, 14)
                    .frame(minHeight: LayoutTokens.minHitTarget)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
                            .strokeBorder(Color.nichijiBorderControl, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LayoutTokens.space16)
    }

    @ViewBuilder private var thumbnail: some View {
        let shape = RoundedRectangle(cornerRadius: LayoutTokens.cornerRadiusSmall, style: .continuous)
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.cameraBase
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.nichijiHairline, lineWidth: 1))
        .accessibilityHidden(true)
    }

    /// The found count over its subtitle, or the note when the read found nothing.
    private func titleBlock(headingFont: Font, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if isFound {
                Text(PhotoLookupCopy.foundCount(model.kanji.count))
                    .font(headingFont)
                    .foregroundColor(.nichijiInk)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.nichijiCaption)
                    .foregroundColor(.nichijiInkMuted)
            } else {
                Text(note)
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var titleRow: some View {
        HStack(spacing: LayoutTokens.space12) {
            titleBlock(headingFont: .nichijiHeading, subtitle: subtitle)
            Spacer(minLength: LayoutTokens.space8)
            if isFound {
                Toggle(PhotoLookupCopy.newOnly, isOn: $model.showsNewOnly)
                    .font(.uiText(size: 14, weight: .medium))
                    .foregroundColor(.nichijiInk)
                    .tint(.nichijiVermilion)
                    .fixedSize()
                    .frame(minHeight: LayoutTokens.minHitTarget)
                    .accessibilityHint(PhotoLookupCopy.newOnlyHint)
            }
        }
        .padding(.leading, LayoutTokens.space24)
        .padding(.trailing, LayoutTokens.space16)
        .padding(.top, LayoutTokens.space4)
    }

    private var subtitle: String {
        PhotoLookupCopy.subtitle(new: model.newCount, learned: model.learnedCount, newOnly: model.showsNewOnly)
    }

    private var note: String {
        model.state == .failed ? PhotoLookupCopy.failed : PhotoLookupCopy.noKanji
    }
}

extension ScanResultsSheet {
    /*-------------------------------body---------------------------------*/

    private var results: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutTokens.space16) {
                if isFound {
                    if model.filterHidesEverything {
                        Text(PhotoLookupCopy.nothingNew)
                            .font(.nichijiCallout)
                            .foregroundColor(.nichijiInkMuted)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, LayoutTokens.space32)
                    }
                    grid
                } else {
                    retakeButton
                }
            }
            .padding(.horizontal, LayoutTokens.space16)
            .padding(.top, LayoutTokens.space12)
            .padding(.bottom, LayoutTokens.space16 + sheet.metrics.bottomInset)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            ScanSheetGeometry.scrollPullsToFull(offset: geometry.contentOffset.y + geometry.contentInsets.top)
        } action: { _, pulled in
            if pulled { sheet.pullToFull(reduceMotion: reduceMotion) }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: ScanResultTile.columns, spacing: LayoutTokens.space8) {
            ForEach(model.visibleKanji, id: \.self) { id in
                Button {
                    onPick(id)
                } label: {
                    ScanResultTile(kanji: id, meaning: model.meanings[id] ?? "", isNew: !model.startedIDs.contains(id))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var retakeButton: some View {
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
}
