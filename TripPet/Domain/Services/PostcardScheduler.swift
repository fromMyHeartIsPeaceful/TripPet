import Foundation

struct PostcardScheduler {
    static let tripDuration: TimeInterval = 60 * 60 * 18
    static let maxPostcardsPerTrip = 2
    private static let queueSpacingOptions: [TimeInterval] = [
        60 * 60 * 2,
        60 * 90,
        60 * 60
    ]

    var randomOffset: (ClosedRange<TimeInterval>) -> TimeInterval
    var calendar: Calendar

    init(
        calendar: Calendar = .current,
        randomOffset: @escaping (ClosedRange<TimeInterval>) -> TimeInterval = { Double.random(in: $0) }
    ) {
        self.calendar = calendar
        self.randomOffset = randomOffset
    }

    func makePostcardPlan(
        departedAt: Date,
        occupiedDueAts: [Date] = []
    ) -> [TripPostcardPlanItem] {
        let dueAts = queuedDueAts(
            departedAt: departedAt,
            occupiedDueAts: occupiedDueAts,
            maxCount: Self.maxPostcardsPerTrip
        )
        return dueAts.enumerated().map { index, dueAt in
            TripPostcardPlanItem(
                sequence: index + 1,
                dueAt: dueAt,
                revealedAt: nil
            )
        }
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
                    normalized.dueAt = PostcardCareTimeRules.normalizedDeliveryDate(
                        for: minimumDueAt,
                        calendar: calendar
                    )
                }
            }
            lastPendingDueAt = normalized.dueAt
            return normalized
        }
    }

    private func queuedDueAts(
        departedAt: Date,
        occupiedDueAts: [Date],
        maxCount: Int
    ) -> [Date] {
        let deadline = departedAt.addingTimeInterval(Self.tripDuration)
        let occupied = occupiedDueAts.sorted()

        for spacing in Self.queueSpacingOptions {
            let slots = availableSlots(
                departedAt: departedAt,
                deadline: deadline,
                occupiedDueAts: occupied,
                spacing: spacing,
                maxCount: maxCount
            )
            if slots.isEmpty == false {
                return slots
            }
        }

        return []
    }

    private func availableSlots(
        departedAt: Date,
        deadline: Date,
        occupiedDueAts: [Date],
        spacing: TimeInterval,
        maxCount: Int
    ) -> [Date] {
        var selected: [Date] = []
        let queueBase = max(departedAt, occupiedDueAts.last ?? departedAt)
        var candidate = nextSendableDate(onOrAfter: queueBase.addingTimeInterval(spacing))

        while candidate <= deadline, selected.count < maxCount {
            let takenDueAts = occupiedDueAts + selected
            if isAvailable(candidate, against: takenDueAts, spacing: spacing) {
                selected.append(candidate)
            }

            candidate = nextSendableDate(onOrAfter: candidate.addingTimeInterval(spacing))
        }

        return selected
    }

    private func isAvailable(_ candidate: Date, against dueAts: [Date], spacing: TimeInterval) -> Bool {
        dueAts.allSatisfy { dueAt in
            abs(candidate.timeIntervalSince(dueAt)) >= spacing
        }
    }

    private func nextSendableDate(onOrAfter date: Date) -> Date {
        let minute = PostcardCareTimeRules.minuteOfDay(for: date, calendar: calendar)
        if minute < PostcardCareTimeRules.quietEndMinute {
            return sendableBoundary(on: date)
        }
        if minute >= PostcardCareTimeRules.quietStartMinute {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(60 * 60 * 8)
            return sendableBoundary(on: nextDay)
        }
        return date
    }

    private func sendableBoundary(on date: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = PostcardCareTimeRules.quietEndMinute / 60
        components.minute = PostcardCareTimeRules.quietEndMinute % 60
        components.second = 0
        components.nanosecond = 0
        return calendar.date(from: components) ?? date
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
