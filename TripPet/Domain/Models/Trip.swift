import Foundation

enum TripStatus: String, Equatable {
    case preparing
    case traveling
    case completed
}

struct TripPostcardPlanItem: Equatable, Codable {
    var sequence: Int
    var dueAt: Date
    var revealedAt: Date?
}

struct Trip: Identifiable, Equatable {
    let id: String
    var animalId: String
    var destinationId: String
    var destination: String
    var departedAt: Date
    var expectedReturnAt: Date
    var status: TripStatus
    var postcardPlan: [TripPostcardPlanItem] = []
    var completedAt: Date?
}
