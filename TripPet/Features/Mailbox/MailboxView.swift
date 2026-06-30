import SwiftUI
import UIKit

struct MailboxView: View {
    var isActive = true

    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = MailboxViewModel()
    @State private var deferredHistoryPostcard: Postcard?

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    MailboxSceneBackground(hasUnread: unreadPostcards.isEmpty == false)
                        .ignoresSafeArea()

                    MailboxSceneContent(
                        size: proxy.size,
                        safeAreaInsets: proxy.safeAreaInsets,
                        unreadCount: unreadPostcards.count,
                        readCount: readPostcards.count,
                        reduceMotion: reduceMotion,
                        speechText: mailboxSpeechText,
                        onOpenMailbox: {
                            viewModel.openStack(with: unreadPostcards)
                            if let firstPostcard = unreadPostcards.first {
                                Task {
                                    await environment.requestNotificationAuthorizationOnPostcardReturn(firstPostcard)
                                }
                            }
                        },
                        onOpenHistory: {
                            viewModel.isHistoryPresented = true
                        },
                        onEmptyMailboxTap: {
                            viewModel.registerEmptyMailboxTap()
                        }
                    )

                    if viewModel.isStackPresented {
                        MailboxPostcardStackOverlay(
                            postcards: stackPostcards,
                            currentIndex: $viewModel.stackIndex,
                            reduceMotion: reduceMotion,
                            senderName: senderName(for:),
                            animalId: animalId(for:),
                            destination: destination(for:),
                            onClose: {
                                viewModel.closeStack(repository: environment.repository)
                            },
                            onPrevious: {
                                viewModel.showPreviousPostcard(count: stackPostcards.count)
                            },
                            onNext: {
                                viewModel.showNextPostcard(count: stackPostcards.count)
                            }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .zIndex(3)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.resetEmptyMailboxPrompt()
            }
            .onChange(of: unreadPostcards.count) {
                viewModel.resetEmptyMailboxPrompt()
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    viewModel.resetEmptyMailboxPrompt()
                }
            }
            .task {
                environment.revealEligiblePostcards()
            }
            .sheet(
                isPresented: $viewModel.isHistoryPresented,
                onDismiss: {
                    if let deferredHistoryPostcard {
                        viewModel.showHistoryDetail(deferredHistoryPostcard)
                        self.deferredHistoryPostcard = nil
                    }
                }
            ) {
                MailboxHistorySheet(
                    readPostcards: readPostcards,
                    senderName: senderName(for:),
                    onSelect: { postcard in
                        deferredHistoryPostcard = postcard
                        viewModel.isHistoryPresented = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .fullScreenCover(
                item: $viewModel.selectedPostcard,
                onDismiss: {
                    viewModel.settleSelectedPostcardDismissal(repository: environment.repository)
                }
            ) { postcard in
                PostcardDetailView(postcard: postcard)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unreadPostcards: [Postcard] {
        environment.repository.postcards.filter { $0.isRead == false }
    }

    private var readPostcards: [Postcard] {
        environment.repository.postcards.filter(\.isRead)
    }

    private var mailboxSpeechText: String {
        unreadPostcards.isEmpty ? viewModel.emptyMailboxPromptText : AppCopy.Mailbox.hasPostcardsPrompt
    }

    private var stackPostcards: [Postcard] {
        viewModel.openedStackPostcardIds.compactMap { postcardId in
            environment.repository.postcards.first { $0.id == postcardId }
        }
    }

    private func senderName(for postcard: Postcard) -> String {
        if let trip = trip(for: postcard) {
            return environment.repository.animalName(for: trip.animalId)
        }
        return postcard.titleSenderNameFallback
    }

    private func animalId(for postcard: Postcard) -> String? {
        trip(for: postcard)?.animalId
    }

    private func destination(for postcard: Postcard) -> ManifestDestination? {
        if let trip = trip(for: postcard),
           let destination = environment.destination(for: trip) {
            return destination
        }
        return environment.destinations.first {
            $0.displayName == postcard.destination ||
                $0.landmarkAssetName == postcard.destinationAssetName
        }
    }

    private func trip(for postcard: Postcard) -> Trip? {
        environment.repository.trips.first { $0.id == postcard.tripId }
    }
}

private struct MailboxSceneContent: View {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    let unreadCount: Int
    let readCount: Int
    let reduceMotion: Bool
    let speechText: String
    let onOpenMailbox: () -> Void
    let onOpenHistory: () -> Void
    let onEmptyMailboxTap: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            header
                .padding(.horizontal, 20)
                .padding(.top, headerTopPadding)

            Button(action: onMailboxTap) {
                MailboxHotspotButton(hasUnread: hasUnread, reduceMotion: reduceMotion)
                    .frame(width: mailboxHitboxWidth, height: mailboxHitboxHeight)
            }
            .buttonStyle(.plain)
            .position(x: mailboxCenterX, y: mailboxCenterY)
            .accessibilityLabel(hasUnread ? "打开邮箱，查看新明信片" : "邮箱还没有新明信片")

            Button(action: onMailboxTap) {
                MailboxButterflySpeechBubble(
                    text: speechText,
                    width: speechBubbleWidth,
                    height: speechBubbleHeight
                )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .position(speechBubbleCenter)
            .accessibilityLabel(hasUnread ? "打开邮箱，查看新明信片" : "蝴蝶说：\(speechText)")

            if hasUnread {
                MailboxPerchedButterfly(height: butterflyHeight, reduceMotion: reduceMotion)
                    .position(x: butterflyCenter.x, y: butterflyCenter.y)
                    .allowsHitTesting(false)
            } else {
                Button(action: onEmptyMailboxTap) {
                    MailboxPerchedButterfly(height: butterflyHeight, reduceMotion: reduceMotion)
                }
                .buttonStyle(.plain)
                .frame(width: butterflyTapWidth, height: butterflyTapHeight)
                .contentShape(Rectangle())
                .position(x: butterflyCenter.x, y: butterflyCenter.y)
                .accessibilityLabel("蝴蝶说：\(speechText)")
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func onMailboxTap() {
        if hasUnread {
            onOpenMailbox()
        } else {
            onEmptyMailboxTap()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Spacer()

            Button(action: onOpenHistory) {
                HStack(spacing: 6) {
                    ArtImage(name: "icon_collection", isDecorative: false)
                        .frame(width: 17, height: 17)
                    Text(readCount == 0 ? "收藏" : "收藏 \(readCount)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel("打开明信片收藏")
        }
    }

    private var hasUnread: Bool {
        unreadCount > 0
    }

    private var headerTopPadding: CGFloat {
        max(safeAreaInsets.top - 8, 16)
    }

    private var mailboxHitboxWidth: CGFloat {
        min(size.width * 0.54, 232)
    }

    private var mailboxHitboxHeight: CGFloat {
        min(size.height * 0.30, 270)
    }

    private var mailboxCenterX: CGFloat {
        size.width * 0.72
    }

    private var mailboxCenterY: CGFloat {
        size.height * 0.535
    }

    private var butterflyHeight: CGFloat {
        min(max(butterflyLayoutSize.width * 0.156, 56), 72)
    }

    private var butterflyWidth: CGFloat {
        butterflyHeight * MailboxButterflyAnimationCatalog.aspectRatio
    }

    private var butterflyTapWidth: CGFloat {
        max(butterflyWidth + 30, 84)
    }

    private var butterflyTapHeight: CGFloat {
        max(butterflyHeight + 28, 92)
    }

    private var speechBubbleWidth: CGFloat {
        min(max(size.width * 0.72, 260), 300)
    }

    private var speechBubbleHeight: CGFloat {
        128
    }

    private var speechBubbleCenter: CGPoint {
        CGPoint(
            x: min(max(butterflyCenter.x - speechBubbleWidth * 0.34, speechBubbleWidth * 0.5 + 14), size.width - speechBubbleWidth * 0.5 - 14),
            y: max(butterflyCenter.y - speechBubbleHeight * 0.82, safeAreaInsets.top + speechBubbleHeight * 0.5 + 44)
        )
    }

    private var butterflyCenter: CGPoint {
        let perchPoint = mailboxPerchPoint
        return CGPoint(
            x: perchPoint.x - (Self.butterflyContactAnchor.x - 0.5) * butterflyWidth,
            y: perchPoint.y - (Self.butterflyContactAnchor.y - 0.5) * butterflyHeight
        )
    }

    private var mailboxPerchPoint: CGPoint {
        scenePoint(forBackgroundNormalizedPoint: mailboxTopPerchPoint)
    }

    private var mailboxTopPerchPoint: CGPoint {
        hasUnread ? Self.unreadMailboxTopPerchPoint : Self.emptyMailboxTopPerchPoint
    }

    private func scenePoint(forBackgroundNormalizedPoint point: CGPoint) -> CGPoint {
        let scale = max(
            size.width / mailboxBackgroundDesignSize.width,
            size.height / mailboxBackgroundDesignSize.height
        )
        let renderedSize = CGSize(
            width: mailboxBackgroundDesignSize.width * scale,
            height: mailboxBackgroundDesignSize.height * scale
        )
        let origin = CGPoint(
            x: (size.width - renderedSize.width) / 2,
            y: (size.height - renderedSize.height) / 2
        )
        return CGPoint(
            x: origin.x + point.x * renderedSize.width,
            y: origin.y + point.y * renderedSize.height
        )
    }

    private var mailboxBackgroundDesignSize: CGSize {
        hasUnread ? Self.unreadMailboxBackgroundDesignSize : Self.emptyMailboxBackgroundDesignSize
    }

    private var butterflyLayoutSize: CGSize {
        let screenSize = UIScreen.main.bounds.size
        return CGSize(
            width: max(size.width, screenSize.width),
            height: max(size.height, screenSize.height)
        )
    }

    private static let unreadMailboxBackgroundDesignSize = CGSize(width: 884, height: 1780)
    private static let emptyMailboxBackgroundDesignSize = CGSize(width: 887, height: 1774)
    private static let unreadMailboxTopPerchPoint = CGPoint(x: 0.704, y: 0.426)
    private static let emptyMailboxTopPerchPoint = CGPoint(x: 0.674, y: 0.445)
    private static let butterflyContactAnchor = CGPoint(x: 0.50, y: 0.83)
}

private struct MailboxButterflySpeechBubble: View {
    let text: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            ArtImage(name: "mailbox_butterfly_speech_bubble", contentMode: .fit)
                .frame(width: width, height: height)
                .allowsHitTesting(false)

            Text(text)
                .font(AppTheme.postcardTitle(size: 16))
                .foregroundStyle(AppTheme.deepSage.opacity(0.98))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .lineLimit(3)
                .minimumScaleFactor(0.76)
                .padding(.horizontal, 30)
                .padding(.top, 24)
                .padding(.bottom, 34)
                .frame(width: width, height: height)
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

private struct MailboxSceneBackground: View {
    let hasUnread: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ArtImage(name: hasUnread ? "mailbox_forest_cabin_unread" : "mailbox_forest_cabin_empty", contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                ArtImage(name: "texture_paper_grain", contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.06)
            }
        }
    }
}

private struct MailboxPerchedButterfly: View {
    let height: CGFloat
    let reduceMotion: Bool

    var body: some View {
        MailboxButterflyFrameAnimation(reduceMotion: reduceMotion)
            .frame(width: height * MailboxButterflyAnimationCatalog.aspectRatio, height: height)
    }
}

private struct MailboxButterflyFrameAnimation: View {
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            frameImage(at: 0)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / MailboxButterflyAnimationCatalog.framesPerSecond)) { timeline in
                let index = MailboxButterflyAnimationCatalog.frameIndex(for: timeline.date)
                frameImage(at: index)
            }
        }
    }

    @ViewBuilder
    private func frameImage(at index: Int) -> some View {
        if let image = MailboxButterflyAnimationCatalog.image(at: index) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            Color.clear
        }
    }
}

private enum MailboxButterflyAnimationCatalog {
    static let resourceSubdirectory = "ButterflyMailboxAnimation/frames"
    static let frameCount = 48
    static let framesPerSecond: TimeInterval = 8
    static let aspectRatio: CGFloat = 184.0 / 240.0

    private static let cache = NSCache<NSNumber, UIImage>()

    static func frameIndex(for date: Date) -> Int {
        let frame = Int((date.timeIntervalSinceReferenceDate * framesPerSecond).rounded(.down))
        return abs(frame) % frameCount
    }

    static func image(at index: Int, bundle: Bundle = .main) -> UIImage? {
        let normalizedIndex = min(max(index, 0), frameCount - 1)
        let cacheKey = NSNumber(value: normalizedIndex)
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let resourceName = String(format: "butterfly_mailbox_%04d", normalizedIndex + 1)
        guard let url = bundle.url(
            forResource: resourceName,
            withExtension: "png",
            subdirectory: resourceSubdirectory
        ),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        cache.setObject(image, forKey: cacheKey)
        return image
    }
}

private struct MailboxHotspotButton: View {
    let hasUnread: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if hasUnread {
                    MailboxArrivalPulse(reduceMotion: reduceMotion)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }

                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            }
        }
    }
}

private struct MailboxArrivalPulse: View {
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            if reduceMotion {
                glow(size: proxy.size, opacity: 0.46, scale: 1.0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let phase = timeline.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: 2.2) / 2.2
                    let easedPulse = 0.5 - 0.5 * cos(phase * 2.0 * Double.pi)

                    glow(
                        size: proxy.size,
                        opacity: 0.40 + easedPulse * 0.18,
                        scale: 0.985 + easedPulse * 0.035
                    )
                }
            }
        }
    }

    private func glow(size: CGSize, opacity: Double, scale: Double) -> some View {
        ArtImage(name: "mailbox_arrival_glow", contentMode: .fill)
            .frame(width: size.width * 1.56, height: size.height * 1.22)
            .position(x: size.width * 0.50, y: size.height * 0.43)
            .blendMode(.screen)
            .opacity(opacity)
            .scaleEffect(scale)
            .allowsHitTesting(false)
    }
}

extension Postcard {
    var titleSenderNameFallback: String {
        let senderMarkers = [
            "寄来的明信片",
            "寄来的第一张明信片",
            "寄来"
        ]
        for marker in senderMarkers {
            if let range = title.range(of: marker) {
                let name = title[..<range.lowerBound]
                if name.isEmpty == false {
                    return String(name)
                }
            }
        }
        return "小动物"
    }
}

private struct MailboxPostcardStackOverlay: View {
    let postcards: [Postcard]
    @Binding var currentIndex: Int
    let reduceMotion: Bool
    let senderName: (Postcard) -> String
    let animalId: (Postcard) -> String?
    let destination: (Postcard) -> ManifestDestination?
    let onClose: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let panelHeight = max(proxy.size.height - Self.panelTopPadding - panelBottomPadding, 0)
            let stackHeight = postcardStackHeight(for: panelHeight)

            ZStack {
                AppTheme.oliveInk.opacity(0.34)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)

                VStack(spacing: 14) {
                    HStack {
                        Text(stackTitle)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                        Button("关闭", action: onClose)
                            .buttonStyle(OutlineButtonStyle())
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)

                    if currentPostcard != nil {
                        postcardStack(height: stackHeight)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("新明信片内容")

                        if postcards.count > 1 {
                            HStack(spacing: 28) {
                                Button(action: onPrevious) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 17, weight: .bold))
                                        .frame(width: 42, height: 42)
                                }
                                .disabled(currentIndex <= 0)

                                Text("\(safeIndex + 1) / \(postcards.count)")
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.secondaryInk)
                                    .frame(width: 58)

                                Button(action: onNext) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 17, weight: .bold))
                                        .frame(width: 42, height: 42)
                                }
                                .disabled(currentIndex >= postcards.count - 1)
                            }
                            .buttonStyle(OutlineButtonStyle())
                        }
                    } else {
                        Text("本次没有新的明信片")
                            .font(AppTheme.body)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 18)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.paperWhite.opacity(0.90))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 18)
                .padding(.top, Self.panelTopPadding)
                .padding(.bottom, panelBottomPadding)
                .shadow(color: AppTheme.oliveInk.opacity(0.18), radius: 22, x: 0, y: 12)
            }
        }
    }

    private func postcardStack(height: CGFloat) -> some View {
        ZStack {
            ForEach(Array(postcards.enumerated()), id: \.element.id) { index, postcard in
                if abs(index - safeIndex) <= 2 {
                    MailboxPostcardPreview(
                        postcard: postcard,
                        senderName: senderName(postcard),
                        animalId: animalId(postcard),
                        destination: destination(postcard),
                        isCurrent: index == safeIndex
                    )
                    .frame(maxWidth: 292)
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .scaleEffect(index == safeIndex ? 1 : 0.92)
                    .rotationEffect(.degrees(Double(index - safeIndex) * 5))
                    .offset(x: CGFloat(index - safeIndex) * 22, y: CGFloat(abs(index - safeIndex)) * 14)
                    .opacity(index == safeIndex ? 1 : 0.72)
                    .zIndex(Double(10 - abs(index - safeIndex)))
                    .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82), value: safeIndex)
                }
            }
        }
        .frame(height: height)
    }

    private static let panelTopPadding: CGFloat = 44
    private static let panelToTabBarGap: CGFloat = 18

    private var panelBottomPadding: CGFloat {
        BottomChromeMetrics.tabBarBottomPadding +
            BottomChromeMetrics.tabBarHeight +
            Self.panelToTabBarGap
    }

    private func postcardStackHeight(for panelHeight: CGFloat) -> CGFloat {
        let reservedHeight: CGFloat = 196
        return min(max(panelHeight - reservedHeight, 280), 470)
    }

    private var safeIndex: Int {
        guard postcards.isEmpty == false else { return 0 }
        return min(max(currentIndex, 0), postcards.count - 1)
    }

    private var currentPostcard: Postcard? {
        guard postcards.indices.contains(safeIndex) else { return nil }
        return postcards[safeIndex]
    }

    private var stackTitle: String {
        postcards.count > 1 ? "本次送达" : "新明信片"
    }
}

private struct MailboxPostcardPreview: View {
    let postcard: Postcard
    let senderName: String
    let animalId: String?
    let destination: ManifestDestination?
    let isCurrent: Bool

    var body: some View {
        PostcardArtwork(
            postcard: postcard,
            senderName: senderName,
            animalId: animalId,
            destination: destination,
            showsShadow: isCurrent
        )
    }
}

private struct MailboxHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let readPostcards: [Postcard]
    let senderName: (Postcard) -> String
    let onSelect: (Postcard) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(AppCopy.Settings.collectionTitle)
                            .font(AppTheme.pageTitle)
                            .foregroundStyle(AppTheme.ink)
                            .padding(.top, 18)

                        if readPostcards.isEmpty {
                            historyEmptyState
                        } else {
                            ForEach(readPostcards) { postcard in
                                Button {
                                    onSelect(postcard)
                                } label: {
                                    historyRow(postcard)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var historyEmptyState: some View {
        VStack(spacing: 12) {
            ArtImage(name: "envelope_old")
                .frame(width: 150, height: 92)
                .opacity(0.72)
            Text(AppCopy.Settings.collectionEmpty)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .paperCard(cornerRadius: 20)
    }

    private func historyRow(_ postcard: Postcard) -> some View {
        HStack(spacing: 12) {
            ArtImage(name: postcard.stampAssetName)
                .frame(width: 42, height: 42)
                .opacity(0.80)

            VStack(alignment: .leading, spacing: 4) {
                Text(postcard.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("来自\(postcard.destination) · \(senderName(postcard))")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .padding(14)
        .paperCard(cornerRadius: 18, stroke: AppTheme.paperGray.opacity(0.80))
    }
}

#Preview("Mailbox with letters") {
    MailboxView()
        .environmentObject(
            AppEnvironment.preview(
                seed: SeedData(
                    animals: SeedData.preview.animals,
                    travelWishes: SeedData.preview.travelWishes,
                    trips: [],
                    postcards: SeedData.previewPostcards,
                    destinations: SeedData.preview.destinations
                )
            )
        )
}

#Preview("Mailbox empty") {
    MailboxView()
        .environmentObject(AppEnvironment.preview())
}
