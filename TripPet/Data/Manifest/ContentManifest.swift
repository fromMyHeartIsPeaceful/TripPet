import Foundation

struct ContentManifest: Decodable {
    var version: Int
    var animals: [ManifestAnimal]
    var destinations: [ManifestDestination]
    var postcards: [ManifestPostcard]
    var narrative: ManifestNarrative?
    var rules: ManifestRules
}

struct ManifestAnimal: Decodable {
    var id: String
    var displayName: String
    var species: String
    var personality: String
    var profileId: String?
    var canTravel: Bool?
    var displayRoleType: String?
    var homeAssetName: String
    var selfieAssetName: String
    var visitorAssetName: String
    var isResident: Bool
}

struct ManifestDestination: Decodable {
    var id: String
    var cityId: String?
    var displayName: String
    var landmarkAssetName: String
    var stampAssetName: String
    var routeMapAssetName: String
    var postcardTemplateAssetName: String?
    var travelKind: String?
    var primaryColor: String
    var postcardTitleTemplate: String
    var postcardSubtitle: String
    var postcardBodyTemplate: String
    var scenes: [ManifestPostcardScene]?
}

struct ManifestPostcard: Decodable {
    var id: String
    var tripId: String
    var animalId: String?
    var profileId: String?
    var destinationId: String
    var cityId: String?
    var sceneId: String?
    var postcardType: String?
    var microArc: String?
    var emotionalWeight: Int?
    var revealBudget: String?
    var relationshipStageAtSend: String?
    var templateAssetName: String
    var destinationAssetName: String
    var stampAssetName: String
    var animalAssetName: String
    var envelopeAssetName: String
    var title: String
    var subtitle: String
    var body: String
    var isRead: Bool
}

struct ManifestRules: Decodable {
    var stepsPerTicket: Int
    var dailyTicketLimit: Int
}

struct ManifestNarrative: Decodable {
    var postcardTypes: [String: Int]
    var profiles: [ManifestAnimalProfile]
    var templates: [ManifestPostcardTemplate]
}

struct ManifestAnimalProfile: Decodable {
    var id: String
    var displayName: String
    var motifs: [String]
    var reactionLines: [String]
    var relationshipLines: [String]
    var actionPatterns: [String]
    var preferredPostcardTypes: [String]
}

struct ManifestPostcardTemplate: Decodable {
    var id: String
    var postcardType: String
    var microArc: String
    var maxEmotionalWeight: Int
    var revealBudget: String
}

struct ManifestPostcardScene: Decodable {
    var sceneId: String
    var sceneName: String
    var sceneType: String
    var sensoryDetails: [String]
    var localObjects: [String]
    var availableActions: [String]
    var postcardTypes: [String]
    var microArcFits: [String]
    var animalAffinity: [String]
    var avoidWriting: [String]
}

extension SeedData {
    init(manifest: ContentManifest, now: Date = Date()) {
        let animals = manifest.animals.map { animal in
            Animal(
                id: animal.id,
                name: animal.displayName,
                species: animal.species,
                personality: animal.personality,
                profileId: animal.profileId ?? animal.id,
                canTravel: animal.canTravel ?? animal.isResident,
                displayRoleType: animal.displayRoleType ?? "",
                homeAssetName: animal.homeAssetName,
                selfieAssetName: animal.selfieAssetName,
                visitorAssetName: animal.visitorAssetName,
                discoveredAt: (animal.isResident || animal.canTravel == true) ? now : nil,
                isResident: animal.isResident
            )
        }

        let destinationsById = manifest.destinations.reduce(into: [String: ManifestDestination]()) { result, destination in
            result[destination.id] = destination
        }
        let travelAnimals = animals.filter(\.canTravel)
        let orderedAnimals = travelAnimals.isEmpty ? animals : travelAnimals
        let travelWishes = orderedAnimals.enumerated().compactMap { index, animal -> TravelWish? in
            guard manifest.destinations.isEmpty == false else { return nil }
            let destination = manifest.destinations[index % manifest.destinations.count]
            return
                TravelWish(
                    id: "wish_\(destination.id)_\(animal.id)",
                    animalId: animal.id,
                    destinationId: destination.id,
                    destination: destination.displayName,
                    destinationAssetName: destination.landmarkAssetName,
                    requiredTickets: 1,
                    status: .waiting,
                    createdAt: now
                )
        }

        let postcards = manifest.postcards.map { postcard in
            let destination = destinationsById[postcard.destinationId]

            return Postcard(
                id: postcard.id,
                tripId: postcard.tripId,
                animalId: postcard.animalId ?? "",
                profileId: postcard.profileId ?? "",
                destination: destination?.displayName ?? postcard.destinationId,
                cityId: postcard.cityId ?? destination?.cityId ?? postcard.destinationId,
                sceneId: postcard.sceneId ?? "",
                postcardType: postcard.postcardType ?? "daily_observation",
                microArc: postcard.microArc ?? "动作型",
                emotionalWeight: postcard.emotionalWeight ?? 0,
                revealBudget: postcard.revealBudget ?? "none",
                relationshipStageAtSend: postcard.relationshipStageAtSend ?? "stranger",
                title: postcard.title,
                body: postcard.body,
                imageAssetName: postcard.id,
                templateAssetName: postcard.templateAssetName,
                destinationAssetName: postcard.destinationAssetName,
                stampAssetName: postcard.stampAssetName,
                animalAssetName: postcard.animalAssetName,
                envelopeAssetName: postcard.envelopeAssetName,
                sentAt: now.addingTimeInterval(postcard.isRead ? -60 * 60 * 24 * 12 : -60 * 60 * 8),
                subtitle: postcard.subtitle,
                isRead: postcard.isRead
            )
        }

        self.init(
            animals: animals,
            travelWishes: travelWishes,
            trips: [],
            postcards: postcards,
            destinations: manifest.destinations
        )
    }
}
