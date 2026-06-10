import Foundation

enum TripStatus: String, Equatable {
    case preparing
    case traveling
    case completed
}

enum TravelKind: String, Codable, Equatable {
    case short
    case standard
    case long
}

struct TripPostcardPlanItem: Codable, Equatable, Identifiable {
    var id: String { "\(sequence)-\(sceneId)-\(postcardType)" }
    var sequence: Int
    var dueAt: Date
    var postcardType: String
    var preferredMicroArc: String
    var plannedEmotionalWeight: Int
    var sceneId: String
}

struct Trip: Identifiable, Equatable {
    let id: String
    var animalId: String
    var destinationId: String
    var destination: String
    var departedAt: Date
    var expectedReturnAt: Date
    var status: TripStatus
    var travelKind: TravelKind = .standard
    var postcardPlan: [TripPostcardPlanItem] = []
    var revealedPostcardCount: Int = 0
    var completedAt: Date?
}
