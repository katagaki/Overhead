import AVKit
import Backbone
import Combine
import SwiftUI

// MARK: - LCD Picture in Picture

/// Floats the journey LCD in a system PiP window by feeding rendered
/// SwiftUI frames into a sample-buffer display layer. Armed while a journey
/// is active; the system lifts the LCD into PiP when the app backgrounds.
final class LCDPiPManager: NSObject, ObservableObject {
    static let shared = LCDPiPManager()

    @Published private(set) var isActive = false

    /// Renders the current LCD frame; nil while no journey is active.
    private var frameProvider: (@MainActor () -> UIImage?)?

    /// Must sit in the app's view hierarchy for PiP to start.
    let hostView = UIView()
    private let displayLayer = AVSampleBufferDisplayLayer()
    private var controller: AVPictureInPictureController?
    private var frameTimer: Timer?

    var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }

    private override init() {
        super.init()
        displayLayer.videoGravity = .resizeAspect
        hostView.layer.addSublayer(displayLayer)
    }

    /// Arms PiP: frames start flowing so the system can auto-start PiP on
    /// backgrounding.
    func prepare(frameProvider: @escaping @MainActor () -> UIImage?) {
        guard isSupported else { return }
        self.frameProvider = frameProvider
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .moviePlayback, options: [.mixWithOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        if controller == nil {
            let source = AVPictureInPictureController.ContentSource(
                sampleBufferDisplayLayer: displayLayer,
                playbackDelegate: self
            )
            let pip = AVPictureInPictureController(contentSource: source)
            pip.delegate = self
            pip.requiresLinearPlayback = true
            pip.canStartPictureInPictureAutomaticallyFromInline = true
            controller = pip
        }
        enqueueFrame()
        scheduleNextFrame()
    }

    /// Disarms PiP (journey ended).
    func teardown() {
        if isActive { controller?.stopPictureInPicture() }
        stopTimer()
        frameProvider = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Frames

    /// Video-rate only while the PiP window is showing; 1fps keeps the
    /// armed-but-hidden session cheap.
    private var frameInterval: TimeInterval {
        guard isActive else { return 1.0 }
        return TrainLCDStyle(
            stored: UserDefaults.standard.string(forKey: TrainLCDStyle.storageKey) ?? ""
        ).pipFrameInterval
    }

    private func scheduleNextFrame() {
        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.enqueueFrame()
                self.scheduleNextFrame()
            }
        }
    }

    private func stopTimer() {
        frameTimer?.invalidate()
        frameTimer = nil
    }

    private func enqueueFrame() {
        guard let image = frameProvider?() else {
            if isActive { controller?.stopPictureInPicture() }
            return
        }
        guard let buffer = Self.sampleBuffer(from: image) else { return }
        let renderer = displayLayer.sampleBufferRenderer
        if renderer.status == .failed { renderer.flush() }
        renderer.enqueue(buffer)
        displayLayer.frame = CGRect(origin: .zero, size: image.size)
    }

    private static func sampleBuffer(from image: UIImage) -> CMSampleBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        guard CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32ARGB, attrs as CFDictionary, &pixelBuffer
        ) == kCVReturnSuccess, let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }
        // Black under the LCD bezel's rounded corners, matching the PiP window.
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var format: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &format
        ) == noErr, let format else { return nil }

        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        var sample: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sample
        ) == noErr else { return nil }
        return sample
    }
}

// MARK: - Delegates

extension LCDPiPManager: AVPictureInPictureControllerDelegate {
    nonisolated func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        Task { @MainActor in self.isActive = true }
    }

    // Frames keep flowing after PiP ends so it can auto-start again on the
    // next backgrounding; teardown() is what stops them.
    nonisolated func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        Task { @MainActor in self.isActive = false }
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Task { @MainActor in self.isActive = false }
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

extension LCDPiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {}

    nonisolated func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    nonisolated func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        false
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {}

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - Layer Host

/// Invisible anchor keeping the PiP layer in the view hierarchy.
struct LCDPiPLayerHost: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        LCDPiPManager.shared.hostView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - LCD Frame Rendering

extension JourneyViewModel {
    /// The current LCD as an image. The share sheet wants breathing room
    /// (padded, 3x); PiP wants the bare LCD (unpadded, 2x for cheap
    /// video-rate rendering).
    func renderLCDImage(scale: CGFloat = 3, padded: Bool = true) -> UIImage? {
        guard let journey = activeJourney, let state = positionState else { return nil }
        let defaults = UserDefaults.standard
        let lcd = StyledTrainLCDView(
            style: TrainLCDStyle(stored: defaults.string(forKey: TrainLCDStyle.storageKey) ?? ""),
            journey: journey,
            state: state,
            lineColor: selectedLine?.color ?? .gray,
            orientation: defaults.string(forKey: TrainLCDOrientation.storageKey)
                .flatMap(TrainLCDOrientation.init) ?? .left
        )
        .frame(width: 360)

        // Unpadded (PiP) frames get a rounder screen — radius 6 reads too
        // square at PiP-window size.
        let content = padded
            ? AnyView(lcd.padding(12).background(Color(.systemBackground)))
            : AnyView(lcd.environment(\.lcdScreenCornerRadius, 12))
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        return renderer.uiImage
    }
}
