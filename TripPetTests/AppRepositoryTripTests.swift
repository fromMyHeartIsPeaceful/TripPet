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
        XCTAssertEqual(repository.postcards.count, 2)
        let generatedPostcard = try! XCTUnwrap(repository.postcards.first { $0.id == postcard.id })
        XCTAssertEqual(generatedPostcard.tripId, trip.id)
        XCTAssertEqual(generatedPostcard.destinationAssetName, "destination_paris_line")
        XCTAssertEqual(generatedPostcard.stampAssetName, "stamp_paris")
        XCTAssertFalse(generatedPostcard.isRead)
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

    func testCabinShowsApproachingStateAndRefreshesNextAnimalAfterRandomDelay() throws {
        let repository = AppRepository(seed: Self.makeSeed())
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: giftedAt)

        XCTAssertNil(repository.currentCabinAnimal)
        XCTAssertTrue(repository.isCabinEmpty)
        XCTAssertTrue(repository.isNextAnimalApproaching)

        let emptyUntil = try XCTUnwrap(repository.cabinLodging.emptyUntil)
        XCTAssertGreaterThanOrEqual(emptyUntil.timeIntervalSince(giftedAt), 10 * 60)
        XCTAssertLessThanOrEqual(emptyUntil.timeIntervalSince(giftedAt), 30 * 60)

        repository.refreshCabinLodging(on: emptyUntil.addingTimeInterval(1))

        XCTAssertEqual(repository.currentCabinAnimal?.id, "cat")
        XCTAssertFalse(repository.isCabinEmpty)
        XCTAssertFalse(repository.isNextAnimalApproaching)
    }

    func testCabinLodgingRotatesToNextTravelAnimal() {
        let repository = AppRepository(seed: .preview)
        let giftedAt = Self.date(hour: 12)

        repository.giftTicket(
            sourceSteps: 5_500,
            ticketCount: 1,
            date: giftedAt,
            destinations: SeedData.preview.destinations
        )
        let emptyUntil = try! XCTUnwrap(repository.cabinLodging.emptyUntil)
        repository.refreshCabinLodging(on: emptyUntil.addingTimeInterval(1))

        XCTAssertEqual(repository.currentCabinAnimal?.id, "dog")
        XCTAssertFalse(repository.currentCabinAnimal?.isResident ?? true)
        XCTAssertTrue(repository.currentCabinAnimal?.canTravel ?? false)
    }

    func testCabinStopsAfterThreeDeparturesAndResetsNextDay() {
        let seed = SeedData.preview
        let repository = AppRepository(seed: seed)
        let first = Self.date(hour: 8)
        let second = Self.date(hour: 10)
        let third = Self.date(hour: 12)

        repository.giftTicket(sourceSteps: 5_500, ticketCount: 1, date: first, destinations: seed.destinations)
        repository.refreshCabinLodging(on: second)
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: second, destinations: seed.destinations)
        repository.refreshCabinLodging(on: third)
        repository.giftTicket(sourceSteps: 7_500, ticketCount: 1, date: third, destinations: seed.destinations)

        XCTAssertEqual(repository.tickets.count, 3)
        XCTAssertEqual(repository.trips.map(\.animalId), ["cat", "dog", "rabbit"])
        XCTAssertTrue(repository.hasReachedDailyAnimalLimit)
        XCTAssertFalse(repository.isNextAnimalApproaching)

        repository.refreshCabinLodging(on: Self.date(day: 2, hour: 8))

        XCTAssertEqual(repository.cabinLodging.dispatchedCount, 0)
        XCTAssertEqual(repository.currentCabinAnimal?.id, "cat")
    }

    func testPreviewAnimalsUseV102TravelProfiles() throws {
        let animalsById = Dictionary(uniqueKeysWithValues: SeedData.preview.animals.map { ($0.id, $0) })

        XCTAssertEqual(try XCTUnwrap(animalsById["cat"]).profileId, "moji_cat")
        XCTAssertEqual(try XCTUnwrap(animalsById["dog"]).profileId, "tangyuan_puppy")
        XCTAssertEqual(try XCTUnwrap(animalsById["dog"]).name, "汤圆")
        XCTAssertEqual(try XCTUnwrap(animalsById["rabbit"]).profileId, "dengdeng_rabbit")
        XCTAssertTrue(try XCTUnwrap(animalsById["cat"]).canTravel)
        XCTAssertTrue(try XCTUnwrap(animalsById["dog"]).canTravel)
        XCTAssertTrue(try XCTUnwrap(animalsById["rabbit"]).canTravel)
    }

    func testPostcardPlanCountsByTravelKind() throws {
        let scheduler = PostcardScheduler()
        let destinations = Self.makeV102Destinations()

        let lisbon = try XCTUnwrap(destinations.first { $0.id == "pt_lisbon" })
        let paris = try XCTUnwrap(destinations.first { $0.id == "fr_paris" })
        let reykjavik = try XCTUnwrap(destinations.first { $0.id == "is_reykjavik" })

        XCTAssertEqual(scheduler.makePostcardPlan(for: lisbon, departedAt: Self.date()).count, 1)
        XCTAssertEqual(scheduler.makePostcardPlan(for: paris, departedAt: Self.date()).count, 1)

        let longPlan = scheduler.makePostcardPlan(for: reykjavik, departedAt: Self.date())
        XCTAssertEqual(longPlan.count, 2)
        XCTAssertNotEqual(longPlan[0].sceneId, longPlan[1].sceneId)
        XCTAssertNotEqual(longPlan[0].postcardType, longPlan[1].postcardType)
        XCTAssertNotEqual(longPlan[0].preferredMicroArc, longPlan[1].preferredMicroArc)
    }

    func testV102GeneratedPostcardUsesLandscapeTemplateWithoutVisualAnimalDependency() throws {
        let scheduler = PostcardScheduler()
        let destination = try XCTUnwrap(Self.makeV102Destinations().first { $0.id == "pt_lisbon" })
        let animal = try XCTUnwrap(SeedData.preview.animals.first { $0.id == "dog" })
        let trip = Trip(
            id: "trip_lisbon",
            animalId: animal.id,
            destinationId: destination.id,
            destination: destination.displayName,
            departedAt: Self.date(day: 1),
            expectedReturnAt: Self.date(day: 2),
            status: .traveling,
            travelKind: .short,
            postcardPlan: scheduler.makePostcardPlan(for: destination, departedAt: Self.date(day: 1))
        )
        let planItem = try XCTUnwrap(trip.postcardPlan.first)

        let postcard = PostcardNarrativeEngine().makePostcard(
            for: trip,
            planItem: planItem,
            animal: animal,
            destination: destination,
            narrative: nil,
            memory: AnimalRelationshipMemory(animalId: animal.id),
            recentPostcards: [],
            on: Self.date(day: 2)
        )

        XCTAssertEqual(postcard.templateAssetName, "postcard_template_landscape_v102")
        XCTAssertEqual(postcard.destinationAssetName, "destination_lisbon_line")
        XCTAssertEqual(postcard.stampAssetName, "stamp_lisbon")
        XCTAssertEqual(postcard.animalId, "dog")
        XCTAssertEqual(postcard.profileId, "tangyuan_puppy")
        XCTAssertEqual(postcard.title, "汤圆寄来的里斯本明信片")
    }

    func testLongTripCompletesOnlyAfterSecondPostcardReveal() throws {
        let destinations = Self.makeV102Destinations()
        let seed = Self.makeV102Seed(destinations: destinations)
        let repository = AppRepository(seed: seed)
        let departedAt = Self.date(day: 1, hour: 9)

        repository.giftTicket(
            sourceSteps: 5_200,
            ticketCount: 1,
            date: departedAt,
            destinations: destinations
        )

        let trip = try XCTUnwrap(repository.activeTrip)
        XCTAssertEqual(trip.travelKind, .long)
        XCTAssertEqual(trip.postcardPlan.count, 2)

        let firstReveal = repository.revealEligiblePostcards(
            scheduler: PostcardScheduler(),
            destinations: destinations,
            on: Self.date(day: 3, hour: 9)
        )

        XCTAssertTrue(firstReveal)
        let firstTravelPostcards = repository.postcards.filter { $0.postcardType != "first_airport_departure" }
        XCTAssertEqual(firstTravelPostcards.count, 1)
        XCTAssertEqual(repository.trips.first?.status, .traveling)
        XCTAssertEqual(repository.trips.first?.revealedPostcardCount, 1)

        let secondReveal = repository.revealEligiblePostcards(
            scheduler: PostcardScheduler(),
            destinations: destinations,
            on: Self.date(day: 5, hour: 9)
        )

        XCTAssertTrue(secondReveal)
        let travelPostcards = repository.postcards.filter { $0.postcardType != "first_airport_departure" }
        XCTAssertEqual(travelPostcards.count, 2)
        XCTAssertEqual(repository.trips.first?.status, .completed)
        XCTAssertEqual(repository.travelWishes.first?.status, .completed)
        XCTAssertEqual(Set(travelPostcards.map(\.sceneId)).count, 2)
        XCTAssertEqual(Set(travelPostcards.map(\.postcardType)).count, 2)
        XCTAssertEqual(Set(travelPostcards.map(\.microArc)).count, 2)
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
        XCTAssertEqual(repository.postcards.filter { $0.postcardType != "first_airport_departure" }.count, 1)
        XCTAssertEqual(repository.trips.first?.status, .completed)
    }

    func testFirstGiftDeliversAirportPostcardOnlyOnce() throws {
        let seed = Self.makeSeed()
        let repository = AppRepository(seed: seed)
        let firstGiftAt = Self.date(hour: 9)

        repository.giftTicket(sourceSteps: 5_200, ticketCount: 1, date: firstGiftAt, destinations: seed.destinations)

        let emptyUntil = try XCTUnwrap(repository.cabinLodging.emptyUntil)
        repository.refreshCabinLodging(on: emptyUntil.addingTimeInterval(1))
        repository.giftTicket(sourceSteps: 6_500, ticketCount: 1, date: emptyUntil.addingTimeInterval(2), destinations: seed.destinations)

        let airportPostcards = repository.postcards.filter { $0.postcardType == "first_airport_departure" }
        XCTAssertEqual(airportPostcards.count, 1)
        XCTAssertEqual(airportPostcards.first?.title, "小动物寄来的第一张明信片")
        XCTAssertEqual(airportPostcards.first?.subtitle, "刚到机场")
        XCTAssertFalse(airportPostcards.first?.isRead ?? true)
        XCTAssertTrue(repository.userFlags.firstAirportPostcardDelivered)
    }

    func testFirstImmediateTicketEligibilityRequiresHealthAndNoPriorTickets() {
        let repository = AppRepository(seed: Self.makeSeed())

        XCTAssertTrue(repository.canUseFirstImmediateTicket(authorizationStatus: .sharingAuthorized))
        XCTAssertTrue(repository.canUseFirstImmediateTicket(authorizationStatus: .readPermissionRequested))
        XCTAssertFalse(repository.canUseFirstImmediateTicket(authorizationStatus: .sharingDenied))

        repository.giftTicket(
            sourceSteps: 400,
            ticketCount: 1,
            date: Self.date(hour: 9),
            destinations: Self.makeSeed().destinations,
            isFirstImmediateTicket: true
        )

        XCTAssertFalse(repository.canUseFirstImmediateTicket(authorizationStatus: .sharingAuthorized))
        XCTAssertTrue(repository.userFlags.firstImmediateTicketGifted)
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

    private static func makeV102Seed(destinations: [ManifestDestination]) -> SeedData {
        let destination = destinations.first { $0.id == "is_reykjavik" } ?? destinations[0]
        return SeedData(
            animals: [
                Animal(
                    id: "cat",
                    name: "墨迹",
                    species: "cat",
                    personality: "安静、好奇、喜欢地图",
                    profileId: "moji_cat",
                    canTravel: true,
                    displayRoleType: "见证者",
                    homeAssetName: "animal_cat_home",
                    selfieAssetName: "animal_cat_selfie",
                    visitorAssetName: "animal_cat_home",
                    discoveredAt: date(),
                    isResident: true
                )
            ],
            travelWishes: [
                TravelWish(
                    id: "wish_reykjavik_cat",
                    animalId: "cat",
                    destinationId: destination.id,
                    destination: destination.displayName,
                    destinationAssetName: destination.landmarkAssetName,
                    requiredTickets: 1,
                    status: .waiting,
                    createdAt: date()
                )
            ],
            trips: [],
            postcards: [],
            destinations: destinations
        )
    }

    private static func makeV102Destinations() -> [ManifestDestination] {
        [
            ManifestDestination(
                id: "fr_paris",
                cityId: "fr_paris",
                displayName: "巴黎",
                landmarkAssetName: "destination_paris_line",
                stampAssetName: "stamp_paris",
                routeMapAssetName: "trip_route_map_paris",
                postcardTemplateAssetName: "postcard_template_landscape_v102",
                travelKind: "standard",
                primaryColor: "#D8B36A",
                postcardTitleTemplate: "{animal}寄来的巴黎明信片",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "{animal}在{destination}写信。",
                scenes: Self.makeScenes(prefix: "fr_paris")
            ),
            ManifestDestination(
                id: "is_reykjavik",
                cityId: "is_reykjavik",
                displayName: "雷克雅未克",
                landmarkAssetName: "destination_iceland_line",
                stampAssetName: "stamp_iceland",
                routeMapAssetName: "trip_route_map_iceland",
                postcardTemplateAssetName: "postcard_template_landscape_v102",
                travelKind: "long",
                primaryColor: "#A9C9D8",
                postcardTitleTemplate: "{animal}寄来的雷克雅未克明信片",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "{animal}在{destination}写信。",
                scenes: Self.makeScenes(prefix: "is_reykjavik")
            ),
            ManifestDestination(
                id: "pt_lisbon",
                cityId: "pt_lisbon",
                displayName: "里斯本",
                landmarkAssetName: "destination_lisbon_line",
                stampAssetName: "stamp_lisbon",
                routeMapAssetName: "trip_route_map_lisbon",
                postcardTemplateAssetName: "postcard_template_landscape_v102",
                travelKind: "short",
                primaryColor: "#C9895F",
                postcardTitleTemplate: "{animal}寄来的里斯本明信片",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "{animal}在{destination}写信。",
                scenes: Self.makeScenes(prefix: "pt_lisbon")
            )
        ]
    }

    private static func makeScenes(prefix: String) -> [ManifestPostcardScene] {
        [
            ManifestPostcardScene(
                sceneId: "\(prefix)_street_01",
                sceneName: "旧街转角",
                sceneType: "street_corner",
                sensoryDetails: ["风擦过门牌", "浅色墙面反光", "脚步声很轻"],
                localObjects: ["门牌", "票角", "纸袋"],
                availableActions: ["把门牌上的水擦掉", "把票角压平", "把纸袋扶正"],
                postcardTypes: ["daily_observation", "personality_reaction"],
                microArcFits: ["旁观型", "选择型"],
                animalAffinity: ["moji_cat", "tangyuan_puppy", "dengdeng_rabbit"],
                avoidWriting: ["景点介绍"]
            ),
            ManifestPostcardScene(
                sceneId: "\(prefix)_pier_02",
                sceneName: "码头边",
                sceneType: "pier",
                sensoryDetails: ["低云贴着栏杆", "海风有盐味", "远处的路发亮"],
                localObjects: ["围巾角", "旧票根", "小石子"],
                availableActions: ["等风过去", "把旧票根夹回本子", "把小石子推回边上"],
                postcardTypes: ["motif_echo", "relationship_card"],
                microArcFits: ["回声型", "误会型"],
                animalAffinity: ["moji_cat", "tangyuan_puppy", "dengdeng_rabbit"],
                avoidWriting: ["强行安慰"]
            )
        ]
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
