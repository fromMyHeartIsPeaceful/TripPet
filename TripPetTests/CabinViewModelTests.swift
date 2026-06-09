import XCTest
@testable import TripPet

@MainActor
final class CabinViewModelTests: XCTestCase {
    func testStepCounterDisplayTextClampsAndPads() {
        XCTAssertEqual(StepCounterView.displayText(value: -1), "0000")
        XCTAssertEqual(StepCounterView.displayText(value: 0), "0000")
        XCTAssertEqual(StepCounterView.displayText(value: 42), "0042")
        XCTAssertEqual(StepCounterView.displayText(value: 3_000), "3000")
        XCTAssertEqual(StepCounterView.displayText(value: 9_999), "3000")
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
