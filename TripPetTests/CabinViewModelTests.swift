import XCTest
@testable import TripPet

@MainActor
final class CabinViewModelTests: XCTestCase {
    func testStepCounterDisplayTextShowsActualStepsAndPadsSmallValues() {
        XCTAssertEqual(StepCounterView.displayText(value: -1), "0000")
        XCTAssertEqual(StepCounterView.displayText(value: 0), "0000")
        XCTAssertEqual(StepCounterView.displayText(value: 42), "0042")
        XCTAssertEqual(StepCounterView.displayText(value: 3_000), "3000")
        XCTAssertEqual(StepCounterView.displayText(value: 5_000), "5000")
        XCTAssertEqual(StepCounterView.displayText(value: 9_999), "9999")
    }

    func testAvailableStepsDisplayShowsActualStepsBeforeGift() async {
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            steps: 5_000
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await environment.refreshStepsIfPossible()

        XCTAssertEqual(viewModel.availableStepsForDisplay, 5_000)
        XCTAssertTrue(viewModel.canGiftAvailableSteps)
        XCTAssertNil(viewModel.giftedStepsSummaryText)
    }

    func testFirstImmediateTicketIsGiftableWithoutReadingHealthSteps() async {
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()

        XCTAssertFalse(viewModel.requiresHealthConnection)
        XCTAssertEqual(viewModel.availableStepsForDisplay, 3_000)
        XCTAssertTrue(viewModel.canGiftAvailableSteps)

        await viewModel.prepareGiftConfirmation()

        XCTAssertEqual(viewModel.pendingGiftConfirmation?.ticketCount, 1)
        XCTAssertEqual(viewModel.pendingGiftConfirmation?.steps, 0)
        XCTAssertEqual(viewModel.pendingGiftConfirmation?.isFirstImmediateTicket, true)
    }

    func testFirstImmediateTicketMarksFlagAndThenRequiresNormalHealthFlow() async {
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await viewModel.confirmGiftTodaySteps(animalId: animalId)
        await viewModel.refresh()

        XCTAssertNotNil(trip)
        XCTAssertTrue(environment.repository.userFlags.firstImmediateTicketGifted)
        XCTAssertFalse(environment.repository.canUseFirstImmediateTicket())
        XCTAssertTrue(viewModel.requiresHealthConnection)
    }

    func testGiftedStepsSummaryKeepsTotalStepsVisibleAfterGift() async {
        let environment = AppEnvironment.preview(steps: 5_000)
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await environment.refreshStepsIfPossible()
        environment.repository.giftTicket(sourceSteps: 5_000, ticketCount: 1)

        XCTAssertEqual(viewModel.availableStepsForDisplay, 2_000)
        XCTAssertFalse(viewModel.canGiftAvailableSteps)
        XCTAssertEqual(viewModel.giftedStepsSummaryText, "今日总步数 5000，已赠送 3000 步")
    }

    func testAvailableStepsDisplayKeepsRemainderAfterGift() async {
        let environment = AppEnvironment.preview(steps: 3_012)
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await environment.refreshStepsIfPossible()
        environment.repository.giftTicket(sourceSteps: 3_012, ticketCount: 1)

        XCTAssertEqual(viewModel.availableStepsForDisplay, 12)
        XCTAssertFalse(viewModel.canGiftAvailableSteps)
    }

    func testConnectHealthImmediatelyReadsTodaySteps() async {
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            stepStatus: .notDetermined,
            steps: 3_456
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.connectHealth()

        XCTAssertEqual(environment.stepSnapshot.steps, 3_456)
        XCTAssertTrue(viewModel.actionMessage.contains("3456 步"))
    }

    func testReadPermissionRequestedPreservesStepReadMessage() async {
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            stepStatus: .readPermissionRequested,
            steps: 2_999
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()

        XCTAssertEqual(viewModel.stepStatusText, "Health 已请求")
        XCTAssertTrue(viewModel.actionMessage.contains("2999 步"))
    }

    #if DEBUG
    func testDebugStepBonusAppliesToCurrentSimulatedDay() async {
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            steps: 500
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await environment.refreshStepsIfPossible()
        environment.debugAddSteps()

        XCTAssertEqual(viewModel.availableStepsForDisplay, 1_500)
    }

    func testDebugStepBonusCanPrepareGiftWithoutHealthRead() async {
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            stepStatus: .sharingDenied,
            steps: 0
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        environment.debugAddSteps(3_000)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()

        XCTAssertFalse(viewModel.requiresHealthConnection)
        XCTAssertTrue(viewModel.canGiftAvailableSteps)
        XCTAssertEqual(viewModel.pendingGiftConfirmation?.steps, 3_000)
        XCTAssertEqual(viewModel.pendingGiftConfirmation?.isFirstImmediateTicket, false)
    }

    func testDebugStepsAfterFirstImmediateTicketAreNotReducedByFreeTicket() async {
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        _ = await viewModel.confirmGiftTodaySteps(animalId: animalId)

        environment.debugAddSteps(3_000)
        await viewModel.refresh()

        XCTAssertEqual(environment.repository.giftedTicketCountToday(on: environment.currentDate), 1)
        XCTAssertEqual(environment.repository.stepFundedTicketCountToday(on: environment.currentDate), 0)
        XCTAssertEqual(viewModel.availableStepsForDisplay, 3_000)
        XCTAssertTrue(viewModel.canGiftAvailableSteps)
    }

    func testDebugAdvanceHoursUsesCalendarDateForDailyCabinRefresh() {
        let environment = AppEnvironment.preview()
        let before = environment.currentDate

        environment.debugAdvanceHours()

        let elapsed = environment.currentDate.timeIntervalSince(before)
        XCTAssertEqual(elapsed, 21_600, accuracy: 2)
    }
    #endif
}
