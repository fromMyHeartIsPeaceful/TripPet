import Foundation

enum TripStatus: String, Equatable {
    case preparing
    case traveling
    case completed
}

struct Trip: Identifiable, Equatable {
    let id: String
    var animalId: String
    var destinationId: String
    var destination: String
    var departedAt: Date
    var expectedReturnAt: Date
    var status: TripStatus
}
