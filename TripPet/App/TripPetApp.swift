import CoreText
import SwiftUI

@main
@MainActor
struct TripPetApp: App {
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
