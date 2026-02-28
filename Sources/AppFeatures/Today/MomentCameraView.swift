#if os(iOS)
import SwiftUI
import AVFoundation
import AVKit
import UIKit
import CoreModels

struct MomentCameraView: View {
    let entryType: EntryType
    let onFallbackImport: () -> Void
    let onConfirm: (CapturedMediaDraft) async -> String?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = CameraSessionController()
    @State private var confirmationError: String?
    @State private var isPersisting = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch controller.sessionState {
            case .preparing:
                ProgressView("Preparing camera…")
                    .tint(.white)
                    .foregroundStyle(.white)

            case .ready:
                cameraReadyView

            case .denied:
                permissionErrorView(
                    title: "Camera access is required",
                    message: "Enable camera and microphone access in Settings, or import media from files."
                )

            case .unavailable(let message):
                permissionErrorView(
                    title: "Camera unavailable",
                    message: message
                )
            }
        }
        .task {
            await controller.startIfNeeded()
        }
        .onDisappear {
            controller.stopSession()
            controller.clearDraft(deleteFile: true)
        }
    }

    private var cameraReadyView: some View {
        ZStack {
            CameraPreviewView(session: controller.session)
                .ignoresSafeArea()

            if let draft = controller.draft {
                confirmationView(for: draft)
            } else {
                controlsOverlay
            }
        }
    }

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.4), in: Circle())
                }

                Spacer()

                Text(entryType.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    controller.flipCamera()
                } label: {
                    Image(systemName: "camera.rotate")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.4), in: Circle())
                }
                .disabled(controller.isRecording)
                .opacity(controller.isRecording ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            if let message = controller.captureErrorMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.8), in: Capsule())
                    .padding(.bottom, 12)
            }

            VStack(spacing: 14) {
                Picker("Capture mode", selection: $controller.mode) {
                    ForEach(CameraSessionController.CaptureMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(controller.isRecording)
                .padding(.horizontal, 24)

                zoomControl

                Button {
                    controller.capture()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(controller.mode == .video3s ? Color.red : Color.white)
                            .frame(width: controller.mode == .video3s ? 56 : 64, height: controller.mode == .video3s ? 56 : 64)
                    }
                }
                .disabled(controller.isRecording)
                .accessibilityLabel(controller.mode == .photo ? "Take photo" : "Record 3 second video")

                if controller.isRecording {
                    Text("Recording 3-second clip…")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(.bottom, 28)
        }
    }

    private var zoomControl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(controller.availableZoomPresets, id: \.self) { preset in
                    Button {
                        controller.setZoomPreset(preset)
                    } label: {
                        Text(String(format: "%.1fx", Double(preset)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(controller.selectedZoomPreset == preset ? Color.black : Color.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(controller.selectedZoomPreset == preset ? Color.white : Color.white.opacity(0.2), in: Capsule())
                    }
                    .disabled(controller.isRecording)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func permissionErrorView(title: String, message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.9))

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)

            Button("Import from Files") {
                onFallbackImport()
                dismiss()
            }
            .buttonStyle(.bordered)

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 18))
        .padding(20)
    }

    private func confirmationView(for draft: CapturedMediaDraft) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.45), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Group {
                switch draft {
                case .photo(let url, _, _):
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Label("Preview unavailable", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                case .video(let url, _, _, _, _):
                    DraftVideoPreview(url: url)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .padding(.top, 10)

            if let confirmationError {
                Text(confirmationError)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.8), in: Capsule())
                    .padding(.bottom, 10)
            }

            HStack(spacing: 12) {
                Button("Retake") {
                    confirmationError = nil
                    controller.clearDraft(deleteFile: true)
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await saveDraft() }
                } label: {
                    if isPersisting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Use")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPersisting)
            }
            .padding(.bottom, 24)
        }
        .background(.black.opacity(0.85))
    }

    private func saveDraft() async {
        guard let draft = controller.draft else { return }
        isPersisting = true
        defer { isPersisting = false }

        let failure = await onConfirm(draft)
        if let failure {
            confirmationError = failure
            return
        }

        controller.clearDraft(deleteFile: true)
        dismiss()
    }
}

private struct DraftVideoPreview: View {
    let url: URL
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let item = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: item)
                player.play()
            }
            .onDisappear {
                player.pause()
                player.replaceCurrentItem(with: nil)
            }
    }
}

private final class CameraPreviewHostView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewHostView {
        let view = CameraPreviewHostView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewHostView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class CameraSessionController: NSObject, ObservableObject {
    enum CaptureMode: String, CaseIterable, Identifiable {
        case photo
        case video3s

        var id: String { rawValue }

        var title: String {
            switch self {
            case .photo:
                return "Photo"
            case .video3s:
                return "3s Video"
            }
        }
    }

    enum SessionState: Equatable {
        case preparing
        case ready
        case denied
        case unavailable(String)
    }

    @Published var mode: CaptureMode = .photo
    @Published var sessionState: SessionState = .preparing
    @Published var availableZoomPresets: [CGFloat] = [1]
    @Published var selectedZoomPreset: CGFloat = 1
    @Published var isRecording = false
    @Published var captureErrorMessage: String?
    @Published var draft: CapturedMediaDraft?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.rosebudthorn.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()

    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var didStart = false

    func startIfNeeded() async {
        guard !didStart else { return }
        didStart = true
        sessionState = .preparing

        let videoGranted = await Self.requestPermission(for: .video)
        let audioGranted = await Self.requestPermission(for: .audio)

        guard videoGranted, audioGranted else {
            sessionState = .denied
            return
        }

        do {
            try await configureSession()
            sessionState = .ready
        } catch {
            sessionState = .unavailable(error.localizedDescription)
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capture() {
        captureErrorMessage = nil
        switch mode {
        case .photo:
            capturePhoto()
        case .video3s:
            startVideoRecording()
        }
    }

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self, let currentInput = self.videoInput else { return }
            let targetPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            guard let targetDevice = self.videoDevice(for: targetPosition) else { return }

            do {
                let newInput = try AVCaptureDeviceInput(device: targetDevice)
                self.session.beginConfiguration()
                self.session.removeInput(currentInput)

                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.videoInput = newInput
                    self.session.commitConfiguration()
                    self.publishZoomPresets(for: targetDevice)
                } else {
                    self.session.addInput(currentInput)
                    self.session.commitConfiguration()
                }
            } catch {
                DispatchQueue.main.async {
                    self.captureErrorMessage = "Could not switch camera."
                }
            }
        }
    }

    func setZoomPreset(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoInput?.device else { return }
            let clamped = max(device.minAvailableVideoZoomFactor, min(factor, device.maxAvailableVideoZoomFactor))

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
                DispatchQueue.main.async {
                    self.selectedZoomPreset = clamped
                }
            } catch {
                DispatchQueue.main.async {
                    self.captureErrorMessage = "Could not set zoom."
                }
            }
        }
    }

    func clearDraft(deleteFile: Bool) {
        if deleteFile, let url = draft?.url {
            try? FileManager.default.removeItem(at: url)
        }
        draft = nil
        captureErrorMessage = nil
    }

    private func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func startVideoRecording() {
        sessionQueue.async { [weak self] in
            guard let self, !self.movieOutput.isRecording else { return }

            let destination = self.temporaryURL(extension: "mov")
            self.movieOutput.maxRecordedDuration = CMTime(seconds: 3, preferredTimescale: 600)
            self.movieOutput.startRecording(to: destination, recordingDelegate: self)
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }

    private func configureSession() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: NSError(domain: "CameraSessionController", code: -1))
                    return
                }

                guard let backDevice = self.videoDevice(for: .back) else {
                    continuation.resume(throwing: NSError(
                        domain: "CameraSessionController",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "No camera device was found on this device."]
                    ))
                    return
                }

                do {
                    let videoInput = try AVCaptureDeviceInput(device: backDevice)
                    let audioDevice = AVCaptureDevice.default(for: .audio)
                    let audioInput = try audioDevice.map { try AVCaptureDeviceInput(device: $0) }

                    self.session.beginConfiguration()
                    self.session.sessionPreset = .high

                    if self.session.canAddInput(videoInput) {
                        self.session.addInput(videoInput)
                        self.videoInput = videoInput
                    }

                    if let audioInput, self.session.canAddInput(audioInput) {
                        self.session.addInput(audioInput)
                        self.audioInput = audioInput
                    }

                    if self.session.canAddOutput(self.photoOutput) {
                        self.session.addOutput(self.photoOutput)
                    }

                    if self.session.canAddOutput(self.movieOutput) {
                        self.session.addOutput(self.movieOutput)
                    }

                    self.session.commitConfiguration()
                    self.session.startRunning()
                    self.publishZoomPresets(for: backDevice)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func publishZoomPresets(for device: AVCaptureDevice) {
        let presets = supportedZoomPresets(for: device)
        DispatchQueue.main.async {
            self.availableZoomPresets = presets
            let preferred = presets.contains(1) ? CGFloat(1) : (presets.first ?? 1)
            self.selectedZoomPreset = preferred
        }
    }

    private func supportedZoomPresets(for device: AVCaptureDevice) -> [CGFloat] {
        let minZoom = device.minAvailableVideoZoomFactor
        let maxZoom = min(device.maxAvailableVideoZoomFactor, 6)
        let candidates: [CGFloat] = [0.5, 1, 2, 3]

        var supported = candidates.filter { $0 >= minZoom - 0.01 && $0 <= maxZoom + 0.01 }
        if supported.isEmpty {
            supported = [minZoom]
        }

        return supported.map { round($0 * 10) / 10 }
    }

    private func videoDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualWideCamera,
            .builtInDualCamera,
            .builtInWideAngleCamera,
            .builtInTrueDepthCamera
        ]

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )

        return discovery.devices.first
    }

    private func temporaryURL(extension fileExtension: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
    }

    private static func requestPermission(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

extension CameraSessionController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            DispatchQueue.main.async {
                self.captureErrorMessage = "Photo capture failed: \(error.localizedDescription)"
            }
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.captureErrorMessage = "Photo capture failed."
            }
            return
        }

        let destination = temporaryURL(extension: "jpg")

        do {
            try data.write(to: destination)
            DispatchQueue.main.async {
                self.draft = .photo(url: destination, pixelWidth: nil, pixelHeight: nil)
            }
        } catch {
            DispatchQueue.main.async {
                self.captureErrorMessage = "Could not save captured photo."
            }
        }
    }
}

extension CameraSessionController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isRecording = false
        }

        if let error {
            let nsError = error as NSError
            let completed = nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false
            guard completed else {
                DispatchQueue.main.async {
                    self.captureErrorMessage = "Video capture failed: \(error.localizedDescription)"
                }
                try? FileManager.default.removeItem(at: outputFileURL)
                return
            }
        }

        Task {
            let metadata = await Self.videoMetadata(at: outputFileURL)
            DispatchQueue.main.async {
                self.draft = .video(
                    url: outputFileURL,
                    durationSeconds: metadata.durationSeconds,
                    pixelWidth: metadata.dimensions?.0,
                    pixelHeight: metadata.dimensions?.1,
                    hasAudio: metadata.hasAudio
                )
            }
        }
    }

    private static func videoMetadata(at url: URL) async -> (durationSeconds: Double, dimensions: (Int, Int)?, hasAudio: Bool) {
        let asset = AVURLAsset(url: url)
        let duration = max(CMTimeGetSeconds((try? await asset.load(.duration)) ?? .zero), 0)
        let videoTrack = try? await asset.loadTracks(withMediaType: .video).first

        let dimensions: (Int, Int)?
        if let videoTrack {
            let naturalSize = (try? await videoTrack.load(.naturalSize)) ?? .zero
            let preferredTransform = (try? await videoTrack.load(.preferredTransform)) ?? .identity
            let transformed = naturalSize.applying(preferredTransform)
            dimensions = (Int(abs(transformed.width).rounded()), Int(abs(transformed.height).rounded()))
        } else {
            dimensions = nil
        }

        let hasAudio = !((try? await asset.loadTracks(withMediaType: .audio)) ?? []).isEmpty
        return (duration, dimensions, hasAudio)
    }
}
#endif
