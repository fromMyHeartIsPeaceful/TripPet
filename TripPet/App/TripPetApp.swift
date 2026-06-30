import CoreText
import SwiftUI
import UIKit
import UserNotifications

@main
@MainActor
struct TripPetApp: App {
    @UIApplicationDelegateAdaptor(TripPetAppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.live()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didEnterBackground = false

    init() {
        BundledFontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(environment)
                .task {
                    environment.revealEligiblePostcards()
                    await environment.refreshStepsIfPossible()
                    await environment.schedulePendingPostcardNotificationsForActiveTrips()
                    environment.startStepObservationIfPossible()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        didEnterBackground = true
                    case .active:
                        guard didEnterBackground else { return }
                        didEnterBackground = false
                        Task {
                            environment.revealEligiblePostcards()
                            await environment.refreshStepsIfPossible()
                            await environment.schedulePendingPostcardNotificationsForActiveTrips()
                            environment.startStepObservationIfPossible()
                        }
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
}

final class TripPetAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        PostcardNotificationDiagnostics.record("delegate registered willFinishLaunching")
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        []
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        PostcardNotificationDiagnostics.record("didReceive response action=\(response.actionIdentifier)")
        await MainActor.run {
            _ = NotificationRouteStore.shared.enqueueNotificationResponse(
                userInfo: response.notification.request.content.userInfo,
                actionIdentifier: response.actionIdentifier
            )
        }
    }
}

private enum BundledFontRegistrar {
    static func registerFonts() {
        registerFont(named: "LXGWWenKaiScreen", extension: "ttf")
    }

    private static func registerFont(named name: String, extension fileExtension: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
