import Foundation

struct PostcardScheduler {
    func shouldRevealPostcard(for trip: Trip, on date: Date = Date()) -> Bool {
        date >= trip.departedAt.addingTimeInterval(60 * 60 * 24)
    }

    func makePostcard(
        for trip: Trip,
        animal: Animal,
        destination: ManifestDestination,
        on date: Date = Date()
    ) -> Postcard {
        let title = destination.postcardTitleTemplate
            .replacingOccurrences(of: "{animal}", with: animal.name)
            .replacingOccurrences(of: "{destination}", with: destination.displayName)
        let body = destination.postcardBodyTemplate
            .replacingOccurrences(of: "{animal}", with: animal.name)
            .replacingOccurrences(of: "{destination}", with: destination.displayName)

        return Postcard(
            id: "postcard_\(destination.id)_\(animal.id)_\(Int(date.timeIntervalSince1970))",
            tripId: trip.id,
            destination: destination.displayName,
            title: title,
            body: body,
            imageAssetName: "postcard_\(destination.id)_\(animal.id)",
            templateAssetName: "postcard_template_classic",
            destinationAssetName: destination.landmarkAssetName,
            stampAssetName: destination.stampAssetName,
            animalAssetName: animal.selfieAssetName,
            envelopeAssetName: "envelope_unread",
            sentAt: date,
            subtitle: destination.postcardSubtitle,
            isRead: false
        )
    }
}
