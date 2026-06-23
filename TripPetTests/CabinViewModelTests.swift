import XCTest
@testable import TripPet

@MainActor
final class CabinViewModelTests: XCTestCase {
    func testCabinAnimalLayoutUsesFixedSingleRoomSlots() {
        XCTAssertEqual(CabinAnimalLayout.slots.map(\.animalId), [
            "xiaoman_hamster",
            "moji_cat",
            "dengdeng_rabbit",
            "tangyuan_puppy",
            "xiaolu_guinea_pig",
            "bear_visitor",
            "deer_visitor",
            "fox_visitor",
            "feifei_parrot"
        ])

        let backRowSlots = CabinAnimalLayout.slots.filter { $0.footPointRatio.y < 0.63 }
        let middleRowSlots = CabinAnimalLayout.slots.filter { $0.footPointRatio.y >= 0.63 && $0.footPointRatio.y < 0.82 }
        let frontRowSlots = CabinAnimalLayout.slots.filter { $0.footPointRatio.y >= 0.82 }

        XCTAssertEqual(backRowSlots.count, 3)
        XCTAssertEqual(middleRowSlots.count, 4)
        XCTAssertEqual(frontRowSlots.count, 2)

        XCTAssertEqual(CabinAnimalLayout.slot(for: "moji_cat")?.side, .leftLarge)
        XCTAssertEqual(CabinAnimalLayout.slot(for: "dengdeng_rabbit")?.side, .rightSmall)
        XCTAssertEqual(CabinAnimalLayout.slot(for: "bear_visitor")?.side, .rightSmall)
        XCTAssertEqual(CabinAnimalLayout.slot(for: "feifei_parrot")?.floor, .bottom)
        XCTAssertEqual(CabinAnimalLayout.slot(for: "dengdeng_rabbit")?.isMirrored, true)
        XCTAssertEqual(CabinAnimalLayout.slot(for: "bear_visitor")?.isMirrored, true)
        XCTAssertEqual(CabinAnimalLayout.slot(for: "moji_cat")?.isMirrored, false)
    }

    func testCabinAnimalLayoutAnchorsAnimalsToRoomSurfaces() {
        let sceneSize = CGSize(width: 1254, height: 1455)

        for slot in CabinAnimalLayout.slots {
            let frame = slot.frame(in: sceneSize, aspectRatio: 0.9)
            let footPoint = slot.footPoint(in: sceneSize)

            XCTAssertEqual(frame.maxY, footPoint.y, accuracy: 0.01)
            XCTAssertGreaterThanOrEqual(frame.minX, 0)
            XCTAssertLessThanOrEqual(frame.maxX, sceneSize.width)
            XCTAssertGreaterThanOrEqual(frame.height / sceneSize.height, 0.15)
            XCTAssertLessThanOrEqual(frame.height / sceneSize.height, 0.19)
            XCTAssertGreaterThanOrEqual(slot.footPointRatio.y, 0.56)
            XCTAssertLessThanOrEqual(slot.footPointRatio.y, 0.89)
        }
    }

    func testCabinAnimalLayoutKeepsRemainingCanonicalAnimalsInFixedSlots() {
        let animals = SeedData.preview.animals.filter { $0.id != "xiaoman_hamster" }
        let placements = CabinAnimalLayout.placements(for: animals)

        XCTAssertNil(placements.first { $0.animal.id == "xiaoman_hamster" })
        XCTAssertEqual(placements.count, 8)
        XCTAssertEqual(
            placements.first { $0.animal.id == "tangyuan_puppy" }?.slot.footPointRatio,
            CabinAnimalLayout.slot(for: "tangyuan_puppy")?.footPointRatio
        )
        XCTAssertEqual(
            placements.first { $0.animal.id == "bear_visitor" }?.slot.side,
            .rightSmall
        )
    }

    func testCabinAnimalAnimationsMapEveryCanonicalAnimalToGif() {
        let expectedFilenamesByAnimalId = [
            "xiaoman_hamster": "animal_animation_xiaoman_hamster.gif",
            "tangyuan_puppy": "animal_animation_tangyuan_puppy.gif",
            "moji_cat": "animal_animation_moji_cat.gif",
            "dengdeng_rabbit": "animal_animation_dengdeng_rabbit.gif",
            "feifei_parrot": "animal_animation_feifei_parrot.gif",
            "xiaolu_guinea_pig": "animal_animation_xiaolu_guinea_pig.gif",
            "deer_visitor": "animal_animation_jiujiu_deer.gif",
            "fox_visitor": "animal_animation_aini_fox.gif",
            "bear_visitor": "animal_animation_dundun_bear.gif"
        ]

        XCTAssertEqual(CabinAnimalAnimationCatalog.fallbackEntries.count, 9)
        for animal in SeedData.preview.animals {
            let entry = CabinAnimalAnimationCatalog.entry(for: animal.id)
            XCTAssertEqual(entry?.filename, expectedFilenamesByAnimalId[animal.id])
            XCTAssertGreaterThan(entry?.aspectRatio ?? 0, 0.6)
            XCTAssertLessThan(entry?.aspectRatio ?? 0, 1.1)
        }
    }

    func testCabinAnimalAnimationUsesPingPongOnlyForNonSeamlessPuppyGif() {
        XCTAssertTrue(CabinAnimalAnimationCatalog.usesPingPongLoop(for: "tangyuan_puppy"))

        for animal in SeedData.preview.animals where animal.id != "tangyuan_puppy" {
            XCTAssertFalse(CabinAnimalAnimationCatalog.usesPingPongLoop(for: animal.id))
        }
    }

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
        XCTAssertNotNil(viewModel.pendingGiftConfirmation)
        XCTAssertEqual(viewModel.confirmedGiftTrip?.id, trip?.id)
        XCTAssertTrue(environment.repository.userFlags.firstImmediateTicketGifted)
        XCTAssertFalse(environment.repository.canUseFirstImmediateTicket())
        XCTAssertTrue(viewModel.requiresHealthConnection)

        viewModel.finishGiftFlow()

        XCTAssertNil(viewModel.pendingGiftConfirmation)
        XCTAssertNil(viewModel.confirmedGiftTrip)
    }

    func testFirstImmediateTicketDoesNotRequestAuthorizationButSchedulesTripNotificationsWhenAuthorized() async {
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
        await Task.yield()

        XCTAssertNotNil(trip)
        XCTAssertEqual(notificationService.authorizationRequestCount, 0)
        XCTAssertEqual(notificationService.scheduledPostcardIds, [
            "postcard_\(trip?.id ?? "")_1",
            "postcard_\(trip?.id ?? "")_2"
        ])
        XCTAssertEqual(notificationService.scheduledDeliveryDates.count, 2)
    }

    func testPostcardReturnRequestsNotificationAuthorizationOnlyOnceAndDoesNotDuplicateScheduledNotifications() async {
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
        await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertEqual(notificationService.scheduledPostcardIds.count, 2)
    }

    func testNormalTicketGiftKeepsSheetOpenInConfirmedState() async {
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            steps: 5_000
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await environment.refreshStepsIfPossible()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await viewModel.confirmGiftTodaySteps(animalId: animalId)

        XCTAssertNotNil(trip)
        XCTAssertNotNil(viewModel.pendingGiftConfirmation)
        XCTAssertEqual(viewModel.confirmedGiftTrip?.id, trip?.id)

        viewModel.finishGiftFlow()

        XCTAssertNil(viewModel.pendingGiftConfirmation)
        XCTAssertNil(viewModel.confirmedGiftTrip)
    }

    func testRevealEligiblePostcardsDoesNotScheduleForegroundNotifications() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            postcardNotificationService: notificationService
        )
        let departedAt = Date()

        environment.repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: departedAt)
        XCTAssertTrue(environment.revealEligiblePostcards(on: departedAt.addingTimeInterval(60 * 60 * 20)))
        await Task.yield()

        XCTAssertEqual(notificationService.authorizationRequestCount, 0)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
    }

    func testRevealEligiblePostcardsDoesNotScheduleNotificationWhenNothingIsNew() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            postcardNotificationService: notificationService
        )
        let departedAt = Date()

        environment.repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: departedAt)
        XCTAssertFalse(environment.revealEligiblePostcards(on: departedAt))
        await Task.yield()

        XCTAssertEqual(notificationService.authorizationRequestCount, 0)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
    }

    func testGiftSchedulesFuturePostcardNotificationsAndRevealDoesNotDuplicateThem() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: true)
        let environment = AppEnvironment.preview(
            flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: true, firstImmediateTicketGifted: true),
            postcardNotificationService: notificationService
        )
        let departedAt = Date()

        let trip = await environment.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: departedAt)
        XCTAssertNotNil(trip)
        XCTAssertEqual(notificationService.scheduledPostcardIds, [
            "postcard_\(trip?.id ?? "")_1",
            "postcard_\(trip?.id ?? "")_2"
        ])

        XCTAssertTrue(environment.revealEligiblePostcards(on: departedAt.addingTimeInterval(60 * 60 * 20)))
        await Task.yield()

        XCTAssertEqual(notificationService.scheduledPostcardIds.count, 2)
    }

    func testAuthorizationBackfillSkipsPastDuePostcardNotifications() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: false)
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0,
            postcardNotificationService: notificationService
        )
        let departedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await environment.giftTicket(
            sourceSteps: 0,
            ticketCount: 1,
            animalId: animalId,
            date: departedAt,
            isFirstImmediateTicket: true
        )

        XCTAssertNotNil(trip)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
        guard let postcard = environment.repository.postcards.first else {
            XCTFail("Expected first immediate ticket to create a postcard")
            return
        }

        notificationService.authorizationGranted = true
        await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
    }

    func testAuthorizationBackfillSchedulesOnlyFuturePostcardsWhenFirstDuePassed() async {
        let notificationService = RecordingPostcardNotificationService(authorizationGranted: false)
        let environment = AppEnvironment.preview(
            stepStatus: .notDetermined,
            steps: 0,
            postcardNotificationService: notificationService
        )
        let departedAt = Date().addingTimeInterval(-60 * 60 * 4)
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.prepareGiftConfirmation()
        let animalId = viewModel.pendingGiftConfirmation?.animalOptions.first?.animalId
        let trip = await environment.giftTicket(
            sourceSteps: 0,
            ticketCount: 1,
            animalId: animalId,
            date: departedAt,
            isFirstImmediateTicket: true
        )

        XCTAssertNotNil(trip)
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
        guard let postcard = environment.repository.postcards.first else {
            XCTFail("Expected first immediate ticket to create a postcard")
            return
        }

        notificationService.authorizationGranted = true
        await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertEqual(notificationService.scheduledPostcardIds, [
            "postcard_\(trip?.id ?? "")_2"
        ])
    }

    func testUnauthorizedGiftDoesNotScheduleUntilExistingAuthorizationEntrySucceeds() async {
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
        XCTAssertTrue(notificationService.scheduledPostcardIds.isEmpty)
        guard let postcard = environment.repository.postcards.first else {
            XCTFail("Expected first immediate ticket to create a postcard")
            return
        }

        notificationService.authorizationGranted = true
        await environment.requestNotificationAuthorizationOnPostcardReturn(postcard)

        XCTAssertEqual(notificationService.authorizationRequestCount, 1)
        XCTAssertEqual(notificationService.scheduledPostcardIds, [
            "postcard_\(trip?.id ?? "")_1",
            "postcard_\(trip?.id ?? "")_2"
        ])
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

    private(set) var scheduledDeliveryDates: [Date?] = []

    func scheduleNewPostcardNotification(postcardId: String) async -> Bool {
        await scheduleNewPostcardNotification(postcardId: postcardId, requiresCurrentAuthorization: true)
    }

    func scheduleNewPostcardNotification(
        postcardId: String,
        requiresCurrentAuthorization: Bool
    ) async -> Bool {
        await scheduleNewPostcardNotification(
            postcardId: postcardId,
            deliveryDate: nil,
            requiresCurrentAuthorization: requiresCurrentAuthorization
        )
    }

    func scheduleNewPostcardNotification(
        postcardId: String,
        deliveryDate: Date?,
        requiresCurrentAuthorization: Bool
    ) async -> Bool {
        guard authorizationGranted else { return false }
        scheduledPostcardIds.append(postcardId)
        scheduledTitles.append(PostcardNotificationService.newPostcardTitle)
        scheduledDeliveryDates.append(deliveryDate)
        return true
    }
}
