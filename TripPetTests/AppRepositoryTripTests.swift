import XCTest
@testable import TripPet

@MainActor
final class AppRepositoryTripTests: XCTestCase {
    func testGiftTicketCreatesTravelingTrip() {
        let repository = AppRepository(seed: Self.makeSeed())
        let giftedAt = Self.date(hour: 9)

        repository.giftTicket(sourceSteps: 4_200, ticketCount: 1, date: giftedAt)

        XCTAssertEqual(repository.tickets.count, 1)
        XCTAssertEqual(repository.trips.count, 1)
        XCTAssertEqual(repository.trips.first?.animalId, "cat")
        XCTAssertEqual(repository.trips.first?.destination, "巴黎")
        XCTAssertEqual(repository.trips.first?.status, .traveling)
        XCTAssertEqual(repository.travelWishes.first?.status, .traveling)
    }

    func testActiveTripCanBeReadAfterGift() {
        let repository = AppRepository(seed: Self.makeSeed())

        repository.giftTicket(sourceSteps: 5_000, ticketCount: 1, date: Self.date(hour: 10))

        XCTAssertEqual(repository.activeTrip?.destination, "巴黎")
        XCTAssertEqual(repository.activeTrip?.status, .traveling)
    }

    func testCompletingTripAddsGeneratedPostcard() {
        let repository = AppRepository(seed: Self.makeSeed())
        let scheduler = PostcardScheduler()
        let destination = ManifestDestination(
            id: "paris",
            displayName: "巴黎",
            landmarkAssetName: "destination_paris_line",
            stampAssetName: "stamp_paris",
            routeMapAssetName: "trip_route_map_paris",
            primaryColor: "#7AA7B8",
            postcardTitleTemplate: "{animal}寄来的巴黎早安",
            postcardSubtitle: "旅途中寄来",
            postcardBodyTemplate: "{animal}在{destination}的街角停了一会儿。"
        )

        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(hour: 11))

        let trip = try! XCTUnwrap(repository.activeTrip)
        let animal = try! XCTUnwrap(repository.residentAnimal)
        let postcard = scheduler.makePostcard(
            for: trip,
            animal: animal,
            destination: destination,
            on: Self.date(day: 4, hour: 8)
        )

        XCTAssertTrue(repository.completeTrip(trip, postcard: postcard))

        XCTAssertNil(repository.activeTrip)
        XCTAssertEqual(repository.trips.first?.status, .completed)
        XCTAssertEqual(repository.travelWishes.first?.status, .completed)
        XCTAssertEqual(repository.postcards.count, 1)
        XCTAssertEqual(repository.postcards.first?.tripId, trip.id)
        XCTAssertEqual(repository.postcards.first?.destinationAssetName, "destination_paris_line")
        XCTAssertEqual(repository.postcards.first?.stampAssetName, "stamp_paris")
        XCTAssertFalse(repository.postcards.first?.isRead ?? true)
    }

    func testPostcardSchedulerUsesDestinationCopyTemplate() throws {
        let scheduler = PostcardScheduler()
        let animal = Animal(
            id: "cat",
            name: "小猫",
            species: "cat",
            personality: "安静",
            homeAssetName: "animal_cat_home",
            selfieAssetName: "animal_cat_selfie",
            visitorAssetName: "animal_cat_home",
            discoveredAt: Self.date(),
            isResident: true
        )
        let destination = ManifestDestination(
            id: "iceland",
            displayName: "冰岛",
            landmarkAssetName: "destination_iceland_line",
            stampAssetName: "stamp_iceland",
            routeMapAssetName: "trip_route_map_iceland",
            primaryColor: "#A9C9D8",
            postcardTitleTemplate: "{animal}寄来的风声",
            postcardSubtitle: "第 1 封来信",
            postcardBodyTemplate: "{animal}在{destination}听见风从海边跑过去。"
        )
        let trip = Trip(
            id: "trip_iceland",
            animalId: animal.id,
            destinationId: destination.id,
            destination: destination.displayName,
            departedAt: Self.date(day: 1),
            expectedReturnAt: Self.date(day: 3),
            status: .traveling
        )

        let postcard = scheduler.makePostcard(
            for: trip,
            animal: animal,
            destination: destination,
            on: Self.date(day: 2)
        )

        XCTAssertEqual(postcard.title, "小猫寄来的风声")
        XCTAssertEqual(postcard.subtitle, "第 1 封来信")
        XCTAssertEqual(postcard.body, "小猫在冰岛听见风从海边跑过去。")
        XCTAssertEqual(postcard.destinationAssetName, "destination_iceland_line")
        XCTAssertEqual(postcard.stampAssetName, "stamp_iceland")
    }

    func testContentManifestDestinationCopyDecodes() throws {
        let json = """
        {
          "version": 1,
          "animals": [],
          "destinations": [
            {
              "id": "paris",
              "displayName": "巴黎",
              "landmarkAssetName": "destination_paris_line",
              "stampAssetName": "stamp_paris",
              "routeMapAssetName": "trip_route_map_paris",
              "primaryColor": "#D8B36A",
              "postcardTitleTemplate": "{animal}寄来的巴黎早安",
              "postcardSubtitle": "旅途中寄来",
              "postcardBodyTemplate": "{animal}在{destination}写信。"
            }
          ],
          "postcards": [],
          "rules": {
            "stepsPerTicket": 3000,
            "dailyTicketLimit": 1
          }
        }
        """

        let manifest = try JSONDecoder().decode(ContentManifest.self, from: Data(json.utf8))

        XCTAssertEqual(manifest.destinations.first?.postcardTitleTemplate, "{animal}寄来的巴黎早安")
        XCTAssertEqual(manifest.destinations.first?.postcardBodyTemplate, "{animal}在{destination}写信。")
    }

    func testAnimalVisitServiceUsesStableVisualOnlyRotation() {
        let service = AnimalVisitService()
        let animals = SeedData.preview.animals

        XCTAssertEqual(service.visitingAnimal(from: animals, on: Self.date(day: 1))?.id, "rabbit")
        XCTAssertNil(service.visitingAnimal(from: animals, on: Self.date(day: 2)))
        XCTAssertEqual(service.visitingAnimal(from: animals, on: Self.date(day: 4))?.id, "dog")
    }

    func testDuplicateGiftDoesNotCreateDuplicateTrip() {
        let repository = AppRepository(seed: Self.makeSeed())
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: giftedAt.addingTimeInterval(60))

        XCTAssertEqual(repository.tickets.count, 1)
        XCTAssertEqual(repository.trips.count, 1)
        XCTAssertEqual(repository.activeTrip?.destination, "巴黎")
    }

    func testCabinRefreshesNextAnimalAfterEmptyHour() {
        let repository = AppRepository(seed: Self.makeSeed())
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)

        XCTAssertNil(repository.currentCabinAnimal)
        XCTAssertTrue(repository.isCabinEmpty)

        repository.refreshCabinLodging(on: giftedAt.addingTimeInterval(60 * 60 + 1))

        XCTAssertEqual(repository.currentCabinAnimal?.id, "cat")
        XCTAssertFalse(repository.isCabinEmpty)
    }

    func testCabinLodgingDoesNotPromoteVisitorsToResidents() {
        let repository = AppRepository(seed: .preview)
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)
        repository.refreshCabinLodging(on: giftedAt.addingTimeInterval(60 * 60 + 1))

        XCTAssertEqual(repository.currentCabinAnimal?.id, "cat")
    }

    func testCabinStopsAfterThreeDeparturesAndResetsNextDay() {
        let repository = AppRepository(seed: Self.makeSeed())
        let first = Self.date(hour: 8)
        let second = Self.date(hour: 10)
        let third = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: first)
        repository.refreshCabinLodging(on: second)
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: second)
        repository.refreshCabinLodging(on: third)
        repository.giftTicket(sourceSteps: 7_500, ticketCount: 1, date: third)

        XCTAssertEqual(repository.tickets.count, 3)
        XCTAssertTrue(repository.hasReachedDailyAnimalLimit)

        repository.refreshCabinLodging(on: Self.date(day: 2, hour: 8))

        XCTAssertEqual(repository.cabinLodging.dispatchedCount, 0)
        XCTAssertEqual(repository.currentCabinAnimal?.id, "cat")
    }

    func testSwiftDataStorePersistsRepositoryStateAcrossRepositoryInstances() throws {
        let store = try SwiftDataUserStateStore(inMemory: true)
        let seed = Self.makeSeed()
        let repository = AppRepository(seed: seed, store: store)
        let scheduler = PostcardScheduler()
        let destination = try XCTUnwrap(seed.destinations.first)

        repository.completeOnboarding()
        repository.dismissHealthGuide()
        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(hour: 11))

        let trip = try XCTUnwrap(repository.activeTrip)
        let animal = try XCTUnwrap(repository.residentAnimal)
        let postcard = scheduler.makePostcard(
            for: trip,
            animal: animal,
            destination: destination,
            on: Self.date(day: 4, hour: 8)
        )
        XCTAssertTrue(repository.completeTrip(trip, postcard: postcard))
        repository.markPostcardRead(postcard)

        let restoredRepository = AppRepository(seed: seed, store: store)

        XCTAssertTrue(restoredRepository.userFlags.onboardingCompleted)
        XCTAssertTrue(restoredRepository.userFlags.healthGuideDismissed)
        XCTAssertEqual(restoredRepository.tickets.count, 1)
        XCTAssertEqual(restoredRepository.trips.first?.status, .completed)
        XCTAssertEqual(restoredRepository.postcards.first?.tripId, trip.id)
        XCTAssertTrue(restoredRepository.postcards.first?.isRead ?? false)
    }

    func testEligibleTripRevealsPostcardOnlyOnce() throws {
        let repository = AppRepository(seed: Self.makeSeed())
        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        let didReveal = repository.revealEligiblePostcards(
            scheduler: PostcardScheduler(),
            destinations: Self.makeSeed().destinations,
            on: Self.date(day: 3, hour: 9)
        )
        let didRevealAgain = repository.revealEligiblePostcards(
            scheduler: PostcardScheduler(),
            destinations: Self.makeSeed().destinations,
            on: Self.date(day: 3, hour: 10)
        )

        XCTAssertTrue(didReveal)
        XCTAssertFalse(didRevealAgain)
        XCTAssertNil(repository.activeTrip)
        XCTAssertEqual(repository.postcards.count, 1)
        XCTAssertEqual(repository.trips.first?.status, .completed)
    }

    func testPersistedDestinationIdRehydratesLatestManifestCatalog() throws {
        let store = try SwiftDataUserStateStore(inMemory: true)
        let repository = AppRepository(seed: Self.makeSeed(), store: store)

        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        let updatedSeed = Self.makeSeed(
            destinationName: "巴黎新名字",
            destinationAssetName: "destination_iceland_line"
        )
        let restoredRepository = AppRepository(seed: updatedSeed, store: store)

        XCTAssertEqual(restoredRepository.activeTrip?.destinationId, "paris")
        XCTAssertEqual(restoredRepository.activeTrip?.destination, "巴黎新名字")
        XCTAssertEqual(restoredRepository.travelWishes.first?.destination, "巴黎新名字")
        XCTAssertEqual(restoredRepository.travelWishes.first?.destinationAssetName, "destination_iceland_line")
    }

    private static func makeSeed(
        destinationName: String = "巴黎",
        destinationAssetName: String = "destination_paris_line"
    ) -> SeedData {
        SeedData(
            animals: [
                Animal(
                    id: "cat",
                    name: "小猫",
                    species: "cat",
                    personality: "安静、好奇、喜欢地图",
                    homeAssetName: "animal_cat_home",
                    selfieAssetName: "animal_cat_selfie",
                    visitorAssetName: "animal_cat_home",
                    discoveredAt: date(),
                    isResident: true
                )
            ],
            travelWishes: [
                TravelWish(
                    id: "wish_paris_cat",
                    animalId: "cat",
                    destinationId: "paris",
                    destination: destinationName,
                    destinationAssetName: destinationAssetName,
                    requiredTickets: 1,
                    status: .waiting,
                    createdAt: date()
                )
            ],
            trips: [],
            postcards: [],
            destinations: [
                ManifestDestination(
                    id: "paris",
                    displayName: destinationName,
                    landmarkAssetName: destinationAssetName,
                    stampAssetName: "stamp_paris",
                    routeMapAssetName: "trip_route_map_paris",
                    primaryColor: "#D8B36A",
                    postcardTitleTemplate: "{animal}寄来的巴黎早安",
                    postcardSubtitle: "旅途中寄来",
                    postcardBodyTemplate: "{animal}在{destination}的街角停了一会儿。"
                )
            ]
        )
    }

    private static func date(day: Int = 1, hour: Int = 0) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 6,
            day: day,
            hour: hour
        ).date!
    }
}
