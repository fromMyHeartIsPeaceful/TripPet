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

    func testFirstImmediateTicketRequestsAuthorizationAndSendsPostcardNotification() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0,
            postcardNotificationService: notificationService
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await viewModel.confirmGiftTodaySteps(animalId: animalId)

        XCTAssertNotNil(trip)
        XCTAssertEqual(notificationService.authorizationRequestCount, 0)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)

        await environment.requestAuthorizationAndNotifyPendingPostcards()

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertEqual(notificationService.scheduledTitles, [PostcardNotificationService.newPostcardTitle])
        XCTAssertEqual(notificationService.scheduledPostcardIds, environment.repository.postcards.map(\.id))
    }

    func testFirstImmediateTicketDoesNotSendNotificationWhenAuthorizationIsDenied() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: false)
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0,
            postcardNotificationService: notificationService
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await viewModel.confirmGiftTodaySteps(animalId: animalId)

        XCTAssertNotNil(trip)
        XCTAssertEqual(notificationService.authorizationRequestCount, 0)

        await environment.requestAuthorizationAndNotifyPendingPostcards()

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
    }

    func testPostcardReturnAuthorizationDoesNotSendAlreadyExposedFirstPostcardNotification() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0,
            postcardNotificationService: notificationService
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await viewModel.confirmGiftTodaySteps(animalId: animalId)

        XCTAssertNotNil(trip)
        guard let postcard = environment.repository.postcards.first else {
            XCTFail("Expected first immediate ticket to create a postcard")
            return
        }

        await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)
        await environment.requestAuthorizationAndNotifyPendingPostcards()

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
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

    func testRevealEligiblePostcardsSchedulesNotificationWithoutRequestingAuthorization() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(postcardNotificationService: notificationService)
        let departedAt = Date(timeIntervalSince1970: 1_700_000_000)

        environment.repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: departedAt)
        XCTAssertTrue(environment.revealEligiblePostcards(on: departedAt.addingTimeInterval(60 * 60 * 40)))
        await waitForScheduledNotifications(in: notificationService, count: 2)

        XCTAssertEqual(notificationService.authorizationRequestCount, 0)
        XCTAssertEqual(notificationService.scheduledTitles, [
            PostcardNotificationService.newPostcardTitle,
            PostcardNotificationService.newPostcardTitle
        ])
    }

    func testRevealEligiblePostcardsDoesNotScheduleNotificationWhenNothingIsNew() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(postcardNotificationService: notificationService)
        let departedAt = Date(timeIntervalSince1970: 1_700_000_000)

        environment.repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: departedAt)
        XCTAssertFalse(environment.revealEligiblePostcards(on: departedAt))
        await Task.yield()

        XCTAssertEqual(notificationService.authorizationRequestCount, 0)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
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

    func testPostcardReturnRequestsNotificationAuthorizationOnlyOnceWithoutSchedulingNotification() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(
            seed: SeedData(
                animals: SeedData.preview.animals,
                travelWishes: SeedData.preview.travelWishes,
                trips: SeedData.preview.trips,
                postcards: SeedData.previewPostcards,
                destinations: SeedData.preview.destinations
            ),
            postcardNotificationService: notificationService
        )
        let postcard = environment.repository.postcards[0]

        await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)
        await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
    }

}

@MainActor
private final class RecordingPostcardNotificationService: PostcardNotificationServiceProtocol {
    var requestedTab: AppTab?
    var tabRequestHandler: ((AppTab) -> Void)?
    var authorizationGranted: Bool
    private(set) var authorizationRequestCount = 0
    private(set) var scheduledPostcardIds: [String] = []
    private(set) var scheduledTitles: [String] = []

    init(authorizationGranted: Bool) {
        self.authorizationGranted = authorizationGranted
    }

    func requestAuthorization() async -> Bool {
        authorizationRequestCount += 1
        return authorizationGranted
    }

    func scheduleNewPostcardNotification(postcardId: String) async {
        await scheduleNewPostcardNotification(postcardId: postcardId, requiresCurrentAuthorization: true)
    }

    func scheduleNewPostcardNotification(
        postcardId: String,
        requiresCurrentAuthorization: Bool
    ) async {
        guard authorizationGranted else { return }
        scheduledPostcardIds.append(postcardId)
        scheduledTitles.append(PostcardNotificationService.newPostcardTitle)
    }
}

private func waitForScheduledNotifications(
    in service: RecordingPostcardNotificationService,
    count: Int,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    for _ in 0..<20 {
        if await service.scheduledPostcardIds.count >= count {
            return
        }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }

    let actualCount = await service.scheduledPostcardIds.count
    XCTAssertEqual(actualCount, count, file: file, line: line)
}
