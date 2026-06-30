import XCTest
@testable import TripPet
import simd

@MainActor
final class RootTabViewTests: XCTestCase {
    func testMailboxBadgeCountsOnlyUnreadPostcards() {
        let postcards = [
            makePostcard(id: "unread", isRead: false),
            makePostcard(id: "read", isRead: true)
        ]

        XCTAssertEqual(RootTabView.unreadMailboxBadgeCount(in: postcards), 1)
    }

    func testMailboxBadgeClearsWhenPostcardIsRead() {
        let postcard = makePostcard(id: "postcard", isRead: true)

        XCTAssertEqual(RootTabView.unreadMailboxBadgeCount(in: [postcard]), 0)
    }

    func testRootBottomTabOrderIncludesAchievementsBetweenCabinAndMailbox() {
        XCTAssertEqual(RootTabView.bottomTabOrder, [.cabin, .achievements, .mailbox, .map])
        XCTAssertEqual(
            RootTabView.bottomTabOrder.map { tab in
                switch tab {
                case .cabin:
                    AppCopy.Tabs.cabin
                case .achievements:
                    AppCopy.Tabs.achievements
                case .mailbox:
                    AppCopy.Tabs.mailbox
                case .map:
                    AppCopy.Tabs.map
                }
            },
            ["小屋", "成就", "邮箱", "地球"]
        )
    }

    func testRootTabPrewarmsOnlyMapAfterInitialCabinLoad() {
        XCTAssertEqual(RootTabView.initialRetainedTabs, [.cabin])
        XCTAssertEqual(RootTabView.deferredPrewarmTabs, [.map])
        XCTAssertFalse(RootTabView.deferredPrewarmTabs.contains(.achievements))
        XCTAssertFalse(RootTabView.deferredPrewarmTabs.contains(.mailbox))
    }

    func testMailboxViewModelOpeningStackDoesNotMarkPostcardRead() {
        let postcard = makePostcard(id: "unread", isRead: false)
        let viewModel = MailboxViewModel()

        viewModel.openStack(with: [postcard])

        XCTAssertTrue(viewModel.isStackPresented)
        XCTAssertEqual(viewModel.openedStackPostcardIds, ["unread"])
        XCTAssertNil(viewModel.selectedPostcard)
        XCTAssertFalse(postcard.isRead)
    }

    func testMailboxViewModelMarksOpenedStackReadWhenClosingOverlay() {
        let first = makePostcard(id: "first", isRead: false)
        let second = makePostcard(id: "second", isRead: false)
        let repository = AppRepository(
            seed: SeedData(
                animals: [],
                travelWishes: [],
                trips: [],
                postcards: [first, second]
            )
        )
        let viewModel = MailboxViewModel()

        viewModel.openStack(with: repository.postcards)
        viewModel.closeStack(repository: repository)

        XCTAssertTrue(repository.postcards.allSatisfy { $0.isRead })
        XCTAssertFalse(viewModel.isStackPresented)
        XCTAssertTrue(viewModel.openedStackPostcardIds.isEmpty)
        XCTAssertEqual(viewModel.stackIndex, 0)
    }

    func testMailboxViewModelDoesNotMarkPostcardReadWhenShowingUnreadStackDetail() {
        let postcard = makePostcard(id: "unread", isRead: false)
        let repository = AppRepository(
            seed: SeedData(
                animals: [],
                travelWishes: [],
                trips: [],
                postcards: [postcard]
            )
        )
        let viewModel = MailboxViewModel()

        viewModel.openStack(with: repository.postcards)
        XCTAssertFalse(repository.postcards[0].isRead)

        viewModel.showUnreadStackDetail(repository.postcards[0])

        XCTAssertEqual(viewModel.selectedPostcard?.id, "unread")
        XCTAssertEqual(viewModel.selectedPostcardSource, .unreadStack)
        XCTAssertEqual(viewModel.pendingReadPostcardId, "unread")
        XCTAssertFalse(repository.postcards[0].isRead)
        XCTAssertEqual(viewModel.openedStackPostcardIds, ["unread"])
    }

    func testMailboxViewModelMarksPostcardReadWhenUnreadDetailDismisses() {
        let postcard = makePostcard(id: "unread", isRead: false)
        let repository = AppRepository(
            seed: SeedData(
                animals: [],
                travelWishes: [],
                trips: [],
                postcards: [postcard]
            )
        )
        let viewModel = MailboxViewModel()

        viewModel.openStack(with: repository.postcards)
        viewModel.showUnreadStackDetail(repository.postcards[0])
        viewModel.settleSelectedPostcardDismissal(repository: repository)

        XCTAssertTrue(repository.postcards[0].isRead)
        XCTAssertFalse(viewModel.isStackPresented)
        XCTAssertTrue(viewModel.openedStackPostcardIds.isEmpty)
        XCTAssertNil(viewModel.selectedPostcard)
        XCTAssertNil(viewModel.selectedPostcardSource)
        XCTAssertNil(viewModel.pendingReadPostcardId)
    }

    func testMailboxViewModelKeepsUnreadStackAfterReadingOneOfManyPostcards() {
        let first = makePostcard(id: "first", isRead: false)
        let second = makePostcard(id: "second", isRead: false)
        let repository = AppRepository(
            seed: SeedData(
                animals: [],
                travelWishes: [],
                trips: [],
                postcards: [first, second]
            )
        )
        let viewModel = MailboxViewModel()

        viewModel.openStack(with: repository.postcards)
        viewModel.showNextPostcard(count: repository.postcards.count)
        viewModel.showUnreadStackDetail(repository.postcards[1])
        viewModel.settleSelectedPostcardDismissal(repository: repository)

        XCTAssertFalse(repository.postcards[0].isRead)
        XCTAssertTrue(repository.postcards[1].isRead)
        XCTAssertTrue(viewModel.isStackPresented)
        XCTAssertEqual(viewModel.openedStackPostcardIds, ["first"])
        XCTAssertEqual(viewModel.stackIndex, 0)
    }

    func testMailboxViewModelHistoryDetailDismissDoesNotMarkUnreadPostcardRead() {
        let unread = makePostcard(id: "unread", isRead: false)
        let read = makePostcard(id: "read", isRead: true)
        let repository = AppRepository(
            seed: SeedData(
                animals: [],
                travelWishes: [],
                trips: [],
                postcards: [unread, read]
            )
        )
        let viewModel = MailboxViewModel()

        viewModel.openStack(with: [repository.postcards[0]])
        viewModel.showHistoryDetail(repository.postcards[1])
        viewModel.settleSelectedPostcardDismissal(repository: repository)

        XCTAssertFalse(repository.postcards[0].isRead)
        XCTAssertTrue(repository.postcards[1].isRead)
        XCTAssertTrue(viewModel.isStackPresented)
        XCTAssertEqual(viewModel.openedStackPostcardIds, ["unread"])
    }

    func testPostcardNotificationPayloadRoutesToMailboxTab() {
        XCTAssertEqual(
            PostcardNotificationService.targetTab(from: ["target": "mailbox", "postcardId": "postcard-1"]),
            .mailbox
        )
        XCTAssertNil(PostcardNotificationService.targetTab(from: ["target": "cabin"]))
    }

    func testNotificationResponseQueuesMailboxRouteBeforeReturning() async {
        let notificationService = PostcardNotificationService()
        var handledTabs: [AppTab] = []
        notificationService.tabRequestHandler = { tab in
            handledTabs.append(tab)
        }

        await notificationService.routeNotificationResponse(
            userInfo: ["target": "mailbox", "postcardId": "postcard-1"],
            actionIdentifier: "default"
        )

        XCTAssertEqual(notificationService.requestedTab, .mailbox)
        XCTAssertEqual(handledTabs, [.mailbox])
    }

    func testLaunchPolicySkipsLaunchStoryWithoutBackgroundTimestamp() {
        let now = Date(timeIntervalSince1970: 1_000)

        XCTAssertFalse(
            AppLaunchPresentationPolicy.shouldPresentLaunchStoryOnActivation(
                previousBackgroundedAt: nil,
                now: now
            )
        )
    }

    func testLaunchPolicySkipsLaunchStoryWithinHotLaunchGraceInterval() {
        let previousBackgroundedAt = Date(timeIntervalSince1970: 1_000)
        let now = previousBackgroundedAt.addingTimeInterval(29.9)

        XCTAssertFalse(
            AppLaunchPresentationPolicy.shouldPresentLaunchStoryOnActivation(
                previousBackgroundedAt: previousBackgroundedAt,
                now: now
            )
        )
    }

    func testLaunchPolicyShowsLaunchStoryAtHotLaunchGraceBoundary() {
        let previousBackgroundedAt = Date(timeIntervalSince1970: 1_000)
        let now = previousBackgroundedAt.addingTimeInterval(30)

        XCTAssertTrue(
            AppLaunchPresentationPolicy.shouldPresentLaunchStoryOnActivation(
                previousBackgroundedAt: previousBackgroundedAt,
                now: now
            )
        )
    }

    func testEnvironmentConsumesQueuedNotificationTabRequest() {
        let notificationService = RootTabNotificationService()
        let environment = AppEnvironment.preview(postcardNotificationService: notificationService)

        notificationService.tabRequestHandler?(.mailbox)

        XCTAssertEqual(environment.consumeNotificationTabRequest(), .mailbox)
        XCTAssertNil(environment.consumeNotificationTabRequest())
        XCTAssertNil(notificationService.requestedTab)
    }

    func testEnvironmentQueuesNotificationTabRequestUntilRootConsumesIt() {
        let notificationService = RootTabNotificationService()
        let environment = AppEnvironment.preview(postcardNotificationService: notificationService)

        environment.queueNotificationTabRequest(.mailbox)

        XCTAssertEqual(environment.notificationRequestedTab, .mailbox)
        XCTAssertEqual(notificationService.requestedTab, .mailbox)
        XCTAssertEqual(environment.consumeNotificationTabRequest(), .mailbox)
        XCTAssertNil(environment.notificationRequestedTab)
        XCTAssertNil(notificationService.requestedTab)
    }

    func testNotificationTabRequestSurvivesLaunchStoryBeforeRootConsumesIt() {
        let notificationService = RootTabNotificationService()
        let environment = AppEnvironment.preview(postcardNotificationService: notificationService)

        environment.queueNotificationTabRequest(.mailbox)
        XCTAssertTrue(
            AppLaunchPresentationPolicy.shouldPresentLaunchStoryOnActivation(
                previousBackgroundedAt: Date(timeIntervalSince1970: 960),
                now: Date(timeIntervalSince1970: 1_000)
            )
        )

        XCTAssertEqual(environment.notificationRequestedTab, .mailbox)
        XCTAssertEqual(environment.consumeNotificationTabRequest(), .mailbox)
        XCTAssertNil(environment.consumeNotificationTabRequest())
    }

    func testPostcardSenderFallbackParsesTitleSender() {
        let postcard = makePostcard(
            id: "first",
            title: "墩墩寄来的第一张明信片",
            animalAssetName: "animal_home_dundun_bear",
            isRead: false
        )

        XCTAssertEqual(postcard.titleSenderNameFallback, "墩墩")
    }

    func testPostcardSenderFallbackDoesNotGuessFromAnimalAssetName() {
        let postcard = makePostcard(
            id: "legacy",
            title: "远方来信",
            animalAssetName: "animal_cat_selfie",
            isRead: false
        )

        XCTAssertEqual(postcard.titleSenderNameFallback, "小动物")
    }

    func testDefaultGlobeOrientationCentersCottage() {
        XCTAssertEqual(GlobeCoordinate.cottage.latitude, -20, accuracy: 0.001)
        XCTAssertEqual(GlobeCoordinate.cottage.longitude, -150, accuracy: 0.001)
        XCTAssertEqual(
            GlobeOrientation.defaultReadable.centerLatitude,
            GlobeCoordinate.cottage.latitude,
            accuracy: 0.001
        )
        XCTAssertEqual(
            GlobeOrientation.defaultReadable.centerLongitude,
            GlobeCoordinate.cottage.longitude,
            accuracy: 0.001
        )
    }

    func testGlobeProjectionPlacesCenteredCoordinateAtCircleCenter() {
        let center = CGPoint(x: 120, y: 90)
        let projection = GlobeProjection(
            center: center,
            radius: 60,
            orientation: .cottageCentered
        )

        let projected = projection.project(.cottage)

        XCTAssertEqual(projected?.point.x ?? 0, center.x, accuracy: 0.001)
        XCTAssertEqual(projected?.point.y ?? 0, center.y, accuracy: 0.001)
        XCTAssertEqual(projected?.isVisible, true)
    }

    func testGlobeProjectionHidesBackHemisphereCoordinate() {
        let projection = GlobeProjection(
            center: CGPoint(x: 100, y: 100),
            radius: 50,
            orientation: GlobeOrientation(centerLatitude: 0, centerLongitude: 0)
        )

        let projected = projection.project(GlobeCoordinate(latitude: 0, longitude: 180))

        XCTAssertEqual(projected?.isVisible, false)
    }

    func testGlobeTrackballDragChangesLongitudeHorizontally() {
        let orientation = GlobeOrientation(centerLatitude: 0, centerLongitude: 0)
            .applyingTrackballDrag(
                from: CGPoint(x: 100, y: 100),
                to: CGPoint(x: 140, y: 100),
                center: CGPoint(x: 100, y: 100),
                radius: 80
            )

        XCTAssertLessThan(orientation.centerLongitude, -20)
        XCTAssertGreaterThanOrEqual(orientation.centerLongitude, -180)
        XCTAssertLessThanOrEqual(orientation.centerLongitude, 180)
    }

    func testGlobeTrackballVerticalDragCanCrossClampedLatitudeLimit() {
        let orientation = GlobeOrientation(centerLatitude: 0, centerLongitude: 0)
            .applyingTrackballDrag(
                from: CGPoint(x: 100, y: 100),
                to: CGPoint(x: 100, y: 20),
                center: CGPoint(x: 100, y: 100),
                radius: 80
            )

        XCTAssertLessThan(orientation.centerLatitude, -70)
    }

    func testGlobeTrackballDiagonalDragKeepsProjectedPointsInsideCircle() {
        let orientation = GlobeOrientation(centerLatitude: 0, centerLongitude: 0)
            .applyingTrackballDrag(
                from: CGPoint(x: 100, y: 100),
                to: CGPoint(x: 134, y: 132),
                center: CGPoint(x: 100, y: 100),
                radius: 80
            )
        let projection = GlobeProjection(center: CGPoint(x: 100, y: 100), radius: 80, orientation: orientation)

        let projected = projection.project(orientation.forward.coordinate)

        XCTAssertGreaterThan(abs(orientation.centerLatitude), 10)
        XCTAssertGreaterThan(abs(orientation.centerLongitude), 10)
        XCTAssertEqual(projected?.point.x ?? 0, 100, accuracy: 0.001)
        XCTAssertEqual(projected?.point.y ?? 0, 100, accuracy: 0.001)
    }

    func testGlobeTrackballRotationKeepsBasisNormalizedAndBackHemisphereHidden() {
        let orientation = GlobeOrientation(centerLatitude: 18, centerLongitude: 56)
            .applyingTrackballDrag(
                from: CGPoint(x: 80, y: 86),
                to: CGPoint(x: 148, y: 34),
                center: CGPoint(x: 100, y: 100),
                radius: 80
            )
        let projection = GlobeProjection(center: CGPoint(x: 100, y: 100), radius: 80, orientation: orientation)
        let centerCoordinate = orientation.forward.coordinate
        let backLongitude = centerCoordinate.longitude > 0 ?
            centerCoordinate.longitude - 180 :
            centerCoordinate.longitude + 180
        let backCoordinate = GlobeCoordinate(
            latitude: -centerCoordinate.latitude,
            longitude: backLongitude
        )

        XCTAssertEqual(orientation.right.length, 1, accuracy: 0.001)
        XCTAssertEqual(orientation.up.length, 1, accuracy: 0.001)
        XCTAssertEqual(orientation.forward.length, 1, accuracy: 0.001)
        XCTAssertEqual(orientation.right.dot(orientation.up), 0, accuracy: 0.001)
        XCTAssertEqual(orientation.right.dot(orientation.forward), 0, accuracy: 0.001)
        XCTAssertEqual(orientation.up.dot(orientation.forward), 0, accuracy: 0.001)
        XCTAssertEqual(projection.project(backCoordinate)?.isVisible, false)
    }

    func testGlobeOrientationSceneKitTransformFacesCenteredCoordinateForward() {
        let orientation = GlobeOrientation.cottageCentered
        let vector = GlobeVector(coordinate: .cottage)
        let transformed = orientation.sceneKitTransform * SIMD4(Float(vector.x), Float(vector.y), Float(vector.z), 1)

        XCTAssertEqual(transformed.x, 0, accuracy: 0.001)
        XCTAssertEqual(transformed.y, 0, accuracy: 0.001)
        XCTAssertEqual(transformed.z, 1, accuracy: 0.001)
    }

    func testGreatCircleRouteClipsBackHemisphereSegments() {
        let route = makeGlobeRoute(
            origin: GlobeCoordinate(latitude: 0, longitude: -10),
            destination: GlobeCoordinate(latitude: 0, longitude: 160)
        )
        let projection = GlobeProjection(
            center: CGPoint(x: 100, y: 100),
            radius: 80,
            orientation: GlobeOrientation(centerLatitude: 0, centerLongitude: 0)
        )

        let visiblePointCount = route.visibleSegments(projection: projection, sampleCount: 40).flatMap { $0 }.count

        XCTAssertGreaterThan(visiblePointCount, 1)
        XCTAssertLessThan(visiblePointCount, 41)
    }

    func testTravelProgressClampsBeforeDepartureAndAfterReturn() {
        let departedAt = Date(timeIntervalSince1970: 1_000)
        let expectedReturnAt = Date(timeIntervalSince1970: 2_000)
        let route = makeGlobeRoute(departedAt: departedAt, expectedReturnAt: expectedReturnAt)

        XCTAssertEqual(route.travelProgress(at: Date(timeIntervalSince1970: 500)), 0)
        XCTAssertEqual(route.travelProgress(at: Date(timeIntervalSince1970: 1_500)), 0.5, accuracy: 0.001)
        XCTAssertEqual(route.travelProgress(at: Date(timeIntervalSince1970: 2_500)), 1)
    }

    func testTravelCountdownShowsArrivingSoonWhenDue() {
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: 0), "即将到达")
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: -12), "即将到达")
    }

    func testTravelCountdownFormatsMinutes() {
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: 1), "1分钟")
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: 59 * 60), "59分钟")
    }

    func testTravelCountdownFormatsHoursAndMinutes() {
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: 60 * 60), "1小时0分钟")
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: (2 * 60 * 60) + (14 * 60)), "2小时14分钟")
    }

    func testTravelCountdownFormatsDaysAndHours() {
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: 24 * 60 * 60), "1天0小时")
        XCTAssertEqual(TravelCountdownFormatter.timeString(remaining: (2 * 24 * 60 * 60) + (5 * 60 * 60)), "2天5小时")
    }

    func testTravelCountdownUsesExpectedReturnDate() {
        let now = Date(timeIntervalSince1970: 1_000)
        let expectedReturnAt = now.addingTimeInterval((3 * 60 * 60) + (21 * 60))

        XCTAssertEqual(
            TravelCountdownFormatter.timeString(until: expectedReturnAt, now: now),
            "3小时21分钟"
        )
    }

    func testDestinationCoordinateUsesLegacyFallback() {
        XCTAssertEqual(
            GlobeCoordinate.coordinate(for: "paris", destination: nil),
            GlobeCoordinate(latitude: 48.8566, longitude: 2.3522)
        )
    }

    func testTravelGlobeRoutesUseSingleDeepBlueTint() {
        XCTAssertEqual(TravelGlobeRoute.palette.count, 1)
    }

    private func makePostcard(
        id: String,
        title: String = "小满寄来的明信片",
        animalAssetName: String = "animal_home_xiaoman_hamster",
        isRead: Bool
    ) -> Postcard {
        Postcard(
            id: id,
            tripId: "trip-\(id)",
            destination: "巴黎",
            title: title,
            body: "今天有一封远方来信。",
            imageAssetName: "postcard_paris_day_2",
            templateAssetName: "postcard_template_classic",
            destinationAssetName: "postcard_destination_paris",
            stampAssetName: "postcard_stamp_paris",
            animalAssetName: animalAssetName,
            envelopeAssetName: "envelope_unread",
            sentAt: Date(),
            subtitle: "旅途中寄来",
            isRead: isRead
        )
    }

    private func makeGlobeRoute(
        origin: GlobeCoordinate = .cottage,
        destination: GlobeCoordinate = GlobeCoordinate(latitude: 48.8566, longitude: 2.3522),
        departedAt: Date = Date(timeIntervalSince1970: 1_000),
        expectedReturnAt: Date = Date(timeIntervalSince1970: 2_000)
    ) -> TravelGlobeRoute {
        TravelGlobeRoute(
            id: "route",
            animalName: "小满",
            destination: "巴黎",
            animalAssetName: "animal_home_xiaoman_hamster",
            origin: origin,
            destinationCoordinate: destination,
            departedAt: departedAt,
            expectedReturnAt: expectedReturnAt,
            tint: .blue
        )
    }
}

@MainActor
private final class RootTabNotificationService: PostcardNotificationServiceProtocol {
    var requestedTab: AppTab?
    var tabRequestHandler: ((AppTab) -> Void)?

    func requestAuthorization() async -> Bool { true }
    func scheduleNewPostcardNotification(postcardId: String) async -> Bool { true }
    func scheduleNewPostcardNotification(postcardId: String, requiresCurrentAuthorization: Bool) async -> Bool { true }
    func scheduleNewPostcardNotification(
        postcardId: String,
        deliveryDate: Date?,
        requiresCurrentAuthorization: Bool
    ) async -> Bool { true }
}
