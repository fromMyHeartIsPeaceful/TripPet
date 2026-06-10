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
                .badge(environment.repository.postcards.filter { $0.isRead == false }.count)
        }
        .tint(AppTheme.deepSage)
    }
}
