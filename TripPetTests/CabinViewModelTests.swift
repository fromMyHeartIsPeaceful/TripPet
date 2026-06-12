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

        XCTAssertTrue(viewModel.shouldShowStepCounter)
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
        XCTAssertFalse(viewModel.shouldShowStepCounter)
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

    func testFirstImmediateTicketRefreshesAndShowsRealStepsAfterGift() async {
        let environment = AppEnvironment.preview(
            stepStatus: .sharingAuthorized,
            steps: 1_234
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()

        XCTAssertFalse(viewModel.shouldShowStepCounter)
        XCTAssertNil(environment.stepSnapshot.steps)

        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await viewModel.confirmGiftTodaySteps(animalId: animalId)

        XCTAssertNotNil(trip)
        XCTAssertTrue(environment.repository.userFlags.firstImmediateTicketGifted)
        XCTAssertTrue(viewModel.shouldShowStepCounter)
        XCTAssertEqual(environment.stepSnapshot.steps, 1_234)
        XCTAssertEqual(viewModel.availableStepsForDisplay, 1_234)
    }

    func testGiftedStepsSummaryKeepsTotalStepsVisibleAfterGift() async {
        let environment = AppEnvironment.preview(steps: 5_000)
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await environment.refreshStepsIfPossible()
        environment.repository.giftTicket(sourceSteps: 5_000, ticketCount: 1)

        XCTAssertTrue(viewModel.shouldShowStepCounter)
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

}
