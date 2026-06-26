import UIKit
import XCTest
@testable import TripPet

final class AchievementEngineTests: XCTestCase {
    private let engine = AchievementEngine()

    func testEmptyTripsLeaveAllTravelMedalsUncollected() throws {
        let progress = engine.travelProgress(animals: Self.animals, trips: [])

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        XCTAssertEqual(xiaoman.travelCount, 0)
        XCTAssertEqual(xiaoman.medals.first?.valueText, "0 / 1")
        XCTAssertEqual(xiaoman.medals.first?.state, .inProgress)
        XCTAssertTrue(xiaoman.medals.allSatisfy { $0.isUnlocked == false })
    }

    func testOneTripUnlocksFirstTravelMedal() throws {
        let progress = engine.travelProgress(
            animals: Self.animals,
            trips: Self.makeTrips(animalId: "xiaoman", count: 1)
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        XCTAssertEqual(xiaoman.completedMedalCount, 1)
        XCTAssertEqual(xiaoman.medals.map(\.isUnlocked), [true, false, false, false, false, false])
        XCTAssertEqual(xiaoman.medals.map(\.valueText), ["1 / 1", "0 / 10", "0 / 20", "0 / 30", "0 / 50", "0 / 100"])
        XCTAssertEqual(xiaoman.medals.map(\.state), [.collected, .inProgress, .locked, .locked, .locked, .locked])
    }

    func testTwelveTripsUnlockFirstTwoTravelMedalsAndStartsTwentyMedal() throws {
        let progress = engine.travelProgress(
            animals: Self.animals,
            trips: Self.makeTrips(animalId: "xiaoman", count: 12)
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        XCTAssertEqual(xiaoman.completedMedalCount, 2)
        XCTAssertEqual(xiaoman.medals.map(\.valueText), ["1 / 1", "10 / 10", "1 / 20", "0 / 30", "0 / 50", "0 / 100"])
        XCTAssertEqual(xiaoman.medals.map(\.state), [.collected, .collected, .inProgress, .locked, .locked, .locked])
    }

    func testTwoHundredElevenTripsUnlocksAllTravelMedals() throws {
        let progress = engine.travelProgress(
            animals: Self.animals,
            trips: Self.makeTrips(animalId: "xiaoman", count: 211)
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        XCTAssertEqual(xiaoman.completedMedalCount, 6)
        XCTAssertEqual(xiaoman.medals.map(\.valueText), ["1 / 1", "10 / 10", "20 / 20", "30 / 30", "50 / 50", "100 / 100"])
        XCTAssertTrue(xiaoman.medals.allSatisfy { $0.state == .collected })
    }

    func testTravelCountsStaySeparatedByAnimal() throws {
        let trips = Self.makeTrips(animalId: "xiaoman", count: 12) +
            Self.makeTrips(animalId: "tangyuan", count: 1)

        let progress = engine.travelProgress(animals: Self.animals, trips: trips)

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        let tangyuan = try XCTUnwrap(progress.first { $0.animal.id == "tangyuan" })
        XCTAssertEqual(xiaoman.travelCount, 12)
        XCTAssertEqual(xiaoman.completedMedalCount, 2)
        XCTAssertEqual(tangyuan.travelCount, 1)
        XCTAssertEqual(tangyuan.completedMedalCount, 1)
    }

    func testStepProgressStaysSeparatedByAnimal() throws {
        let tickets = [
            Self.makeTicket(sourceSteps: 42_600, animalId: "xiaoman"),
            Self.makeTicket(sourceSteps: 9_000, animalId: "tangyuan")
        ]

        let progress = engine.progress(
            category: .steps,
            animals: Self.animals,
            trips: [],
            tickets: tickets,
            postcards: []
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        let tangyuan = try XCTUnwrap(progress.first { $0.animal.id == "tangyuan" })
        XCTAssertEqual(xiaoman.totalValue, 42_600)
        XCTAssertEqual(xiaoman.completedMedalCount, 4)
        XCTAssertEqual(xiaoman.medals[4].valueText, "42600 / 50000")
        XCTAssertEqual(xiaoman.medals[4].state, .inProgress)
        XCTAssertEqual(tangyuan.totalValue, 9_000)
        XCTAssertEqual(tangyuan.completedMedalCount, 2)
    }

    func testZeroSourceStepsDoNotIncreaseStepProgress() throws {
        let progress = engine.progress(
            category: .steps,
            animals: Self.animals,
            trips: [],
            tickets: [Self.makeTicket(sourceSteps: 0, animalId: "xiaoman")],
            postcards: []
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        XCTAssertEqual(xiaoman.totalValue, 0)
        XCTAssertTrue(xiaoman.medals.allSatisfy { $0.isUnlocked == false })
    }

    func testLegacyStepTicketInfersAnimalFromTripDepartureTime() throws {
        let departedAt = Self.date(offset: 10)
        let ticket = Self.makeTicket(sourceSteps: 3_000, animalId: nil, date: departedAt)
        let trips = [
            Self.makeTrip(id: "legacy-trip", animalId: "xiaoman", departedAt: departedAt)
        ]

        let progress = engine.progress(
            category: .steps,
            animals: Self.animals,
            trips: trips,
            tickets: [ticket],
            postcards: []
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        XCTAssertEqual(xiaoman.totalValue, 3_000)
        XCTAssertEqual(xiaoman.completedMedalCount, 1)
    }

    func testLegacyStepTicketWithoutMatchingTripIsIgnored() throws {
        let progress = engine.progress(
            category: .steps,
            animals: Self.animals,
            trips: [],
            tickets: [Self.makeTicket(sourceSteps: 3_000, animalId: nil)],
            postcards: []
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        XCTAssertEqual(xiaoman.totalValue, 0)
        XCTAssertEqual(xiaoman.completedMedalCount, 0)
    }

    func testPostcardProgressUsesTripAnimalAndIgnoresMissingTrips() throws {
        let trips = [
            Self.makeTrip(id: "xiaoman-trip", animalId: "xiaoman"),
            Self.makeTrip(id: "tangyuan-trip", animalId: "tangyuan")
        ]
        let postcards = Self.makePostcards(tripId: "xiaoman-trip", count: 10) +
            Self.makePostcards(tripId: "tangyuan-trip", count: 1) +
            Self.makePostcards(tripId: "missing-trip", count: 8)

        let progress = engine.progress(
            category: .postcards,
            animals: Self.animals,
            trips: trips,
            tickets: [],
            postcards: postcards
        )

        let xiaoman = try XCTUnwrap(progress.first { $0.animal.id == "xiaoman" })
        let tangyuan = try XCTUnwrap(progress.first { $0.animal.id == "tangyuan" })
        XCTAssertEqual(xiaoman.totalValue, 10)
        XCTAssertEqual(xiaoman.completedMedalCount, 2)
        XCTAssertEqual(xiaoman.medals.map(\.valueText).prefix(3), ["1 / 1", "10 / 10", "10 / 50"])
        XCTAssertEqual(tangyuan.totalValue, 1)
        XCTAssertEqual(tangyuan.completedMedalCount, 1)
    }

    func testSummariesCountCollectedAndAvailableMedalsByCategory() {
        let trips = Self.makeTrips(animalId: "xiaoman", count: 12) +
            Self.makeTrips(animalId: "tangyuan", count: 1)
        let tickets = [
            Self.makeTicket(sourceSteps: 42_600, animalId: "xiaoman"),
            Self.makeTicket(sourceSteps: 3_000, animalId: "tangyuan")
        ]
        let postcards = Self.makePostcards(tripId: "xiaoman-trip", count: 10)
        let postcardTrips = [Self.makeTrip(id: "xiaoman-trip", animalId: "xiaoman")]

        let travelSummary = engine.travelSummary(animals: Self.animals, trips: trips)
        let stepSummary = engine.summary(category: .steps, animals: Self.animals, trips: [], tickets: tickets, postcards: [])
        let postcardSummary = engine.summary(category: .postcards, animals: Self.animals, trips: postcardTrips, tickets: [], postcards: postcards)

        XCTAssertEqual(travelSummary.collectedMedalCount, 3)
        XCTAssertEqual(travelSummary.availableMedalCount, Self.animals.count * 6)
        XCTAssertEqual(stepSummary.collectedMedalCount, 5)
        XCTAssertEqual(stepSummary.availableMedalCount, Self.animals.count * 14)
        XCTAssertEqual(postcardSummary.collectedMedalCount, 2)
        XCTAssertEqual(postcardSummary.availableMedalCount, Self.animals.count * 9)
    }

    func testAchievementCategoriesKeepExpectedDefaultOrder() {
        XCTAssertEqual(AchievementCategory.allCases.map(\.buttonTitle), ["旅行", "脚步", "明信片"])
    }

    func testAllTiersExposeFormalArtAssets() {
        XCTAssertEqual(
            AchievementEngine.travelTiers.map(\.medalAssetName),
            [
                "achievement_medal_travel_tier_001",
                "achievement_medal_travel_tier_002",
                "achievement_medal_travel_tier_003",
                "achievement_medal_travel_tier_004",
                "achievement_medal_travel_tier_005",
                "achievement_medal_travel_tier_006"
            ]
        )
        XCTAssertEqual(
            AchievementEngine.stepTiers.map(\.medalAssetName),
            [
                "achievement_medal_steps_tier_001",
                "achievement_medal_steps_tier_002",
                "achievement_medal_steps_tier_003",
                "achievement_medal_steps_tier_004",
                "achievement_medal_steps_tier_005",
                "achievement_medal_steps_tier_006",
                "achievement_medal_steps_tier_007",
                "achievement_medal_steps_tier_008",
                "achievement_medal_steps_tier_009",
                "achievement_medal_steps_tier_010",
                "achievement_medal_steps_tier_011",
                "achievement_medal_steps_tier_012",
                "achievement_medal_steps_tier_013",
                "achievement_medal_steps_tier_014"
            ]
        )
        XCTAssertEqual(
            AchievementEngine.postcardTiers.map(\.medalAssetName),
            [
                "achievement_medal_postcards_tier_001",
                "achievement_medal_postcards_tier_002",
                "achievement_medal_postcards_tier_003",
                "achievement_medal_postcards_tier_004",
                "achievement_medal_postcards_tier_005",
                "achievement_medal_postcards_tier_006",
                "achievement_medal_postcards_tier_007",
                "achievement_medal_postcards_tier_008",
                "achievement_medal_postcards_tier_009"
            ]
        )
    }

    func testFormalAchievementMedalAssetsExistInBundle() {
        let assetNames = [
            "achievement_medal_travel_tier_001",
            "achievement_medal_travel_tier_002",
            "achievement_medal_travel_tier_003",
            "achievement_medal_travel_tier_004",
            "achievement_medal_travel_tier_005",
            "achievement_medal_travel_tier_006",
            "achievement_medal_steps_tier_001",
            "achievement_medal_steps_tier_002",
            "achievement_medal_steps_tier_003",
            "achievement_medal_steps_tier_004",
            "achievement_medal_steps_tier_005",
            "achievement_medal_steps_tier_006",
            "achievement_medal_steps_tier_007",
            "achievement_medal_steps_tier_008",
            "achievement_medal_steps_tier_009",
            "achievement_medal_steps_tier_010",
            "achievement_medal_steps_tier_011",
            "achievement_medal_steps_tier_012",
            "achievement_medal_steps_tier_013",
            "achievement_medal_steps_tier_014",
            "achievement_medal_postcards_tier_001",
            "achievement_medal_postcards_tier_002",
            "achievement_medal_postcards_tier_003",
            "achievement_medal_postcards_tier_004",
            "achievement_medal_postcards_tier_005",
            "achievement_medal_postcards_tier_006",
            "achievement_medal_postcards_tier_007",
            "achievement_medal_postcards_tier_008",
            "achievement_medal_postcards_tier_009"
        ]

        for assetName in assetNames {
            XCTAssertNotNil(UIImage(named: assetName), "Missing achievement medal asset: \(assetName)")
        }
    }

    private static let animals = [
        Animal(
            id: "xiaoman",
            name: "小满",
            species: "仓鼠",
            personality: "温柔",
            homeAssetName: "animal_home_xiaoman_hamster",
            selfieAssetName: "animal_home_xiaoman_hamster",
            visitorAssetName: "animal_home_xiaoman_hamster",
            discoveredAt: Date(),
            isResident: true
        ),
        Animal(
            id: "tangyuan",
            name: "糖圆",
            species: "小狗",
            personality: "活泼",
            homeAssetName: "animal_home_tangyuan_puppy",
            selfieAssetName: "animal_home_tangyuan_puppy",
            visitorAssetName: "animal_home_tangyuan_puppy",
            discoveredAt: Date(),
            isResident: false
        )
    ]

    private static func makeTrips(animalId: String, count: Int) -> [Trip] {
        (0..<count).map { index in
            makeTrip(
                id: "\(animalId)-trip-\(index)",
                animalId: animalId,
                departedAt: date(offset: index)
            )
        }
    }

    private static func makeTrip(
        id: String,
        animalId: String,
        departedAt: Date = date()
    ) -> Trip {
        Trip(
            id: id,
            animalId: animalId,
            destinationId: "paris",
            destination: "巴黎",
            departedAt: departedAt,
            expectedReturnAt: departedAt.addingTimeInterval(60),
            status: .completed,
            completedAt: departedAt.addingTimeInterval(60)
        )
    }

    private static func makeTicket(
        sourceSteps: Int,
        animalId: String?,
        date: Date = date()
    ) -> Ticket {
        Ticket(
            id: UUID(),
            date: date,
            sourceSteps: sourceSteps,
            ticketCount: 1,
            animalId: animalId,
            giftedAt: date
        )
    }

    private static func makePostcards(tripId: String, count: Int) -> [Postcard] {
        (0..<count).map { index in
            Postcard(
                id: "\(tripId)-postcard-\(index)",
                tripId: tripId,
                destination: "巴黎",
                title: "小满寄来的明信片",
                body: "今天有一封远方来信。",
                imageAssetName: "postcard_paris_day_2",
                templateAssetName: "postcard_template_classic",
                destinationAssetName: "postcard_destination_paris",
                stampAssetName: "postcard_stamp_paris",
                animalAssetName: "animal_home_xiaoman_hamster",
                envelopeAssetName: "envelope_unread",
                sentAt: date(offset: index),
                subtitle: "旅途中寄来",
                isRead: false
            )
        }
    }

    private static func date(offset: Int = 0) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000 + TimeInterval(offset))
    }
}
