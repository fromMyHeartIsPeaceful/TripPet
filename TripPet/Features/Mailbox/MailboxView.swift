import SwiftUI

struct MailboxView: View {
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
                        onOpenMailbox: {
                            viewModel.openStack(with: unreadPostcards)
                        },
                        onOpenHistory: {
                            viewModel.isHistoryPresented = true
                        }
                    )

                    if viewModel.isStackPresented {
                        MailboxPostcardStackOverlay(
                            postcards: stackPostcards,
                            currentIndex: $viewModel.stackIndex,
                            reduceMotion: reduceMotion,
                            senderName: senderName(for:),
                            onClose: {
                                viewModel.closeStack()
                            },
                            onPrevious: {
                                viewModel.showPreviousPostcard(count: stackPostcards.count)
                            },
                            onNext: {
                                viewModel.showNextPostcard(count: stackPostcards.count)
                            },
                            onOpenPostcard: { postcard in
                                viewModel.showUnreadStackDetail(postcard)
                            }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .zIndex(3)
                    }
                }
            }
            .navigationBarHidden(true)
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
    }

    private var unreadPostcards: [Postcard] {
        environment.repository.postcards.filter { $0.isRead == false }
    }

    private var readPostcards: [Postcard] {
        environment.repository.postcards.filter(\.isRead)
    }

    private var stackPostcards: [Postcard] {
        viewModel.openedStackPostcardIds.compactMap { postcardId in
            environment.repository.postcards.first { $0.id == postcardId }
        }
    }

    private func senderName(for postcard: Postcard) -> String {
        if let trip = environment.repository.trips.first(where: { $0.id == postcard.tripId }) {
            return environment.repository.animalName(for: trip.animalId)
        }
        return postcard.titleSenderNameFallback
    }
}

private struct MailboxSceneContent: View {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    let unreadCount: Int
    let readCount: Int
    let reduceMotion: Bool
    let onOpenMailbox: () -> Void
    let onOpenHistory: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            header
                .padding(.horizontal, 20)
                .padding(.top, headerTopPadding)

            Button(action: onOpenMailbox) {
                MailboxHotspotButton(hasUnread: hasUnread, reduceMotion: reduceMotion)
                    .frame(width: mailboxHitboxWidth, height: mailboxHitboxHeight)
            }
            .buttonStyle(.plain)
            .disabled(hasUnread == false)
            .position(x: mailboxCenterX, y: mailboxCenterY)
            .accessibilityLabel(hasUnread ? "打开邮箱，查看新明信片" : "邮箱还没有新明信片")

            VStack {
                Spacer()

                Text(statusText)
                    .font(AppTheme.body)
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 142)
            }
            .allowsHitTesting(false)
        }
        .frame(width: size.width, height: size.height)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(AppCopy.Mailbox.title)
                .font(AppTheme.pageTitle)
                .foregroundStyle(AppTheme.ink)

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
        min(size.width * 0.44, 188)
    }

    private var mailboxHitboxHeight: CGFloat {
        min(size.height * 0.22, 188)
    }

    private var mailboxCenterX: CGFloat {
        size.width * 0.68
    }

    private var mailboxCenterY: CGFloat {
        size.height * 0.56
    }

    private var statusText: String {
        if hasUnread {
            return unreadCount == 1 ? "有新的明信片到了" : "\(unreadCount) 张新的明信片到了"
        }
        return AppCopy.Mailbox.emptyTitle
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

private struct MailboxHotspotButton: View {
    let hasUnread: Bool
    let reduceMotion: Bool
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                if hasUnread {
                    MailboxArrivalPulse(isAnimating: isAnimating, reduceMotion: reduceMotion)
                        .frame(width: width, height: height)
                }

                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            }
        }
        .onAppear {
            guard reduceMotion == false else { return }
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

private struct MailboxArrivalPulse: View {
    let isAnimating: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(AppTheme.ochre.opacity(isAnimating && reduceMotion == false ? 0.22 : 0.12))
                .blur(radius: 18)
                .scaleEffect(isAnimating && reduceMotion == false ? 1.08 : 0.96)

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(AppTheme.ochre.opacity(0.72))
                    .frame(width: 5 + CGFloat(index % 2) * 2, height: 5 + CGFloat(index % 2) * 2)
                    .offset(sparkOffset(index))
                    .opacity(isAnimating && reduceMotion == false ? 0.70 : 0.38)
                    .scaleEffect(isAnimating && reduceMotion == false ? 1.12 : 0.86)
            }
        }
    }

    private func sparkOffset(_ index: Int) -> CGSize {
        let offsets = [
            CGSize(width: -58, height: -44),
            CGSize(width: -28, height: -76),
            CGSize(width: 42, height: -58),
            CGSize(width: 66, height: 8),
            CGSize(width: -50, height: 34)
        ]
        return offsets[index % offsets.count]
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
    let onClose: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onOpenPostcard: (Postcard) -> Void

    var body: some View {
        ZStack {
            AppTheme.oliveInk.opacity(0.34)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 18) {
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

                if let postcard = currentPostcard {
                    Button {
                        onOpenPostcard(postcard)
                    } label: {
                        postcardStack
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("查看\(postcard.destination)明信片内容")

                    HStack(spacing: 28) {
                        Button(action: onPrevious) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .bold))
                                .frame(width: 42, height: 42)
                        }
                        .disabled(currentIndex <= 0)

                        Text("\(safeIndex + 1) / \(max(postcards.count, 1))")
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

                    Text("点击明信片查看内容")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                } else {
                    Text("本次没有新的明信片")
                        .font(AppTheme.body)
                        .foregroundStyle(AppTheme.secondaryInk)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 18)
            .padding(.bottom, 96)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.paperWhite.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.vertical, 44)
            .shadow(color: AppTheme.oliveInk.opacity(0.18), radius: 22, x: 0, y: 12)
        }
    }

    private var postcardStack: some View {
        ZStack {
            ForEach(Array(postcards.enumerated()), id: \.element.id) { index, postcard in
                if abs(index - safeIndex) <= 2 {
                    MailboxPostcardPreview(
                        postcard: postcard,
                        senderName: senderName(postcard),
                        isCurrent: index == safeIndex
                    )
                    .frame(maxWidth: 292)
                    .aspectRatio(0.74, contentMode: .fit)
                    .scaleEffect(index == safeIndex ? 1 : 0.92)
                    .rotationEffect(.degrees(Double(index - safeIndex) * 5))
                    .offset(x: CGFloat(index - safeIndex) * 22, y: CGFloat(abs(index - safeIndex)) * 14)
                    .opacity(index == safeIndex ? 1 : 0.72)
                    .zIndex(Double(10 - abs(index - safeIndex)))
                    .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82), value: safeIndex)
                }
            }
        }
        .frame(height: 400)
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
    let isCurrent: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                ArtImage(name: "postcard_base_portrait", contentMode: .fill, cornerRadius: 22, showsShadow: isCurrent)
                    .frame(width: size.width, height: size.height)
                    .clipped()

                ArtImage(name: destinationArtworkName, contentMode: .fill, cornerRadius: 14)
                    .frame(width: size.width * 0.82, height: size.height * 0.40)
                    .clipped()
                    .position(x: size.width * 0.50, y: size.height * 0.31)

                ArtImage(name: postcard.stampAssetName)
                    .frame(width: size.width * 0.17, height: size.width * 0.17)
                    .rotationEffect(.degrees(-10))
                    .opacity(0.78)
                    .position(x: size.width * 0.82, y: size.height * 0.12)

                VStack(spacing: 7) {
                    Text(postcard.destination)
                        .font(AppTheme.postcardTitle(size: 22))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text("\(senderName)寄来的明信片")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .frame(width: size.width * 0.76)
                .position(x: size.width * 0.50, y: size.height * 0.72)
            }
        }
    }

    private var destinationArtworkName: String {
        switch postcard.destinationAssetName {
        case "destination_paris_line", "postcard_portrait_destination_paris":
            return "postcard_destination_paris"
        case "destination_iceland_line", "postcard_portrait_destination_reykjavik":
            return "postcard_destination_reykjavik"
        case "destination_lisbon_line", "postcard_portrait_destination_lisbon":
            return "postcard_destination_lisbon"
        case "postcard_airport_first_departure", "postcard_portrait_destination_airport":
            return "postcard_destination_airport"
        default:
            return postcard.destinationAssetName
        }
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
