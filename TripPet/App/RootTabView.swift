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

            AchievementWallView {
                selectedTab = .cabin
            }
                .tabItem {
                    Label(AppCopy.Tabs.achievements, image: "icon_collection")
                }
                .tag(AppTab.achievements)

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
}
