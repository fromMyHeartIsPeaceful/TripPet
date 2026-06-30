import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: AppTab = .cabin
    @State private var retainedTabs: Set<AppTab> = Self.initialRetainedTabs
    @State private var departureTransitionContext: DepartureTransitionContext?
    @State private var releaseDepartureRefreshHold: (() -> Void)?

    static let bottomTabOrder: [AppTab] = [.cabin, .achievements, .mailbox, .map]
    static let initialRetainedTabs: Set<AppTab> = [.cabin]
    static let deferredPrewarmTabs: Set<AppTab> = [.map]

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                retainedContentStack
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, contentBottomReserve)

                RootBottomTabBar(
                    selectedTab: $selectedTab,
                    unreadMailboxBadgeCount: unreadMailboxBadgeCount,
                    bottomPadding: tabBarBottomPadding
                )
            }

            if let departureTransitionContext {
                DepartureCardTransitionOverlay(
                    context: departureTransitionContext,
                    onCoverReady: {
                        releaseDepartureRefreshHoldIfNeeded()
                    },
                    onComplete: {
                        releaseDepartureRefreshHoldIfNeeded()
                        self.departureTransitionContext = nil
                    }
                )
                .zIndex(10)
            }
        }
        .background {
            if selectedTab == .cabin && colorScheme == .dark {
                ArtImage(name: cabinBackgroundAssetName, contentMode: .fill)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            applyPendingNotificationTabRequest()
            try? await Task.sleep(nanoseconds: 180_000_000)
            retainedTabs.formUnion(Self.deferredPrewarmTabs)
        }
        .onChange(of: selectedTab) { _, newTab in
            retainedTabs.insert(newTab)
        }
        .onChange(of: environment.notificationRequestedTab) { _, _ in
            applyPendingNotificationTabRequest()
        }
    }

    @ViewBuilder
    private var retainedContentStack: some View {
        ZStack {
            retainedContent(.cabin) {
                CabinView { context, releaseRefreshHold in
                    releaseDepartureRefreshHold = releaseRefreshHold
                    departureTransitionContext = context
                }
            }

            if shouldBuildTab(.achievements) {
                retainedContent(.achievements) {
                    AchievementWallView()
                }
            }

            if shouldBuildTab(.mailbox) {
                retainedContent(.mailbox) {
                    MailboxView(isActive: selectedTab == .mailbox)
                }
            }

            if shouldBuildTab(.map) {
                retainedContent(.map) {
                    WorldMapView(isActive: selectedTab == .map)
                }
            }
        }
    }

    private func applyPendingNotificationTabRequest() {
        guard let requestedTab = environment.consumeNotificationTabRequest() else { return }
        selectedTab = requestedTab
    }

    private func shouldBuildTab(_ tab: AppTab) -> Bool {
        retainedTabs.contains(tab) || selectedTab == tab
    }

    private func retainedContent<Content: View>(
        _ tab: AppTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
    }

    var unreadMailboxBadgeCount: Int {
        Self.unreadMailboxBadgeCount(in: environment.repository.postcards)
    }

    static func unreadMailboxBadgeCount(in postcards: [Postcard]) -> Int {
        postcards.filter { $0.isRead == false }.count
    }

    private var cabinBackgroundAssetName: String {
        colorScheme == .dark ? "cabin_bg_night_full" : "cabin_bg_day_full"
    }

    private var contentBottomReserve: CGFloat {
        switch selectedTab {
        case .cabin:
            0
        case .achievements:
            0
        case .map:
            28
        case .mailbox:
            0
        }
    }

    private var tabBarBottomPadding: CGFloat {
        BottomChromeMetrics.tabBarBottomPadding
    }

    private func releaseDepartureRefreshHoldIfNeeded() {
        releaseDepartureRefreshHold?()
        releaseDepartureRefreshHold = nil
    }
}

private struct RootBottomTabBar: View {
    @Binding var selectedTab: AppTab
    var unreadMailboxBadgeCount: Int
    var bottomPadding: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RootTabView.bottomTabOrder, id: \.self) { tab in
                tabButton(
                    tab: tab,
                    title: title(for: tab),
                    iconName: iconName(for: tab),
                    badgeCount: tab == .mailbox ? unreadMailboxBadgeCount : 0
                )
            }
        }
        .padding(6)
        .frame(height: BottomChromeMetrics.tabBarHeight)
        .frame(maxWidth: 328)
        .background(AppTheme.paperWhite)
        .clipShape(Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppTheme.paperGray.opacity(0.70), lineWidth: AppTheme.hairline)
        }
        .shadow(color: AppTheme.oliveInk.opacity(0.14), radius: 14, x: 0, y: 6)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.bottom, bottomPadding)
    }

    private func title(for tab: AppTab) -> String {
        switch tab {
        case .cabin:
            AppCopy.Tabs.cabin
        case .achievements:
            AppCopy.Tabs.achievements
        case .mailbox:
            AppCopy.Tabs.mailbox
        case .map:
            AppCopy.Tabs.map
        }
    }

    private func iconName(for tab: AppTab) -> String {
        switch tab {
        case .cabin:
            "icon_home"
        case .achievements:
            "icon_collection"
        case .mailbox:
            "icon_mail"
        case .map:
            "icon_map"
        }
    }

    private func tabButton(
        tab: AppTab,
        title: String,
        iconName: String,
        badgeCount: Int = 0
    ) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)

                    if badgeCount > 0 {
                        Text(badgeText(for: badgeCount))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.paperWhite)
                            .frame(minWidth: 15, minHeight: 15)
                            .padding(.horizontal, badgeCount > 9 ? 3 : 0)
                            .background(Color(red: 0.78, green: 0.23, blue: 0.19))
                            .clipShape(Capsule())
                            .offset(x: 9, y: -6)
                    }
                }

                Text(title)
                    .font(AppTheme.tab)
            }
            .foregroundStyle(isSelected ? AppTheme.deepSage : AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(AppTheme.sage.opacity(0.22))
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func badgeText(for count: Int) -> String {
        count > 99 ? "99+" : "\(count)"
    }
}
