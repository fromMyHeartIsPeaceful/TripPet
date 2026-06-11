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
    @Published private(set) var stepSnapshot: StepCountSnapshot
    #if DEBUG
    @Published private var debugStepBonusByDay: [Date: Int] = [:]
    @Published private(set) var debugTimeOffset: TimeInterval = 0
    #endif
    private var cancellables: Set<AnyCancellable> = []
    private var isRefreshingSteps = false
    private var isObservingStepChanges = false

    init(
        repository: AppRepository,
        stepCountProvider: StepCountProvider,
        ticketRuleEngine: TicketRuleEngine,
        animalVisitService: AnimalVisitService,
        postcardScheduler: PostcardScheduler,
        destinations: [ManifestDestination]
    ) {
        self.repository = repository
        self.stepCountProvider = stepCountProvider
        self.ticketRuleEngine = ticketRuleEngine
        self.animalVisitService = animalVisitService
        self.postcardScheduler = postcardScheduler
        self.destinations = destinations
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
            destinations: seed.destinations.isEmpty ? ContentManifestLoader.loadDestinations() : seed.destinations
        )
    }

    static func preview(
        seed: SeedData = .preview,
        flags: AppUserFlags = AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true),
        stepStatus: StepCountAuthorizationStatus = .sharingAuthorized,
        steps: Int = 4_200
    ) -> AppEnvironment {
        let state = AppUserState(seed: seed, flags: flags)
        let repository = AppRepository(seed: seed, store: InMemoryUserStateStore(savedState: state))
        return AppEnvironment(
            repository: repository,
            stepCountProvider: FakeStepCountProvider(status: stepStatus, steps: steps),
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations.isEmpty ? ContentManifestLoader.loadDestinations() : seed.destinations
        )
    }

    func destination(for trip: Trip) -> ManifestDestination? {
        destinations.first { $0.id == trip.destinationId || $0.displayName == trip.destination }
    }

    var currentDate: Date {
        #if DEBUG
        Date().addingTimeInterval(debugTimeOffset)
        #else
        Date()
        #endif
    }

    var effectiveTodaySteps: Int {
        let providerSteps = stepSnapshot.steps ?? 0
        #if DEBUG
        return providerSteps + debugStepBonus
        #else
        return providerSteps
        #endif
    }

    var usesDebugStepOverride: Bool {
        #if DEBUG
        debugStepBonus > 0
        #else
        false
        #endif
    }

    #if DEBUG
    var debugStepBonus: Int {
        debugStepBonusByDay[debugCurrentDay, default: 0]
    }

    var debugCurrentDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: currentDate)
    }

    func debugAddSteps(_ amount: Int = 1_000) {
        debugStepBonusByDay[debugCurrentDay, default: 0] += max(0, amount)
    }

    func debugAdvanceHours(_ hours: Int = 6) {
        let advancedDate = Calendar.current.date(
            byAdding: .hour,
            value: hours,
            to: currentDate
        ) ?? currentDate.addingTimeInterval(TimeInterval(hours * 3_600))
        debugTimeOffset = advancedDate.timeIntervalSince(Date())
        repository.refreshCabinLodging(on: currentDate)
        _ = revealEligiblePostcards()
    }

    private var debugCurrentDay: Date {
        Calendar.current.startOfDay(for: currentDate)
    }
    #endif

    @discardableResult
    func requestStepAuthorizationAndRefresh() async throws -> Bool {
        let didRequest = try await stepCountProvider.requestAuthorization()
        updateStepStatus()

        if didRequest, stepSnapshot.status.canAttemptStepRead {
            _ = try await readTodaySteps()
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
            readAt: currentDate,
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
            on: date ?? currentDate
        )
    }
}
