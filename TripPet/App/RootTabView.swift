import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: AppTab = .cabin
    @State private var mapInstanceID = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedContent
                .padding(.bottom, contentBottomReserve)

            RootBottomTabBar(
                selectedTab: $selectedTab,
                unreadMailboxBadgeCount: unreadMailboxBadgeCount,
                bottomPadding: tabBarBottomPadding
            )
        }
        .background {
            if selectedTab == .cabin {
                ArtImage(name: cabinBackgroundAssetName, contentMode: .fill)
                    .ignoresSafeArea()
            } else if selectedTab == .map {
                ArtImage(name: "world_travel_map", contentMode: .fill)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            applyPendingNotificationTabRequest()
        }
        .onChange(of: environment.notificationRequestedTab) { _, _ in
            applyPendingNotificationTabRequest()
        }
        .onChange(of: selectedTab) { _, tab in
            guard tab == .map else { return }
            mapInstanceID = UUID()
        }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .cabin:
            CabinView()
        case .mailbox:
            MailboxView()
        case .map:
            WorldMapView()
                .id(mapInstanceID)
        }
    }

    private func applyPendingNotificationTabRequest() {
        guard let requestedTab = environment.consumeNotificationTabRequest() else { return }
        selectedTab = requestedTab
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
            58
        case .map:
            28
        case .mailbox:
            0
        }
    }

    private var tabBarBottomPadding: CGFloat {
        8
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
