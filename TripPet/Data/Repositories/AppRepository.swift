import Combine
import Foundation

@MainActor
final class AppRepository: ObservableObject {
    @Published private(set) var animals: [Animal]
    @Published private(set) var travelWishes: [TravelWish]
    @Published private(set) var trips: [Trip]
    @Published private(set) var postcards: [Postcard]
    @Published private(set) var tickets: [Ticket]
    @Published private(set) var relationshipMemories: [AnimalRelationshipMemory]
    @Published private(set) var userFlags: AppUserFlags
    @Published private(set) var cabinLodging: CabinLodgingState

    private let store: AppUserStateStore
    private let calendar: Calendar
    private let maxDailyAnimalDepartures = 3
    private let nextAnimalArrivalDelayRange: ClosedRange<TimeInterval> = (10 * 60)...(30 * 60)

    init(seed: SeedData, store: AppUserStateStore? = nil, calendar: Calendar = .current) {
        let resolvedStore = store ?? InMemoryUserStateStore()
        self.store = resolvedStore
        self.calendar = calendar
        let userState = resolvedStore.load(seed: seed)
        animals = seed.animals
        travelWishes = userState.travelWishes
        trips = userState.trips
        postcards = userState.postcards
        tickets = userState.tickets
        relationshipMemories = userState.relationshipMemories
        userFlags = userState.flags
        cabinLodging = userState.cabinLodging
        refreshCabinLodging()
    }

    var residentAnimal: Animal? {
        animals.first(where: \.isResident)
    }

    var currentCabinAnimal: Animal? {
        guard let id = cabinLodging.currentAnimalId else { return nil }
        return animals.first { $0.id == id }
    }

    var isCabinEmpty: Bool {
        cabinLodging.currentAnimalId == nil && cabinLodging.dispatchedCount < maxDailyAnimalDepartures
    }

    var isNextAnimalApproaching: Bool {
        cabinLodging.currentAnimalId == nil &&
            cabinLodging.dispatchedCount < maxDailyAnimalDepartures &&
            cabinLodging.emptyUntil != nil
    }

    var hasReachedDailyAnimalLimit: Bool {
        cabinLodging.currentAnimalId == nil && cabinLodging.dispatchedCount >= maxDailyAnimalDepartures
    }

    var activeWish: TravelWish? {
        travelWishes.first { $0.status == .waiting || $0.status == .ready }
    }

    var currentTravelWish: TravelWish? {
        guard let animalId = currentCabinAnimal?.id else { return activeWish }
        return activeWish(for: animalId)
    }

    var activeTrip: Trip? {
        trips.first { $0.status == .preparing || $0.status == .traveling }
    }

    func animalName(for animalId: String) -> String {
        animals.first { $0.id == animalId }?.name ?? "小动物"
    }

    func hasGiftedTicketToday(calendar: Calendar = .current) -> Bool {
        tickets.contains { calendar.isDateInToday($0.giftedAt) }
    }

    func giftedTicketCountToday(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        tickets
            .filter { calendar.isDate($0.giftedAt, inSameDayAs: date) }
            .reduce(0) { total, ticket in
                total + max(1, ticket.ticketCount)
            }
    }

    func canUseFirstImmediateTicket(authorizationStatus: StepCountAuthorizationStatus) -> Bool {
        authorizationStatus.canAttemptStepRead &&
            tickets.isEmpty &&
            userFlags.firstImmediateTicketGifted == false
    }

    func refreshCabinLodging(on date: Date = Date()) {
        let startOfDay = calendar.startOfDay(for: date)
        if calendar.isDate(cabinLodging.statusDate, inSameDayAs: date) == false {
            cabinLodging = CabinLodgingState.initial(
                on: date,
                animalId: firstCabinAnimalId(forDispatchIndex: 0)
            )
            saveState()
            return
        }

        if let emptyUntil = cabinLodging.emptyUntil,
           emptyUntil <= date,
           cabinLodging.dispatchedCount < maxDailyAnimalDepartures {
            cabinLodging.statusDate = startOfDay
            cabinLodging.currentAnimalId = firstCabinAnimalId(forDispatchIndex: cabinLodging.dispatchedCount)
            cabinLodging.emptyUntil = nil
            saveState()
        }
    }

    @discardableResult
    func giftTicket(
        sourceSteps: Int,
        ticketCount: Int,
        date: Date = Date(),
        destinations: [ManifestDestination] = [],
        scheduler: PostcardScheduler = PostcardScheduler(),
        isFirstImmediateTicket: Bool = false
    ) -> Trip? {
        refreshCabinLodging(on: date)
        guard cabinLodging.dispatchedCount < maxDailyAnimalDepartures,
              let animal = currentCabinAnimal else {
            return nil
        }

        guard let resolvedWish = activeWish(for: animal.id) ?? createNextWish(
            for: animal,
            destinations: destinations,
            date: date
        ) else {
            return nil
        }

        let isFirstGiftEver = tickets.isEmpty
        let ticket = Ticket(
            id: UUID(),
            date: date,
            sourceSteps: sourceSteps,
            ticketCount: ticketCount,
            giftedAt: date
        )
        tickets.append(ticket)

        if let index = travelWishes.firstIndex(where: { $0.id == resolvedWish.id }),
           travelWishes[index].status == .waiting || travelWishes[index].status == .ready {
            travelWishes[index].status = .traveling
        }

        let destination = destinations.first {
            $0.id == resolvedWish.destinationId || $0.displayName == resolvedWish.destination
        }
        let plan = destination.map { scheduler.makePostcardPlan(for: $0, departedAt: date) } ?? []
        let expectedReturnAt = plan.last?.dueAt ?? date.addingTimeInterval(60 * 60 * 24)
        let travelKind = destination.flatMap { TravelKind(rawValue: $0.travelKind ?? "") } ?? .standard
        let trip = Trip(
            id: UUID().uuidString,
            animalId: animal.id,
            destinationId: resolvedWish.destinationId,
            destination: resolvedWish.destination,
            departedAt: date,
            expectedReturnAt: expectedReturnAt,
            status: .traveling,
            travelKind: travelKind,
            postcardPlan: plan,
            revealedPostcardCount: 0,
            completedAt: nil
        )
        trips.append(trip)
        markTripStarted(for: animal.id, cityId: destination?.cityId ?? resolvedWish.destinationId)

        if isFirstGiftEver && isFirstImmediateTicket && userFlags.firstImmediateTicketGifted == false {
            userFlags.firstImmediateTicketGifted = true
        }

        if isFirstGiftEver && userFlags.firstAirportPostcardDelivered == false {
            postcards.insert(
                makeFirstAirportPostcard(for: trip, animal: animal, date: date),
                at: 0
            )
            userFlags.firstAirportPostcardDelivered = true
        }

        cabinLodging.statusDate = calendar.startOfDay(for: date)
        cabinLodging.dispatchedCount += 1
        cabinLodging.currentAnimalId = nil
        cabinLodging.emptyUntil = cabinLodging.dispatchedCount >= maxDailyAnimalDepartures
            ? nil
            : date.addingTimeInterval(randomNextAnimalArrivalDelay())
        saveState()
        return trip
    }

    @discardableResult
    func completeTrip(_ trip: Trip, postcard: Postcard? = nil) -> Bool {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) else {
            return false
        }

        trips[tripIndex].status = .completed
        trips[tripIndex].completedAt = Date()

        if let wishIndex = travelWishes.firstIndex(where: {
            $0.animalId == trip.animalId &&
            $0.destination == trip.destination &&
            $0.status == .traveling
        }) {
            travelWishes[wishIndex].status = .completed
        }

        if let postcard, !postcards.contains(where: { $0.id == postcard.id }) {
            postcards.insert(postcard, at: 0)
        }

        saveState()
        return true
    }

    func markPostcardRead(_ postcard: Postcard) {
        guard let index = postcards.firstIndex(where: { $0.id == postcard.id }) else { return }
        postcards[index].isRead = true
        saveState()
    }

    @discardableResult
    func revealEligiblePostcards(
        scheduler: PostcardScheduler,
        destinations: [ManifestDestination],
        narrative: ManifestNarrative? = nil,
        on date: Date = Date()
    ) -> Bool {
        var didReveal = false

        for trip in trips where trip.status == .traveling {
            guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }),
                  let animal = animals.first(where: { $0.id == trip.animalId }),
                  let destination = destinations.first(where: { $0.id == trip.destinationId || $0.displayName == trip.destination }) else {
                continue
            }

            if trip.postcardPlan.isEmpty {
                guard scheduler.shouldRevealPostcard(for: trip, on: date),
                      postcards.contains(where: { $0.tripId == trip.id && $0.postcardType != "first_airport_departure" }) == false else {
                    continue
                }
                let postcard = scheduler.makePostcard(
                    for: trip,
                    animal: animal,
                    destination: destination,
                    on: date
                )
                didReveal = completeTrip(trip, postcard: postcard) || didReveal
                continue
            }

            let nextSequence = trip.revealedPostcardCount
            guard nextSequence < trip.postcardPlan.count else { continue }
            let planItem = trip.postcardPlan[nextSequence]
            guard date >= planItem.dueAt,
                  postcards.contains(where: { $0.tripId == trip.id && $0.id.contains("_\(planItem.sequence)_") }) == false else {
                continue
            }

            let memory = relationshipMemory(for: animal.id)
            let postcard = PostcardNarrativeEngine().makePostcard(
                for: trip,
                planItem: planItem,
                animal: animal,
                destination: destination,
                narrative: narrative,
                memory: memory,
                recentPostcards: postcards.filter { $0.animalId == animal.id },
                on: date
            )

            postcards.insert(postcard, at: 0)
            trips[tripIndex].revealedPostcardCount += 1
            updateRelationshipMemory(afterSending: postcard)

            if trips[tripIndex].revealedPostcardCount >= trips[tripIndex].postcardPlan.count {
                trips[tripIndex].status = .completed
                trips[tripIndex].completedAt = date
                completeTravelingWish(for: trips[tripIndex])
            }

            didReveal = true
        }

        if didReveal {
            saveState()
        }
        return didReveal
    }

    func completeOnboarding() {
        userFlags.onboardingCompleted = true
        saveState()
    }

    func dismissHealthGuide() {
        userFlags.healthGuideDismissed = true
        saveState()
    }

    func resetAppGuidesForPreview() {
        userFlags = AppUserFlags()
        saveState()
    }

    private func saveState() {
        store.save(
            AppUserState(
                travelWishes: travelWishes,
                trips: trips,
                postcards: postcards,
                tickets: tickets,
                relationshipMemories: relationshipMemories,
                flags: userFlags,
                cabinLodging: cabinLodging
            )
        )
    }

    private func firstCabinAnimalId(forDispatchIndex dispatchIndex: Int) -> String? {
        let travelAnimals = animals.filter(\.canTravel)
        let orderedAnimals = travelAnimals.isEmpty ? animals : travelAnimals
        guard orderedAnimals.isEmpty == false else { return nil }
        return orderedAnimals[dispatchIndex % orderedAnimals.count].id
    }

    private func activeWish(for animalId: String) -> TravelWish? {
        travelWishes.first {
            $0.animalId == animalId && ($0.status == .waiting || $0.status == .ready)
        }
    }

    private func createNextWish(
        for animal: Animal,
        destinations: [ManifestDestination],
        date: Date
    ) -> TravelWish? {
        guard destinations.isEmpty == false else { return nil }
        let completedCount = travelWishes.filter {
            $0.animalId == animal.id && $0.status == .completed
        }.count
        let destination = destinations[completedCount % destinations.count]
        let wish = TravelWish(
            id: "wish_\(destination.id)_\(animal.id)_\(Int(date.timeIntervalSince1970))",
            animalId: animal.id,
            destinationId: destination.id,
            destination: destination.displayName,
            destinationAssetName: destination.landmarkAssetName,
            requiredTickets: 1,
            status: .waiting,
            createdAt: date
        )
        travelWishes.append(wish)
        return wish
    }

    private func randomNextAnimalArrivalDelay() -> TimeInterval {
        TimeInterval.random(in: nextAnimalArrivalDelayRange)
    }

    private func makeFirstAirportPostcard(for trip: Trip, animal: Animal, date: Date) -> Postcard {
        Postcard(
            id: "postcard_first_airport_\(animal.id)_\(Int(date.timeIntervalSince1970))",
            tripId: trip.id,
            animalId: animal.id,
            profileId: animal.profileId,
            destination: "机场",
            cityId: "first_airport",
            sceneId: "airport_departure",
            postcardType: "first_airport_departure",
            microArc: "出发型",
            emotionalWeight: 0,
            revealBudget: "none",
            relationshipStageAtSend: relationshipMemory(for: animal.id).relationshipStage,
            title: "小动物寄来的第一张明信片",
            body: "我已经出发啦！谢谢你赠送的机票，等我给你寄明信片哦！",
            imageAssetName: "postcard_airport_first_departure",
            templateAssetName: "postcard_template_landscape_v102",
            destinationAssetName: "postcard_airport_first_departure",
            stampAssetName: "stamp_airport_first_departure",
            animalAssetName: animal.selfieAssetName,
            envelopeAssetName: "envelope_unread",
            sentAt: date,
            subtitle: "刚到机场",
            isRead: false
        )
    }

    private func completeTravelingWish(for trip: Trip) {
        if let wishIndex = travelWishes.firstIndex(where: {
            $0.animalId == trip.animalId &&
            $0.destinationId == trip.destinationId &&
            $0.status == .traveling
        }) {
            travelWishes[wishIndex].status = .completed
        }
    }

    private func relationshipMemory(for animalId: String) -> AnimalRelationshipMemory {
        if let memory = relationshipMemories.first(where: { $0.animalId == animalId }) {
            return memory
        }
        return AnimalRelationshipMemory(animalId: animalId)
    }

    private func markTripStarted(for animalId: String, cityId: String) {
        let memory = relationshipMemory(for: animalId)
        upsertRelationshipMemory { editable in
            if editable.animalId != animalId { return }
            editable.encounterCount = max(editable.encounterCount + 1, 1)
            editable.tripCount += 1
            if editable.visitedCityIds.contains(cityId) == false {
                editable.visitedCityIds.append(cityId)
            }
            editable.relationshipStage = relationshipStage(encounterCount: editable.encounterCount, tripCount: editable.tripCount)
        } defaultMemory: {
            var newMemory = memory
            newMemory.encounterCount = max(newMemory.encounterCount + 1, 1)
            newMemory.tripCount += 1
            newMemory.visitedCityIds = [cityId]
            newMemory.relationshipStage = relationshipStage(encounterCount: newMemory.encounterCount, tripCount: newMemory.tripCount)
            return newMemory
        }
    }

    private func updateRelationshipMemory(afterSending postcard: Postcard) {
        let memory = relationshipMemory(for: postcard.animalId)
        upsertRelationshipMemory { editable in
            if editable.animalId != postcard.animalId { return }
            if editable.sentPostcardIds.contains(postcard.id) == false {
                editable.sentPostcardIds.append(postcard.id)
            }
            editable.recentSceneIds.append(postcard.sceneId)
            editable.recentSceneIds = Array(editable.recentSceneIds.suffix(8))
            editable.recentlyUsedMotifs.append(postcard.microArc)
            editable.recentlyUsedMotifs = Array(editable.recentlyUsedMotifs.suffix(8))
        } defaultMemory: {
            var newMemory = memory
            newMemory.sentPostcardIds = [postcard.id]
            newMemory.recentSceneIds = [postcard.sceneId]
            newMemory.recentlyUsedMotifs = [postcard.microArc]
            return newMemory
        }
    }

    private func upsertRelationshipMemory(
        update: (inout AnimalRelationshipMemory) -> Void,
        defaultMemory: () -> AnimalRelationshipMemory
    ) {
        var memory = defaultMemory()
        if let index = relationshipMemories.firstIndex(where: { $0.animalId == memory.animalId }) {
            update(&relationshipMemories[index])
        } else {
            update(&memory)
            relationshipMemories.append(memory)
        }
    }

    private func relationshipStage(encounterCount: Int, tripCount: Int) -> String {
        if tripCount >= 8 || encounterCount >= 12 { return "attached" }
        if tripCount >= 5 || encounterCount >= 8 { return "trusted" }
        if tripCount >= 3 || encounterCount >= 5 { return "familiar" }
        if tripCount >= 1 || encounterCount >= 2 { return "testing" }
        return "stranger"
    }
}
