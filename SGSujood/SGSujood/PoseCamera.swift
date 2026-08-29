import SwiftUI
import AVFoundation
import Vision
import Combine

// MARK: - Rak'ah / sujud counter engine
//
// Runs the camera + Apple's Vision body-pose detector ENTIRELY ON DEVICE. No frame is ever
// recorded or uploaded — buffers are analysed live and discarded. From the body joints it
// classifies the worshipper's posture (standing / ruku' / sujud / sitting) and counts how many
// times they stand up and go into sujud. Rak'ah is derived as sujud ÷ 2.
//
// This is a prototype: the classifier uses joint geometry with sensible thresholds. It works
// best with the phone propped to the side so the whole body is in frame. For production accuracy
// across body types, camera angles and clothing, retrain with a Create ML Action Classifier and
// swap `classify(_:)` for the model — the camera/counting scaffolding stays the same.

enum Posture: String {
    case unknown, standing, ruku, sujud, sitting

    var label: String {
        switch self {
        case .unknown:  return "—"
        case .standing: return "Qiyam"
        case .ruku:     return "Ruku'"
        case .sujud:    return "Sujud"
        case .sitting:  return "Duduk"
        }
    }
}

@MainActor
final class PoseCamera: NSObject, ObservableObject {

    // Published UI state
    @Published private(set) var authorization: AVAuthorizationStatus = .notDetermined
    @Published private(set) var isRunning = false
    @Published private(set) var bodyInFrame = false
    @Published private(set) var posture: Posture = .unknown
    @Published private(set) var standUps = 0
    @Published private(set) var sujudCount = 0
    /// Normalised joints (0…1, origin top-left, already mirrored to match the preview) for the
    /// skeleton overlay.
    @Published private(set) var overlayPoints: [CGPoint] = []

    var rakaat: Int { sujudCount / 2 }

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sgsujood.posecamera.session")
    private let videoQueue = DispatchQueue(label: "sgsujood.posecamera.video")
    private let output = AVCaptureVideoDataOutput()
    private var configured = false

    // Posture debounce: only commit a new posture after it holds for a few frames.
    private var candidate: Posture = .unknown
    private var candidateFrames = 0
    private let stableFramesNeeded = 5

    // MARK: Lifecycle

    func start() {
        authorization = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorization {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    self.authorization = granted ? .authorized : .denied
                    if granted { self.configureAndRun() }
                }
            }
        default:
            break   // denied / restricted → the view shows guidance
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            Task { @MainActor in self.isRunning = false }
        }
    }

    func reset() {
        standUps = 0
        sujudCount = 0
        posture = .unknown
        candidate = .unknown
        candidateFrames = 0
    }

    // MARK: Session setup

    private func configureAndRun() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                   let input = try? AVCaptureDeviceInput(device: device),
                   self.session.canAddInput(input) {
                    self.session.addInput(input)
                }

                self.output.alwaysDiscardsLateVideoFrames = true
                self.output.setSampleBufferDelegate(self, queue: self.videoQueue)
                if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }

                if let conn = self.output.connection(with: .video) {
                    if conn.isVideoRotationAngleSupported(90) { conn.videoRotationAngle = 90 } // portrait
                }
                self.session.commitConfiguration()
                self.configured = true
            }
            if !self.session.isRunning { self.session.startRunning() }
            Task { @MainActor in self.isRunning = self.session.isRunning }
        }
    }

    // MARK: Classification

    /// Classify posture from joints in Vision space (normalised, origin bottom-left, y up).
    /// Uses positions RELATIVE to the body's own bounding box so it's robust to distance/scale.
    private nonisolated func classify(_ pts: [VNHumanBodyPoseObservation.JointName: CGPoint])
        -> (Posture, [CGPoint], Bool) {

        func y(_ names: [VNHumanBodyPoseObservation.JointName]) -> CGFloat? {
            let vals = names.compactMap { pts[$0]?.y }
            return vals.isEmpty ? nil : vals.reduce(0, +) / CGFloat(vals.count)
        }
        guard let headY = y([.nose, .neck]),
              let hipY  = y([.root, .leftHip, .rightHip]),
              let ankleY = y([.leftAnkle, .rightAnkle, .leftKnee, .rightKnee]),
              pts.count >= 5 else {
            return (.unknown, [], false)
        }

        let ys = pts.values.map { $0.y }
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 1
        let height = maxY - minY
        guard height > 0.12 else { return (.unknown, mirrored(pts), true) }   // too small / partial

        let relHead  = (headY  - minY) / height     // 1 = head at top, 0 = head at bottom
        let relAnkle = (ankleY - minY) / height     // ~0 = feet at bottom (standing)

        let posture: Posture
        if relHead < 0.38 {
            posture = .sujud                                   // head down near the floor
        } else if relHead > 0.68 && relAnkle < 0.22 && height > 0.42 {
            posture = .standing                                // tall: head top, feet bottom
        } else if relHead >= 0.38 && relHead <= 0.68 && relAnkle < 0.25 && height > 0.42 {
            posture = .ruku                                    // torso folded, legs still straight
        } else if relAnkle > 0.28 || height < 0.42 {
            posture = .sitting                                 // compact / knees folded up
        } else {
            posture = .unknown                                 // in between → hold previous
        }
        return (posture, mirrored(pts), true)
    }

    /// Map Vision points (y up, origin bottom-left) to overlay space (y down, origin top-left)
    /// and mirror x to match the mirrored front-camera preview.
    private nonisolated func mirrored(_ pts: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> [CGPoint] {
        pts.values.map { CGPoint(x: 1 - $0.x, y: 1 - $0.y) }
    }

    private func commit(_ p: Posture) {
        // Debounce: a posture must persist a few frames before we trust it.
        if p == candidate {
            candidateFrames += 1
        } else {
            candidate = p
            candidateFrames = 1
        }
        guard candidateFrames == stableFramesNeeded, p != posture, p != .unknown else { return }

        let previous = posture
        posture = p
        if p == .sujud, previous != .sujud { sujudCount += 1 }
        if p == .standing, previous != .standing, previous != .unknown { standUps += 1 }
    }
}

// MARK: - Frame delegate (runs on videoQueue)

extension PoseCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])

        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        if let obs = request.results?.first,
           let recognized = try? obs.recognizedPoints(.all) {
            for (name, point) in recognized where point.confidence > 0.2 {
                joints[name] = point.location
            }
        }

        let (posture, overlay, present) = classify(joints)
        Task { @MainActor in
            self.bodyInFrame = present
            self.overlayPoints = overlay
            if present { self.commit(posture) }
        }
    }
}

// MARK: - Camera preview (mirrored front camera)

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        if let conn = v.videoPreviewLayer.connection, conn.isVideoRotationAngleSupported(90) {
            conn.videoRotationAngle = 90
        }
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
