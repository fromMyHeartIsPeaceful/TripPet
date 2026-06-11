import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        TabView {
            CabinView()
                .tabItem {
                    Label(AppCopy.Tabs.cabin, image: "icon_home")
                }

            MailboxView()
                .tabItem {
                    Label(AppCopy.Tabs.mailbox, image: "icon_mail")
                }
                .badge(unreadMailboxBadgeCount)
        }
        .tint(AppTheme.deepSage)
    }

    var unreadMailboxBadgeCount: Int {
        Self.unreadMailboxBadgeCount(in: environment.repository.postcards)
    }

    static func unreadMailboxBadgeCount(in postcards: [Postcard]) -> Int {
        postcards.filter { $0.isRead == false }.count
    }
}
