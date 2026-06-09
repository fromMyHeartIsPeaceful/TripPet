import Foundation

enum TravelWishStatus: String, Equatable {
    case waiting
    case ready
    case traveling
    case completed
}

struct TravelWish: Identifiable, Equatable {
    let id: String
    var animalId: String
    var destinationId: String
    var destination: String
    var destinationAssetName: String
    var requiredTickets: Int
    var status: TravelWishStatus
    var createdAt: Date
}
