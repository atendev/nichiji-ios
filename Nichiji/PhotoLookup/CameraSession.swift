import AVFoundation
import Observation
import SwiftUI
import UIKit

/*---------------------------------access---------------------------------*/

/// Whether photo lookup can show the live camera.
enum CameraAccess: Equatable, Sendable {
    case notDetermined
    case authorized
    /// Denied by the learner or restricted by the device's owner.
    case denied
    /// No rear camera, as in the Simulator.
    case unavailable

    static func from(status: AVAuthorizationStatus, hasCamera: Bool) -> CameraAccess {
        guard hasCamera else { return .unavailable }
        switch status {
        case .authorized: return .authorized
        case .notDetermined: return .notDetermined
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }
}

/*---------------------------------session--------------------------------*/

/// The rear camera for photo lookup: live preview, tap to focus, torch, and one still per shutter tap.
@MainActor
@Observable
final class CameraSession {
    private(set) var access: CameraAccess
    private(set) var hasTorch = false
    private(set) var isTorchOn = false

    @ObservationIgnored private let worker = CameraWorker()
    @ObservationIgnored private weak var previewLayer: AVCaptureVideoPreviewLayer?
    @ObservationIgnored private var rotation: AVCaptureDevice.RotationCoordinator?

    init() {
        access = CameraAccess.from(
            status: AVCaptureDevice.authorizationStatus(for: .video),
            hasCamera: CameraWorker.backCamera() != nil
        )
    }

    /// Asks for access the first time, then runs the session.
    func start() async {
        if access == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            access = granted ? .authorized : .denied
        }
        guard access == .authorized else { return }
        hasTorch = await worker.start()
        makeRotationCoordinator()
    }

    func stop() {
        isTorchOn = false
        worker.stop()
    }

    func attach(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        layer.session = worker.session
        layer.videoGravity = .resizeAspectFill
        makeRotationCoordinator()
    }

    /// Keeps the preview upright as the interface rotates.
    func applyPreviewRotation() {
        guard let rotation, let connection = previewLayer?.connection else { return }
        let angle = rotation.videoRotationAngleForHorizonLevelPreview
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }

    func focus(atLayerPoint point: CGPoint) {
        guard let previewLayer else { return }
        worker.focus(at: previewLayer.captureDevicePointConverted(fromLayerPoint: point))
    }

    func toggleTorch() {
        isTorchOn.toggle()
        worker.setTorch(isTorchOn)
    }

    /// The shot as image data, upright for how the phone is held, or nil when the capture fails.
    func capture() async -> Data? {
        let angle = rotation?.videoRotationAngleForHorizonLevelCapture ?? 90
        return await worker.capture(rotationAngle: angle)
    }

    private func makeRotationCoordinator() {
        // Its own handle on the rear camera, so the main actor never reads the worker's device.
        guard rotation == nil, access == .authorized, let previewLayer, let device = CameraWorker.backCamera() else { return }
        rotation = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        applyPreviewRotation()
    }
}

/*---------------------------------worker---------------------------------*/

/// Owns the capture session. Every session and device change runs on its own serial queue.
private final class CameraWorker: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let session = AVCaptureSession()

    private var device: AVCaptureDevice?
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "com.aten.nichiji.camera")
    private var isConfigured = false
    private var pendingCapture: CheckedContinuation<Data?, Never>?

    static func backCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    /// Returns whether the camera has a torch.
    func start() async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                configureIfNeeded()
                if isConfigured, !session.isRunning {
                    session.startRunning()
                }
                continuation.resume(returning: device?.hasTorch ?? false)
            }
        }
    }

    func stop() {
        queue.async { [self] in
            setTorchOnQueue(false)
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func focus(at devicePoint: CGPoint) {
        queue.async { [self] in
            guard let device, (try? device.lockForConfiguration()) != nil else { return }
            defer { device.unlockForConfiguration() }
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
        }
    }

    func setTorch(_ isOn: Bool) {
        queue.async { [self] in setTorchOnQueue(isOn) }
    }

    func capture(rotationAngle: CGFloat) async -> Data? {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                guard session.isRunning, pendingCapture == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(rotationAngle) {
                    connection.videoRotationAngle = rotationAngle
                }
                pendingCapture = continuation
                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = .balanced
                output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        queue.async { [self] in
            pendingCapture?.resume(returning: data)
            pendingCapture = nil
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured, let camera = Self.backCamera(),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if session.canAddInput(input), session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
            output.maxPhotoQualityPrioritization = .balanced
            device = camera
            isConfigured = true
        }
        session.commitConfiguration()
    }

    private func setTorchOnQueue(_ isOn: Bool) {
        guard let device, device.hasTorch, (try? device.lockForConfiguration()) != nil else { return }
        device.torchMode = isOn ? .on : .off
        device.unlockForConfiguration()
    }
}

/*---------------------------------preview--------------------------------*/

/// The live camera feed, filling its frame.
struct CameraPreview: UIViewRepresentable {
    let camera: CameraSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.camera = camera
        if let layer = view.layer as? AVCaptureVideoPreviewLayer {
            camera.attach(layer)
        }
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        weak var camera: CameraSession?

        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        override func layoutSubviews() {
            super.layoutSubviews()
            camera?.applyPreviewRotation()
        }
    }
}
