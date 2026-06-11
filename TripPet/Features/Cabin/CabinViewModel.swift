import Combine
import Foundation

struct TicketGiftConfirmation: Identifiable, Equatable {
    let id = UUID()
    var animalName: String
    var destination: String
    var ticketCount: Int
    var steps: Int
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

    var requiresHealthConnection: Bool {
        healthAuthorizationStatus.canAttemptStepRead == false
    }

    var availableStepsForDisplay: Int {
        guard let environment else { return 0 }
        return availableSteps(from: environment.stepSnapshot.steps ?? 0)
    }

    var giftedStepsSummaryText: String? {
        guard let environment,
              let totalSteps = environment.stepSnapshot.steps else {
            return nil
        }

        let giftedSteps = environment.repository.giftedTicketCountToday() * environment.ticketRuleEngine.requiredStepsPerTicket
        guard giftedSteps > 0 else { return nil }

        return AppCopy.Cabin.giftedStepsSummary(
            totalSteps: totalSteps,
            giftedSteps: giftedSteps
        )
    }

    var canGiftAvailableSteps: Bool {
        guard let environment, requiresHealthConnection == false else { return false }
        let eligibility = environment.ticketRuleEngine.evaluate(
            todaySteps: environment.stepSnapshot.steps ?? 0,
            giftedCountToday: environment.repository.giftedTicketCountToday()
        )
        return eligibility.isEligible
    }

    func bind(environment: AppEnvironment) {
        self.environment = environment
    }

    func refresh() async {
        guard let environment else { return }
        environment.repository.refreshCabinLodging()

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

        if environment.repository.hasReachedDailyAnimalLimit {
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

        let status = environment.stepSnapshot.status
        guard status.canAttemptStepRead else {
            await connectHealth()
            return
        }

        environment.repository.refreshCabinLodging()
        guard environment.repository.currentCabinAnimal != nil else {
            await refresh()
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let steps = try await environment.readTodaySteps()
            let eligibility = environment.ticketRuleEngine.evaluate(
                todaySteps: steps,
                giftedCountToday: environment.repository.giftedTicketCountToday()
            )

            guard eligibility.isEligible else {
                actionMessage = eligibility.message
                await refresh()
                return
            }

            pendingSteps = steps
            pendingTicketCount = eligibility.ticketCount
            pendingGiftConfirmation = TicketGiftConfirmation(
                animalName: environment.repository.currentCabinAnimal?.name ?? "小动物",
                destination: environment.repository.activeWish?.destination ?? "远方",
                ticketCount: eligibility.ticketCount,
                steps: steps
            )
        } catch {
            actionMessage = AppCopy.Cabin.stepReadFailed
            await refresh()
        }
    }

    @discardableResult
    func confirmGiftTodaySteps() async -> Trip? {
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
            pendingGiftConfirmation = nil
            isWorking = false
        }

        let eligibility = environment.ticketRuleEngine.evaluate(
            todaySteps: steps,
            giftedCountToday: environment.repository.giftedTicketCountToday()
        )

        guard eligibility.isEligible else {
            actionMessage = eligibility.message
            await refresh()
            return nil
        }

        let trip = environment.repository.giftTicket(
            sourceSteps: steps,
            ticketCount: ticketCount
        )
        lastGiftedTrip = trip
        actionMessage = AppCopy.Cabin.gifted
        await refresh()
        return trip
    }

    func cancelGiftConfirmation() {
        pendingSteps = nil
        pendingTicketCount = nil
        pendingGiftConfirmation = nil
    }

    private func availableSteps(from steps: Int) -> Int {
        guard let environment else { return 0 }
        return environment.ticketRuleEngine.remainingSteps(
            todaySteps: steps,
            giftedCountToday: environment.repository.giftedTicketCountToday()
        )
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
