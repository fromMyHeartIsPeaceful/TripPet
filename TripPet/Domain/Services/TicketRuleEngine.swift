import Foundation

struct TicketRuleEngine {
    let requiredStepsPerTicket: Int
    let dailyTicketLimit: Int

    init(requiredStepsPerTicket: Int = 3000, dailyTicketLimit: Int = 3) {
        self.requiredStepsPerTicket = requiredStepsPerTicket
        self.dailyTicketLimit = dailyTicketLimit
    }

    func evaluate(todaySteps: Int, hasGiftedToday: Bool) -> TicketEligibility {
        evaluate(todaySteps: todaySteps, giftedCountToday: hasGiftedToday ? dailyTicketLimit : 0)
    }

    func remainingSteps(todaySteps: Int, giftedCountToday: Int) -> Int {
        max(0, todaySteps - max(0, giftedCountToday) * requiredStepsPerTicket)
    }

    func evaluate(todaySteps: Int, giftedCountToday: Int) -> TicketEligibility {
        evaluate(
            todaySteps: todaySteps,
            giftedCountToday: giftedCountToday,
            stepFundedTicketCountToday: giftedCountToday
        )
    }

    func evaluate(
        todaySteps: Int,
        giftedCountToday: Int,
        stepFundedTicketCountToday: Int
    ) -> TicketEligibility {
        guard giftedCountToday < dailyTicketLimit else {
            return TicketEligibility(
                isEligible: false,
                ticketCount: 0,
                message: AppCopy.TicketRule.alreadyGifted
            )
        }

        let availableSteps = remainingSteps(
            todaySteps: todaySteps,
            giftedCountToday: stepFundedTicketCountToday
        )
        guard availableSteps >= requiredStepsPerTicket else {
            return TicketEligibility(
                isEligible: false,
                ticketCount: 0,
                message: AppCopy.TicketRule.notEnoughSteps(
                    todaySteps: availableSteps,
                    requiredSteps: requiredStepsPerTicket
                )
            )
        }

        return TicketEligibility(
            isEligible: true,
            ticketCount: 1,
            message: AppCopy.TicketRule.eligible
        )
    }
}
