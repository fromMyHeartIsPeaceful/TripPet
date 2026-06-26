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

    func testMailboxViewModelOpeningStackDoesNotMarkPostcardRead() {
        let postcard = makePostcard(id: "unread", isRead: false)
        let viewModel = MailboxViewModel()

        viewModel.openStack(with: [postcard])

        XCTAssertTrue(viewModel.isStackPresented)
        XCTAssertEqual(viewModel.openedStackPostcardIds, ["unread"])
        XCTAssertNil(viewModel.selectedPostcard)
        XCTAssertFalse(postcard.isRead)
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

    func testLaunchPolicyShowsLaunchStoryOnColdActivation() {
        let now = Date(timeIntervalSince1970: 1_000)

        XCTAssertTrue(
            AppLaunchPresentationPolicy.shouldPresentLaunchStoryOnActivation(
                previousActivationAt: nil,
                now: now
            )
        )
    }

    func testLaunchPolicySkipsLaunchStoryWithinHotLaunchGraceInterval() {
        let previousActivationAt = Date(timeIntervalSince1970: 1_000)
        let now = previousActivationAt.addingTimeInterval(29.9)

        XCTAssertFalse(
            AppLaunchPresentationPolicy.shouldPresentLaunchStoryOnActivation(
                previousActivationAt: previousActivationAt,
                now: now
            )
        )
    }

    func testLaunchPolicyShowsLaunchStoryAtHotLaunchGraceBoundary() {
        let previousActivationAt = Date(timeIntervalSince1970: 1_000)
        let now = previousActivationAt.addingTimeInterval(30)

        XCTAssertTrue(
            AppLaunchPresentationPolicy.shouldPresentLaunchStoryOnActivation(
                previousActivationAt: previousActivationAt,
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
                previousActivationAt: nil,
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

    func testGlobeProjectionPlacesCenteredCoordinateAtCircleCenter() {
        let center = CGPoint(x: 120, y: 90)
        let projection = GlobeProjection(
            center: center,
            radius: 60,
            orientation: GlobeOrientation(centerLatitude: 30, centerLongitude: 112)
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
        let orientation = GlobeOrientation(centerLatitude: 30, centerLongitude: 112)
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

    func testDestinationCoordinateUsesLegacyFallback() {
        XCTAssertEqual(
            GlobeCoordinate.coordinate(for: "paris", destination: nil),
            GlobeCoordinate(latitude: 48.8566, longitude: 2.3522)
        )
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
