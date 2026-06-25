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

        let backRowSlots = CabinAnimalLayout.slots.filter { $0.floor == .top }
        let middleRowSlots = CabinAnimalLayout.slots.filter { $0.floor == .middle }
        let frontRowSlots = CabinAnimalLayout.slots.filter { $0.floor == .bottom }

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

    func testCabinAnimalLayoutUsesExpandedFullscreenCoordinates() {
        let expected: [String: (CGPoint, CGFloat)] = [
            "xiaoman_hamster": (CGPoint(x: 0.205, y: 0.478), 0.120),
            "moji_cat": (CGPoint(x: 0.500, y: 0.452), 0.126),
            "dengdeng_rabbit": (CGPoint(x: 0.749, y: 0.458), 0.120),
            "tangyuan_puppy": (CGPoint(x: 0.125, y: 0.615), 0.120),
            "xiaolu_guinea_pig": (CGPoint(x: 0.365, y: 0.635), 0.114),
            "bear_visitor": (CGPoint(x: 0.635, y: 0.635), 0.120),
            "deer_visitor": (CGPoint(x: 0.875, y: 0.646), 0.124),
            "fox_visitor": (CGPoint(x: 0.260, y: 0.700), 0.138),
            "feifei_parrot": (CGPoint(x: 0.740, y: 0.700), 0.116)
        ]

        for (animalId, expectedValues) in expected {
            let slot = CabinAnimalLayout.slot(for: animalId, in: CabinAnimalLayout.fullscreenDayRoom)
            XCTAssertEqual(slot?.footPointRatio.x ?? 0, expectedValues.0.x, accuracy: 0.001)
            XCTAssertEqual(slot?.footPointRatio.y ?? 0, expectedValues.0.y, accuracy: 0.001)
            XCTAssertEqual(slot?.heightRatio ?? 0, expectedValues.1, accuracy: 0.001)
        }

        let cat = CabinAnimalLayout.slot(for: "moji_cat", in: CabinAnimalLayout.fullscreenDayRoom)
        let hamster = CabinAnimalLayout.slot(for: "xiaoman_hamster", in: CabinAnimalLayout.fullscreenDayRoom)
        let rabbit = CabinAnimalLayout.slot(for: "dengdeng_rabbit", in: CabinAnimalLayout.fullscreenDayRoom)
        XCTAssertLessThan(cat?.footPointRatio.y ?? 1, hamster?.footPointRatio.y ?? 0)
        XCTAssertLessThan(cat?.footPointRatio.y ?? 1, rabbit?.footPointRatio.y ?? 0)
    }

    func testCabinAnimalLayoutAnchorsAnimalsToRoomSurfaces() {
        let profile = CabinAnimalLayout.fullscreenDayRoom
        let sceneSize = profile.sourceSize
        let renderedRect = profile.renderedRect(in: sceneSize, contentMode: .fit)

        for slot in profile.slots {
            let frame = slot.frame(in: renderedRect, aspectRatio: 0.9, verticalLiftRatio: 0)
            let footPoint = slot.footPoint(in: renderedRect, verticalLiftRatio: 0)

            XCTAssertEqual(frame.maxY, footPoint.y, accuracy: 0.01)
            XCTAssertGreaterThanOrEqual(frame.minX, 0)
            XCTAssertLessThanOrEqual(frame.maxX, sceneSize.width)
            XCTAssertGreaterThanOrEqual(frame.height / sceneSize.height, 0.10)
            XCTAssertLessThanOrEqual(frame.height / sceneSize.height, 0.14)
            XCTAssertGreaterThanOrEqual(slot.footPointRatio.y, 0.42)
            XCTAssertLessThanOrEqual(slot.footPointRatio.y, 0.70)
        }
    }

    func testCabinAnimalLayoutKeepsRowsStaggeredInFullscreenProfile() {
        let profile = CabinAnimalLayout.fullscreenDayRoom
        let topSlots = profile.slots.filter { $0.floor == .top }
        let middleSlots = profile.slots.filter { $0.floor == .middle }
        let bottomSlots = profile.slots.filter { $0.floor == .bottom }

        XCTAssertLessThan(topSlots.map(\.footPointRatio.y).max() ?? 1, middleSlots.map(\.footPointRatio.y).min() ?? 0)
        XCTAssertLessThan(middleSlots.map(\.footPointRatio.y).max() ?? 1, bottomSlots.map(\.footPointRatio.y).min() ?? 0)

        for slot in profile.slots {
            XCTAssertGreaterThanOrEqual(slot.footPointRatio.x, 0.10)
            XCTAssertLessThanOrEqual(slot.footPointRatio.x, 0.90)
        }
    }

    func testCabinAnimalLayoutMapsSourceCoordinatesAfterFillCropping() {
        let profile = CabinAnimalLayout.fullscreenDayRoom
        let containerSizes = [
            CGSize(width: 320, height: 568),
            CGSize(width: 390, height: 844),
            CGSize(width: 430, height: 932)
        ]

        for containerSize in containerSizes {
            let renderedRect = profile.renderedRect(in: containerSize, contentMode: .fill)
            XCTAssertLessThanOrEqual(renderedRect.minX, 0)
            XCTAssertLessThanOrEqual(renderedRect.minY, 0)
            XCTAssertGreaterThanOrEqual(renderedRect.maxX, containerSize.width)
            XCTAssertGreaterThanOrEqual(renderedRect.maxY, containerSize.height)

            for slot in profile.slots {
                let footPoint = slot.footPoint(in: renderedRect, verticalLiftRatio: 0)
                let mappedRatio = CGPoint(
                    x: (footPoint.x - renderedRect.minX) / renderedRect.width,
                    y: (footPoint.y - renderedRect.minY) / renderedRect.height
                )
                XCTAssertEqual(mappedRatio.x, slot.footPointRatio.x, accuracy: 0.001)
                XCTAssertEqual(mappedRatio.y, slot.footPointRatio.y, accuracy: 0.001)
            }
        }
    }

    func testBottomChromePositionsActionCardAboveTabBar() {
        XCTAssertEqual(BottomChromeMetrics.tabBarBottomPadding, 20)
        XCTAssertEqual(BottomChromeMetrics.tabBarHeight, 60)
        XCTAssertEqual(BottomChromeMetrics.actionCardToTabBarGap, 12)
        XCTAssertEqual(BottomChromeMetrics.actionCardDistanceFromRootBottom, 92)

        let metrics = BottomChromeMetrics(containerHeight: 844, bottomSafeAreaInset: 34)
        XCTAssertEqual(metrics.actionCardBottomPadding, 58)
        XCTAssertEqual(metrics.actionCardVerticalPadding(isWaitingForAnimal: true), 14)
        XCTAssertEqual(metrics.actionCardVerticalPadding(isWaitingForAnimal: false), 10)
    }

    func testBottomChromeDoesNotAutoLiftAnimalGroup() {
        let shortMetrics = BottomChromeMetrics(containerHeight: 568)
        let mediumMetrics = BottomChromeMetrics(containerHeight: 760)
        let tallMetrics = BottomChromeMetrics(containerHeight: 932)

        XCTAssertEqual(shortMetrics.animalGroupLiftRatio, 0, accuracy: 0.001)
        XCTAssertEqual(mediumMetrics.animalGroupLiftRatio, 0, accuracy: 0.001)
        XCTAssertEqual(tallMetrics.animalGroupLiftRatio, 0, accuracy: 0.001)
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
        XCTAssertEqual(viewModel.stepStatusText, "Health 已连接")
        XCTAssertEqual(viewModel.availableStepsForDisplay, 3_456)
        XCTAssertFalse(viewModel.requiresHealthConnection)
    }

    func testSuccessfulHealthAuthorizationDoesNotFailWhenInitialStepReadFails() async throws {
        let seed = SeedData.preview
        let repository = AppRepository(
            seed: seed,
            store: InMemoryUserStateStore(
                savedState: AppUserState(
                    seed: seed,
                    flags: AppUserFlags(
                        onboardingCompleted: true,
                        healthGuideDismissed: true,
                        firstImmediateTicketGifted: true
                    )
                )
            )
        )
        let stepProvider = FakeStepCountProvider(
            status: .notDetermined,
            steps: 0,
            requestSucceeds: true,
            throwsOnStepRead: true
        )
        let environment = AppEnvironment(
            repository: repository,
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.connectHealth()

        XCTAssertEqual(environment.stepSnapshot.status, .sharingAuthorized)
        XCTAssertNil(environment.stepSnapshot.steps)
        XCTAssertEqual(viewModel.stepStatusText, "Health 已连接")
        XCTAssertTrue(viewModel.shouldShowHealthReconnectCard)
        XCTAssertEqual(viewModel.actionMessage, AppCopy.Cabin.stepReadFailed)
    }

    func testConnectHealthRetriesStepReadWithoutRequestingAuthorizationWhenPermissionWasAlreadyRequested() async {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(status: .readPermissionRequested, steps: 4_321)
        let environment = AppEnvironment(
            repository: AppRepository(
                seed: seed,
                store: InMemoryUserStateStore(
                    savedState: AppUserState(
                        seed: seed,
                        flags: AppUserFlags(
                            onboardingCompleted: true,
                            healthGuideDismissed: true,
                            firstImmediateTicketGifted: true
                        )
                    )
                )
            ),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.refresh()
        await viewModel.connectHealth()

        XCTAssertEqual(stepProvider.authorizationRequestCount, 0)
        XCTAssertEqual(stepProvider.stepReadCount, 1)
        XCTAssertEqual(environment.stepSnapshot.steps, 4_321)
        XCTAssertFalse(viewModel.requiresHealthConnection)
    }

    func testRequestStepAuthorizationOnlyDoesNotReadStepsSynchronously() async throws {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(status: .notDetermined, steps: 4_321)
        let environment = AppEnvironment(
            repository: AppRepository(seed: seed, store: InMemoryUserStateStore()),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )

        let didRequest = try await environment.requestStepAuthorizationOnly()

        XCTAssertTrue(didRequest)
        XCTAssertEqual(environment.stepSnapshot.status, .sharingAuthorized)
        XCTAssertNil(environment.stepSnapshot.steps)
        XCTAssertEqual(stepProvider.stepReadCount, 0)

        await environment.refreshStepsIfPossible()

        XCTAssertEqual(environment.stepSnapshot.steps, 4_321)
        XCTAssertEqual(stepProvider.stepReadCount, 1)
    }

    func testRequestStepAuthorizationAndRefreshStillReadsStepsSynchronously() async throws {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(status: .notDetermined, steps: 4_321)
        let environment = AppEnvironment(
            repository: AppRepository(seed: seed, store: InMemoryUserStateStore()),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )

        let didRequest = try await environment.requestStepAuthorizationAndRefresh()

        XCTAssertTrue(didRequest)
        XCTAssertEqual(environment.stepSnapshot.status, .sharingAuthorized)
        XCTAssertEqual(environment.stepSnapshot.steps, 4_321)
        XCTAssertEqual(stepProvider.stepReadCount, 1)
    }

    func testConcurrentStepReadsShareInFlightProviderRequest() async throws {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(
            status: .readPermissionRequested,
            steps: 4_567,
            readDelayNanoseconds: 50_000_000
        )
        let environment = AppEnvironment(
            repository: AppRepository(seed: seed, store: InMemoryUserStateStore()),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )

        async let firstRead = environment.readTodaySteps()
        async let secondRead = environment.readTodaySteps()
        let values = try await (firstRead, secondRead)

        XCTAssertEqual(values.0, 4_567)
        XCTAssertEqual(values.1, 4_567)
        XCTAssertEqual(environment.stepSnapshot.steps, 4_567)
        XCTAssertEqual(stepProvider.stepReadCount, 1)
    }

    func testEnsureTodayStepsLoadedReadsStepsOnHomeEntry() async {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(status: .readPermissionRequested, steps: 4_321)
        let environment = AppEnvironment(
            repository: AppRepository(
                seed: seed,
                store: InMemoryUserStateStore(
                    savedState: AppUserState(
                        seed: seed,
                        flags: AppUserFlags(
                            onboardingCompleted: true,
                            healthGuideDismissed: true,
                            firstImmediateTicketGifted: true
                        )
                    )
                )
            ),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.ensureTodayStepsLoaded()

        XCTAssertEqual(environment.stepSnapshot.steps, 4_321)
        XCTAssertEqual(stepProvider.stepReadCount, 1)
        XCTAssertFalse(viewModel.shouldShowHealthReconnectCard)
        XCTAssertFalse(viewModel.requiresHealthConnection)
    }

    func testEnsureTodayStepsLoadedRetriesOnceAfterInitialReadFailure() async {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(
            status: .readPermissionRequested,
            readResults: [
                .failure(.unableToReadSteps),
                .success(3_210)
            ]
        )
        let environment = AppEnvironment(
            repository: AppRepository(
                seed: seed,
                store: InMemoryUserStateStore(
                    savedState: AppUserState(
                        seed: seed,
                        flags: AppUserFlags(
                            onboardingCompleted: true,
                            healthGuideDismissed: true,
                            firstImmediateTicketGifted: true
                        )
                    )
                )
            ),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.ensureTodayStepsLoaded()

        XCTAssertEqual(environment.stepSnapshot.steps, 3_210)
        XCTAssertEqual(stepProvider.stepReadCount, 2)
        XCTAssertFalse(viewModel.shouldShowHealthReconnectCard)
        XCTAssertFalse(viewModel.requiresHealthConnection)
    }

    func testEnsureTodayStepsLoadedShowsReconnectAfterTwoReadFailures() async {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(
            status: .readPermissionRequested,
            readResults: [
                .failure(.unableToReadSteps),
                .failure(.unableToReadSteps)
            ]
        )
        let environment = AppEnvironment(
            repository: AppRepository(
                seed: seed,
                store: InMemoryUserStateStore(
                    savedState: AppUserState(
                        seed: seed,
                        flags: AppUserFlags(
                            onboardingCompleted: true,
                            healthGuideDismissed: true,
                            firstImmediateTicketGifted: true
                        )
                    )
                )
            ),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.ensureTodayStepsLoaded()

        XCTAssertNil(environment.stepSnapshot.steps)
        XCTAssertEqual(stepProvider.stepReadCount, 2)
        XCTAssertTrue(viewModel.shouldShowHealthReconnectCard)
        XCTAssertTrue(viewModel.requiresHealthConnection)
        XCTAssertEqual(viewModel.actionMessage, AppCopy.Cabin.stepReadFailed)
    }

    func testEnsureTodayStepsLoadedShowsReconnectWhenUnauthorized() async {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(status: .notDetermined, steps: 4_321)
        let environment = AppEnvironment(
            repository: AppRepository(
                seed: seed,
                store: InMemoryUserStateStore(
                    savedState: AppUserState(
                        seed: seed,
                        flags: AppUserFlags(
                            onboardingCompleted: true,
                            healthGuideDismissed: true,
                            firstImmediateTicketGifted: true
                        )
                    )
                )
            ),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.ensureTodayStepsLoaded()

        XCTAssertNil(environment.stepSnapshot.steps)
        XCTAssertEqual(stepProvider.stepReadCount, 0)
        XCTAssertTrue(viewModel.shouldShowHealthReconnectCard)
        XCTAssertTrue(viewModel.requiresHealthConnection)
    }

    func testEnsureTodayStepsLoadedTreatsZeroStepsAsSuccessfulRead() async {
        let seed = SeedData.preview
        let stepProvider = CountingStepProvider(status: .readPermissionRequested, steps: 0)
        let environment = AppEnvironment(
            repository: AppRepository(
                seed: seed,
                store: InMemoryUserStateStore(
                    savedState: AppUserState(
                        seed: seed,
                        flags: AppUserFlags(
                            onboardingCompleted: true,
                            healthGuideDismissed: true,
                            firstImmediateTicketGifted: true
                        )
                    )
                )
            ),
            stepCountProvider: stepProvider,
            ticketRuleEngine: TicketRuleEngine(),
            animalVisitService: AnimalVisitService(),
            postcardScheduler: PostcardScheduler(),
            destinations: seed.destinations
        )
        let viewModel = CabinViewModel()

        viewModel.bind(environment: environment)
        await viewModel.ensureTodayStepsLoaded()

        XCTAssertEqual(environment.stepSnapshot.steps, 0)
        XCTAssertEqual(stepProvider.stepReadCount, 1)
        XCTAssertFalse(viewModel.shouldShowHealthReconnectCard)
        XCTAssertFalse(viewModel.requiresHealthConnection)
        XCTAssertEqual(viewModel.availableStepsForDisplay, 0)
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

private final class CountingStepProvider: StepCountProvider {
    var status: StepCountAuthorizationStatus
    var steps: Int
    var readResults: [Result<Int, StepCountProviderError>]
    var readDelayNanoseconds: UInt64
    private(set) var authorizationRequestCount = 0
    private(set) var stepReadCount = 0

    init(status: StepCountAuthorizationStatus, steps: Int, readDelayNanoseconds: UInt64 = 0) {
        self.status = status
        self.steps = steps
        self.readResults = []
        self.readDelayNanoseconds = readDelayNanoseconds
    }

    init(status: StepCountAuthorizationStatus, readResults: [Result<Int, StepCountProviderError>], readDelayNanoseconds: UInt64 = 0) {
        self.status = status
        self.steps = 0
        self.readResults = readResults
        self.readDelayNanoseconds = readDelayNanoseconds
    }

    var isHealthDataAvailable: Bool {
        status != .unavailable
    }

    func authorizationStatus() -> StepCountAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        status = .sharingAuthorized
        return true
    }

    func todayStepCount() async throws -> Int {
        stepReadCount += 1
        if readDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: readDelayNanoseconds)
        }
        if readResults.isEmpty == false {
            switch readResults.removeFirst() {
            case .success(let steps):
                self.steps = steps
                return steps
            case .failure(let error):
                throw error
            }
        }
        return steps
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
