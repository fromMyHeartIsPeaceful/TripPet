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
    static let maskOpacity: Double = 0.42
    static let cornerRadius: CGFloat = 24
    static let strokeOpacity: Double = 0.56
    static let strokeWidth: CGFloat = 1
    static let settledShadowOpacity: Double = 0.16
}

struct DepartureCardTransitionTiming: Equatable {
    static let maskEntranceDelay: UInt64 = 210_000_000
    static let playbackStartDelay: UInt64 = 120_000_000
    static let minimumPlaybackTimeBeforeReveal: Double = 0.12
    static let videoReadyTimeout: UInt64 = 420_000_000
    static let exitDuration: Double = 0.42
}

struct DepartureCardTransitionOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let context: DepartureTransitionContext
    var onCoverReady: () -> Void = {}
    var onComplete: () -> Void

    @State private var phase: DepartureCardTransitionPhase = .idle
    @State private var shouldPlayVideo = false
    @State private var isVideoReadyForDisplay = false
    @State private var preparedVideo: DepartureTransitionPreparedVideo?
    @State private var shouldUseStaticFallback = false
    @State private var isExiting = false
    @State private var didCompletePlayback = false
    @State private var didReportCoverReady = false

    var body: some View {
        let video = (reduceMotion || shouldUseStaticFallback) ? nil : DepartureTransitionCatalog.video(for: context.animalId)

        GeometryReader { proxy in
            let cardSize = DepartureCardTransitionLayout.cardSize(in: proxy.size)

            ZStack {
                Color.black
                    .opacity(maskOpacity)
                    .ignoresSafeArea()

                transitionCard(video: video)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .background(staticDepartureCard)
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
                    await prepareVideo(url: url)
                }
                shouldPlayVideo = true
            }

            await startSequence(shouldWaitForVideo: video != nil)
            if video == nil {
                shouldPlayVideo = true
            }

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
                staticDepartureCard

                DepartureTransitionVideoView(
                    url: url,
                    preparedVideo: preparedVideo,
                    shouldPlay: shouldPlayVideo,
                    onReadyForDisplay: {
                        isVideoReadyForDisplay = true
                    },
                    onPlaybackUnavailable: {
                        shouldUseStaticFallback = true
                        isVideoReadyForDisplay = false
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
                isRevealed: isVideoReadyForDisplay || shouldUseStaticFallback,
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
            reportCoverReadyIfNeeded()
            try? await Task.sleep(nanoseconds: 120_000_000)
        } else {
            withAnimation(.easeOut(duration: 0.20)) {
                phase = .appearingMask
            }

            try? await Task.sleep(nanoseconds: DepartureCardTransitionTiming.maskEntranceDelay)
            await waitForVideoReadinessIfNeeded(shouldWaitForVideo: shouldWaitForVideo)

            withAnimation(.snappy(duration: 0.52, extraBounce: 0.01)) {
                phase = .enteringCard
            }

            try? await Task.sleep(nanoseconds: 520_000_000)
            withAnimation(.easeOut(duration: 0.18)) {
                phase = .settled
            }
            reportCoverReadyIfNeeded()
            try? await Task.sleep(nanoseconds: DepartureCardTransitionTiming.playbackStartDelay)
        }

        phase = .playing
    }

    private func waitForVideoReadinessIfNeeded(shouldWaitForVideo: Bool) async {
        guard shouldWaitForVideo else { return }

        let pollInterval: UInt64 = 20_000_000
        var waited: UInt64 = 0

        while isVideoVisualReady == false, waited < DepartureCardTransitionTiming.videoReadyTimeout {
            try? await Task.sleep(nanoseconds: pollInterval)
            waited += pollInterval
        }
    }

    private var isVideoVisualReady: Bool {
        isVideoReadyForDisplay
    }

    private func prepareVideo(url: URL) async {
        guard let preparedVideo = await DepartureTransitionPlaybackPreloader.shared.preparedVideo(for: url),
              preparedVideo.url == url else {
            return
        }

        self.preparedVideo = preparedVideo
    }

    private func completePlaybackIfNeeded() {
        guard didCompletePlayback == false else { return }
        didCompletePlayback = true
        reportCoverReadyIfNeeded()

        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.16)
            : .smooth(duration: DepartureCardTransitionTiming.exitDuration)

        withAnimation(animation) {
            isExiting = true
            phase = .exiting
        }

        Task {
            let delay = UInt64((reduceMotion ? 0.16 : DepartureCardTransitionTiming.exitDuration) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            onComplete()
        }
    }

    private func reportCoverReadyIfNeeded() {
        guard didReportCoverReady == false else { return }
        didReportCoverReady = true
        onCoverReady()
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

enum DepartureTransitionCatalog {
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
            duration: 6.04
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

    static var expectedVideos: [DepartureTransitionVideo] {
        [genericVideo] + animalVideos.values.sorted { $0.filename < $1.filename }
    }
}

struct DepartureTransitionVideo: Equatable {
    var filename: String
    var duration: Double
}

struct DepartureTransitionPreparedVideo {
    var url: URL
    var asset: AVURLAsset
    var previewImage: UIImage?
    var player: AVPlayer?
    var didPreroll: Bool
}

@MainActor
final class DepartureTransitionPlaybackPreloader {
    static let shared = DepartureTransitionPlaybackPreloader()

    private var preloadTasks: [URL: Task<DepartureTransitionPreparedVideo?, Never>] = [:]

    func preloadVideo(for animalId: String) {
        guard let video = DepartureTransitionCatalog.video(for: animalId),
              let url = DepartureTransitionCatalog.videoURL(for: video) else {
            return
        }

        preload(url: url)
    }

    func preload(url: URL) {
        guard preloadTasks[url] == nil else {
            return
        }

        preloadTasks[url] = makePreloadTask(for: url)
    }

    func preparedVideo(for url: URL) async -> DepartureTransitionPreparedVideo? {
        let task: Task<DepartureTransitionPreparedVideo?, Never>
        if let existingTask = preloadTasks[url] {
            task = existingTask
        } else {
            task = makePreloadTask(for: url)
            preloadTasks[url] = task
        }

        let preparedVideo = await task.value
        preloadTasks[url] = nil

        return preparedVideo
    }

    private func makePreloadTask(for url: URL) -> Task<DepartureTransitionPreparedVideo?, Never> {
        Task(priority: .userInitiated) { @MainActor in
            guard let loadedResources = await Self.loadResources(for: url) else {
                return nil
            }

            let item = AVPlayerItem(asset: loadedResources.asset)
            let player = Self.makePreparedPlayer(for: item)
            let didPreroll = await Self.preroll(player)

            return DepartureTransitionPreparedVideo(
                url: url,
                asset: loadedResources.asset,
                previewImage: nil,
                player: player,
                didPreroll: didPreroll
            )
        }
    }

    private struct LoadedVideoResources {
        var asset: AVURLAsset
    }

    nonisolated private static func loadResources(for url: URL) async -> LoadedVideoResources? {
        let asset = AVURLAsset(url: url)
        await warmAsset(asset)

        guard (try? await asset.load(.isPlayable)) == true else {
            return nil
        }

        return LoadedVideoResources(asset: asset)
    }

    private static func makePreparedPlayer(for item: AVPlayerItem) -> AVPlayer {
        item.preferredForwardBufferDuration = 0
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }

    private static func preroll(_ player: AVPlayer) async -> Bool {
        guard await waitUntilPlayerReadyForPreroll(player) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            var didResume = false
            let resumeOnce: (Bool) -> Void = { didFinish in
                guard didResume == false else { return }
                didResume = true
                continuation.resume(returning: didFinish)
            }

            player.preroll(atRate: 1.0) { didFinish in
                DispatchQueue.main.async {
                    resumeOnce(didFinish)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                player.cancelPendingPrerolls()
                resumeOnce(false)
            }
        }
    }

    private static func waitUntilPlayerReadyForPreroll(
        _ player: AVPlayer,
        timeoutNanoseconds: UInt64 = 650_000_000
    ) async -> Bool {
        let pollInterval: UInt64 = 20_000_000
        var waited: UInt64 = 0

        while waited < timeoutNanoseconds {
            switch player.status {
            case .readyToPlay:
                return true
            case .failed:
                return false
            case .unknown:
                if player.currentItem?.status == .failed {
                    return false
                }
                try? await Task.sleep(nanoseconds: pollInterval)
                waited += pollInterval
            @unknown default:
                return false
            }
        }

        return player.status == .readyToPlay
    }

    nonisolated private static func warmAsset(_ asset: AVURLAsset) async {
        _ = try? await asset.load(.isPlayable)
        _ = try? await asset.load(.duration)
    }

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
    var preparedVideo: DepartureTransitionPreparedVideo?
    var shouldPlay: Bool = true
    var onReadyForDisplay: () -> Void = {}
    var onPlaybackUnavailable: () -> Void = {}
    var onPlaybackComplete: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.playerLayer.backgroundColor = UIColor.clear.cgColor
        view.playerLayer.isOpaque = false
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PlayerContainerView, context: Context) {
        context.coordinator.configure(
            url: url,
            preparedVideo: preparedVideo,
            shouldPlay: shouldPlay,
            in: view,
            onReadyForDisplay: onReadyForDisplay,
            onPlaybackUnavailable: onPlaybackUnavailable,
            onPlaybackComplete: onPlaybackComplete
        )
    }

    static func dismantleUIView(_ view: PlayerContainerView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        private var currentURL: URL?
        private var currentAsset: AVURLAsset?
        private var player: AVPlayer?
        private var endObserver: NSObjectProtocol?
        private var timeObserver: Any?
        private var readyObserver: NSKeyValueObservation?
        private var statusObserver: NSKeyValueObservation?
        private var hasStartedPlayback = false
        private var isLayerReadyForDisplay = false
        private var didReportReadyForDisplay = false
        private var didReportCompletion = false
        private var didReportUnavailable = false
        private var isPendingPlayback = false
        private var onReadyForDisplay: () -> Void = {}
        private var onPlaybackUnavailable: () -> Void = {}
        private var onPlaybackComplete: () -> Void = {}

        func configure(
            url: URL,
            preparedVideo: DepartureTransitionPreparedVideo?,
            shouldPlay: Bool,
            in view: PlayerContainerView,
            onReadyForDisplay: @escaping () -> Void,
            onPlaybackUnavailable: @escaping () -> Void,
            onPlaybackComplete: @escaping () -> Void
        ) {
            self.onReadyForDisplay = onReadyForDisplay
            self.onPlaybackUnavailable = onPlaybackUnavailable
            self.onPlaybackComplete = onPlaybackComplete

            guard currentURL != url else {
                if let preparedAsset = preparedVideo?.asset,
                   currentAsset !== preparedAsset,
                   hasStartedPlayback == false,
                   didReportReadyForDisplay == false {
                    configureNewItem(
                        url: url,
                        preparedVideo: preparedVideo,
                        fallbackAsset: preparedAsset,
                        shouldPlay: shouldPlay,
                        in: view
                    )
                    return
                }

                if view.playerLayer.isReadyForDisplay {
                    isLayerReadyForDisplay = true
                    reportReadyForDisplayIfPlaybackHasAdvanced()
                }
                playIfNeeded(shouldPlay: shouldPlay)
                return
            }

            removeEndObserver()
            removeTimeObserver()
            removeReadyObserver()
            removeStatusObserver()
            currentURL = url
            hasStartedPlayback = false
            isLayerReadyForDisplay = false
            didReportReadyForDisplay = false
            didReportCompletion = false
            didReportUnavailable = false
            isPendingPlayback = false
            configureNewItem(
                url: url,
                preparedVideo: preparedVideo,
                fallbackAsset: preparedVideo?.asset ?? AVURLAsset(url: url),
                shouldPlay: shouldPlay,
                in: view
            )
        }

        private func configureNewItem(
            url: URL,
            preparedVideo: DepartureTransitionPreparedVideo?,
            fallbackAsset: AVURLAsset,
            shouldPlay: Bool,
            in view: PlayerContainerView
        ) {
            removeEndObserver()
            removeTimeObserver()
            removeReadyObserver()
            removeStatusObserver()
            currentURL = url
            currentAsset = fallbackAsset
            hasStartedPlayback = false
            isLayerReadyForDisplay = false
            didReportReadyForDisplay = false
            didReportCompletion = false
            didReportUnavailable = false
            isPendingPlayback = false

            let item: AVPlayerItem
            let player: AVPlayer
            if let preparedPlayer = preparedVideo?.player,
               let preparedItem = preparedPlayer.currentItem {
                player = preparedPlayer
                item = preparedItem
            } else {
                item = AVPlayerItem(asset: fallbackAsset)
                item.preferredForwardBufferDuration = 0
                player = AVPlayer(playerItem: item)
            }

            player.isMuted = true
            player.automaticallyWaitsToMinimizeStalling = false
            self.player = player
            view.playerLayer.player = player
            currentAsset = preparedVideo?.asset ?? fallbackAsset

            statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                DispatchQueue.main.async {
                    self?.handleItemStatus(item.status)
                }
            }

            readyObserver = view.playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
                guard layer.isReadyForDisplay else { return }
                DispatchQueue.main.async {
                    self?.isLayerReadyForDisplay = true
                    self?.reportReadyForDisplayIfPlaybackHasAdvanced()
                }
            }

            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(value: 1, timescale: 30),
                queue: .main
            ) { [weak self, weak player] time in
                guard let self,
                      self.player === player else {
                    return
                }
                self.reportReadyForDisplayIfPlaybackHasAdvanced(currentTime: time)
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
            removeTimeObserver()
            removeReadyObserver()
            removeStatusObserver()
            player = nil
            currentURL = nil
            currentAsset = nil
            hasStartedPlayback = false
            isLayerReadyForDisplay = false
            didReportReadyForDisplay = false
            didReportCompletion = false
            didReportUnavailable = false
            isPendingPlayback = false
        }

        private func playIfNeeded(shouldPlay: Bool) {
            guard shouldPlay, hasStartedPlayback == false else { return }
            guard player?.currentItem?.status == .readyToPlay else {
                isPendingPlayback = true
                return
            }

            hasStartedPlayback = true
            didReportCompletion = false
            isPendingPlayback = false
            player?.playImmediately(atRate: 1.0)
        }

        private func handleItemStatus(_ status: AVPlayerItem.Status) {
            switch status {
            case .readyToPlay:
                if isPendingPlayback {
                    playIfNeeded(shouldPlay: true)
                }
            case .failed:
                reportPlaybackUnavailableIfNeeded()
            case .unknown:
                break
            @unknown default:
                reportPlaybackUnavailableIfNeeded()
            }
        }

        private func reportReadyForDisplayIfPlaybackHasAdvanced(currentTime: CMTime? = nil) {
            guard isLayerReadyForDisplay else { return }
            let time = currentTime ?? player?.currentTime() ?? .zero
            guard CMTimeGetSeconds(time) >= DepartureCardTransitionTiming.minimumPlaybackTimeBeforeReveal else {
                return
            }
            reportReadyForDisplayIfNeeded()
        }

        private func reportReadyForDisplayIfNeeded() {
            guard didReportReadyForDisplay == false else { return }
            didReportReadyForDisplay = true
            onReadyForDisplay()
        }

        private func reportPlaybackUnavailableIfNeeded() {
            guard didReportUnavailable == false else { return }
            didReportUnavailable = true
            player?.pause()
            onPlaybackUnavailable()
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

        private func removeTimeObserver() {
            if let timeObserver,
               let player {
                player.removeTimeObserver(timeObserver)
                self.timeObserver = nil
            } else {
                timeObserver = nil
            }
        }

        private func removeReadyObserver() {
            readyObserver?.invalidate()
            readyObserver = nil
        }

        private func removeStatusObserver() {
            statusObserver?.invalidate()
            statusObserver = nil
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
            backgroundColor = .clear
            clipsToBounds = true
            isOpaque = false
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .clear
            clipsToBounds = true
            isOpaque = false
        }
    }
}
