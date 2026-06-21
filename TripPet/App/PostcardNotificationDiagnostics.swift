import Foundation

enum PostcardNotificationDiagnostics {
    private static let storeKey = "PostcardNotificationDiagnostics.events"
    private static let maxEvents = 120

    static func record(_ message: @autoclosure () -> String) {
        #if DEBUG
        let line = "\(timestamp()) \(message())"
        print("[PostcardNotification] \(line)")

        var events = UserDefaults.standard.stringArray(forKey: storeKey) ?? []
        events.insert(line, at: 0)
        if events.count > maxEvents {
            events.removeSubrange(maxEvents..<events.count)
        }
        UserDefaults.standard.set(events, forKey: storeKey)
        #endif
    }

    static var recentEvents: [String] {
        #if DEBUG
        UserDefaults.standard.stringArray(forKey: storeKey) ?? []
        #else
        []
        #endif
    }

    static func clear() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: storeKey)
        #endif
    }

    static func describe(_ date: Date?) -> String {
        guard let date else { return "nil" }
        return ISO8601DateFormatter().string(from: date)
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
