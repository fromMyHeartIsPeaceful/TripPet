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

struct FullScreenDepartureTransitionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let context: DepartureTransitionContext
    var onComplete: () -> Void

    @State private var didStart = false
    @State private var shimmer = false

    private let duration: UInt64 = 6_050_000_000

    var body: some View {
        ZStack {
            departureBackground

            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.clear,
                    Color.black.opacity(0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            animalLayer
        }
        .ignoresSafeArea()
        .task {
            guard didStart == false else { return }
            didStart = true

            withAnimation(.easeInOut(duration: reduceMotion ? 0.01 : 4.8)) {
                shimmer = true
            }

            let playbackDuration = reduceMotion ? 1_200_000_000 : duration
            try? await Task.sleep(nanoseconds: playbackDuration)
            onComplete()
        }
        .accessibilityLabel("\(context.animalName)出发了")
    }

    @ViewBuilder
    private var departureBackground: some View {
        if reduceMotion == false,
           let url = DepartureTransitionCatalog.genericVideoURL() {
            DepartureTransitionVideoView(url: url)
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.82, blue: 0.52),
                    Color(red: 0.98, green: 0.92, blue: 0.78),
                    Color(red: 0.72, green: 0.82, blue: 0.86)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var animalLayer: some View {
        GeometryReader { proxy in
            let profile = DepartureAnimalMotionProfile.profile(for: context.animalId)
            let width = proxy.size.width
            let height = proxy.size.height
            let progress = shimmer ? CGFloat(1) : CGFloat(0)
            let x = profile.startX + (profile.endX - profile.startX) * progress
            let y = profile.startY + (profile.endY - profile.startY) * progress
            let scale = profile.startScale + (profile.endScale - profile.startScale) * progress

            ZStack {
                trail(for: profile)
                    .opacity(reduceMotion ? 0 : (shimmer ? 0.82 : 0.0))
                    .position(x: width * 0.50, y: height * 0.70)

                ZStack {
                    ArtImage(name: context.animalAssetName)
                        .frame(width: profile.animalSize.width, height: profile.animalSize.height)
                        .scaleEffect(x: profile.isMirrored ? -1 : 1, y: 1)
                        .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 10)

                    ArtImage(name: "prop_ticket_single")
                        .frame(width: 88, height: 44)
                        .rotationEffect(.degrees(profile.ticketRotation))
                        .offset(profile.ticketOffset)
                        .shadow(color: AppTheme.ochre.opacity(0.36), radius: 10, x: 0, y: 3)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(profile.rotation * progress))
                .position(x: width * x, y: height * y)
            }
            .frame(width: width, height: height)
        }
        .allowsHitTesting(false)
    }

    private func trail(for profile: DepartureAnimalMotionProfile) -> some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.ochre.opacity(0.0),
                            AppTheme.ochre.opacity(0.72),
                            AppTheme.paperWhite.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: profile.trailWidth, height: profile.trailHeight)
                .rotationEffect(.degrees(profile.trailRotation))
                .blur(radius: 4)

            ArtImage(name: "prop_paper_plane")
                .frame(width: 74, height: 52)
                .rotationEffect(.degrees(-12))
                .offset(x: profile.planeOffset.width, y: profile.planeOffset.height)
                .opacity(0.9)
        }
    }
}

private enum DepartureTransitionCatalog {
    private static let resourceSubdirectory = "DepartureTransitions"

    static func genericVideoURL(bundle: Bundle = .main) -> URL? {
        bundle.url(
            forResource: "generic_airport_departure",
            withExtension: "mp4",
            subdirectory: resourceSubdirectory
        )
    }
}

private struct DepartureAnimalMotionProfile {
    var startX: CGFloat
    var startY: CGFloat
    var endX: CGFloat
    var endY: CGFloat
    var startScale: CGFloat
    var endScale: CGFloat
    var rotation: Double
    var ticketRotation: Double
    var ticketOffset: CGSize
    var animalSize: CGSize
    var trailWidth: CGFloat
    var trailHeight: CGFloat
    var trailRotation: Double
    var planeOffset: CGSize
    var isMirrored: Bool = false

    static func profile(for animalId: String) -> DepartureAnimalMotionProfile {
        switch animalId {
        case "tangyuan_puppy":
            return DepartureAnimalMotionProfile(
                startX: 0.28,
                startY: 0.83,
                endX: 0.62,
                endY: 0.66,
                startScale: 0.82,
                endScale: 1.02,
                rotation: -3,
                ticketRotation: -7,
                ticketOffset: CGSize(width: -36, height: 10),
                animalSize: CGSize(width: 245, height: 245),
                trailWidth: 250,
                trailHeight: 18,
                trailRotation: -18,
                planeOffset: CGSize(width: 112, height: -34)
            )
        case "moji_cat":
            return DepartureAnimalMotionProfile(
                startX: 0.35,
                startY: 0.79,
                endX: 0.56,
                endY: 0.63,
                startScale: 0.84,
                endScale: 0.98,
                rotation: 2,
                ticketRotation: 5,
                ticketOffset: CGSize(width: -30, height: 12),
                animalSize: CGSize(width: 250, height: 250),
                trailWidth: 220,
                trailHeight: 14,
                trailRotation: -12,
                planeOffset: CGSize(width: 96, height: -42)
            )
        case "dengdeng_rabbit":
            return DepartureAnimalMotionProfile(
                startX: 0.42,
                startY: 0.84,
                endX: 0.58,
                endY: 0.58,
                startScale: 0.78,
                endScale: 1.00,
                rotation: -2,
                ticketRotation: -4,
                ticketOffset: CGSize(width: -28, height: 14),
                animalSize: CGSize(width: 235, height: 235),
                trailWidth: 210,
                trailHeight: 22,
                trailRotation: -24,
                planeOffset: CGSize(width: 90, height: -54)
            )
        case "feifei_parrot":
            return DepartureAnimalMotionProfile(
                startX: 0.28,
                startY: 0.72,
                endX: 0.62,
                endY: 0.48,
                startScale: 0.78,
                endScale: 0.96,
                rotation: 5,
                ticketRotation: 8,
                ticketOffset: CGSize(width: -18, height: 22),
                animalSize: CGSize(width: 250, height: 250),
                trailWidth: 270,
                trailHeight: 20,
                trailRotation: -28,
                planeOffset: CGSize(width: 122, height: -52)
            )
        case "xiaolu_guinea_pig":
            return DepartureAnimalMotionProfile(
                startX: 0.30,
                startY: 0.84,
                endX: 0.58,
                endY: 0.68,
                startScale: 0.80,
                endScale: 0.96,
                rotation: 1,
                ticketRotation: -2,
                ticketOffset: CGSize(width: -34, height: 16),
                animalSize: CGSize(width: 240, height: 230),
                trailWidth: 230,
                trailHeight: 16,
                trailRotation: -14,
                planeOffset: CGSize(width: 106, height: -34)
            )
        case "deer_visitor":
            return DepartureAnimalMotionProfile(
                startX: 0.33,
                startY: 0.82,
                endX: 0.60,
                endY: 0.56,
                startScale: 0.78,
                endScale: 0.98,
                rotation: -4,
                ticketRotation: -6,
                ticketOffset: CGSize(width: -24, height: 18),
                animalSize: CGSize(width: 225, height: 260),
                trailWidth: 250,
                trailHeight: 18,
                trailRotation: -25,
                planeOffset: CGSize(width: 112, height: -54)
            )
        case "fox_visitor":
            return DepartureAnimalMotionProfile(
                startX: 0.72,
                startY: 0.82,
                endX: 0.44,
                endY: 0.62,
                startScale: 0.78,
                endScale: 0.98,
                rotation: -6,
                ticketRotation: 7,
                ticketOffset: CGSize(width: 30, height: 14),
                animalSize: CGSize(width: 240, height: 250),
                trailWidth: 260,
                trailHeight: 16,
                trailRotation: 18,
                planeOffset: CGSize(width: -110, height: -40),
                isMirrored: true
            )
        case "bear_visitor":
            return DepartureAnimalMotionProfile(
                startX: 0.36,
                startY: 0.84,
                endX: 0.56,
                endY: 0.66,
                startScale: 0.82,
                endScale: 1.06,
                rotation: 1,
                ticketRotation: -3,
                ticketOffset: CGSize(width: -30, height: 18),
                animalSize: CGSize(width: 255, height: 255),
                trailWidth: 225,
                trailHeight: 24,
                trailRotation: -12,
                planeOffset: CGSize(width: 98, height: -34)
            )
        default:
            return DepartureAnimalMotionProfile(
                startX: 0.34,
                startY: 0.83,
                endX: 0.57,
                endY: 0.64,
                startScale: 0.80,
                endScale: 1.00,
                rotation: -2,
                ticketRotation: -5,
                ticketOffset: CGSize(width: -30, height: 14),
                animalSize: CGSize(width: 240, height: 240),
                trailWidth: 230,
                trailHeight: 18,
                trailRotation: -16,
                planeOffset: CGSize(width: 104, height: -40)
            )
        }
    }
}

private struct DepartureTransitionVideoView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PlayerContainerView, context: Context) {
        context.coordinator.configure(url: url, in: view)
    }

    static func dismantleUIView(_ view: PlayerContainerView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVPlayer?

        func configure(url: URL, in view: PlayerContainerView) {
            guard currentURL != url else {
                player?.play()
                return
            }

            currentURL = url
            let player = AVPlayer(url: url)
            player.isMuted = true
            self.player = player
            view.playerLayer.player = player
            player.play()
        }

        func stop() {
            player?.pause()
            player = nil
            currentURL = nil
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
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .clear
            clipsToBounds = true
        }
    }
}
