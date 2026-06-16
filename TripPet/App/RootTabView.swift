import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var selectedTab: AppTab = .cabin

    var body: some View {
        TabView(selection: $selectedTab) {
            CabinView()
                .tabItem {
                    Label(AppCopy.Tabs.cabin, image: "icon_home")
                }
                .tag(AppTab.cabin)

            MailboxView()
                .tabItem {
                    Label(AppCopy.Tabs.mailbox, image: "icon_mail")
                }
                .badge(unreadMailboxBadgeCount)
                .tag(AppTab.mailbox)

            WorldMapView()
                .tabItem {
                    Label(AppCopy.Tabs.map, image: "icon_map")
                }
                .tag(AppTab.map)
        }
        .tint(AppTheme.deepSage)
        .onChange(of: environment.notificationRequestedTab) { _, requestedTab in
            guard let requestedTab else { return }
            selectedTab = requestedTab
            environment.clearNotificationTabRequest()
        }
    }

    var unreadMailboxBadgeCount: Int {
        Self.unreadMailboxBadgeCount(in: environment.repository.postcards)
    }

    static func unreadMailboxBadgeCount(in postcards: [Postcard]) -> Int {
        postcards.filter { $0.isRead == false }.count
    }
}
