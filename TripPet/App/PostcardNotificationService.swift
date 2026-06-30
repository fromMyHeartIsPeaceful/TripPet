import Foundation
import UserNotifications

enum AppTab: Hashable {
    case cabin
    case achievements
    case mailbox
    case map
}

struct NotificationRoute: Equatable {
    var tab: AppTab
    var postcardId: String?
    var actionIdentifier: String
    var receivedAt: Date
}

enum PostcardNotificationPayload {
    static let targetKey = "target"
    static let mailboxTarget = "mailbox"
    static let postcardIdKey = "postcardId"

    static func mailboxUserInfo(postcardId: String) -> [String: String] {
        [
            targetKey: mailboxTarget,
            postcardIdKey: postcardId
        ]
    }

    static func targetTab(from userInfo: [AnyHashable: Any]) -> AppTab? {
        guard userInfo[targetKey] as? String == mailboxTarget else {
            return nil
        }
        return .mailbox
    }

    static func route(
        from userInfo: [AnyHashable: Any],
        actionIdentifier: String,
        receivedAt: Date = Date()
    ) -> NotificationRoute? {
        guard actionIdentifier == UNNotificationDefaultActionIdentifier else {
            PostcardNotificationDiagnostics.record("route skipped action=\(actionIdentifier)")
            return nil
        }
        guard let tab = targetTab(from: userInfo) else {
            PostcardNotificationDiagnostics.record("route skipped unknown target")
            return nil
        }
        return NotificationRoute(
            tab: tab,
            postcardId: userInfo[postcardIdKey] as? String,
            actionIdentifier: actionIdentifier,
            receivedAt: receivedAt
        )
    }
}

@MainActor
final class NotificationRouteStore: ObservableObject {
    static let shared = NotificationRouteStore()

    @Published private(set) var pendingRoute: NotificationRoute?

    init() {}

    @discardableResult
    func enqueueNotificationResponse(
        userInfo: [AnyHashable: Any],
        actionIdentifier: String,
        receivedAt: Date = Date()
    ) -> Bool {
        guard let route = PostcardNotificationPayload.route(
            from: userInfo,
            actionIdentifier: actionIdentifier,
            receivedAt: receivedAt
        ) else {
            return false
        }
        enqueue(route)
        return true
    }

    func enqueue(_ route: NotificationRoute) {
        pendingRoute = route
        PostcardNotificationDiagnostics.record(
            "route queued tab=\(route.tab) postcardId=\(route.postcardId ?? "nil") action=\(route.actionIdentifier)"
        )
    }

    func consumeRoute() -> NotificationRoute? {
        let route = pendingRoute
        pendingRoute = nil
        if let route {
            PostcardNotificationDiagnostics.record(
                "route consumed tab=\(route.tab) postcardId=\(route.postcardId ?? "nil")"
            )
        }
        return route
    }

    func clear() {
        pendingRoute = nil
    }
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

    var requestedTab: AppTab?
    var tabRequestHandler: ((AppTab) -> Void)?

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
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
        content.userInfo = PostcardNotificationPayload.mailboxUserInfo(postcardId: postcardId)

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
        PostcardNotificationPayload.targetTab(from: userInfo)
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
