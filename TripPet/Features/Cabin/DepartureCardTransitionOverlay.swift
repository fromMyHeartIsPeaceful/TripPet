import AVFoundation
import SwiftUI
import UIKit

struct DepartureTransitionContext: Identifiable, Equatable {
    let id = UUID()
    let animalId: String
    let animalName: String
    let animalAssetName: String
    let destination: String
}

struct DepartureCardTransitionLayout: Equatable {
    static let videoAspectRatio: CGFloat = 9.0 / 16.0
    static let widthRatio: CGFloat = 0.78
    static let maxWidth: CGFloat = 340
    static let maxHeightRatio: CGFloat = 0.72

    static func cardSize(in containerSize: CGSize) -> CGSize {
        let widthFromContainer = min(containerSize.width * widthRatio, maxWidth)
        let maxHeight = containerSize.height * maxHeightRatio
        let heightFromWidth = widthFromContainer / videoAspectRatio

        if heightFromWidth <= maxHeight {
            return CGSize(width: widthFromContainer, height: heightFromWidth)
        }

        let height = maxHeight
        return CGSize(width: height * videoAspectRatio, height: height)
    }
}

struct DepartureCardTransitionVisuals: Equatable {
    static let maskOpacity: Double = 0.52
    static let cornerRadius: CGFloat = 24
    static let strokeOpacity: Double = 0.56
    static let strokeWidth: CGFloat = 1
    static let settledShadowOpacity: Double = 0.16
}

struct DepartureCardTransitionOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let context: DepartureTransitionContext
    var onComplete: () -> Void

    @State private var phase: DepartureCardTransitionPhase = .idle
    @State private var shouldPlayVideo = false
    @State private var isVideoReadyForDisplay = false
    @State private var videoPreviewImage: UIImage?
    @State private var isExiting = false
    @State private var didCompletePlayback = false

    private let maskEntranceDelay: UInt64 = 210_000_000
    private let playDelay: UInt64 = 650_000_000
    private let videoReadyTimeout: UInt64 = 420_000_000
    private let exitDuration: Double = 0.42

    var body: some View {
        let video = reduceMotion ? nil : DepartureTransitionCatalog.video(for: context.animalId)

        GeometryReader { proxy in
            let cardSize = DepartureCardTransitionLayout.cardSize(in: proxy.size)

            ZStack {
                Color.black
                    .opacity(maskOpacity)
                    .ignoresSafeArea()

                transitionCard(video: video)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .background(cardPlaceholder)
                    .clipShape(RoundedRectangle(cornerRadius: DepartureCardTransitionVisuals.cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DepartureCardTransitionVisuals.cornerRadius, style: .continuous)
                            .stroke(
                                AppTheme.paperWhite.opacity(DepartureCardTransitionVisuals.strokeOpacity),
                                lineWidth: DepartureCardTransitionVisuals.strokeWidth
                            )
                            .opacity(cardStrokeOpacity)
                    }
                    .shadow(color: Color.black.opacity(cardShadowOpacity), radius: 30, x: 0, y: 18)
                    .scaleEffect(cardScale)
                    .offset(y: cardVerticalOffset)
                    .opacity(cardOpacity)
                    .accessibilityLabel("\(context.animalName)出发了")
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .task(id: context.id) {
            if let video,
               let url = DepartureTransitionCatalog.videoURL(for: video) {
                Task {
                    await prepareVideoPreview(url: url)
                }
            }

            await startSequence(shouldWaitForVideo: video != nil)
            shouldPlayVideo = true

            if video == nil {
                try? await Task.sleep(nanoseconds: reduceMotion ? 800_000_000 : 1_200_000_000)
                completePlaybackIfNeeded()
            } else if let duration = video?.duration {
                let fallbackNanoseconds = UInt64((duration + 0.35) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: fallbackNanoseconds)
                completePlaybackIfNeeded()
            }
        }
    }

    @ViewBuilder
    private func transitionCard(video: DepartureTransitionVideo?) -> some View {
        if let video,
           let url = DepartureTransitionCatalog.videoURL(for: video) {
            ZStack {
                if let videoPreviewImage {
                    Image(uiImage: videoPreviewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    cardPlaceholder
                }

                DepartureTransitionVideoView(
                    url: url,
                    shouldPlay: shouldPlayVideo,
                    onReadyForDisplay: {
                        isVideoReadyForDisplay = true
                    },
                    onPlaybackComplete: completePlaybackIfNeeded
                )
                .opacity(isVideoReadyForDisplay ? 1 : 0)
                .animation(.easeOut(duration: reduceMotion ? 0.01 : 0.12), value: isVideoReadyForDisplay)
            }
        } else {
            staticDepartureCard
        }
    }

    private var cardPlaceholder: some View {
        LinearGradient(
            colors: [
                AppTheme.paperWhite,
                AppTheme.ivory,
                AppTheme.mistBlue.opacity(0.50)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var staticDepartureCard: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.82, blue: 0.52),
                    Color(red: 0.98, green: 0.92, blue: 0.78),
                    Color(red: 0.72, green: 0.82, blue: 0.86)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 16) {
                ArtImage(name: context.animalAssetName)
                    .frame(width: 170, height: 170)
                    .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 8)

                ArtImage(name: "prop_ticket_single")
                    .frame(width: 140, height: 64)
                    .rotationEffect(.degrees(-4))
                    .shadow(color: AppTheme.ochre.opacity(0.30), radius: 8, x: 0, y: 4)
            }
            .offset(y: -10)

            DepartureTransitionMistOverlay(
                isRevealed: shouldPlayVideo,
                isClosing: isExiting
            )
            .opacity(reduceMotion ? 0 : 0.8)
        }
    }

    private var maskOpacity: Double {
        if isExiting { return 0 }
        return phase.isMaskVisible ? DepartureCardTransitionVisuals.maskOpacity : 0
    }

    private var cardOpacity: Double {
        if isExiting { return 0 }
        return phase.isCardVisible ? 1 : 0
    }

    private var cardScale: CGFloat {
        if isExiting { return reduceMotion ? 1 : 0.97 }
        return phase.isCardVisible ? 1 : 0.97
    }

    private var cardVerticalOffset: CGFloat {
        if reduceMotion { return 0 }
        if isExiting { return -12 }
        return phase.isCardVisible ? 0 : 8
    }

    private var cardShadowOpacity: Double {
        switch phase {
        case .settled, .playing:
            return isExiting ? 0 : DepartureCardTransitionVisuals.settledShadowOpacity
        case .enteringCard:
            return 0
        case .idle, .appearingMask, .exiting:
            return 0
        }
    }

    private var cardStrokeOpacity: Double {
        switch phase {
        case .settled, .playing:
            return isExiting ? 0 : 1
        case .enteringCard:
            return 0
        case .idle, .appearingMask, .exiting:
            return 0
        }
    }

    private func startSequence(shouldWaitForVideo: Bool) async {
        guard phase == .idle else { return }

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.16)) {
                phase = .enteringCard
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
            phase = .settled
            try? await Task.sleep(nanoseconds: 120_000_000)
        } else {
            withAnimation(.easeOut(duration: 0.20)) {
                phase = .appearingMask
            }

            try? await Task.sleep(nanoseconds: maskEntranceDelay)
            await waitForVideoReadinessIfNeeded(shouldWaitForVideo: shouldWaitForVideo)

            withAnimation(.snappy(duration: 0.52, extraBounce: 0.01)) {
                phase = .enteringCard
            }

            try? await Task.sleep(nanoseconds: 520_000_000)
            withAnimation(.easeOut(duration: 0.18)) {
                phase = .settled
            }
            try? await Task.sleep(nanoseconds: playDelay)
        }

        phase = .playing
    }

    private func waitForVideoReadinessIfNeeded(shouldWaitForVideo: Bool) async {
        guard shouldWaitForVideo else { return }

        let pollInterval: UInt64 = 20_000_000
        var waited: UInt64 = 0

        while isVideoVisualReady == false, waited < videoReadyTimeout {
            try? await Task.sleep(nanoseconds: pollInterval)
            waited += pollInterval
        }
    }

    private var isVideoVisualReady: Bool {
        isVideoReadyForDisplay || videoPreviewImage != nil
    }

    private func prepareVideoPreview(url: URL) async {
        let image = await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 30)

            guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else {
                return nil as UIImage?
            }

            return UIImage(cgImage: cgImage)
        }.value

        guard let image else { return }
        videoPreviewImage = image
    }

    private func completePlaybackIfNeeded() {
        guard didCompletePlayback == false else { return }
        didCompletePlayback = true

        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.16)
            : .smooth(duration: exitDuration)

        withAnimation(animation) {
            isExiting = true
            phase = .exiting
        }

        Task {
            let delay = UInt64((reduceMotion ? 0.16 : exitDuration) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            onComplete()
        }
    }
}

private enum DepartureCardTransitionPhase: Equatable {
    case idle
    case appearingMask
    case enteringCard
    case settled
    case playing
    case exiting

    var isMaskVisible: Bool {
        switch self {
        case .idle:
            return false
        case .appearingMask, .enteringCard, .settled, .playing, .exiting:
            return true
        }
    }

    var isCardVisible: Bool {
        switch self {
        case .idle, .appearingMask:
            return false
        case .enteringCard, .settled, .playing, .exiting:
            return true
        }
    }
}

private enum DepartureTransitionCatalog {
    private static let resourceSubdirectory = "DepartureTransitions"

    private static let genericVideo = DepartureTransitionVideo(
        filename: "generic_airport_departure.mp4",
        duration: 6.05
    )

    private static let animalVideos: [String: DepartureTransitionVideo] = [
        "xiaoman_hamster": DepartureTransitionVideo(
            filename: "animal_departure_xiaoman_hamster.mp4",
            duration: 6.00
        ),
        "tangyuan_puppy": DepartureTransitionVideo(
            filename: "animal_departure_tangyuan_puppy.mp4",
            duration: 5.58
        ),
        "moji_cat": DepartureTransitionVideo(
            filename: "animal_departure_moji_cat.mp4",
            duration: 5.88
        ),
        "dengdeng_rabbit": DepartureTransitionVideo(
            filename: "animal_departure_dengdeng_rabbit.mp4",
            duration: 5.75
        ),
        "feifei_parrot": DepartureTransitionVideo(
            filename: "animal_departure_feifei_parrot.mp4",
            duration: 6.00
        ),
        "xiaolu_guinea_pig": DepartureTransitionVideo(
            filename: "animal_departure_xiaolu_guinea_pig.mp4",
            duration: 5.71
        ),
        "deer_visitor": DepartureTransitionVideo(
            filename: "animal_departure_deer_visitor.mp4",
            duration: 5.83
        ),
        "fox_visitor": DepartureTransitionVideo(
            filename: "animal_departure_fox_visitor.mp4",
            duration: 5.54
        ),
        "bear_visitor": DepartureTransitionVideo(
            filename: "animal_departure_bear_visitor.mp4",
            duration: 5.88
        )
    ]

    static func video(for animalId: String, bundle: Bundle = .main) -> DepartureTransitionVideo? {
        if let animalVideo = animalVideos[animalId],
           videoURL(for: animalVideo, bundle: bundle) != nil {
            return animalVideo
        }

        guard videoURL(for: genericVideo, bundle: bundle) != nil else {
            return nil
        }

        return genericVideo
    }

    static func videoURL(for video: DepartureTransitionVideo, bundle: Bundle = .main) -> URL? {
        let resourceName = (video.filename as NSString).deletingPathExtension
        let fileExtension = (video.filename as NSString).pathExtension
        return bundle.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: resourceSubdirectory
        )
    }
}

private struct DepartureTransitionVideo: Equatable {
    var filename: String
    var duration: Double
}

private struct DepartureTransitionMistOverlay: View {
    var isRevealed: Bool
    var isClosing: Bool

    private var coverOpacity: Double {
        if isClosing { return 0.92 }
        return isRevealed ? 0 : 0.88
    }

    private var drift: CGFloat {
        if isClosing { return 0 }
        return isRevealed ? -170 : 0
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                Color(red: 1.00, green: 0.95, blue: 0.84)
                    .opacity(coverOpacity)

                mistBand(width: width * 1.45, height: height * 0.30)
                    .offset(x: -width * 0.16, y: -height * 0.31 + drift)

                mistBand(width: width * 1.30, height: height * 0.24)
                    .rotationEffect(.degrees(-6))
                    .offset(x: width * 0.13, y: height * 0.10 - drift * 0.45)

                mistBand(width: width * 1.55, height: height * 0.36)
                    .rotationEffect(.degrees(5))
                    .offset(x: -width * 0.08, y: height * 0.36 - drift * 0.25)
            }
            .frame(width: width, height: height)
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func mistBand(width: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(isClosing ? 0.95 : 0.78),
                        AppTheme.paperWhite.opacity(isClosing ? 0.86 : 0.64),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .blur(radius: 32)
            .opacity(isRevealed && isClosing == false ? 0.18 : 1.0)
    }
}

private struct DepartureTransitionVideoView: UIViewRepresentable {
    let url: URL
    var shouldPlay: Bool = true
    var onReadyForDisplay: () -> Void = {}
    var onPlaybackComplete: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        let paperColor = UIColor(red: 1.0, green: 0.976, blue: 0.937, alpha: 1)
        view.backgroundColor = paperColor
        view.playerLayer.backgroundColor = paperColor.cgColor
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PlayerContainerView, context: Context) {
        context.coordinator.configure(
            url: url,
            shouldPlay: shouldPlay,
            in: view,
            onReadyForDisplay: onReadyForDisplay,
            onPlaybackComplete: onPlaybackComplete
        )
    }

    static func dismantleUIView(_ view: PlayerContainerView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVPlayer?
        private var endObserver: NSObjectProtocol?
        private var readyObserver: NSKeyValueObservation?
        private var hasStartedPlayback = false
        private var didReportReadyForDisplay = false
        private var didReportCompletion = false
        private var onReadyForDisplay: () -> Void = {}
        private var onPlaybackComplete: () -> Void = {}

        func configure(
            url: URL,
            shouldPlay: Bool,
            in view: PlayerContainerView,
            onReadyForDisplay: @escaping () -> Void,
            onPlaybackComplete: @escaping () -> Void
        ) {
            self.onReadyForDisplay = onReadyForDisplay
            self.onPlaybackComplete = onPlaybackComplete

            guard currentURL != url else {
                if view.playerLayer.isReadyForDisplay {
                    reportReadyForDisplayIfNeeded()
                }
                playIfNeeded(shouldPlay: shouldPlay)
                return
            }

            removeEndObserver()
            removeReadyObserver()
            currentURL = url
            hasStartedPlayback = false
            didReportReadyForDisplay = false
            didReportCompletion = false

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = true
            item.preferredForwardBufferDuration = 0
            self.player = player
            view.playerLayer.player = player

            readyObserver = view.playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
                guard layer.isReadyForDisplay else { return }
                DispatchQueue.main.async {
                    self?.reportReadyForDisplayIfNeeded()
                }
            }

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.reportCompletionIfNeeded()
            }

            playIfNeeded(shouldPlay: shouldPlay)
        }

        func stop() {
            player?.pause()
            removeEndObserver()
            removeReadyObserver()
            player = nil
            currentURL = nil
            hasStartedPlayback = false
            didReportReadyForDisplay = false
            didReportCompletion = false
        }

        private func playIfNeeded(shouldPlay: Bool) {
            guard shouldPlay, hasStartedPlayback == false else { return }
            hasStartedPlayback = true
            didReportCompletion = false
            player?.seek(to: .zero)
            player?.play()
        }

        private func reportReadyForDisplayIfNeeded() {
            guard didReportReadyForDisplay == false else { return }
            didReportReadyForDisplay = true
            onReadyForDisplay()
        }

        private func reportCompletionIfNeeded() {
            guard didReportCompletion == false else { return }
            didReportCompletion = true
            player?.pause()
            onPlaybackComplete()
        }

        private func removeEndObserver() {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
        }

        private func removeReadyObserver() {
            readyObserver?.invalidate()
            readyObserver = nil
        }

        deinit {
            stop()
        }
    }

    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor(red: 1.0, green: 0.976, blue: 0.937, alpha: 1)
            clipsToBounds = true
            isOpaque = true
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = UIColor(red: 1.0, green: 0.976, blue: 0.937, alpha: 1)
            clipsToBounds = true
            isOpaque = true
        }
    }
}
