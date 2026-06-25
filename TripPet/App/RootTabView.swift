import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: AppTab = .cabin
    @State private var retainedTabs: Set<AppTab> = [.cabin]
    @State private var departureTransitionContext: DepartureTransitionContext?

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
            .blur(radius: isDepartureTransitionPresented ? 2.6 : 0)
            .scaleEffect(isDepartureTransitionPresented ? 0.995 : 1)
            .animation(.easeOut(duration: 0.20), value: isDepartureTransitionPresented)

            if let departureTransitionContext {
                DepartureCardTransitionOverlay(context: departureTransitionContext) {
                    self.departureTransitionContext = nil
                }
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
                CabinView { context in
                    departureTransitionContext = context
                }
            }

            if shouldBuildTab(.mailbox) {
                retainedContent(.mailbox) {
                    MailboxView()
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
        case .map:
            28
        case .mailbox:
            0
        }
    }

    private var tabBarBottomPadding: CGFloat {
        BottomChromeMetrics.tabBarBottomPadding
    }

    private var isDepartureTransitionPresented: Bool {
        departureTransitionContext != nil
    }
}

private struct RootBottomTabBar: View {
    @Binding var selectedTab: AppTab
    var unreadMailboxBadgeCount: Int
    var bottomPadding: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            tabButton(tab: .cabin, title: AppCopy.Tabs.cabin, iconName: "icon_home")
            tabButton(
                tab: .mailbox,
                title: AppCopy.Tabs.mailbox,
                iconName: "icon_mail",
                badgeCount: unreadMailboxBadgeCount
            )
            tabButton(tab: .map, title: AppCopy.Tabs.map, iconName: "icon_map")
        }
        .padding(6)
        .frame(height: BottomChromeMetrics.tabBarHeight)
        .frame(maxWidth: 252)
        .background(AppTheme.paperWhite)
        .clipShape(Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppTheme.paperGray.opacity(0.70), lineWidth: AppTheme.hairline)
        }
        .shadow(color: AppTheme.oliveInk.opacity(0.14), radius: 14, x: 0, y: 6)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.bottom, bottomPadding)
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
