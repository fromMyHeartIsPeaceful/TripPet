import Foundation

struct Ticket: Identifiable, Equatable {
    let id: UUID
    var date: Date
    var sourceSteps: Int
    var ticketCount: Int
    var animalId: String? = nil
    var giftedAt: Date
}

struct TicketEligibility: Equatable {
    var isEligible: Bool
    var ticketCount: Int
    var message: String
}
