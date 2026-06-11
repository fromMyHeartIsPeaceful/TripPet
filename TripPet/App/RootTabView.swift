import SwiftUI

struct RootTabView: View {
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
        }
        .tint(AppTheme.deepSage)
    }
}
