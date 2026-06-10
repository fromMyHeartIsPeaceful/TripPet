import Foundation

struct AnimalRelationshipMemory: Identifiable, Codable, Equatable {
    var id: String { animalId }
    var animalId: String
    var encounterCount: Int
    var relationshipStage: String
    var tripCount: Int
    var visitedCityIds: [String]
    var recentSceneIds: [String]
    var sentPostcardIds: [String]
    var recentlyUsedMotifs: [String]
    var favoritedPostcardIds: [String]

    init(
        animalId: String,
        encounterCount: Int = 0,
        relationshipStage: String = "stranger",
        tripCount: Int = 0,
        visitedCityIds: [String] = [],
        recentSceneIds: [String] = [],
        sentPostcardIds: [String] = [],
        recentlyUsedMotifs: [String] = [],
        favoritedPostcardIds: [String] = []
    ) {
        self.animalId = animalId
        self.encounterCount = encounterCount
        self.relationshipStage = relationshipStage
        self.tripCount = tripCount
        self.visitedCityIds = visitedCityIds
        self.recentSceneIds = recentSceneIds
        self.sentPostcardIds = sentPostcardIds
        self.recentlyUsedMotifs = recentlyUsedMotifs
        self.favoritedPostcardIds = favoritedPostcardIds
    }
}
