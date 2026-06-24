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
        XCTAssertEqual(repository.trips.first?.expectedReturnAt, giftedAt.addingTimeInterval(60 * 60 * 18))
        XCTAssertEqual(repository.trips.first?.postcardPlan.count, 2)
        XCTAssertEqual(repository.trips.first?.postcardPlan.first?.dueAt, giftedAt.addingTimeInterval(60 * 60 * 2))
        XCTAssertEqual(repository.trips.first?.postcardPlan.last?.dueAt, giftedAt.addingTimeInterval(60 * 60 * 6))
        XCTAssertEqual(repository.travelWishes.first?.status, .traveling)
    }

    func testPostcardPlanRandomWindowsStayInRange() throws {
        let departedAt = Self.date(hour: 9)
        let lowPlan = PostcardScheduler(randomOffset: { $0.lowerBound }).makePostcardPlan(departedAt: departedAt)
        let highPlan = PostcardScheduler(randomOffset: { $0.upperBound }).makePostcardPlan(departedAt: departedAt)

        XCTAssertEqual(lowPlan[0].dueAt, departedAt.addingTimeInterval(60 * 60 * 2))
        XCTAssertEqual(highPlan[0].dueAt, departedAt.addingTimeInterval(60 * 60 * 3))
        XCTAssertEqual(lowPlan[1].dueAt, departedAt.addingTimeInterval(60 * 60 * 6))
        XCTAssertEqual(highPlan[1].dueAt, departedAt.addingTimeInterval(60 * 60 * 8))
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

    func testMultipleDeparturesDoNotReuseActiveDestination() {
        let repository = AppRepository(
            seed: Self.makeMultiAnimalSeed(primaryCount: 3, backupCount: 0),
            randomDestinationIndex: { _ in 0 }
        )
        let first = Self.date(hour: 8)
        let second = Self.date(hour: 10)
        let third = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: first)
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: second)
        repository.giftTicket(sourceSteps: 7_500, ticketCount: 1, date: third)

        let activeDestinationIds = repository.activeTravelTrips.map(\.destinationId)
        XCTAssertEqual(activeDestinationIds.count, 3)
        XCTAssertEqual(Set(activeDestinationIds).count, 3)
    }

    func testCompletedDestinationCanBeSelectedAgain() throws {
        let seed = Self.makeMultiAnimalSeed(primaryCount: 1, backupCount: 0, destinationCount: 1)
        let repository = AppRepository(seed: seed, randomDestinationIndex: { _ in 0 })
        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: Self.date(day: 1, hour: 8))
        let firstTrip = try XCTUnwrap(repository.trips.first)

        XCTAssertTrue(repository.completeTrip(firstTrip, postcard: nil))
        repository.refreshCabinLodging(on: Self.date(day: 2, hour: 8))
        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: Self.date(day: 2, hour: 9))

        XCTAssertEqual(repository.trips.count, 2)
        XCTAssertEqual(repository.trips[0].destinationId, repository.trips[1].destinationId)
    }

    func testOccupiedWaitingWishIsReassignedBeforeDeparture() {
        let seed = Self.makeMultiAnimalSeed(
            primaryCount: 2,
            backupCount: 0,
            destinationCount: 2,
            duplicateInitialWishDestination: true
        )
        let repository = AppRepository(seed: seed, randomDestinationIndex: { _ in 0 })
        let first = Self.date(hour: 8)
        let second = Self.date(hour: 10)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: first)
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: second)

        XCTAssertEqual(repository.trips.count, 2)
        XCTAssertNotEqual(repository.trips[0].destinationId, repository.trips[1].destinationId)
        XCTAssertEqual(repository.trips[1].animalId, "primary_2")
    }

    func testGiftReturnsNilWhenNoDestinationIsAvailable() {
        let repository = AppRepository(
            seed: Self.makeMultiAnimalSeed(primaryCount: 2, backupCount: 0, destinationCount: 1),
            randomDestinationIndex: { _ in 0 }
        )
        let first = Self.date(hour: 8)
        let second = Self.date(hour: 10)

        XCTAssertNotNil(repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: first))
        XCTAssertNil(repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: second))

        XCTAssertEqual(repository.tickets.count, 1)
        XCTAssertEqual(repository.trips.count, 1)
    }

    func testNewRepositoryStartsWithOnlyMojiCatWhenAvailable() {
        let repository = AppRepository(seed: .preview)

        XCTAssertEqual(repository.cabinLodging.presentAnimalIds, ["moji_cat"])
        XCTAssertEqual(repository.cabinAnimals.map(\.id), ["moji_cat"])
    }

    func testFirstImmediateTicketUnlocksRemainingIdleAnimals() {
        let repository = AppRepository(seed: .preview, randomDestinationIndex: { _ in 0 })
        let giftedAt = Self.date(hour: 12)

        let trip = repository.giftTicket(
            sourceSteps: 0,
            ticketCount: 1,
            animalId: "moji_cat",
            date: giftedAt,
            isFirstImmediateTicket: true
        )

        XCTAssertEqual(trip?.animalId, "moji_cat")
        XCTAssertEqual(repository.activeTravelTrips.map(\.animalId), ["moji_cat"])
        XCTAssertEqual(repository.cabinAnimals.count, 8)
        XCTAssertFalse(repository.cabinLodging.presentAnimalIds.contains("moji_cat"))
    }

    func testCompletedTripRestoresAnimalToIdleCabinSet() throws {
        let repository = AppRepository(seed: .preview, randomDestinationIndex: { _ in 0 })
        let giftedAt = Self.date(hour: 12)
        let trip = try XCTUnwrap(
            repository.giftTicket(
                sourceSteps: 0,
                ticketCount: 1,
                animalId: "moji_cat",
                date: giftedAt,
                isFirstImmediateTicket: true
            )
        )

        XCTAssertEqual(repository.cabinAnimals.count, 8)

        XCTAssertTrue(repository.completeTrip(trip, postcard: nil))

        XCTAssertTrue(repository.activeTravelTrips.isEmpty)
        XCTAssertEqual(repository.cabinAnimals.count, 9)
        XCTAssertTrue(repository.cabinLodging.presentAnimalIds.contains("moji_cat"))
    }

    func testLegacyEightAnimalCabinStateBackfillsToAllIdleAnimals() {
        let seed = SeedData.preview
        let missingMojiIds = seed.animals.map(\.id).filter { $0 != "moji_cat" }
        let savedState = AppUserState(
            travelWishes: seed.travelWishes,
            trips: [],
            postcards: [],
            tickets: [],
            flags: AppUserFlags(firstImmediateTicketGifted: true),
            cabinLodging: CabinLodgingState.initial(on: Self.date(), animalIds: missingMojiIds)
        )

        let repository = AppRepository(seed: seed, store: InMemoryUserStateStore(savedState: savedState))

        XCTAssertEqual(repository.cabinAnimals.count, 9)
        XCTAssertEqual(repository.cabinLodging.presentAnimalIds, seed.animals.map(\.id))
    }

    func testCabinShowsAllRemainingIdleAnimalsAfterDeparture() {
        let repository = AppRepository(seed: Self.makeMultiAnimalSeed(primaryCount: 3, backupCount: 0))
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)

        XCTAssertEqual(repository.cabinLodging.presentAnimalIds, ["primary_2", "primary_3"])
        XCTAssertFalse(repository.isCabinEmpty)
    }

    func testPrimaryAndBackupAnimalsBothAppearWhenIdleAfterUnlock() {
        let repository = AppRepository(seed: Self.makeMultiAnimalSeed(primaryCount: 2, backupCount: 1))
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)
        XCTAssertEqual(repository.cabinLodging.presentAnimalIds, ["primary_2", "backup_1"])

        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: giftedAt.addingTimeInterval(60))
        XCTAssertEqual(repository.cabinLodging.presentAnimalIds, ["backup_1"])
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

    func testFirstImmediateTicketDoesNotCountTowardDailyStepFundedLimit() {
        let repository = AppRepository(seed: Self.makeMultiAnimalSeed(primaryCount: 4, backupCount: 0, destinationCount: 4))
        let first = Self.date(hour: 8)
        let second = Self.date(hour: 10)
        let third = Self.date(hour: 12)
        let fourth = Self.date(hour: 14)

        repository.giftTicket(sourceSteps: 0, ticketCount: 1, date: first, isFirstImmediateTicket: true)
        XCTAssertEqual(repository.giftedTicketCountToday(on: first), 1)
        XCTAssertEqual(repository.dailyLimitedTicketCountToday(on: first), 0)
        XCTAssertFalse(repository.hasReachedDailyAnimalLimit)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: second)
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: third)
        repository.giftTicket(sourceSteps: 7_500, ticketCount: 1, date: fourth)

        XCTAssertEqual(repository.tickets.count, 4)
        XCTAssertEqual(repository.giftedTicketCountToday(on: first), 4)
        XCTAssertEqual(repository.dailyLimitedTicketCountToday(on: first), 3)
        XCTAssertTrue(repository.hasReachedDailyAnimalLimit)
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

    func testMarkPostcardReadIsIdempotentAndSkipsUnneededPersistence() throws {
        let seed = Self.makeSeed(postcards: [
            Self.makePostcard(id: "postcard-unread", isRead: false)
        ])
        let store = CountingUserStateStore(state: AppUserState(seed: seed))
        let repository = AppRepository(seed: seed, store: store)
        let postcard = try XCTUnwrap(repository.postcards.first)

        XCTAssertTrue(repository.markPostcardRead(postcard))
        XCTAssertTrue(repository.postcards.first?.isRead ?? false)
        XCTAssertEqual(store.markPostcardReadCount, 1)
        XCTAssertEqual(store.saveCount, 0)

        let readPostcard = try XCTUnwrap(repository.postcards.first)
        XCTAssertFalse(repository.markPostcardRead(readPostcard))
        XCTAssertFalse(repository.markPostcardRead(Self.makePostcard(id: "missing", isRead: false)))
        XCTAssertEqual(store.markPostcardReadCount, 1)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testSwiftDataStoreTargetedPostcardReadUpdateKeepsOtherState() throws {
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
        XCTAssertTrue(repository.markPostcardRead(postcard))

        let restoredRepository = AppRepository(seed: seed, store: store)

        XCTAssertTrue(restoredRepository.userFlags.onboardingCompleted)
        XCTAssertTrue(restoredRepository.userFlags.healthGuideDismissed)
        XCTAssertEqual(restoredRepository.tickets.count, 1)
        XCTAssertEqual(restoredRepository.trips.first?.status, .completed)
        XCTAssertEqual(restoredRepository.travelWishes.first?.status, .completed)
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

    func testPostcardsRevealAcrossEighteenHourTrip() throws {
        let scheduler = Self.fixedScheduler()
        let seed = Self.makeSeed()
        let repository = AppRepository(seed: seed, postcardScheduler: scheduler)
        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        XCTAssertFalse(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 1, hour: 10)))
        XCTAssertEqual(repository.postcards.count, 0)

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 1, hour: 11)))
        XCTAssertEqual(repository.postcards.count, 1)
        XCTAssertEqual(repository.trips.first?.status, .traveling)

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 1, hour: 15)))
        XCTAssertEqual(repository.postcards.count, 2)
        XCTAssertEqual(repository.trips.first?.status, .traveling)

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 2, hour: 3)))
        XCTAssertEqual(repository.trips.first?.status, .completed)
        XCTAssertEqual(repository.trips.first?.completedAt, Self.date(day: 2, hour: 3))
        XCTAssertEqual(repository.currentCabinAnimal?.id, "cat")
    }

    func testRevealedPostcardsUseConsumableNarrativeLibraryWithoutRepeating() throws {
        let scheduler = Self.fixedScheduler()
        let seed = Self.makeNarrativeSeed()
        let repository = AppRepository(seed: seed, postcardScheduler: scheduler)
        let xiaomanBodies = Set(
            PostcardTextLibrary.narratives
                .filter { $0.animalKey == "xiaoman_hamster" }
                .map(\.body)
        )

        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 1, hour: 15)))
        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 2, hour: 6)))

        XCTAssertEqual(repository.postcards.count, 2)
        XCTAssertEqual(Set(repository.postcards.map(\.body)).count, 2)
        XCTAssertTrue(repository.postcards.allSatisfy { xiaomanBodies.contains($0.body) })
        XCTAssertEqual(repository.consumedPostcardTextIds.count, 2)
    }

    func testPostcardTextLibraryImportsVersionOnePointZeroSixMarkdownCorpus() {
        let counts = Dictionary(
            grouping: PostcardTextLibrary.narratives,
            by: \.animalKey
        ).mapValues(\.count)

        XCTAssertEqual(PostcardTextLibrary.narratives.count, 1_260)
        XCTAssertEqual(counts["xiaoman_hamster"], 140)
        XCTAssertEqual(counts["tangyuan_puppy"], 140)
        XCTAssertEqual(counts["moji_cat"], 140)
        XCTAssertEqual(counts["dengdeng_rabbit"], 140)
        XCTAssertEqual(counts["feifei_parrot"], 140)
        XCTAssertEqual(counts["xiaolu_guinea_pig"], 140)
        XCTAssertEqual(counts["deer_visitor"], 140)
        XCTAssertEqual(counts["fox_visitor"], 140)
        XCTAssertEqual(counts["bear_visitor"], 140)
    }

    func testNarrativeLibraryFallsBackToDestinationTemplateWhenAnimalTextsAreExhausted() throws {
        let scheduler = Self.fixedScheduler()
        let seed = Self.makeNarrativeSeed()
        let consumedIds = Set(
            PostcardTextLibrary.narratives
                .filter { $0.animalKey == "xiaoman_hamster" }
                .map(\.id)
        )
        let savedState = AppUserState(
            travelWishes: seed.travelWishes,
            trips: seed.trips,
            postcards: [],
            tickets: [],
            flags: AppUserFlags(),
            cabinLodging: CabinLodgingState.initial(on: Self.date(), animalId: "cat"),
            consumedPostcardTextIds: consumedIds
        )
        let repository = AppRepository(
            seed: seed,
            store: InMemoryUserStateStore(savedState: savedState),
            postcardScheduler: scheduler
        )

        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: Self.date(day: 1, hour: 9))

        XCTAssertTrue(repository.revealEligiblePostcards(scheduler: scheduler, destinations: seed.destinations, on: Self.date(day: 1, hour: 15)))
        XCTAssertEqual(repository.postcards.first?.body, "小猫在巴黎的街角停了一会儿。")
        XCTAssertEqual(repository.consumedPostcardTextIds, consumedIds)
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

    func testContentManifestUsesCanonicalAnimalIdentities() throws {
        let manifest = try Self.loadContentManifest()
        let expectedAnimals: [(id: String, name: String, species: String, homeAssetName: String)] = [
            ("xiaoman_hamster", "小满", "仓鼠", "animal_home_xiaoman_hamster"),
            ("tangyuan_puppy", "糖圆", "小狗", "animal_home_tangyuan_puppy"),
            ("moji_cat", "墨迹", "猫", "animal_home_moji_cat"),
            ("dengdeng_rabbit", "灯灯", "兔子", "animal_home_dengdeng_rabbit"),
            ("feifei_parrot", "飞飞", "鹦鹉", "animal_home_feifei_parrot"),
            ("xiaolu_guinea_pig", "小炉", "豚鼠", "animal_home_xiaolu_guinea_pig"),
            ("deer_visitor", "啾啾", "小鹿", "animal_home_jiujiu_deer"),
            ("fox_visitor", "埃尼", "小狐狸", "animal_home_aini_fox"),
            ("bear_visitor", "墩墩", "小熊", "animal_home_dundun_bear")
        ]

        XCTAssertEqual(manifest.animals.count, expectedAnimals.count)
        XCTAssertEqual(manifest.animals.map(\.id), expectedAnimals.map(\.id))
        for (animal, expectedAnimal) in zip(manifest.animals, expectedAnimals) {
            XCTAssertEqual(animal.displayName, expectedAnimal.name)
            XCTAssertEqual(animal.species, expectedAnimal.species)
            XCTAssertEqual(animal.homeAssetName, expectedAnimal.homeAssetName)
            XCTAssertEqual(animal.selfieAssetName, expectedAnimal.homeAssetName)
            XCTAssertEqual(animal.visitorAssetName, expectedAnimal.homeAssetName)
        }
        XCTAssertFalse(manifest.animals.map(\.displayName).contains { name in
            ["地图小猫", "邮路小狗", "折角小兔", "新伙伴", "安静小猫", "小路小狗"].contains(name)
        })
    }

    func testSeedPreviewUsesCanonicalAnimalIdentities() {
        XCTAssertEqual(SeedData.preview.animals.map(\.id), [
            "xiaoman_hamster",
            "tangyuan_puppy",
            "moji_cat",
            "dengdeng_rabbit",
            "feifei_parrot",
            "xiaolu_guinea_pig",
            "deer_visitor",
            "fox_visitor",
            "bear_visitor"
        ])
        XCTAssertEqual(SeedData.preview.animals.map(\.name), [
            "小满",
            "糖圆",
            "墨迹",
            "灯灯",
            "飞飞",
            "小炉",
            "啾啾",
            "埃尼",
            "墩墩"
        ])
        XCTAssertTrue(SeedData.preview.animals.allSatisfy { animal in
            animal.selfieAssetName == animal.homeAssetName &&
                animal.visitorAssetName == animal.homeAssetName &&
                animal.travelMarkerAssetName == animal.homeAssetName
        })
    }

    func testLegacyAnimalIdsMigrateToCanonicalIdsWhenCanonicalAnimalsExist() throws {
        let seed = SeedData.preview
        let legacyTrip = Trip(
            id: "legacy-map-cat-trip",
            animalId: "map_cat",
            destinationId: "paris",
            destination: "巴黎",
            departedAt: Self.date(day: 1, hour: 9),
            expectedReturnAt: Self.date(day: 1, hour: 21),
            status: .traveling
        )
        let savedState = AppUserState(
            travelWishes: [
                TravelWish(
                    id: "legacy-wish",
                    animalId: "cat",
                    destinationId: "paris",
                    destination: "巴黎",
                    destinationAssetName: "postcard_destination_paris",
                    requiredTickets: 1,
                    status: .waiting,
                    createdAt: Self.date()
                )
            ],
            trips: [legacyTrip],
            postcards: [],
            tickets: [],
            flags: AppUserFlags(),
            cabinLodging: CabinLodgingState.initial(
                on: Self.date(),
                animalIds: ["cat", "map_cat", "cat", "quiet_cat"]
            )
        )

        let repository = AppRepository(seed: seed, store: InMemoryUserStateStore(savedState: savedState))

        XCTAssertEqual(repository.travelWishes.first?.animalId, "xiaoman_hamster")
        XCTAssertEqual(repository.trips.first?.animalId, "deer_visitor")
        XCTAssertEqual(repository.animalName(for: "map_cat"), "啾啾")
        XCTAssertEqual(repository.cabinLodging.presentAnimalIds, ["moji_cat"])
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

    private static func makeNarrativeSeed() -> SeedData {
        var seed = makeSeed()
        seed.animals[0].homeAssetName = "animal_home_xiaoman_hamster"
        return seed
    }

    func testLocationDestinationCatalogDecodesThreeHundredCities() throws {
        let catalog = try Self.loadLocationDestinationCatalog()

        XCTAssertEqual(catalog.destinations.count, 300)
        XCTAssertEqual(Set(catalog.destinations.map(\.id)).count, 300)
    }

    func testLocationDestinationCatalogCoordinatesAreValid() throws {
        let catalog = try Self.loadLocationDestinationCatalog()

        for destination in catalog.destinations {
            let latitude = try XCTUnwrap(destination.latitude, destination.id)
            let longitude = try XCTUnwrap(destination.longitude, destination.id)
            XCTAssert((-90...90).contains(latitude), destination.id)
            XCTAssert((-180...180).contains(longitude), destination.id)
        }
    }

    func testWorldMapUsesCatalogCoordinatesAndLegacyFallback() throws {
        let catalogDestination = ManifestDestination(
            id: "test_city",
            displayName: "测试城市",
            landmarkAssetName: "postcard_destination_city_generic",
            stampAssetName: "postcard_stamp_city_generic",
            routeMapAssetName: "trip_route_map_generic",
            primaryColor: "#7AA7B8",
            postcardTitleTemplate: "{animal}寄来的测试城市来信",
            postcardSubtitle: "旅途中寄来",
            postcardBodyTemplate: "{animal}在{destination}写信。",
            latitude: 12.34,
            longitude: 56.78
        )

        XCTAssertEqual(
            WorldMapDestinationCoordinate.coordinate(for: "test_city", destination: catalogDestination),
            WorldMapDestinationCoordinate(latitude: 12.34, longitude: 56.78)
        )
        XCTAssertEqual(
            WorldMapDestinationCoordinate.coordinate(for: "paris", destination: nil),
            WorldMapDestinationCoordinate(latitude: 48.8566, longitude: 2.3522)
        )
        XCTAssertNil(WorldMapDestinationCoordinate.coordinate(for: "unknown_city", destination: nil))
    }

    func testTravelMarkerAssetUsesHomeAnimalResource() {
        let dog = Animal(
            id: "tangyuan_puppy",
            name: "糖圆",
            species: "小狗",
            personality: "活力过剩，喜欢把旅途小事故讲成现场播报",
            homeAssetName: "animal_home_tangyuan_puppy",
            selfieAssetName: "animal_home_tangyuan_puppy",
            visitorAssetName: "animal_home_tangyuan_puppy",
            discoveredAt: nil,
            isResident: false
        )

        XCTAssertEqual(dog.travelMarkerAssetName, "animal_home_tangyuan_puppy")
    }

    private static func makeMultiAnimalSeed(
        primaryCount: Int,
        backupCount: Int,
        destinationCount: Int? = nil,
        duplicateInitialWishDestination: Bool = false
    ) -> SeedData {
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
        let resolvedDestinationCount = destinationCount ?? max(3, primaryCount + backupCount)
        let destinations = (0..<resolvedDestinationCount).map { offset in
            let index = offset + 1
            return ManifestDestination(
                id: "destination_\(index)",
                displayName: "地点\(index)",
                landmarkAssetName: "destination_paris_line",
                stampAssetName: "stamp_paris",
                routeMapAssetName: "trip_route_map_paris",
                primaryColor: "#D8B36A",
                postcardTitleTemplate: "{animal}寄来的地点\(index)早安",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "{animal}在{destination}的街角停了一会儿。"
            )
        }
        let travelWishes = duplicateInitialWishDestination ? primaryAnimals.map { animal in
            TravelWish(
                id: "wish_destination_1_\(animal.id)",
                animalId: animal.id,
                destinationId: "destination_1",
                destination: "地点1",
                destinationAssetName: "destination_paris_line",
                requiredTickets: 1,
                status: .waiting,
                createdAt: date()
            )
        } : []

        return SeedData(
            animals: animals,
            travelWishes: travelWishes,
            trips: [],
            postcards: [],
            destinations: destinations
        )
    }

    private static func loadLocationDestinationCatalog() throws -> LocationDestinationCatalog {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        let catalogURL = repoRoot
            .appendingPathComponent("TripPet")
            .appendingPathComponent("Resources")
            .appendingPathComponent("LocationDestinationCatalog.json")
        let data = try Data(contentsOf: catalogURL)
        return try JSONDecoder().decode(LocationDestinationCatalog.self, from: data)
    }

    private static func loadContentManifest() throws -> ContentManifest {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        let manifestURL = repoRoot
            .appendingPathComponent("TripPet")
            .appendingPathComponent("Resources")
            .appendingPathComponent("ContentManifest.json")
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode(ContentManifest.self, from: data)
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

    private static func makePostcard(id: String, isRead: Bool) -> Postcard {
        Postcard(
            id: id,
            tripId: "trip-\(id)",
            destination: "巴黎",
            title: "小猫寄来的巴黎早安",
            body: "小猫在巴黎的街角停了一会儿。",
            imageAssetName: "postcard_destination_paris",
            templateAssetName: "postcard_template_classic",
            destinationAssetName: "postcard_destination_paris",
            stampAssetName: "postcard_stamp_paris",
            animalAssetName: "animal_cat_selfie",
            envelopeAssetName: "envelope_unread",
            sentAt: date(day: 1, hour: 12),
            subtitle: "旅途中寄来",
            isRead: isRead
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

@MainActor
private final class CountingUserStateStore: AppUserStateStore {
    private var state: AppUserState
    private(set) var saveCount = 0
    private(set) var markPostcardReadCount = 0

    init(state: AppUserState) {
        self.state = state
    }

    func load(seed _: SeedData) -> AppUserState {
        state
    }

    func save(_ state: AppUserState) {
        saveCount += 1
        self.state = state
    }

    func markPostcardRead(postcardId: String) {
        guard let index = state.postcards.firstIndex(where: { $0.id == postcardId }) else { return }
        markPostcardReadCount += 1
        state.postcards[index].isRead = true
    }
}
