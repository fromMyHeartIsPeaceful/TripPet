import Foundation

struct PostcardScheduler {
    func shouldRevealPostcard(for trip: Trip, on date: Date = Date()) -> Bool {
        date >= trip.departedAt.addingTimeInterval(60 * 60 * 24)
    }

    func makePostcardPlan(
        for destination: ManifestDestination,
        departedAt: Date = Date()
    ) -> [TripPostcardPlanItem] {
        let kind = TravelKind(rawValue: destination.travelKind ?? "") ?? .standard
        let scenes = destination.scenes ?? []

        switch kind {
        case .short:
            return [
                planItem(
                    sequence: 1,
                    dayOffset: 1,
                    type: "daily_observation",
                    fallbackArc: "动作型",
                    weight: 0,
                    scenes: scenes,
                    departedAt: departedAt
                )
            ]
        case .standard:
            return [
                planItem(
                    sequence: 1,
                    dayOffset: 2,
                    type: "personality_reaction",
                    fallbackArc: "选择型",
                    weight: 1,
                    scenes: scenes,
                    departedAt: departedAt
                )
            ]
        case .long:
            let first = planItem(
                sequence: 1,
                dayOffset: 2,
                type: "daily_observation",
                fallbackArc: "旁观型",
                weight: 0,
                scenes: scenes,
                departedAt: departedAt
            )
            let secondScene = scenes.first {
                $0.sceneId != first.sceneId &&
                ($0.postcardTypes.contains("motif_echo") || $0.postcardTypes.contains("relationship_card"))
            } ?? scenes.dropFirst().first
            let second = planItem(
                sequence: 2,
                dayOffset: 4,
                type: "motif_echo",
                fallbackArc: "回声型",
                weight: 2,
                scene: secondScene,
                scenes: scenes,
                departedAt: departedAt
            )
            return [first, second]
        }
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
            animalId: animal.id,
            profileId: animal.profileId,
            destination: destination.displayName,
            cityId: destination.cityId ?? destination.id,
            sceneId: "",
            postcardType: "daily_observation",
            microArc: "动作型",
            emotionalWeight: 0,
            revealBudget: "none",
            relationshipStageAtSend: "stranger",
            title: title,
            body: body,
            imageAssetName: "postcard_\(destination.id)_\(animal.id)",
            templateAssetName: destination.postcardTemplateAssetName ?? "postcard_template_landscape_v102",
            destinationAssetName: destination.landmarkAssetName,
            stampAssetName: destination.stampAssetName,
            animalAssetName: animal.selfieAssetName,
            envelopeAssetName: "envelope_unread",
            sentAt: date,
            subtitle: destination.postcardSubtitle,
            isRead: false
        )
    }

    private func planItem(
        sequence: Int,
        dayOffset: Int,
        type: String,
        fallbackArc: String,
        weight: Int,
        scene: ManifestPostcardScene? = nil,
        scenes: [ManifestPostcardScene],
        departedAt: Date
    ) -> TripPostcardPlanItem {
        let selectedScene = scene ?? scenes.first { $0.postcardTypes.contains(type) } ?? scenes.first
        let microArc = selectedScene?.microArcFits.first ?? fallbackArc
        return TripPostcardPlanItem(
            sequence: sequence,
            dueAt: departedAt.addingTimeInterval(TimeInterval(dayOffset) * 60 * 60 * 24),
            postcardType: type,
            preferredMicroArc: microArc,
            plannedEmotionalWeight: weight,
            sceneId: selectedScene?.sceneId ?? ""
        )
    }
}
