import CoreGraphics
import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Nichiji

/*----------------------------photo-crop-tests----------------------------*/

/// Reads three kanji from the full 400 pt wide photo and two from anything narrower, so a test can tell which image was read.
private struct CropStubReader: PhotoTextReader {
    func read(imageData: Data) async throws -> PhotoTextReading {
        let width = UIImage(data: imageData)?.size.width ?? 0
        return PhotoTextReading(visionLines: [width >= 400 ? "日一川" : "日一"], liveTextLines: [])
    }
}

private func jpeg(width: Int, height: Int, orientation: UIImage.Orientation = .up) -> Data {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    guard let cgImage = image.cgImage else { return Data() }
    return UIImage(cgImage: cgImage, scale: 1, orientation: orientation).jpegData(compressionQuality: 1) ?? Data()
}

private func pixelSize(of data: Data?) -> CGSize? {
    data.flatMap(UIImage.init(data:)).map { CGSize(width: $0.size.width * $0.scale, height: $0.size.height * $0.scale) }
}

@Suite("Crop Frame Rules")
struct PhotoCropFrameTests {
    private let fitted = CGSize(width: 300, height: 400)

    @Test("A corner drag moves only the two edges that corner touches")
    func cornerMovesItsEdges() {
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)

        let moved = PhotoCrop.move(.topLeft, of: rect, by: CGVector(dx: 0.1, dy: 0.05), minSize: CGSize(width: 0.1, height: 0.1))

        #expect(abs(moved.minX - 0.3) < 1e-9)
        #expect(abs(moved.minY - 0.25) < 1e-9)
        #expect(moved.maxX == rect.maxX)
        #expect(moved.maxY == rect.maxY)

        let other = PhotoCrop.move(.bottomRight, of: rect, by: CGVector(dx: -0.1, dy: -0.05), minSize: CGSize(width: 0.1, height: 0.1))

        #expect(other.minX == rect.minX)
        #expect(other.minY == rect.minY)
        #expect(abs(other.maxX - 0.7) < 1e-9)
        #expect(abs(other.maxY - 0.75) < 1e-9)
    }

    @Test("A drag cannot leave the photo", arguments: PhotoCrop.Corner.allCases)
    func staysInsidePhoto(corner: PhotoCrop.Corner) {
        let outward = PhotoCrop.move(corner, of: PhotoCrop.fullFrame, by: CGSize(width: -900, height: -900), fitted: fitted)
        let outwardRight = PhotoCrop.move(corner, of: PhotoCrop.fullFrame, by: CGSize(width: 900, height: 900), fitted: fitted)

        #expect(PhotoCrop.fullFrame.contains(outward))
        #expect(PhotoCrop.fullFrame.contains(outwardRight))
    }

    @Test("A drag cannot shrink the frame below 88 pt a side", arguments: PhotoCrop.Corner.allCases)
    func keepsMinimumSize(corner: PhotoCrop.Corner) {
        let inward: CGSize = CGSize(width: corner.isLeft ? 900 : -900, height: corner.isTop ? 900 : -900)

        let rect = PhotoCrop.move(corner, of: PhotoCrop.fullFrame, by: inward, fitted: fitted)

        #expect(abs(rect.width * fitted.width - PhotoCrop.minSide) < 1e-6)
        #expect(abs(rect.height * fitted.height - PhotoCrop.minSide) < 1e-6)
    }

    @Test("A drag in points measures against the photo's drawn size")
    func dragInPoints() {
        let rect = PhotoCrop.move(.topLeft, of: PhotoCrop.fullFrame, by: CGSize(width: 30, height: 40), fitted: fitted)

        #expect(abs(rect.minX - 0.1) < 1e-9)
        #expect(abs(rect.minY - 0.1) < 1e-9)
    }

    @Test("A photo with no drawn size leaves the frame alone")
    func zeroSizeIsInert() {
        let rect = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)

        #expect(PhotoCrop.move(.topLeft, of: rect, by: CGSize(width: 10, height: 10), fitted: .zero) == rect)
        #expect(PhotoCrop.nudge(.topLeft, of: rect, inward: true, fitted: .zero) == rect)
    }

    @Test("A VoiceOver nudge moves a corner a step toward the middle or away from it", arguments: PhotoCrop.Corner.allCases)
    func nudgeDirections(corner: PhotoCrop.Corner) {
        let rect = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)

        let inward = PhotoCrop.nudge(corner, of: rect, inward: true, fitted: fitted)
        let outward = PhotoCrop.nudge(corner, of: rect, inward: false, fitted: fitted)

        #expect(inward.width < rect.width)
        #expect(inward.height < rect.height)
        #expect(outward.width > rect.width)
        #expect(outward.height > rect.height)
        #expect(abs(inward.width - (rect.width - PhotoCrop.nudgeStep)) < 1e-9)
    }

    @Test("The frame turns into whole pixels, clamped and never empty")
    func pixelRect() {
        let half = PhotoCrop.pixelRect(forNormalized: CGRect(x: 0.25, y: 0.5, width: 0.5, height: 0.5), pixelWidth: 400, pixelHeight: 200)
        #expect(half == CGRect(x: 100, y: 100, width: 200, height: 100))

        let sliver = PhotoCrop.pixelRect(forNormalized: CGRect(x: 1, y: 1, width: 0, height: 0), pixelWidth: 10, pixelHeight: 10)
        #expect(sliver.width >= 1 && sliver.height >= 1)
        #expect(CGRect(x: 0, y: 0, width: 10, height: 10).contains(sliver))

        #expect(PhotoCrop.pixelRect(forNormalized: PhotoCrop.fullFrame, pixelWidth: 0, pixelHeight: 5) == .zero)
    }

    @Test("A portrait photo fits by height and is centred sideways")
    func fitsPortrait() {
        let frame = PhotoFit.fittedFrame(imageSize: CGSize(width: 100, height: 200), in: CGSize(width: 300, height: 300))

        #expect(frame == CGRect(x: 75, y: 0, width: 150, height: 300))
    }

    @Test("A square photo in a tall view fits by width and is centred vertically")
    func fitsSquare() {
        let frame = PhotoFit.fittedFrame(imageSize: CGSize(width: 1_000, height: 1_000), in: CGSize(width: 300, height: 600))

        #expect(frame == CGRect(x: 0, y: 150, width: 300, height: 300))
    }

    @Test("A landscape photo in a tall view fits by width and is centred vertically")
    func fitsLandscape() {
        let frame = PhotoFit.fittedFrame(imageSize: CGSize(width: 4_000, height: 3_000), in: CGSize(width: 300, height: 600))

        #expect(frame == CGRect(x: 0, y: 187.5, width: 300, height: 225))
    }

    @Test("A fitted photo never overflows the view and keeps its aspect ratio", arguments: [
        CGSize(width: 100, height: 200), CGSize(width: 500, height: 500), CGSize(width: 4_032, height: 3_024), CGSize(width: 10, height: 3_000)
    ])
    func fitsInside(imageSize: CGSize) {
        let view = CGSize(width: 390, height: 560)
        let frame = PhotoFit.fittedFrame(imageSize: imageSize, in: view)

        #expect(CGRect(origin: .zero, size: view).insetBy(dx: -1e-6, dy: -1e-6).contains(frame))
        #expect(abs(frame.width / frame.height - imageSize.width / imageSize.height) < 1e-9)
        #expect(abs(frame.midX - view.width / 2) < 1e-9)
        #expect(abs(frame.midY - view.height / 2) < 1e-9)
    }

    @Test("A photo with no size or a view with no size fits to nothing")
    func fitsNothing() {
        #expect(PhotoFit.fittedFrame(imageSize: .zero, in: CGSize(width: 10, height: 10)) == .zero)
        #expect(PhotoFit.fittedFrame(imageSize: CGSize(width: 10, height: 10), in: .zero) == .zero)
    }

    @Test("The whole-photo frame covers exactly the fitted photo")
    func fullFrameCoversPhoto() {
        let fittedFrame = PhotoFit.fittedFrame(imageSize: CGSize(width: 4_000, height: 3_000), in: CGSize(width: 300, height: 600))

        #expect(PhotoCrop.frameRect(for: PhotoCrop.fullFrame, fitted: fittedFrame.size) == CGRect(origin: .zero, size: fittedFrame.size))
    }

    @Test("The whole-photo frame sits on the letterboxed photo for any shape", arguments: [
        CGSize(width: 100, height: 200), CGSize(width: 500, height: 500), CGSize(width: 4_000, height: 3_000)
    ])
    func wholeFrameHugsPhoto(imageSize: CGSize) {
        let canvas = CGSize(width: 300, height: 600)
        let photo = PhotoFit.fittedFrame(imageSize: imageSize, in: canvas)
        let frame = PhotoCrop.frameRect(for: PhotoCrop.fullFrame, fitted: photo.size)

        #expect(frame.size == photo.size)
        #expect(frame.origin == .zero)
        #expect(abs(photo.width - canvas.width) < 1e-6 || abs(photo.height - canvas.height) < 1e-6)
        #expect(photo.width <= canvas.width + 1e-6 && photo.height <= canvas.height + 1e-6)
    }

    @Test("A frame in the corner of a square photo is measured on the photo, not the view")
    func frameMeasuredOnPhoto() {
        let photo = PhotoFit.fittedFrame(imageSize: CGSize(width: 500, height: 500), in: CGSize(width: 300, height: 600))
        let frame = PhotoCrop.frameRect(for: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5), fitted: photo.size)

        #expect(photo == CGRect(x: 0, y: 150, width: 300, height: 300))
        #expect(frame == CGRect(x: 150, y: 150, width: 150, height: 150))
    }

    @Test("Dragging inside the frame moves it without resizing it")
    func translateKeepsSize() {
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.5)

        let moved = PhotoCrop.translate(rect, by: CGSize(width: 30, height: -40), fitted: fitted)

        #expect(abs(moved.minX - 0.3) < 1e-9)
        #expect(abs(moved.minY - 0.1) < 1e-9)
        #expect(abs(moved.width - rect.width) < 1e-9)
        #expect(abs(moved.height - rect.height) < 1e-9)
    }

    @Test("A frame drag stops at the photo's edges")
    func translateClamps() {
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.5)

        let topLeft = PhotoCrop.translate(rect, by: CGSize(width: -900, height: -900), fitted: fitted)
        let bottomRight = PhotoCrop.translate(rect, by: CGSize(width: 900, height: 900), fitted: fitted)

        #expect(topLeft == CGRect(x: 0, y: 0, width: 0.4, height: 0.5))
        #expect(abs(bottomRight.maxX - 1) < 1e-9)
        #expect(abs(bottomRight.maxY - 1) < 1e-9)
        #expect(abs(bottomRight.width - 0.4) < 1e-9)
    }

    @Test("The whole-photo frame has nowhere to move")
    func fullFrameStaysPut() {
        #expect(PhotoCrop.translate(PhotoCrop.fullFrame, by: CGSize(width: 50, height: -50), fitted: fitted) == PhotoCrop.fullFrame)
        #expect(PhotoCrop.translate(PhotoCrop.fullFrame, by: CGSize(width: 50, height: 50), fitted: .zero) == PhotoCrop.fullFrame)
    }

    @Test("A VoiceOver move steps the whole frame one way and stops at the edge", arguments: PhotoCrop.Direction.allCases)
    func nudgeFrame(direction: PhotoCrop.Direction) {
        let rect = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)

        let moved = PhotoCrop.nudge(rect, toward: direction)

        #expect(abs(moved.width - rect.width) < 1e-9)
        #expect(abs(moved.minX - (rect.minX + direction.unit.dx * PhotoCrop.nudgeStep)) < 1e-9)
        #expect(abs(moved.minY - (rect.minY + direction.unit.dy * PhotoCrop.nudgeStep)) < 1e-9)

        let edge = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        #expect(PhotoCrop.nudge(edge, toward: .left) == edge)
        #expect(PhotoCrop.nudge(edge, toward: .up) == edge)
    }

    @Test("Each corner handle has a 44 pt target and its bracket stays inside it", arguments: PhotoCrop.Corner.allCases)
    func handleShape(corner: PhotoCrop.Corner) {
        let target = CGRect(x: 0, y: 0, width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
        let path = CropHandleShape(corner: corner).path(in: target)

        #expect(!path.isEmpty)
        #expect(target.contains(path.boundingRect))
    }
}

@Suite("Crop The Photo")
@MainActor
struct PhotoCropTests {
    private func makeModel() -> PhotoLookupModel {
        PhotoLookupModel(
            reader: CropStubReader(),
            contentStore: TestKanjiContentStore(entries: SeedKanjiDataset.entries),
            learnerStore: TestLearnerStore()
        )
    }

    @Test("The cropper cuts the frame out of the photo")
    func cropperCuts() {
        let data = jpeg(width: 400, height: 200)

        let cropped = PhotoCropper.crop(imageData: data, to: CGRect(x: 0.25, y: 0, width: 0.5, height: 0.5))

        #expect(pixelSize(of: cropped) == CGSize(width: 200, height: 100))
    }

    @Test("A photo stored sideways is cropped as it shows on screen")
    func cropperUsesUprightPixels() {
        // 400 x 200 stored pixels turned a quarter show as 200 wide and 400 tall.
        let data = jpeg(width: 400, height: 200, orientation: .right)

        let cropped = PhotoCropper.crop(imageData: data, to: CGRect(x: 0, y: 0, width: 1, height: 0.5))

        #expect(pixelSize(of: cropped) == CGSize(width: 200, height: 200))
    }

    @Test("Data that is not a photo cannot be cropped")
    func cropperRejectsJunk() {
        #expect(PhotoCropper.crop(imageData: Data([1, 2, 3]), to: PhotoCrop.fullFrame) == nil)
    }

    @Test("Cropping makes the crop the photo and reads it again")
    func cropReplacesPhoto() async {
        let model = makeModel()
        await model.lookUp(imageData: jpeg(width: 400, height: 200))
        let original = model.photoData
        #expect(model.kanji == ["日", "一", "川"])

        let done = await model.crop(to: CGRect(x: 0, y: 0, width: 0.5, height: 1))

        #expect(done)
        #expect(model.photoData != original)
        #expect(pixelSize(of: model.photoData) == CGSize(width: 200, height: 200))
        #expect(model.state == .found)
        #expect(model.kanji == ["日", "一"])
    }

    @Test("A crop works again on a cropped photo")
    func cropTwice() async {
        let model = makeModel()
        await model.lookUp(imageData: jpeg(width: 400, height: 200))

        await model.crop(to: CGRect(x: 0, y: 0, width: 0.5, height: 1))
        await model.crop(to: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))

        #expect(pixelSize(of: model.photoData) == CGSize(width: 100, height: 100))
    }

    @Test("A photo that cannot be cropped stays as it was")
    func badCropChangesNothing() async {
        let model = makeModel()
        await model.lookUp(imageData: Data([1]))

        let done = await model.crop(to: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))

        #expect(!done)
        #expect(model.photoData == Data([1]))
        #expect(model.state == .found)
    }

    @Test("There is nothing to crop before a photo")
    func nothingToCrop() async {
        let model = makeModel()

        #expect(await model.crop(to: PhotoCrop.fullFrame) == false)
        #expect(model.state == .empty)
    }

    @Test("A retake during a crop drops the crop")
    func retakeDropsCrop() async {
        let model = makeModel()
        await model.lookUp(imageData: jpeg(width: 400, height: 200))

        let crop = Task { await model.crop(to: CGRect(x: 0, y: 0, width: 0.5, height: 1)) }
        await Task.yield()
        model.retake()
        let done = await crop.value

        #expect(!done)
        #expect(model.state == .empty)
        #expect(model.photoData == nil)
    }

    @Test("The crop screen uses the design's words")
    func copy() {
        #expect(PhotoCropCopy.title == "Crop")
        #expect(PhotoCropCopy.hint == "Drag the corners to resize the frame, or drag inside it to move it")
        #expect(PhotoCropCopy.cancel == "Cancel")
        #expect(PhotoCropCopy.done == "Done")
    }
}
