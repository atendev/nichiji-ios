import CoreGraphics
import Foundation
import UIKit

/*--------------------------------geometry--------------------------------*/

enum PhotoCrop {
    /// The whole photo, in normalized coordinates with the origin at the top left.
    static let fullFrame = CGRect(x: 0, y: 0, width: 1, height: 1)
    /// The frame never shrinks below this many points a side, so every corner keeps its own 44 pt target.
    static let minSide: CGFloat = 88
    /// How far one VoiceOver swipe moves a corner, as a share of the photo.
    static let nudgeStep: CGFloat = 0.05

    enum Corner: CaseIterable, Hashable, Sendable {
        case topLeft, topRight, bottomLeft, bottomRight

        var isLeft: Bool { self == .topLeft || self == .bottomLeft }
        var isTop: Bool { self == .topLeft || self == .topRight }

        /// The corner's position on a normalized frame.
        func point(on rect: CGRect) -> CGPoint {
            CGPoint(x: isLeft ? rect.minX : rect.maxX, y: isTop ? rect.minY : rect.maxY)
        }
    }

    /// Drags one corner by a normalized distance, keeping the frame inside the photo and at least the given size.
    static func move(_ corner: Corner, of rect: CGRect, by delta: CGVector, minSize: CGSize) -> CGRect {
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY
        let width = min(1, max(0, minSize.width))
        let height = min(1, max(0, minSize.height))
        let dx = delta.dx, dy = delta.dy

        if corner.isLeft {
            minX = clamp(rect.minX + dx, lower: 0, upper: max(0, rect.maxX - width))
        } else {
            maxX = clamp(rect.maxX + dx, lower: min(1, rect.minX + width), upper: 1)
        }
        if corner.isTop {
            minY = clamp(rect.minY + dy, lower: 0, upper: max(0, rect.maxY - height))
        } else {
            maxY = clamp(rect.maxY + dy, lower: min(1, rect.minY + height), upper: 1)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// The same drag from a distance in points on a photo drawn at `fitted` size.
    static func move(_ corner: Corner, of rect: CGRect, by translation: CGSize, fitted: CGSize) -> CGRect {
        guard fitted.width > 0, fitted.height > 0 else { return rect }
        return move(
            corner,
            of: rect,
            by: CGVector(dx: translation.width / fitted.width, dy: translation.height / fitted.height),
            minSize: CGSize(width: minSide / fitted.width, height: minSide / fitted.height)
        )
    }

    /// One step with the corner moved toward the middle (`inward`) or away from it.
    static func nudge(_ corner: Corner, of rect: CGRect, inward: Bool, fitted: CGSize) -> CGRect {
        guard fitted.width > 0, fitted.height > 0 else { return rect }
        let direction: CGFloat = inward ? 1 : -1
        let delta = CGVector(
            dx: (corner.isLeft ? direction : -direction) * nudgeStep,
            dy: (corner.isTop ? direction : -direction) * nudgeStep
        )
        return move(corner, of: rect, by: delta, minSize: CGSize(width: minSide / fitted.width, height: minSide / fitted.height))
    }

    /// The frame in whole pixels, clamped to the photo and never empty.
    static func pixelRect(forNormalized rect: CGRect, pixelWidth: Int, pixelHeight: Int) -> CGRect {
        guard pixelWidth > 0, pixelHeight > 0 else { return .zero }
        let width = CGFloat(pixelWidth), height = CGFloat(pixelHeight)
        let minX = clamp((rect.minX * width).rounded(), lower: 0, upper: width - 1)
        let minY = clamp((rect.minY * height).rounded(), lower: 0, upper: height - 1)
        let maxX = clamp((rect.maxX * width).rounded(), lower: minX + 1, upper: width)
        let maxY = clamp((rect.maxY * height).rounded(), lower: minY + 1, upper: height)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), max(lower, upper))
    }
}

extension PhotoFit {
    /// Where a photo is drawn when it is fitted whole inside a view: centred, with room left on one axis.
    static func fittedFrame(imageSize: CGSize, in viewSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else { return .zero }
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: (viewSize.width - size.width) / 2, y: (viewSize.height - size.height) / 2, width: size.width, height: size.height)
    }
}

/*--------------------------------cropper---------------------------------*/

enum PhotoCropper {
    /// The part of a photo inside a normalized, top-left-origin frame, as upright JPEG data. Nil when the photo cannot be decoded.
    static func crop(imageData: Data, to region: CGRect) -> Data? {
        guard let source = UIImage(data: imageData) else { return nil }
        guard let upright = uprightCGImage(of: source) else { return nil }
        let pixels = PhotoCrop.pixelRect(forNormalized: region, pixelWidth: upright.width, pixelHeight: upright.height)
        guard !pixels.isEmpty, let piece = upright.cropping(to: pixels) else { return nil }
        return UIImage(cgImage: piece).jpegData(compressionQuality: 0.92)
    }

    /// The pixels as they show on screen, so the frame the learner dragged lines up even for a photo stored sideways.
    private static func uprightCGImage(of image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            return cgImage
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(at: .zero)
        }.cgImage
    }
}
