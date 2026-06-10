import Combine
import Foundation

struct StepCountSnapshot: Equatable {
    var status: StepCountAuthorizationStatus
    var steps: Int?
    var readAt: Date?
    var errorMessage: String?
}

@MainActor
final class AppEnvironment: ObservableObject {
    let repository: AppRepository
    let stepCountProvider: StepCountProvider
    let ticketRuleEngine: TicketRuleEngine
    let animalVisitService: AnimalVisitService
    let postcardScheduler: PostcardScheduler
    let destinations: [ManifestDestination]
    let narrative: ManifestNarrative?
    @Published private(set) var stepSnapshot: StepCountSnapshot
    @Published private(set) var testingTimeOffset: TimeInterval = 0
    private var cancellables: Set<AnyCancellable> = []
    private var isRefreshingSteps = false
    private var isObservingStepChanges = false

    init(
        repository: AppRepository,
        stepCountProvider: StepCountProvider,
        ticketRuleEngine: TicketRuleEngine,
        animalVisitService: AnimalVisitService,
        postcardScheduler: PostcardScheduler,
        destinations: [ManifestDestination],
        narrative: ManifestNarrative? = nil
    ) {
        self.repository = repository
        self.stepCountProvider = stepCountProvider
        self.ticketRuleEngine = ticketRuleEngine
        self.animalVisitService = animalVisitService
        self.postcardScheduler = postcardScheduler
        self.destinations = destinations
        self.narrative = narrative
        self.stepSnapshot = StepCountSnapshot(
            status: stepCountProvider.authorizationStatus(),
            steps: nil,
            readAt: nil,
            errorMessage: nil
        )

        repository.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    static func live() -> AppEnvironment {
        let seed = ContentManifestLoader.loadSeedData()
        let store: AppUserStateStore
        if let swiftDataStore = try? SwiftDataUserStateStore() {
            store = swiftDataStore
        } else {
            store = InMemoryUserStateStore()
        }
        let repository = AppRepository(seed: seed, store: store)
        return AppEnvironment(
            repository: repository,
            stepCountProvider: HealthKitStepCountProvider(),
            ticketRuleEngine: ContentManifestLoader.loadTicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations.isEmpty ? ContentManifestLoader.loadDestinations() : seed.destinations,
            narrative: ContentManifestLoader.loadNarrative()
        )
    }

    static func preview(
        seed: SeedData = .preview,
        flags: AppUserFlags = AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true),
        stepStatus: StepCountAuthorizationStatus = .sharingAuthorized,
        steps: Int = 4_200,
        throwsOnStepRead: Bool = false
    ) -> AppEnvironment {
        let state = AppUserState(seed: seed, flags: flags)
        let repository = AppRepository(seed: seed, store: InMemoryUserStateStore(savedState: state))
        return AppEnvironment(
            repository: repository,
            stepCountProvider: FakeStepCountProvider(
                status: stepStatus,
                steps: steps,
                throwsOnStepRead: throwsOnStepRead
            ),
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations.isEmpty ? ContentManifestLoader.loadDestinations() : seed.destinations,
            narrative: ContentManifestLoader.loadNarrative()
        )
    }

    func destination(for trip: Trip) -> ManifestDestination? {
        destinations.first { $0.id == trip.destinationId || $0.displayName == trip.destination }
    }

    var currentDate: Date {
        Date().addingTimeInterval(testingTimeOffset)
    }

    @discardableResult
    func requestStepAuthorizationAndRefresh() async throws -> Bool {
        let didRequest = try await stepCountProvider.requestAuthorization()
        updateStepStatus()

        if didRequest, stepSnapshot.status.canAttemptStepRead {
            do {
                _ = try await readTodaySteps()
            } catch {
                stepSnapshot = StepCountSnapshot(
                    status: stepCountProvider.authorizationStatus(),
                    steps: stepSnapshot.steps,
                    readAt: stepSnapshot.readAt,
                    errorMessage: error.localizedDescription
                )
            }
        }

        return didRequest
    }

    func refreshStepsIfPossible() async {
        repository.refreshCabinLodging(on: currentDate)
        updateStepStatus()
        guard stepSnapshot.status.canAttemptStepRead else { return }
        guard isRefreshingSteps == false else { return }

        do {
            _ = try await readTodaySteps()
        } catch {
            stepSnapshot = StepCountSnapshot(
                status: stepCountProvider.authorizationStatus(),
                steps: stepSnapshot.steps,
                readAt: stepSnapshot.readAt,
                errorMessage: error.localizedDescription
            )
        }
    }

    @discardableResult
    func readTodaySteps() async throws -> Int {
        guard isRefreshingSteps == false else {
            return stepSnapshot.steps ?? 0
        }

        isRefreshingSteps = true
        defer { isRefreshingSteps = false }

        let providerSteps = try await stepCountProvider.todayStepCount()
        let steps = providerSteps
        stepSnapshot = StepCountSnapshot(
            status: stepCountProvider.authorizationStatus(),
            steps: steps,
            readAt: Date(),
            errorMessage: nil
        )
        startStepObservationIfPossible()
        return steps
    }

    func startStepObservationIfPossible() {
        updateStepStatus()
        guard stepSnapshot.status.canAttemptStepRead, isObservingStepChanges == false else { return }

        do {
            try stepCountProvider.startObservingStepChanges { [weak self] in
                await self?.refreshStepsIfPossible()
            }
            isObservingStepChanges = true
        } catch {
            stepSnapshot = StepCountSnapshot(
                status: stepSnapshot.status,
                steps: stepSnapshot.steps,
                readAt: stepSnapshot.readAt,
                errorMessage: error.localizedDescription
            )
        }
    }

    private func updateStepStatus() {
        let status = stepCountProvider.authorizationStatus()
        guard status != stepSnapshot.status else { return }
        stepSnapshot = StepCountSnapshot(
            status: status,
            steps: stepSnapshot.steps,
            readAt: stepSnapshot.readAt,
            errorMessage: stepSnapshot.errorMessage
        )
    }

    @discardableResult
    func revealEligiblePostcards(on date: Date? = nil) -> Bool {
        repository.revealEligiblePostcards(
            scheduler: postcardScheduler,
            destinations: destinations,
            narrative: narrative,
            on: date ?? currentDate
        )
    }

    func advanceTestingTime(by interval: TimeInterval) {
        testingTimeOffset += interval
        repository.refreshCabinLodging(on: currentDate)
        revealEligiblePostcards(on: currentDate)
    }
}
