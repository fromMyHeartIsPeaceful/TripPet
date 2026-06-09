import Foundation

struct ContentManifest: Decodable {
    var version: Int
    var animals: [ManifestAnimal]
    var destinations: [ManifestDestination]
    var postcards: [ManifestPostcard]
    var rules: ManifestRules
}

struct ManifestAnimal: Decodable {
    var id: String
    var displayName: String
    var species: String
    var personality: String
    var homeAssetName: String
    var selfieAssetName: String
    var visitorAssetName: String
    var isResident: Bool
}

struct ManifestDestination: Decodable {
    var id: String
    var displayName: String
    var landmarkAssetName: String
    var stampAssetName: String
    var routeMapAssetName: String
    var primaryColor: String
    var postcardTitleTemplate: String
    var postcardSubtitle: String
    var postcardBodyTemplate: String
}

struct ManifestPostcard: Decodable {
    var id: String
    var tripId: String
    var destinationId: String
    var animalId: String
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

extension SeedData {
    init(manifest: ContentManifest, now: Date = Date()) {
        let animals = manifest.animals.map { animal in
            Animal(
                id: animal.id,
                name: animal.displayName,
                species: animal.species,
                personality: animal.personality,
                homeAssetName: animal.homeAssetName,
                selfieAssetName: animal.selfieAssetName,
                visitorAssetName: animal.visitorAssetName,
                discoveredAt: animal.isResident ? now : nil,
                isResident: animal.isResident
            )
        }

        let destinationsById = manifest.destinations.reduce(into: [String: ManifestDestination]()) { result, destination in
            result[destination.id] = destination
        }
        let residentAnimalId = animals.first(where: \.isResident)?.id ?? manifest.animals.first?.id ?? "cat"
        let firstDestination = manifest.destinations.first
        let travelWishes: [TravelWish] = firstDestination.map { destination in
            [
                TravelWish(
                    id: "wish_\(destination.id)_\(residentAnimalId)",
                    animalId: residentAnimalId,
                    destinationId: destination.id,
                    destination: destination.displayName,
                    destinationAssetName: destination.landmarkAssetName,
                    requiredTickets: 1,
                    status: .waiting,
                    createdAt: now
                )
            ]
        } ?? []

        let postcards = manifest.postcards.map { postcard in
            let destination = destinationsById[postcard.destinationId]

            return Postcard(
                id: postcard.id,
                tripId: postcard.tripId,
                destination: destination?.displayName ?? postcard.destinationId,
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
