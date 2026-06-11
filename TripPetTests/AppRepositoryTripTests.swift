import XCTest
@testable import TripPet

@MainActor
final class AppRepositoryTripTests: XCTestCase {
    func testGiftTicketCreatesTravelingTrip() {
        let repository = AppRepository(seed: Self.makeSeed(), postcardScheduler: Self.fixedScheduler())
        let giftedAt = Self.date(hour: 9)

        repository.giftTicket(sourceSteps: 4_200, ticketCount: 1, date: giftedAt)

        XCTAssertEqual(repository.tickets.count, 1)
        XCTAssertEqual(repository.trips.count, 1)
        XCTAssertEqual(repository.trips.first?.animalId, "cat")
        XCTAssertEqual(repository.trips.first?.destination, "巴黎")
        XCTAssertEqual(repository.trips.first?.status, .traveling)
        XCTAssertEqual(repository.trips.first?.expectedReturnAt, giftedAt.addingTimeInterval(60 * 60 * 36))
        XCTAssertEqual(repository.trips.first?.postcardPlan.count, 2)
        XCTAssertEqual(repository.trips.first?.postcardPlan.first?.dueAt, giftedAt.addingTimeInterval(60 * 60 * 5))
        XCTAssertEqual(repository.trips.first?.postcardPlan.last?.dueAt, giftedAt.addingTimeInterval(60 * 60 * 16))
        XCTAssertEqual(repository.travelWishes.first?.status, .traveling)
    }

    func testPostcardPlanRandomWindowsStayInRange() throws {
        let departedAt = Self.date(hour: 9)
        let lowPlan = PostcardScheduler(randomOffset: { $0.lowerBound }).makePostcardPlan(departedAt: departedAt)
        let highPlan = PostcardScheduler(randomOffset: { $0.upperBound }).makePostcardPlan(departedAt: departedAt)

        XCTAssertEqual(lowPlan[0].dueAt, departedAt.addingTimeInterval(60 * 60 * 5))
        XCTAssertEqual(highPlan[0].dueAt, departedAt.addingTimeInterval(60 * 60 * 8))
        XCTAssertEqual(lowPlan[1].dueAt, departedAt.addingTimeInterval(60 * 60 * 16))
        XCTAssertEqual(highPlan[1].dueAt, departedAt.addingTimeInterval(60 * 60 * 24))
    }

    func testActiveTripCanBeReadAfterGift() {
        let repository = AppRepository(seed: Self.makeSeed())

        repository.giftTicket(sourceSteps: 5_000, ticketCount: 1, date: Self.date(hour: 10))

        XCTAssertEqual(repository.activeTrip?.destination, "巴黎")
        XCTAssertEqual(repository.activeTrip?.status, .traveling)
    }

    func testFirstImmediateTicketDeliversAirportPostcard() throws {
        let repository = AppRepository(seed: Self.makeSeed(), postcardScheduler: Self.fixedScheduler())
        let giftedAt = Self.date(hour: 9)

        let trip = try XCTUnwrap(
            repository.giftTicket(
                sourceSteps: 0,
                ticketCount: 1,
                date: giftedAt,
                isFirstImmediateTicket: true
            )
        )

        let postcard = try XCTUnwrap(repository.postcards.first)
        XCTAssertEqual(postcard.id, "postcard_first_airport_\(trip.id)")
        XCTAssertEqual(postcard.tripId, trip.id)
        XCTAssertEqual(postcard.destination, "机场")
        XCTAssertEqual(postcard.title, "小猫寄来的第一张明信片")
        XCTAssertEqual(postcard.destinationAssetName, "postcard_destination_airport")
        XCTAssertEqual(postcard.stampAssetName, "postcard_stamp_airport")
        XCTAssertEqual(postcard.templateAssetName, "postcard_base_portrait")
        XCTAssertFalse(postcard.isRead)
        XCTAssertTrue(repository.userFlags.firstImmediateTicketGifted)
        XCTAssertTrue(repository.userFlags.firstAirportPostcardDelivered)
    }

    func testFirstAirportPostcardBackfillsForExistingFirstTicketState() throws {
        let seed = Self.makeSeed()
        let trip = Trip(
            id: "legacy-first-trip",
            animalId: "cat",
            destinationId: "paris",
            destination: "巴黎",
            departedAt: Self.date(hour: 9),
            expectedReturnAt: Self.date(day: 2, hour: 21),
            status: .traveling,
            postcardPlan: Self.fixedScheduler().makePostcardPlan(departedAt: Self.date(hour: 9)),
            completedAt: nil
        )
        let savedState = AppUserState(
            travelWishes: seed.travelWishes,
            trips: [trip],
            postcards: [],
            tickets: [
                Ticket(
                    id: UUID(),
                    date: Self.date(hour: 9),
                    sourceSteps: 0,
                    ticketCount: 1,
                    giftedAt: Self.date(hour: 9)
                )
            ],
            flags: AppUserFlags(firstImmediateTicketGifted: true),
            cabinLodging: CabinLodgingState.initial(on: Self.date(hour: 9), animalIds: [])
        )

        let repository = AppRepository(seed: seed, store: InMemoryUserStateStore(savedState: savedState))

        XCTAssertEqual(repository.postcards.count, 1)
        XCTAssertEqual(repository.postcards.first?.id, "postcard_first_airport_legacy-first-trip")
        XCTAssertEqual(repository.postcards.first?.destinationAssetName, "postcard_destination_airport")
        XCTAssertTrue(repository.userFlags.firstAirportPostcardDelivered)
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
        let animals = [
            Self.makeAnimal(id: "cat", isResident: true),
            Self.makeAnimal(id: "visitor_unknown"),
            Self.makeAnimal(id: "dog"),
            Self.makeAnimal(id: "rabbit")
        ]

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

    func testCabinRefreshesNextAnimalImmediatelyAfterDeparture() {
        let repository = AppRepository(seed: Self.makeMultiAnimalSeed(primaryCount: 2, backupCount: 0))
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)

        XCTAssertEqual(repository.currentCabinAnimal?.id, "primary_2")
        XCTAssertFalse(repository.isCabinEmpty)
    }

    func testBackupAnimalsAppearOnlyAfterPrimaryPoolIsUnavailable() {
        let repository = AppRepository(seed: Self.makeMultiAnimalSeed(primaryCount: 2, backupCount: 1))
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)
        XCTAssertEqual(repository.currentCabinAnimal?.id, "primary_2")

        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: giftedAt.addingTimeInterval(60))
        XCTAssertEqual(repository.currentCabinAnimal?.id, "backup_1")
    }

    func testCabinStopsAfterThreeDeparturesAndResetsNextDay() {
        let repository = AppRepository(seed: Self.makeMultiAnimalSeed(primaryCount: 3, backupCount: 0))
        let first = Self.date(hour: 8)
        let second = Self.date(hour: 10)
        let third = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: first)
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: second)
        repository.giftTicket(sourceSteps: 7_500, ticketCount: 1, date: third)

        XCTAssertEqual(repository.tickets.count, 3)
        XCTAssertTrue(repository.hasReachedDailyAnimalLimit)

        repository.refreshCabinLodging(on: Self.date(day: 2, hour: 8))

        XCTAssertEqual(repository.cabinLodging.dispatchedCount, 0)
        XCTAssertNil(repository.currentCabinAnimal)
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

    func testSwiftDataStoreDoesNotHydrateSeedPostcardsForEmptyMailbox() throws {
        let store = try SwiftDataUserStateStore(inMemory: true)
        let seed = Self.makeSeed(postcards: SeedData.previewPostcards)

        let repository = AppRepository(seed: seed, store: store)

        XCTAssertTrue(repository.postcards.isEmpty)
    }

    func testEligibleTripRevealsPostcardOnlyOnce() throws {
        let scheduler = Self.fixedScheduler()
        let repository = AppRepository(seed: Self.makeSeed(), postcardScheduler: scheduler)
        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        let didReveal = repository.revealEligiblePostcards(
            scheduler: scheduler,
            destinations: Self.makeSeed().destinations,
            on: Self.date(day: 3, hour: 9)
        )
        let didRevealAgain = repository.revealEligiblePostcards(
            scheduler: scheduler,
            destinations: Self.makeSeed().destinations,
            on: Self.date(day: 3, hour: 10)
        )

        XCTAssertTrue(didReveal)
        XCTAssertFalse(didRevealAgain)
        XCTAssertNil(repository.activeTrip)
        XCTAssertEqual(repository.postcards.count, 2)
        XCTAssertEqual(repository.trips.first?.status, .completed)
    }

    func testPostcardsRevealAcrossThirtySixHourTrip() throws {
        let scheduler = Self.fixedScheduler()
        let seed = Self.makeSeed()
        let repository = AppRepository(seed: seed, postcardScheduler: scheduler)
        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        XCTAssertFalse(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 1, hour: 13)))
        XCTAssertEqual(repository.postcards.count, 0)

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 1, hour: 15)))
        XCTAssertEqual(repository.postcards.count, 1)
        XCTAssertEqual(repository.trips.first?.status, .traveling)

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 2, hour: 6)))
        XCTAssertEqual(repository.postcards.count, 2)
        XCTAssertEqual(repository.trips.first?.status, .traveling)

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 2, hour: 21)))
        XCTAssertEqual(repository.trips.first?.status, .completed)
        XCTAssertEqual(repository.trips.first?.completedAt, Self.date(day: 2, hour: 21))
        XCTAssertEqual(repository.currentCabinAnimal?.id, "cat")
    }

    func testLateRefreshRevealsBothPostcardsAndCompletesTrip() throws {
        let scheduler = Self.fixedScheduler()
        let seed = Self.makeSeed()
        let repository = AppRepository(seed: seed, postcardScheduler: scheduler)
        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 3, hour: 1)))

        XCTAssertNil(repository.activeTrip)
        XCTAssertEqual(repository.postcards.count, 2)
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
        destinationAssetName: String = "destination_paris_line",
        postcards: [Postcard] = []
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
            postcards: postcards,
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

    private static func makeMultiAnimalSeed(primaryCount: Int, backupCount: Int) -> SeedData {
        let primaryAnimals = (0..<primaryCount).map { offset in
            let index = offset + 1
            return makeAnimal(
                id: "primary_\(index)",
                name: "初始\(index)",
                isResident: index == 1,
                pool: .primary
            )
        }
        let backupAnimals = (0..<backupCount).map { offset in
            let index = offset + 1
            return makeAnimal(
                id: "backup_\(index)",
                name: "备用\(index)",
                pool: .backup
            )
        }
        let animals = primaryAnimals + backupAnimals
        let destinations = [
            ManifestDestination(
                id: "paris",
                displayName: "巴黎",
                landmarkAssetName: "destination_paris_line",
                stampAssetName: "stamp_paris",
                routeMapAssetName: "trip_route_map_paris",
                primaryColor: "#D8B36A",
                postcardTitleTemplate: "{animal}寄来的巴黎早安",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "{animal}在{destination}的街角停了一会儿。"
            )
        ]

        return SeedData(
            animals: animals,
            travelWishes: [],
            trips: [],
            postcards: [],
            destinations: destinations
        )
    }

    private static func makeAnimal(
        id: String,
        name: String? = nil,
        isResident: Bool = false,
        pool: AnimalPool = .primary
    ) -> Animal {
        Animal(
            id: id,
            name: name ?? id,
            species: id.contains("dog") ? "dog" : "cat",
            personality: "安静",
            homeAssetName: id.contains("dog") ? "animal_dog_home" : "animal_cat_home",
            selfieAssetName: "animal_cat_selfie",
            visitorAssetName: id.contains("dog") ? "animal_dog_visitor" : "animal_cat_home",
            discoveredAt: isResident ? date() : nil,
            isResident: isResident,
            pool: pool
        )
    }

    private static func fixedScheduler() -> PostcardScheduler {
        PostcardScheduler(randomOffset: { $0.lowerBound })
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
