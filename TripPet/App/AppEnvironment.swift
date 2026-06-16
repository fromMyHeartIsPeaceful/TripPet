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
    let postcardNotificationService: PostcardNotificationServiceProtocol
    let destinations: [ManifestDestination]
    @Published private(set) var stepSnapshot: StepCountSnapshot
    @Published private(set) var notificationRequestedTab: AppTab?
    private var cancellables: Set<AnyCancellable> = []
    private var notifiedPostcardIds: Set<String> = []
    private var authorizationPendingPostcards: [Postcard] = []
    private var didRequestPostcardReturnNotificationAuthorization = false
    private var isRefreshingSteps = false
    private var isObservingStepChanges = false

    init(
        repository: AppRepository,
        stepCountProvider: StepCountProvider,
        ticketRuleEngine: TicketRuleEngine,
        animalVisitService: AnimalVisitService,
        postcardScheduler: PostcardScheduler,
        postcardNotificationService: PostcardNotificationServiceProtocol? = nil,
        destinations: [ManifestDestination]
    ) {
        self.repository = repository
        self.stepCountProvider = stepCountProvider
        self.ticketRuleEngine = ticketRuleEngine
        self.animalVisitService = animalVisitService
        self.postcardScheduler = postcardScheduler
        self.postcardNotificationService = postcardNotificationService ?? DisabledPostcardNotificationService()
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

        self.postcardNotificationService.tabRequestHandler = { [weak self] tab in
            self?.notificationRequestedTab = tab
        }
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
            postcardNotificationService: PostcardNotificationService(),
            destinations: seed.destinations.isEmpty ? ContentManifestLoader.loadDestinations() : seed.destinations
        )
    }

    static func preview(
        seed: SeedData = .preview,
        flags: AppUserFlags = AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true),
        stepStatus: StepCountAuthorizationStatus = .sharingAuthorized,
        steps: Int = 4_200,
        postcardNotificationService: PostcardNotificationServiceProtocol? = nil
    ) -> AppEnvironment {
        let state = AppUserState(seed: seed, flags: flags)
        let repository = AppRepository(seed: seed, store: InMemoryUserStateStore(savedState: state))
        return AppEnvironment(
            repository: repository,
            stepCountProvider: FakeStepCountProvider(status: stepStatus, steps: steps),
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            postcardNotificationService: postcardNotificationService,
            destinations: seed.destinations.isEmpty ? ContentManifestLoader.loadDestinations() : seed.destinations
        )
    }

    func destination(for trip: Trip) -> ManifestDestination? {
        destinations.first { $0.id == trip.destinationId || $0.displayName == trip.destination }
    }

    var currentDate: Date {
        Date()
    }

    var effectiveTodaySteps: Int {
        stepSnapshot.steps ?? 0
    }

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
    func giftTicket(
        sourceSteps: Int,
        ticketCount: Int,
        animalId: String? = nil,
        date: Date? = nil,
        isFirstImmediateTicket: Bool = false
    ) async -> Trip? {
        let knownPostcardIds = currentPostcardIds
        let shouldDeferFirstPostcardNotification = isFirstImmediateTicket &&
            repository.canUseFirstImmediateTicket()

        let trip = repository.giftTicket(
            sourceSteps: sourceSteps,
            ticketCount: ticketCount,
            animalId: animalId,
            date: date ?? currentDate,
            isFirstImmediateTicket: isFirstImmediateTicket
        )

        guard trip != nil else { return nil }

        let newPostcards = newUnreadPostcards(since: knownPostcardIds)
        if shouldDeferFirstPostcardNotification {
            authorizationPendingPostcards.append(contentsOf: newPostcards)
        } else {
            notifyNewPostcardsLater(newPostcards)
        }

        return trip
    }

    func requestAuthorizationAndNotifyPendingPostcards() async {
        let pendingPostcards = authorizationPendingPostcards
        authorizationPendingPostcards.removeAll()
        await notifyNewPostcards(
            pendingPostcards,
            shouldRequestAuthorization: true
        )
    }

    @discardableResult
    func revealEligiblePostcards(on date: Date? = nil) -> Bool {
        let knownPostcardIds = currentPostcardIds
        let didReveal = repository.revealEligiblePostcards(
            scheduler: postcardScheduler,
            destinations: destinations,
            on: date ?? currentDate
        )

        let newPostcards = newUnreadPostcards(since: knownPostcardIds)
        notifyNewPostcardsLater(newPostcards)
        return didReveal
    }

    func clearNotificationTabRequest() {
        notificationRequestedTab = nil
        postcardNotificationService.requestedTab = nil
    }

    func requestNotificationAuthorizationOnPostcardReturn(_ postcard: Postcard) async {
        guard didRequestPostcardReturnNotificationAuthorization == false else { return }
        didRequestPostcardReturnNotificationAuthorization = true
        authorizationPendingPostcards.removeAll { $0.id == postcard.id }
        _ = await postcardNotificationService.requestAuthorization()
    }

    private var currentPostcardIds: Set<String> {
        Set(repository.postcards.map(\.id))
    }

    private func newUnreadPostcards(since knownPostcardIds: Set<String>) -> [Postcard] {
        repository.postcards.filter { postcard in
            knownPostcardIds.contains(postcard.id) == false &&
                postcard.isRead == false
        }
    }

    private func notifyNewPostcardsLater(_ postcards: [Postcard]) {
        guard postcards.isEmpty == false else { return }
        Task {
            await notifyNewPostcards(postcards, shouldRequestAuthorization: false)
        }
    }

    private func notifyNewPostcards(
        _ postcards: [Postcard],
        shouldRequestAuthorization: Bool
    ) async {
        let postcardsToNotify = postcards.filter { notifiedPostcardIds.contains($0.id) == false }
        guard postcardsToNotify.isEmpty == false else { return }

        if shouldRequestAuthorization {
            let granted = await postcardNotificationService.requestAuthorization()
            guard granted else { return }
        }

        for postcard in postcardsToNotify {
            notifiedPostcardIds.insert(postcard.id)
            await postcardNotificationService.scheduleNewPostcardNotification(
                postcardId: postcard.id,
                requiresCurrentAuthorization: shouldRequestAuthorization == false
            )
        }
    }
}
