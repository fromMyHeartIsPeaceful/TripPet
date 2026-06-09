import XCTest
@testable import TripPet

final class TicketRuleEngineTests: XCTestCase {
    func testStepsBelowThresholdAreNotEligible() {
        let engine = TicketRuleEngine()

        let eligibility = engine.evaluate(todaySteps: 2_999, hasGiftedToday: false)

        XCTAssertFalse(eligibility.isEligible)
        XCTAssertEqual(eligibility.ticketCount, 0)
        XCTAssertTrue(eligibility.message.contains("2999 步"))
    }

    func testStepsEqualToThresholdAreEligible() {
        let engine = TicketRuleEngine()

        let eligibility = engine.evaluate(todaySteps: 3_000, hasGiftedToday: false)

        XCTAssertTrue(eligibility.isEligible)
        XCTAssertEqual(eligibility.ticketCount, 1)
    }

    func testStepsAboveThresholdAreEligible() {
        let engine = TicketRuleEngine()

        let eligibility = engine.evaluate(todaySteps: 4_500, hasGiftedToday: false)

        XCTAssertTrue(eligibility.isEligible)
        XCTAssertEqual(eligibility.ticketCount, 1)
    }

    func testGiftedTicketsDeductOnlyRequiredStepsFromAvailableTotal() {
        let engine = TicketRuleEngine()

        let afterOneGift = engine.evaluate(todaySteps: 3_012, giftedCountToday: 1)
        let readyAgain = engine.evaluate(todaySteps: 6_000, giftedCountToday: 1)

        XCTAssertEqual(engine.remainingSteps(todaySteps: 3_012, giftedCountToday: 1), 12)
        XCTAssertFalse(afterOneGift.isEligible)
        XCTAssertTrue(afterOneGift.message.contains("12 步"))
        XCTAssertTrue(readyAgain.isEligible)
        XCTAssertEqual(readyAgain.ticketCount, 1)
    }

    func testDailyGiftLimitBlocksSecondGift() {
        let engine = TicketRuleEngine(dailyTicketLimit: 1)

        let eligibility = engine.evaluate(todaySteps: 6_000, hasGiftedToday: true)

        XCTAssertFalse(eligibility.isEligible)
        XCTAssertEqual(eligibility.ticketCount, 0)
    }

    func testDailyGiftLimitAllowsUpToThreeGifts() {
        let engine = TicketRuleEngine(dailyTicketLimit: 3)

        let secondGiftEligibility = engine.evaluate(todaySteps: 9_999, giftedCountToday: 1)
        let afterLimitEligibility = engine.evaluate(todaySteps: 9_999, giftedCountToday: 3)

        XCTAssertTrue(secondGiftEligibility.isEligible)
        XCTAssertEqual(secondGiftEligibility.ticketCount, 1)
        XCTAssertFalse(afterLimitEligibility.isEligible)
    }

    @MainActor
    func testGiftStateResetsAcrossDays() {
        let repository = AppRepository(seed: SeedData.preview)
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        repository.giftTicket(sourceSteps: 3_000, ticketCount: 1, date: yesterday)

        XCTAssertFalse(repository.hasGiftedTicketToday(calendar: calendar))
    }
}
