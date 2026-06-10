import Foundation

struct PostcardNarrativeEngine {
    func makePostcard(
        for trip: Trip,
        planItem: TripPostcardPlanItem,
        animal: Animal,
        destination: ManifestDestination,
        narrative: ManifestNarrative?,
        memory: AnimalRelationshipMemory,
        recentPostcards: [Postcard],
        on date: Date = Date()
    ) -> Postcard {
        let profile = narrative?.profiles.first { $0.id == animal.profileId }
        let scene = selectedScene(
            from: destination.scenes ?? [],
            planItem: planItem,
            animal: animal,
            recentSceneIds: memory.recentSceneIds
        )
        let template = narrative?.templates.first {
            $0.postcardType == planItem.postcardType &&
            $0.microArc == planItem.preferredMicroArc
        } ?? narrative?.templates.first { $0.postcardType == planItem.postcardType }
        let emotionalWeight = min(
            planItem.plannedEmotionalWeight,
            template?.maxEmotionalWeight ?? planItem.plannedEmotionalWeight
        )
        let motif = selectedMotif(profile: profile, memory: memory, date: date)
        let object = pick(scene?.localObjects, fallback: "票角", salt: trip.id + "object")
        let action = pick(scene?.availableActions, fallback: "把那件东西放回原位", salt: trip.id + "action")
        let sensory = pick(scene?.sensoryDetails, fallback: "风从纸边擦过去", salt: trip.id + "sense")
        let reaction = selectedReaction(
            profile: profile,
            animal: animal,
            type: planItem.postcardType,
            salt: trip.id + "\(planItem.sequence)"
        )
        let body = bodyText(
            destinationName: destination.displayName,
            scene: scene,
            sensory: sensory,
            object: object,
            action: action,
            motif: motif,
            reaction: reaction,
            postcardType: planItem.postcardType,
            microArc: planItem.preferredMicroArc
        )

        return Postcard(
            id: "postcard_\(trip.id)_\(planItem.sequence)_\(Int(date.timeIntervalSince1970))",
            tripId: trip.id,
            animalId: animal.id,
            profileId: animal.profileId,
            destination: destination.displayName,
            cityId: destination.cityId ?? destination.id,
            sceneId: scene?.sceneId ?? planItem.sceneId,
            postcardType: planItem.postcardType,
            microArc: planItem.preferredMicroArc,
            emotionalWeight: emotionalWeight,
            revealBudget: template?.revealBudget ?? "tiny",
            relationshipStageAtSend: memory.relationshipStage,
            title: "\(animal.name)寄来的\(destination.displayName)明信片",
            body: body,
            imageAssetName: "postcard_\(destination.id)_\(animal.id)",
            templateAssetName: destination.postcardTemplateAssetName ?? "postcard_template_landscape_v102",
            destinationAssetName: destination.landmarkAssetName,
            stampAssetName: destination.stampAssetName,
            animalAssetName: animal.selfieAssetName,
            envelopeAssetName: "envelope_unread",
            sentAt: date,
            subtitle: planItem.sequence == 1 ? "旅途中寄来" : "第二封来信",
            isRead: false
        )
    }

    private func selectedScene(
        from scenes: [ManifestPostcardScene],
        planItem: TripPostcardPlanItem,
        animal: Animal,
        recentSceneIds: [String]
    ) -> ManifestPostcardScene? {
        if let planned = scenes.first(where: { $0.sceneId == planItem.sceneId }),
           recentSceneIds.contains(planned.sceneId) == false {
            return planned
        }
        return scenes.first {
            $0.postcardTypes.contains(planItem.postcardType) &&
            $0.animalAffinity.contains(animal.profileId) &&
            recentSceneIds.contains($0.sceneId) == false
        } ?? scenes.first {
            $0.postcardTypes.contains(planItem.postcardType) &&
            recentSceneIds.contains($0.sceneId) == false
        } ?? scenes.first
    }

    private func selectedMotif(
        profile: ManifestAnimalProfile?,
        memory: AnimalRelationshipMemory,
        date: Date
    ) -> String {
        let motifs = profile?.motifs ?? ["票角", "门牌", "纸袋"]
        return motifs.first { memory.recentlyUsedMotifs.contains($0) == false } ?? motifs[stableIndex(seed: Int(date.timeIntervalSince1970), count: motifs.count)]
    }

    private func selectedReaction(
        profile: ManifestAnimalProfile?,
        animal: Animal,
        type: String,
        salt: String
    ) -> String {
        let lines = type == "relationship_card"
            ? (profile?.relationshipLines ?? [])
            : (profile?.reactionLines ?? [])
        return pick(lines, fallback: "我把这件事记在明信片背面。", salt: salt)
    }

    private func bodyText(
        destinationName: String,
        scene: ManifestPostcardScene?,
        sensory: String,
        object: String,
        action: String,
        motif: String,
        reaction: String,
        postcardType: String,
        microArc: String
    ) -> String {
        let place = scene?.sceneType.displayName ?? "街角"
        switch microArc {
        case "误会型":
            return "\(destinationName)的\(place)边，\(sensory)。\(object)看起来像被谁弄丢了。我\(action)，后来发现只是放错了位置。\(reaction)"
        case "旁观型":
            return "\(destinationName)的\(place)很安静，\(sensory)。\(object)就放在旁边，我没有急着走，只看见有人把那件东西重新放好。\(reaction)"
        case "回声型":
            return "\(destinationName)的\(place)有一点风，\(object)压住了\(motif)一样的影子。我\(action)，没有解释，只把这件小事寄回来。\(reaction)"
        case "选择型":
            return "\(destinationName)的\(place)旁，\(sensory)。\(object)被挪到边上，我想了一会儿，还是\(action)。\(reaction)"
        default:
            return "\(destinationName)的\(place)里，\(sensory)。\(object)就在旁边，我\(action)，事情就小小地停在那里。\(reaction)"
        }
    }

    private func pick(_ values: [String]?, fallback: String, salt: String) -> String {
        guard let values, values.isEmpty == false else { return fallback }
        return values[stableIndex(seed: stableHash(salt), count: values.count)]
    }

    private func stableIndex(seed: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(UInt(bitPattern: seed) % UInt(count))
    }

    private func stableHash(_ value: String) -> Int {
        value.utf8.reduce(5381) { hash, byte in
            ((hash << 5) &+ hash) &+ Int(byte)
        }
    }
}

private extension String {
    var displayName: String {
        switch self {
        case "bookish_place": return "旧书店门口"
        case "street_corner": return "旧街转角"
        case "museum_edge": return "展馆侧门"
        case "lodging": return "旅馆洗衣房"
        case "pier": return "码头边"
        case "food_counter": return "外带窗口"
        case "repair_stand": return "修补摊前"
        case "quiet_place": return "长椅旁"
        default: return "街角"
        }
    }
}
