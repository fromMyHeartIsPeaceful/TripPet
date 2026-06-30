import Foundation

struct PostcardScheduler {
    static let tripDuration: TimeInterval = 60 * 60 * 18

    var randomOffset: (ClosedRange<TimeInterval>) -> TimeInterval
    var calendar: Calendar

    init(
        calendar: Calendar = .current,
        randomOffset: @escaping (ClosedRange<TimeInterval>) -> TimeInterval = { Double.random(in: $0) }
    ) {
        self.calendar = calendar
        self.randomOffset = randomOffset
    }

    func makePostcardPlan(departedAt: Date) -> [TripPostcardPlanItem] {
        normalizedPostcardPlan([
            TripPostcardPlanItem(
                sequence: 1,
                dueAt: departedAt.addingTimeInterval(randomOffset(60 * 60 * 2...60 * 60 * 3)),
                revealedAt: nil
            ),
            TripPostcardPlanItem(
                sequence: 2,
                dueAt: departedAt.addingTimeInterval(randomOffset(60 * 60 * 6...60 * 60 * 8)),
                revealedAt: nil
            )
        ])
    }

    func normalizedPostcardPlan(_ plan: [TripPostcardPlanItem]) -> [TripPostcardPlanItem] {
        var lastPendingDueAt: Date?
        return plan.map { item in
            guard item.revealedAt == nil else {
                return item
            }

            var normalized = item
            normalized.dueAt = PostcardCareTimeRules.normalizedDeliveryDate(
                for: normalized.dueAt,
                calendar: calendar
            )
            if let lastPendingDueAt {
                let minimumDueAt = lastPendingDueAt.addingTimeInterval(PostcardCareTimeRules.minimumSpacing)
                if normalized.dueAt < minimumDueAt {
                    normalized.dueAt = minimumDueAt
                }
            }
            lastPendingDueAt = normalized.dueAt
            return normalized
        }
    }

    func shouldRevealPostcard(for planItem: TripPostcardPlanItem, on date: Date = Date()) -> Bool {
        planItem.revealedAt == nil && date >= planItem.dueAt
    }

    func shouldRevealPostcard(for trip: Trip, on date: Date = Date()) -> Bool {
        if trip.postcardPlan.isEmpty {
            return date >= trip.departedAt.addingTimeInterval(60 * 60 * 24)
        }
        return trip.postcardPlan.contains { shouldRevealPostcard(for: $0, on: date) }
    }

    func makePostcard(
        for trip: Trip,
        animal: Animal,
        destination: ManifestDestination,
        sequence: Int = 1,
        on date: Date = Date(),
        bodyOverride: String? = nil
    ) -> Postcard {
        let title = destination.postcardTitleTemplate
            .replacingOccurrences(of: "{animal}", with: animal.name)
            .replacingOccurrences(of: "{destination}", with: destination.displayName)
        let templateBody = destination.postcardBodyTemplate
            .replacingOccurrences(of: "{animal}", with: animal.name)
            .replacingOccurrences(of: "{destination}", with: destination.displayName)

        return Postcard(
            id: "postcard_\(trip.id)_\(sequence)",
            tripId: trip.id,
            destination: destination.displayName,
            title: title,
            body: bodyOverride ?? templateBody,
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
