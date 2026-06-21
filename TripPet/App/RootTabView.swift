import SwiftUI
import UIKit

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var selectedTab: AppTab = .cabin

    init() {
        Self.configureTabBarAppearance()
    }

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

    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.paperWhite)
        appearance.shadowColor = UIColor(AppTheme.paperGray.opacity(0.7))

        let selectedColor = UIColor(AppTheme.deepSage)
        let normalColor = UIColor(AppTheme.ink)
        let selectedAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: selectedColor]
        let normalAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: normalColor]

        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance].forEach { itemAppearance in
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = selectedAttributes
            itemAppearance.normal.iconColor = normalColor
            itemAppearance.normal.titleTextAttributes = normalAttributes
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().barTintColor = UIColor(AppTheme.paperWhite)
        UITabBar.appearance().backgroundColor = UIColor(AppTheme.paperWhite)
        UITabBar.appearance().unselectedItemTintColor = normalColor
        UITabBar.appearance().overrideUserInterfaceStyle = .light
    }
}
