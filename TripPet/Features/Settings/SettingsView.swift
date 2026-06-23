import SwiftUI

#if DEBUG
import UserNotifications
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var environment: AppEnvironment
    @State private var healthStatus = "正在检查"

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                VStack(alignment: .leading, spacing: 18) {
                    header
                    healthCard

                    VStack(spacing: 10) {
                        NavigationLink {
                            NotificationSettingsPage()
                        } label: {
                            SettingsStrip(iconName: "icon_notification", title: AppCopy.Settings.notificationTitle, detail: AppCopy.Settings.notificationDetail)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            CollectionSettingsPage()
                                .environmentObject(environment)
                        } label: {
                            SettingsStrip(iconName: "icon_collection", title: AppCopy.Settings.collectionTitle, detail: AppCopy.Settings.collectionDetail)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            AboutSettingsPage()
                        } label: {
                            SettingsStrip(iconName: "icon_about", title: AppCopy.Settings.aboutTitle, detail: AppCopy.Settings.aboutDetail)
                        }
                        .buttonStyle(.plain)

                        #if DEBUG
                        NavigationLink {
                            NotificationDiagnosticsPage()
                        } label: {
                            SettingsStrip(iconName: "icon_notification", title: "通知诊断", detail: "查看授权、pending 通知和最近排程日志")
                        }
                        .buttonStyle(.plain)
                        #endif
                    }

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationBarHidden(true)
            .task {
                await environment.refreshStepsIfPossible()
                updateHealthStatus()
            }
            .onChange(of: environment.stepSnapshot) { _, _ in
                updateHealthStatus()
            }
        }
    }

    private var header: some View {
        HStack {
                Text(AppCopy.Settings.title)
                .font(AppTheme.pageTitle)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Button(AppCopy.Settings.doneButton) {
                dismiss()
            }
            .buttonStyle(OutlineButtonStyle())
        }
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ArtImage(name: "icon_health", isDecorative: false)
                    .frame(width: 26, height: 26)
                    .foregroundStyle(AppTheme.deepSage)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.paperWhite)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.paperGray, lineWidth: AppTheme.hairline))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(AppCopy.Settings.healthTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        statusTag
                    }

                    Text(healthStatus)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineSpacing(3)
                }
            }

            Button(AppCopy.Settings.healthButton) {
                Task { await requestHealthPermission() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel("连接或更新 Apple 健康权限")
        }
        .padding(18)
        .paperCard(cornerRadius: 24)
    }

    private var statusTag: some View {
        Text(statusTagText)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(statusTagColor)
            .padding(.horizontal, 9)
            .frame(height: 25)
            .background(statusTagColor.opacity(0.13))
            .clipShape(Capsule())
    }

    private var statusTagText: String {
        switch environment.stepSnapshot.status {
        case .sharingAuthorized:
            return "已连接"
        case .unavailable:
            return "不可用"
        case .notDetermined:
            return "未请求"
        case .sharingDenied:
            return "未开启"
        case .readPermissionRequested:
            return "已请求"
        }
    }

    private var statusTagColor: Color {
        switch environment.stepSnapshot.status {
        case .sharingAuthorized:
            return AppTheme.deepSage
        case .readPermissionRequested:
            return AppTheme.deepSage
        case .unavailable, .sharingDenied:
            return Color(red: 0.788, green: 0.537, blue: 0.463)
        case .notDetermined:
            return AppTheme.ochre
        }
    }

    private func updateHealthStatus() {
        switch environment.stepSnapshot.status {
        case .unavailable:
            healthStatus = AppCopy.Health.settingsUnavailable
        case .notDetermined:
            healthStatus = AppCopy.Health.settingsNotDetermined
        case .sharingDenied:
            healthStatus = AppCopy.Health.settingsDenied
        case .sharingAuthorized:
            if let errorMessage = environment.stepSnapshot.errorMessage {
                healthStatus = errorMessage
            } else if let steps = environment.stepSnapshot.steps {
                healthStatus = AppCopy.Health.todayStepsRead(steps)
            } else {
                healthStatus = AppCopy.Health.settingsAuthorized
            }
        case .readPermissionRequested:
            if let errorMessage = environment.stepSnapshot.errorMessage {
                healthStatus = errorMessage
            } else if let steps = environment.stepSnapshot.steps {
                healthStatus = AppCopy.Health.todayStepsRead(steps)
            } else {
                healthStatus = AppCopy.Health.settingsReadPermissionRequested
            }
        }
    }

    private func requestHealthPermission() async {
        do {
            _ = try await environment.requestStepAuthorizationAndRefresh()
            updateHealthStatus()
        } catch {
            updateHealthStatus()
            healthStatus = error.localizedDescription
        }
    }
}

#if DEBUG
private struct NotificationDiagnosticsPage: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var authorizationSummary = "正在读取"
    @State private var pendingRequests: [String] = []
    @State private var events = PostcardNotificationDiagnostics.recentEvents
    @State private var debugScheduleStatus = ""

    var body: some View {
        SettingsDetailScaffold(
            title: "通知诊断",
            imageName: "settings_notification_note",
            bodyText: "这个页面只在 DEBUG 包显示，用来判断端外通知是否成功排进系统。"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(authorizationSummary)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineSpacing(3)

                HStack {
                    Button("刷新") {
                        Task { await reload() }
                    }
                    .buttonStyle(OutlineButtonStyle())

                    Button("1秒测试通知") {
                        Task { await scheduleDebugNotification() }
                    }
                    .buttonStyle(OutlineButtonStyle())

                    Button("清空日志") {
                        PostcardNotificationDiagnostics.clear()
                        events = []
                    }
                    .buttonStyle(OutlineButtonStyle())
                }

                if debugScheduleStatus.isEmpty == false {
                    Text(debugScheduleStatus)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }

                diagnosticGroup(title: "Pending 通知", lines: pendingRequests)
                diagnosticGroup(title: "最近日志", lines: events)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .paperCard(cornerRadius: 18)
            .task {
                await reload()
            }
        }
    }

    private func reload() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()

        authorizationSummary = [
            "授权：\(describe(settings.authorizationStatus))",
            "横幅：\(settings.alertSetting.rawValue)",
            "声音：\(settings.soundSetting.rawValue)",
            "角标：\(settings.badgeSetting.rawValue)",
            "pending：\(requests.count)"
        ].joined(separator: " · ")

        pendingRequests = requests.map { request in
            "\(request.identifier) · \(describe(request.trigger)) · \(request.content.title)"
        }.sorted()

        events = PostcardNotificationDiagnostics.recentEvents
    }

    private func scheduleDebugNotification() async {
        let isAuthorized = await environment.postcardNotificationService.requestAuthorization()
        guard isAuthorized else {
            debugScheduleStatus = "通知授权未开启"
            await reload()
            return
        }

        let postcardId = "debug-\(Int(Date().timeIntervalSince1970))"
        let didSchedule = await environment.postcardNotificationService.scheduleNewPostcardNotification(
            postcardId: postcardId,
            deliveryDate: Date().addingTimeInterval(1),
            requiresCurrentAuthorization: false
        )
        debugScheduleStatus = didSchedule ? "已排入 1 秒测试通知" : "测试通知排入失败"
        await reload()
    }

    @ViewBuilder
    private func diagnosticGroup(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            if lines.isEmpty {
                Text("暂无")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            } else {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(AppTheme.secondaryInk)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func describe(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .provisional:
            return "provisional"
        case .ephemeral:
            return "ephemeral"
        @unknown default:
            return "unknown"
        }
    }

    private func describe(_ trigger: UNNotificationTrigger?) -> String {
        guard let trigger else { return "no trigger" }
        if let trigger = trigger as? UNTimeIntervalNotificationTrigger {
            return "timeInterval=\(Int(trigger.timeInterval))s"
        }
        if let trigger = trigger as? UNCalendarNotificationTrigger,
           let nextDate = trigger.nextTriggerDate() {
            return "calendar=\(PostcardNotificationDiagnostics.describe(nextDate))"
        }
        return String(describing: type(of: trigger))
    }
}
#endif

private struct SettingsStrip: View {
    var iconName: String
    var title: String
    var detail: String

    var body: some View {
        HStack(spacing: 12) {
            ArtImage(name: iconName)
                .frame(width: 22, height: 22)
                .foregroundStyle(AppTheme.ink)
                .frame(width: 36, height: 36)
                .background(AppTheme.ivory)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(detail)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .paperCard(cornerRadius: 18, stroke: AppTheme.paperGray.opacity(0.8))
    }
}

private struct NotificationSettingsPage: View {
    @State private var wantsReturnReminder = true

    var body: some View {
        SettingsDetailScaffold(
            title: AppCopy.Settings.notificationTitle,
            imageName: "settings_notification_note",
            bodyText: AppCopy.Settings.notificationBody
        ) {
            Toggle(AppCopy.Settings.notificationToggle, isOn: $wantsReturnReminder)
                .font(AppTheme.body)
                .tint(AppTheme.deepSage)
                .padding(16)
                .paperCard(cornerRadius: 18)
        }
    }
}

private struct CollectionSettingsPage: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        SettingsDetailScaffold(
            title: AppCopy.Settings.collectionTitle,
            imageName: "settings_collection_empty",
            bodyText: collectionText
        ) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(environment.repository.postcards.filter(\.isRead)) { postcard in
                    HStack(spacing: 10) {
                        ArtImage(name: postcard.stampAssetName)
                            .frame(width: 36, height: 36)
                            .opacity(0.76)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(postcard.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                            Text("来自\(postcard.destination) · \(postcard.subtitle)")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.secondaryInk)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .paperCard(cornerRadius: 16)
                }
            }
        }
    }

    private var collectionText: String {
        let readCount = environment.repository.postcards.filter(\.isRead).count
        if readCount == 0 {
            return AppCopy.Settings.collectionEmpty
        }
        return AppCopy.Settings.collectionCount(readCount)
    }
}

private struct AboutSettingsPage: View {
    var body: some View {
        SettingsDetailScaffold(
            title: AppCopy.Settings.aboutTitle,
            imageName: "settings_about_cabin",
            bodyText: AppCopy.Settings.aboutBody
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppCopy.Settings.versionTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(AppCopy.Settings.versionBody)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .paperCard(cornerRadius: 18)
        }
    }
}

private struct SettingsDetailScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    var title: String
    var imageName: String
    var bodyText: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            PaperBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(title)
                            .font(AppTheme.pageTitle)
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                    }

                    ArtImage(name: imageName)
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)

                    Text(bodyText)
                        .font(AppTheme.body)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    content
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(AppEnvironment.preview())
}
