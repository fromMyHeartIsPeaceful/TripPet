import Foundation
import UserNotifications

enum AppTab: Hashable {
    case cabin
    case achievements
    case map
}

@MainActor
protocol PostcardNotificationServiceProtocol: AnyObject {
    var requestedTab: AppTab? { get set }
    var tabRequestHandler: ((AppTab) -> Void)? { get set }

    func requestAuthorization() async -> Bool
    func scheduleNewPostcardNotification(postcardId: String) async
    func scheduleNewPostcardNotification(postcardId: String, requiresCurrentAuthorization: Bool) async
}

@MainActor
final class DisabledPostcardNotificationService: PostcardNotificationServiceProtocol {
    var requestedTab: AppTab?
    var tabRequestHandler: ((AppTab) -> Void)?

    func requestAuthorization() async -> Bool {
        false
    }

    func scheduleNewPostcardNotification(postcardId: String) async {}
    func scheduleNewPostcardNotification(postcardId: String, requiresCurrentAuthorization: Bool) async {}
}

@MainActor
final class PostcardNotificationService: NSObject, ObservableObject, PostcardNotificationServiceProtocol {
    nonisolated static let newPostcardTitle = "邮箱收到1条新的明信片"
    private nonisolated static let targetKey = "target"
    private nonisolated static let mailboxTarget = "mailbox"
    private nonisolated static let postcardIdKey = "postcardId"

    @Published var requestedTab: AppTab?
    var tabRequestHandler: ((AppTab) -> Void)?

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleNewPostcardNotification(postcardId: String) async {
        await scheduleNewPostcardNotification(postcardId: postcardId, requiresCurrentAuthorization: true)
    }

    func scheduleNewPostcardNotification(
        postcardId: String,
        requiresCurrentAuthorization: Bool
    ) async {
        if requiresCurrentAuthorization {
            let settings = await center.notificationSettings()
            guard Self.canScheduleNotification(for: settings.authorizationStatus) else {
                return
            }
        }

        let content = UNMutableNotificationContent()
        content.title = Self.newPostcardTitle
        content.sound = .default
        content.userInfo = [
            Self.targetKey: Self.mailboxTarget,
            Self.postcardIdKey: postcardId
        ]

        let request = UNNotificationRequest(
            identifier: "postcard-new-\(postcardId)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try? await center.add(request)
    }

    nonisolated static func targetTab(from userInfo: [AnyHashable: Any]) -> AppTab? {
        guard userInfo[targetKey] as? String == mailboxTarget else {
            return nil
        }
        return .achievements
    }

    private nonisolated static func canScheduleNotification(for status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }
}

extension PostcardNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let tab = Self.targetTab(from: response.notification.request.content.userInfo) else {
            return
        }

        await MainActor.run {
            requestedTab = tab
            tabRequestHandler?(tab)
        }
    }
}
