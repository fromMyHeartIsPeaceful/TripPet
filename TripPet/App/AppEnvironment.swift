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
    let notificationRouteStore: NotificationRouteStore
    let destinations: [ManifestDestination]
    @Published private(set) var stepSnapshot: StepCountSnapshot
    @Published private(set) var notificationRequestedTab: AppTab?
    private var cancellables: Set<AnyCancellable> = []
    private var notifiedPostcardIds: Set<String> = []
    private var didRequestPostcardReturnNotificationAuthorization = false
    private var stepReadTask: Task<Int, Error>?
    private var isObservingStepChanges = false

    init(
        repository: AppRepository,
        stepCountProvider: StepCountProvider,
        ticketRuleEngine: TicketRuleEngine,
        animalVisitService: AnimalVisitService,
        postcardScheduler: PostcardScheduler,
        postcardNotificationService: PostcardNotificationServiceProtocol? = nil,
        notificationRouteStore: NotificationRouteStore? = nil,
        destinations: [ManifestDestination]
    ) {
        self.repository = repository
        self.stepCountProvider = stepCountProvider
        self.ticketRuleEngine = ticketRuleEngine
        self.animalVisitService = animalVisitService
        self.postcardScheduler = postcardScheduler
        self.postcardNotificationService = postcardNotificationService ?? DisabledPostcardNotificationService()
        self.notificationRouteStore = notificationRouteStore ?? .shared
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
            self?.queueNotificationTabRequest(tab)
        }

        self.notificationRouteStore.$pendingRoute
            .sink { [weak self] route in
                guard let route else { return }
                self?.queueNotificationRoute(route)
            }
            .store(in: &cancellables)

        queuePendingNotificationRouteIfNeeded()
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
            notificationRouteStore: .shared,
            destinations: seed.destinations.isEmpty ? ContentManifestLoader.loadDestinations() : seed.destinations
        )
    }

    static func preview(
        seed: SeedData = .preview,
        flags: AppUserFlags = AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true),
        stepStatus: StepCountAuthorizationStatus = .sharingAuthorized,
        steps: Int = 4_200,
        postcardNotificationService: PostcardNotificationServiceProtocol? = nil,
        notificationRouteStore: NotificationRouteStore? = nil
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
            notificationRouteStore: notificationRouteStore ?? NotificationRouteStore(),
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
        healthDebugLog("requestStepAuthorizationAndRefresh begin status=\(stepSnapshot.status) steps=\(String(describing: stepSnapshot.steps))")
        let didRequest = try await stepCountProvider.requestAuthorization()
        updateStepStatus()
        healthDebugLog("requestStepAuthorizationAndRefresh didRequest=\(didRequest) status=\(stepSnapshot.status)")

        if stepSnapshot.status.canAttemptStepRead {
            do {
                _ = try await readTodaySteps()
            } catch {
                healthDebugLog("requestStepAuthorizationAndRefresh first read failed=\(error.localizedDescription)")
                try? await Task.sleep(nanoseconds: 750_000_000)
                do {
                    _ = try await readTodaySteps()
                } catch {
                    healthDebugLog("requestStepAuthorizationAndRefresh second read failed=\(error.localizedDescription)")
                    stepSnapshot = StepCountSnapshot(
                        status: stepCountProvider.authorizationStatus(),
                        steps: stepSnapshot.steps,
                        readAt: stepSnapshot.readAt,
                        errorMessage: error.localizedDescription
                    )
                }
            }
        }

        return didRequest
    }

    @discardableResult
    func requestStepAuthorizationOnly() async throws -> Bool {
        let didRequest = try await stepCountProvider.requestAuthorization()
        updateStepStatus()
        return didRequest
    }

    func refreshStepsIfPossible() async {
        repository.refreshCabinLodging(on: currentDate)
        updateStepStatus()
        healthDebugLog("refreshStepsIfPossible status=\(stepSnapshot.status) steps=\(String(describing: stepSnapshot.steps))")
        guard stepSnapshot.status.canAttemptStepRead else { return }

        do {
            _ = try await readTodaySteps()
        } catch {
            healthDebugLog("refreshStepsIfPossible failed=\(error.localizedDescription)")
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
        if let stepReadTask {
            healthDebugLog("readTodaySteps reuse in-flight task")
            return try await stepReadTask.value
        }

        healthDebugLog("readTodaySteps begin status=\(stepSnapshot.status)")
        let task = Task { @MainActor [weak self] in
            guard let self else { throw CancellationError() }
            return try await self.stepCountProvider.todayStepCount()
        }
        stepReadTask = task

        defer {
            stepReadTask = nil
        }

        let providerSteps = try await task.value
        let steps = providerSteps
        stepSnapshot = StepCountSnapshot(
            status: stepCountProvider.authorizationStatus(),
            steps: steps,
            readAt: currentDate,
            errorMessage: nil
        )
        healthDebugLog("readTodaySteps success steps=\(steps) status=\(stepSnapshot.status)")
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
        let trip = repository.giftTicket(
            sourceSteps: sourceSteps,
            ticketCount: ticketCount,
            animalId: animalId,
            date: date ?? currentDate,
            isFirstImmediateTicket: isFirstImmediateTicket
        )

        guard let trip else { return nil }
        PostcardNotificationDiagnostics.record(
            "gift created trip=\(trip.id) animal=\(trip.animalId) plan=\(trip.postcardPlan.map { "\($0.sequence):\(PostcardNotificationDiagnostics.describe($0.dueAt))" }.joined(separator: ","))"
        )

        let newPostcards = newUnreadPostcards(since: knownPostcardIds)
        if isFirstImmediateTicket == false {
            notifyNewPostcardsLater(newPostcards)
        }
        await schedulePendingPostcardNotifications(for: [trip])

        return trip
    }

    @discardableResult
    func revealEligiblePostcards(on date: Date? = nil) -> Bool {
        let didReveal = repository.revealEligiblePostcards(
            scheduler: postcardScheduler,
            destinations: destinations,
            on: date ?? currentDate
        )

        return didReveal
    }

    func clearNotificationTabRequest() {
        notificationRequestedTab = nil
        postcardNotificationService.requestedTab = nil
        notificationRouteStore.clear()
    }

    func queueNotificationTabRequest(_ tab: AppTab) {
        notificationRequestedTab = tab
        postcardNotificationService.requestedTab = tab
    }

    func queueNotificationRoute(_ route: NotificationRoute) {
        queueNotificationTabRequest(route.tab)
    }

    func queuePendingNotificationRouteIfNeeded() {
        guard let route = notificationRouteStore.pendingRoute else { return }
        queueNotificationRoute(route)
    }

    func consumeNotificationTabRequest() -> AppTab? {
        let requestedTab = notificationRequestedTab ??
            postcardNotificationService.requestedTab ??
            notificationRouteStore.pendingRoute?.tab
        guard requestedTab != nil else { return nil }
        notificationRequestedTab = nil
        postcardNotificationService.requestedTab = nil
        notificationRouteStore.clear()
        return requestedTab
    }

    func requestNotificationAuthorizationOnPostcardReturn(_ postcard: Postcard) async {
        guard didRequestPostcardReturnNotificationAuthorization == false else { return }
        didRequestPostcardReturnNotificationAuthorization = true
        notifiedPostcardIds.insert(postcard.id)
        PostcardNotificationDiagnostics.record("authorization entry postcardId=\(postcard.id)")
        let isAuthorized = await postcardNotificationService.requestAuthorization()
        PostcardNotificationDiagnostics.record("authorization entry result=\(isAuthorized)")
        if isAuthorized {
            await schedulePendingPostcardNotificationsForActiveTrips()
        }
    }

    func schedulePendingPostcardNotificationsForActiveTrips() async {
        PostcardNotificationDiagnostics.record("schedule active trips count=\(repository.activeTravelTrips.count)")
        await schedulePendingPostcardNotifications(for: repository.activeTravelTrips)
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
            await notifyNewPostcards(postcards)
        }
    }

    private func notifyNewPostcards(_ postcards: [Postcard]) async {
        let postcardsToNotify = postcards.filter { notifiedPostcardIds.contains($0.id) == false }
        guard postcardsToNotify.isEmpty == false else { return }

        for postcard in postcardsToNotify {
            let didSchedule = await postcardNotificationService.scheduleNewPostcardNotification(
                postcardId: postcard.id,
                requiresCurrentAuthorization: true
            )
            if didSchedule {
                notifiedPostcardIds.insert(postcard.id)
            }
        }
    }

    private func schedulePendingPostcardNotifications(for trips: [Trip]) async {
        let now = currentDate
        for trip in trips where trip.status == .traveling || trip.status == .preparing {
            for planItem in trip.postcardPlan where planItem.revealedAt == nil {
                let postcardId = "postcard_\(trip.id)_\(planItem.sequence)"
                let isAlreadyNotified = notifiedPostcardIds.contains(postcardId)
                let alreadyExists = repository.postcards.contains { $0.id == postcardId }
                let isFuture = planItem.dueAt > now

                guard isAlreadyNotified == false,
                      alreadyExists == false,
                      isFuture else {
                    PostcardNotificationDiagnostics.record(
                        "schedule skipped postcardId=\(postcardId) alreadyNotified=\(isAlreadyNotified) exists=\(alreadyExists) future=\(isFuture) dueAt=\(PostcardNotificationDiagnostics.describe(planItem.dueAt)) now=\(PostcardNotificationDiagnostics.describe(now))"
                    )
                    continue
                }

                let didSchedule = await postcardNotificationService.scheduleNewPostcardNotification(
                    postcardId: postcardId,
                    deliveryDate: planItem.dueAt,
                    requiresCurrentAuthorization: true
                )
                if didSchedule {
                    notifiedPostcardIds.insert(postcardId)
                }
            }
        }
    }
}
