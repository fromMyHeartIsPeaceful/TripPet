import XCTest
@testable import TripPet

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

    func testPostcardNotificationPayloadRoutesToMailboxTab() {
        XCTAssertEqual(
            PostcardNotificationService.targetTab(from: ["target": "mailbox", "postcardId": "postcard-1"]),
            .mailbox
        )
        XCTAssertNil(PostcardNotificationService.targetTab(from: ["target": "cabin"]))
    }

    func testEnvironmentConsumesQueuedNotificationTabRequest() {
        let notificationService = RootTabNotificationService()
        let environment = AppEnvironment.preview(postcardNotificationService: notificationService)

        notificationService.tabRequestHandler?(.mailbox)

        XCTAssertEqual(environment.consumeNotificationTabRequest(), .mailbox)
        XCTAssertNil(environment.consumeNotificationTabRequest())
        XCTAssertNil(notificationService.requestedTab)
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
