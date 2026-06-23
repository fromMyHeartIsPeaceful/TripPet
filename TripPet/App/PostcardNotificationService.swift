import Foundation
import UserNotifications

enum AppTab: Hashable {
    case cabin
    case mailbox
    case map
}

@MainActor
protocol PostcardNotificationServiceProtocol: AnyObject {
    var requestedTab: AppTab? { get set }
    var tabRequestHandler: ((AppTab) -> Void)? { get set }

    func requestAuthorization() async -> Bool
    func scheduleNewPostcardNotification(postcardId: String) async -> Bool
    func scheduleNewPostcardNotification(postcardId: String, requiresCurrentAuthorization: Bool) async -> Bool
    func scheduleNewPostcardNotification(
        postcardId: String,
        deliveryDate: Date?,
        requiresCurrentAuthorization: Bool
    ) async -> Bool
}

@MainActor
final class DisabledPostcardNotificationService: PostcardNotificationServiceProtocol {
    var requestedTab: AppTab?
    var tabRequestHandler: ((AppTab) -> Void)?

    func requestAuthorization() async -> Bool {
        false
    }

    func scheduleNewPostcardNotification(postcardId: String) async -> Bool { false }
    func scheduleNewPostcardNotification(postcardId: String, requiresCurrentAuthorization: Bool) async -> Bool { false }
    func scheduleNewPostcardNotification(
        postcardId: String,
        deliveryDate: Date?,
        requiresCurrentAuthorization: Bool
    ) async -> Bool { false }
}

@MainActor
final class PostcardNotificationService: NSObject, ObservableObject, PostcardNotificationServiceProtocol {
    nonisolated static let newPostcardTitle = "邮箱收到1条新的明信片"
    private nonisolated static let targetKey = "target"
    private nonisolated static let mailboxTarget = "mailbox"
    private nonisolated static let postcardIdKey = "postcardId"

    var requestedTab: AppTab?
    var tabRequestHandler: ((AppTab) -> Void)?

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        PostcardNotificationDiagnostics.record("request authorization")
        do {
            let isGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            PostcardNotificationDiagnostics.record("authorization result granted=\(isGranted)")
            return isGranted
        } catch {
            PostcardNotificationDiagnostics.record("authorization error=\(error.localizedDescription)")
            return false
        }
    }

    func scheduleNewPostcardNotification(postcardId: String) async -> Bool {
        await scheduleNewPostcardNotification(postcardId: postcardId, requiresCurrentAuthorization: true)
    }

    func scheduleNewPostcardNotification(
        postcardId: String,
        requiresCurrentAuthorization: Bool
    ) async -> Bool {
        await scheduleNewPostcardNotification(
            postcardId: postcardId,
            deliveryDate: nil,
            requiresCurrentAuthorization: requiresCurrentAuthorization
        )
    }

    func scheduleNewPostcardNotification(
        postcardId: String,
        deliveryDate: Date?,
        requiresCurrentAuthorization: Bool
    ) async -> Bool {
        PostcardNotificationDiagnostics.record(
            "schedule request postcardId=\(postcardId) deliveryDate=\(PostcardNotificationDiagnostics.describe(deliveryDate)) requiresAuth=\(requiresCurrentAuthorization)"
        )

        if let deliveryDate, deliveryDate <= Date() {
            PostcardNotificationDiagnostics.record("schedule skipped past deliveryDate postcardId=\(postcardId)")
            return false
        }

        if requiresCurrentAuthorization {
            let settings = await center.notificationSettings()
            PostcardNotificationDiagnostics.record(
                "notification settings status=\(Self.describe(settings.authorizationStatus)) alert=\(settings.alertSetting.rawValue) sound=\(settings.soundSetting.rawValue) badge=\(settings.badgeSetting.rawValue)"
            )
            guard Self.canScheduleNotification(for: settings.authorizationStatus) else {
                PostcardNotificationDiagnostics.record("schedule skipped unauthorized postcardId=\(postcardId)")
                return false
            }
        }

        let content = UNMutableNotificationContent()
        content.title = Self.newPostcardTitle
        content.sound = .default
        content.userInfo = [
            Self.targetKey: Self.mailboxTarget,
            Self.postcardIdKey: postcardId
        ]

        let timeInterval = max(1, deliveryDate?.timeIntervalSinceNow ?? 1)
        let request = UNNotificationRequest(
            identifier: "postcard-new-\(postcardId)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        )
        center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
        do {
            try await center.add(request)
            let pendingCount = await center.pendingNotificationRequests().count
            PostcardNotificationDiagnostics.record(
                "schedule added identifier=\(request.identifier) timeInterval=\(timeInterval) pendingCount=\(pendingCount)"
            )
            return true
        } catch {
            PostcardNotificationDiagnostics.record(
                "schedule add error identifier=\(request.identifier) error=\(error.localizedDescription)"
            )
            return false
        }
    }

    nonisolated static func targetTab(from userInfo: [AnyHashable: Any]) -> AppTab? {
        guard userInfo[targetKey] as? String == mailboxTarget else {
            return nil
        }
        return .mailbox
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

    private nonisolated static func describe(_ status: UNAuthorizationStatus) -> String {
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
}

extension PostcardNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        []
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        PostcardNotificationDiagnostics.record("didReceive response action=\(response.actionIdentifier)")
        guard let tab = Self.targetTab(from: response.notification.request.content.userInfo) else {
            PostcardNotificationDiagnostics.record("didReceive skipped unknown target")
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            PostcardNotificationDiagnostics.record("didReceive route tab=\(tab)")
            requestedTab = tab
            tabRequestHandler?(tab)
        }
    }
}
