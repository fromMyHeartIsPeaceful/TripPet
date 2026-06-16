import Combine
import Foundation

struct TicketGiftConfirmation: Identifiable, Equatable {
    let id = UUID()
    var animalOptions: [TicketGiftAnimalOption]
    var ticketCount: Int
    var steps: Int
    var isFirstImmediateTicket: Bool = false
}

struct TicketGiftAnimalOption: Identifiable, Equatable {
    var id: String { animalId }
    var animalId: String
    var animalName: String
    var assetName: String
    var destination: String
}

@MainActor
final class CabinViewModel: ObservableObject {
    @Published var stepStatusText = "Health 已连接"
    @Published var actionMessage = AppCopy.Cabin.defaultAction
    @Published var isWorking = false
    @Published var healthAuthorizationStatus: StepCountAuthorizationStatus = .sharingAuthorized
    @Published var pendingGiftConfirmation: TicketGiftConfirmation?
    @Published var lastGiftedTrip: Trip?

    private var environment: AppEnvironment?
    private var pendingSteps: Int?
    private var pendingTicketCount: Int?
    private var pendingIsFirstImmediateTicket = false

    var requiresHealthConnection: Bool {
        if isFirstImmediateTicketAvailable {
            return false
        }
        return healthAuthorizationStatus.canAttemptStepRead == false
    }

    var shouldShowStepCounter: Bool {
        isFirstImmediateTicketAvailable == false
    }

    var availableStepsForDisplay: Int {
        guard let environment else { return 0 }
        if isFirstImmediateTicketAvailable {
            return environment.ticketRuleEngine.requiredStepsPerTicket
        }
        return availableSteps(from: environment.effectiveTodaySteps)
    }

    var giftedStepsSummaryText: String? {
        guard let environment,
              environment.stepSnapshot.steps != nil else {
            return nil
        }

        let totalSteps = environment.effectiveTodaySteps
        let giftedSteps = environment.repository.stepFundedTicketCountToday(on: environment.currentDate) * environment.ticketRuleEngine.requiredStepsPerTicket
        guard giftedSteps > 0 else { return nil }

        return AppCopy.Cabin.giftedStepsSummary(
            totalSteps: totalSteps,
            giftedSteps: giftedSteps
        )
    }

    var canGiftAvailableSteps: Bool {
        guard let environment, requiresHealthConnection == false else { return false }
        if isFirstImmediateTicketAvailable {
            return true
        }
        let eligibility = environment.ticketRuleEngine.evaluate(
            todaySteps: environment.effectiveTodaySteps,
            giftedCountToday: environment.repository.giftedTicketCountToday(on: environment.currentDate),
            stepFundedTicketCountToday: environment.repository.stepFundedTicketCountToday(on: environment.currentDate)
        )
        return eligibility.isEligible
    }

    var isFirstImmediateTicketAvailable: Bool {
        guard let environment else { return false }
        return environment.repository.canUseFirstImmediateTicket() &&
            environment.repository.cabinAnimals.isEmpty == false
    }

    func bind(environment: AppEnvironment) {
        self.environment = environment
    }

    func refresh() async {
        guard let environment else { return }
        environment.repository.refreshCabinLodging(on: environment.currentDate)

        healthAuthorizationStatus = environment.stepSnapshot.status

        switch healthAuthorizationStatus {
        case .unavailable:
            stepStatusText = "Health 不可用"
            actionMessage = AppCopy.Cabin.healthUnavailable
        case .notDetermined:
            stepStatusText = "Health 未连接"
            actionMessage = AppCopy.Cabin.healthNotDetermined
        case .sharingDenied:
            stepStatusText = "Health 未连接"
            actionMessage = AppCopy.Cabin.healthDenied
        case .sharingAuthorized:
            stepStatusText = "Health 已连接"
        case .readPermissionRequested:
            stepStatusText = "Health 已请求"
            if shouldReplaceActionMessageWithHealthGuidance {
                if let steps = environment.stepSnapshot.steps {
                    actionMessage = AppCopy.Cabin.healthConnectedWithSteps(
                        steps,
                        requiredSteps: environment.ticketRuleEngine.requiredStepsPerTicket
                    )
                } else {
                    actionMessage = AppCopy.Cabin.healthReadPermissionRequested
                }
            }
        }

        if isFirstImmediateTicketAvailable {
            actionMessage = AppCopy.Cabin.firstTicketRuleHint
        } else if environment.repository.hasReachedDailyAnimalLimit {
            actionMessage = AppCopy.Cabin.dailyLimitReached
        } else if environment.repository.isCabinEmpty {
            actionMessage = AppCopy.Cabin.emptyCabinBody.isEmpty
                ? AppCopy.Cabin.emptyCabinTitle
                : "\(AppCopy.Cabin.emptyCabinTitle)\n\(AppCopy.Cabin.emptyCabinBody)"
        }
    }

    func connectHealth() async {
        guard let environment else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            let didRequest = try await environment.requestStepAuthorizationAndRefresh()
            if let steps = environment.stepSnapshot.steps {
                actionMessage = AppCopy.Cabin.healthConnectedWithSteps(
                    steps,
                    requiredSteps: environment.ticketRuleEngine.requiredStepsPerTicket
                )
            } else if didRequest == false {
                actionMessage = AppCopy.Health.requestUnchanged
            }
            await refresh()
        } catch {
            actionMessage = error.localizedDescription
            await refresh()
        }
    }

    func keepLookingAroundCabin() {
        actionMessage = AppCopy.Cabin.keepLooking
    }

    func prepareGiftConfirmation() async {
        guard let environment else { return }

        environment.repository.refreshCabinLodging(on: environment.currentDate)
        guard environment.repository.cabinAnimals.isEmpty == false else {
            await refresh()
            return
        }

        if environment.repository.canUseFirstImmediateTicket() {
            pendingSteps = 0
            pendingTicketCount = 1
            pendingIsFirstImmediateTicket = true
            pendingGiftConfirmation = TicketGiftConfirmation(
                animalOptions: giftAnimalOptions(from: environment),
                ticketCount: 1,
                steps: 0,
                isFirstImmediateTicket: true
            )
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let status = environment.stepSnapshot.status
            guard status.canAttemptStepRead else {
                isWorking = false
                await connectHealth()
                return
            }
            _ = try await environment.readTodaySteps()
            let steps = environment.effectiveTodaySteps
            let eligibility = environment.ticketRuleEngine.evaluate(
                todaySteps: steps,
                giftedCountToday: environment.repository.giftedTicketCountToday(on: environment.currentDate),
                stepFundedTicketCountToday: environment.repository.stepFundedTicketCountToday(on: environment.currentDate)
            )

            guard eligibility.isEligible else {
                actionMessage = eligibility.message
                await refresh()
                return
            }

            pendingSteps = steps
            pendingTicketCount = eligibility.ticketCount
            pendingIsFirstImmediateTicket = false
            pendingGiftConfirmation = TicketGiftConfirmation(
                animalOptions: giftAnimalOptions(from: environment),
                ticketCount: eligibility.ticketCount,
                steps: steps,
                isFirstImmediateTicket: false
            )
        } catch {
            actionMessage = AppCopy.Cabin.stepReadFailed
            await refresh()
        }
    }

    @discardableResult
    func confirmGiftTodaySteps(animalId: String? = nil) async -> Trip? {
        guard let environment,
              let steps = pendingSteps,
              let ticketCount = pendingTicketCount else {
            pendingGiftConfirmation = nil
            return nil
        }

        isWorking = true
        defer {
            pendingSteps = nil
            pendingTicketCount = nil
            pendingIsFirstImmediateTicket = false
            pendingGiftConfirmation = nil
            isWorking = false
        }

        if pendingIsFirstImmediateTicket == false {
            let eligibility = environment.ticketRuleEngine.evaluate(
                todaySteps: steps,
                giftedCountToday: environment.repository.giftedTicketCountToday(on: environment.currentDate),
                stepFundedTicketCountToday: environment.repository.stepFundedTicketCountToday(on: environment.currentDate)
            )

            guard eligibility.isEligible else {
                actionMessage = eligibility.message
                await refresh()
                return nil
            }
        } else if environment.repository.canUseFirstImmediateTicket() == false {
            await refresh()
            return nil
        }

        let trip = await environment.giftTicket(
            sourceSteps: steps,
            ticketCount: ticketCount,
            animalId: animalId,
            date: environment.currentDate,
            isFirstImmediateTicket: pendingIsFirstImmediateTicket
        )
        lastGiftedTrip = trip
        actionMessage = AppCopy.Cabin.gifted
        await environment.refreshStepsIfPossible()
        await refresh()
        return trip
    }

    func cancelGiftConfirmation() {
        pendingSteps = nil
        pendingTicketCount = nil
        pendingIsFirstImmediateTicket = false
        pendingGiftConfirmation = nil
    }

    private func availableSteps(from steps: Int) -> Int {
        guard let environment else { return 0 }
        return environment.ticketRuleEngine.remainingSteps(
            todaySteps: steps,
            giftedCountToday: environment.repository.stepFundedTicketCountToday(on: environment.currentDate)
        )
    }

    private func giftAnimalOptions(from environment: AppEnvironment) -> [TicketGiftAnimalOption] {
        environment.repository.cabinAnimals.map { animal in
            TicketGiftAnimalOption(
                animalId: animal.id,
                animalName: animal.name,
                assetName: animal.homeAssetName,
                destination: environment.repository.activeWish(for: animal.id)?.destination ?? "远方"
            )
        }
    }

    private var shouldReplaceActionMessageWithHealthGuidance: Bool {
        actionMessage == AppCopy.Cabin.defaultAction ||
            actionMessage == AppCopy.Cabin.healthUnavailable ||
            actionMessage == AppCopy.Cabin.healthNotDetermined ||
            actionMessage == AppCopy.Cabin.healthDenied ||
            actionMessage == AppCopy.Cabin.healthRequestFailed ||
            actionMessage == AppCopy.Cabin.healthReadPermissionRequested
    }
}
