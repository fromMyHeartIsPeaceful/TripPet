import CoreText
import SwiftUI

@main
@MainActor
struct TripPetApp: App {
    @StateObject private var environment = AppEnvironment.live()
    @Environment(\.scenePhase) private var scenePhase

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
                    guard newPhase == .active else { return }
                    Task {
                        environment.revealEligiblePostcards()
                        await environment.refreshStepsIfPossible()
                        await environment.schedulePendingPostcardNotificationsForActiveTrips()
                        environment.startStepObservationIfPossible()
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
