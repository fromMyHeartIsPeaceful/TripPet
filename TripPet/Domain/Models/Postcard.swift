import Foundation

struct Postcard: Identifiable, Equatable {
    let id: String
    var tripId: String
    var animalId: String = ""
    var profileId: String = ""
    var destination: String
    var cityId: String = ""
    var sceneId: String = ""
    var postcardType: String = "daily_observation"
    var microArc: String = "动作型"
    var emotionalWeight: Int = 0
    var revealBudget: String = "none"
    var relationshipStageAtSend: String = "stranger"
    var title: String
    var body: String
    var imageAssetName: String
    var templateAssetName: String
    var destinationAssetName: String
    var stampAssetName: String
    var animalAssetName: String
    var envelopeAssetName: String
    var sentAt: Date
    var subtitle: String
    var isRead: Bool
}
