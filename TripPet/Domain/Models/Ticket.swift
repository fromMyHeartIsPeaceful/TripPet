import Foundation

enum TicketGrantType: String, Equatable {
    case stepFunded
    case firstImmediate
    case manual
}

struct Ticket: Identifiable, Equatable {
    let id: UUID
    var date: Date
    var sourceSteps: Int
    var ticketCount: Int
    var giftedAt: Date
    var grantType: TicketGrantType

    init(
        id: UUID,
        date: Date,
        sourceSteps: Int,
        ticketCount: Int,
        giftedAt: Date,
        grantType: TicketGrantType? = nil
    ) {
        self.id = id
        self.date = date
        self.sourceSteps = sourceSteps
        self.ticketCount = ticketCount
        self.giftedAt = giftedAt
        self.grantType = grantType ?? (sourceSteps > 0 ? .stepFunded : .manual)
    }
}

struct TicketEligibility: Equatable {
    var isEligible: Bool
    var ticketCount: Int
    var message: String
}
