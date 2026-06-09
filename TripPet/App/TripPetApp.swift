import SwiftUI

@main
@MainActor
struct TripPetApp: App {
    @StateObject private var environment = AppEnvironment.live()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(environment)
                .task {
                    await environment.refreshStepsIfPossible()
                    environment.startStepObservationIfPossible()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await environment.refreshStepsIfPossible()
                        environment.startStepObservationIfPossible()
                    }
                }
        }
    }
}
