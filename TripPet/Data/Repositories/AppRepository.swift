import Combine
import Foundation

@MainActor
final class AppRepository: ObservableObject {
    @Published private(set) var animals: [Animal]
    @Published private(set) var travelWishes: [TravelWish]
    @Published private(set) var trips: [Trip]
    @Published private(set) var postcards: [Postcard]
    @Published private(set) var tickets: [Ticket]
    @Published private(set) var userFlags: AppUserFlags
    @Published private(set) var cabinLodging: CabinLodgingState
    @Published private(set) var consumedPostcardTextIds: Set<String>

    private let store: AppUserStateStore
    private let calendar: Calendar
    private let destinations: [ManifestDestination]
    private let postcardScheduler: PostcardScheduler
    private let randomDestinationIndex: (Int) -> Int
    private let maxDailyAnimalDepartures = 3
    private let maxCabinAnimals = 9
    private static let minimumDestinationSpacingDegrees = 12.0
    private static let defaultInitialCabinAnimalId = "moji_cat"

    init(
        seed: SeedData,
        store: AppUserStateStore? = nil,
        calendar: Calendar = .current,
        postcardScheduler: PostcardScheduler = PostcardScheduler(),
        randomDestinationIndex: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) {
        let resolvedStore = store ?? InMemoryUserStateStore()
        self.store = resolvedStore
        self.calendar = calendar
        self.postcardScheduler = postcardScheduler
        self.randomDestinationIndex = randomDestinationIndex
        destinations = seed.destinations
        let userState = resolvedStore.load(seed: seed)
        animals = seed.animals
        let availableAnimalIds = Set(seed.animals.map(\.id))
        travelWishes = Self.migratedTravelWishes(userState.travelWishes, availableAnimalIds: availableAnimalIds)
        trips = Self.migratedTrips(userState.trips, availableAnimalIds: availableAnimalIds)
        postcards = userState.postcards
        tickets = userState.tickets
        userFlags = userState.flags
        cabinLodging = Self.migratedCabinLodging(userState.cabinLodging, availableAnimalIds: availableAnimalIds)
        consumedPostcardTextIds = userState.consumedPostcardTextIds
        normalizePendingPostcardPlans()
        if travelWishes != userState.travelWishes ||
            trips != userState.trips ||
            cabinLodging != userState.cabinLodging {
            saveState()
        }
        ensureOpenWishes(on: Date())
        ensureFirstAirportPostcardIfNeeded()
        refreshCabinLodging()
    }

    var residentAnimal: Animal? {
        animals.first(where: \.isResident)
    }

    var cabinAnimals: [Animal] {
        cabinLodging.presentAnimalIds.compactMap { animalId in
            animals.first { $0.id == animalId }
        }
    }

    var currentCabinAnimal: Animal? {
        cabinAnimals.first
    }

    var isCabinEmpty: Bool {
        cabinAnimals.isEmpty && cabinLodging.dispatchedCount < maxDailyAnimalDepartures
    }

    var hasReachedDailyAnimalLimit: Bool {
        cabinAnimals.isEmpty && cabinLodging.dispatchedCount >= maxDailyAnimalDepartures
    }

    var activeWish: TravelWish? {
        currentCabinAnimal.flatMap { activeWish(for: $0.id) } ??
            travelWishes.first { $0.status == .waiting || $0.status == .ready }
    }

    var activeTrip: Trip? {
        trips.first { $0.status == .preparing || $0.status == .traveling }
    }

    var activeTravelTrips: [Trip] {
        Array(
            trips
                .filter { $0.status == .preparing || $0.status == .traveling }
                .prefix(9)
        )
    }

    func animal(for animalId: String) -> Animal? {
        let normalizedAnimalId = normalizedAnimalId(animalId)
        return animals.first { $0.id == normalizedAnimalId }
    }

    func animalName(for animalId: String) -> String {
        let normalizedAnimalId = normalizedAnimalId(animalId)
        return animals.first { $0.id == normalizedAnimalId }?.name ?? "小动物"
    }

    func activeWish(for animalId: String) -> TravelWish? {
        let normalizedAnimalId = normalizedAnimalId(animalId)
        return travelWishes.first {
            $0.animalId == normalizedAnimalId &&
                ($0.status == .waiting || $0.status == .ready)
        }
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

    func stepFundedTicketCountToday(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        tickets
            .filter { calendar.isDate($0.giftedAt, inSameDayAs: date) && $0.sourceSteps > 0 }
            .reduce(0) { total, ticket in
                total + max(1, ticket.ticketCount)
            }
    }

    func dailyLimitedTicketCountToday(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        stepFundedTicketCountToday(on: date, calendar: calendar)
    }

    func canUseFirstImmediateTicket() -> Bool {
        tickets.isEmpty && userFlags.firstImmediateTicketGifted == false
    }

    func refreshCabinLodging(on date: Date = Date()) {
        let originalState = cabinLodging
        cabinLodging.statusDate = calendar.startOfDay(for: date)
        cabinLodging.dispatchedCount = dailyLimitedTicketCountToday(on: date, calendar: calendar)
        cabinLodging.emptyUntil = nil
        cabinLodging.presentAnimalIds = refreshedCabinAnimalIds()

        if cabinLodging != originalState {
            saveState()
        }
    }

    @discardableResult
    func giftTicket(
        sourceSteps: Int,
        ticketCount: Int,
        animalId: String? = nil,
        date: Date = Date(),
        isFirstImmediateTicket: Bool = false
    ) -> Trip? {
        refreshCabinLodging(on: date)
        guard cabinLodging.dispatchedCount < maxDailyAnimalDepartures else {
            return nil
        }

        let resolvedAnimalId = animalId ?? cabinLodging.presentAnimalIds.first
        guard let resolvedAnimalId,
              cabinLodging.presentAnimalIds.contains(resolvedAnimalId),
              let animal = animals.first(where: { $0.id == resolvedAnimalId }) else {
            return nil
        }
        let isFirstGiftEver = tickets.isEmpty

        ensureOpenWish(for: animal.id, on: date)
        guard let resolvedWish = departureWish(for: animal.id, on: date) else { return nil }

        let ticket = Ticket(
            id: UUID(),
            date: date,
            sourceSteps: sourceSteps,
            ticketCount: ticketCount,
            animalId: animal.id,
            giftedAt: date
        )
        tickets.append(ticket)

        if isFirstImmediateTicket {
            userFlags.firstImmediateTicketGifted = true
        }

        if let index = travelWishes.firstIndex(where: { $0.id == resolvedWish.id }),
           travelWishes[index].status == .waiting || travelWishes[index].status == .ready {
            travelWishes[index].status = .traveling
        }

        let trip = Trip(
            id: UUID().uuidString,
            animalId: animal.id,
            destinationId: resolvedWish.destinationId,
            destination: resolvedWish.destination,
            departedAt: date,
            expectedReturnAt: date.addingTimeInterval(PostcardScheduler.tripDuration),
            status: .traveling,
            postcardPlan: postcardScheduler.makePostcardPlan(departedAt: date),
            completedAt: nil
        )
        trips.append(trip)

        if isFirstGiftEver,
           isFirstImmediateTicket,
           userFlags.firstAirportPostcardDelivered == false {
            postcards.insert(
                makeFirstAirportPostcard(for: trip, animal: animal, date: date),
                at: 0
            )
            userFlags.firstAirportPostcardDelivered = true
        }

        refreshCabinLodging(on: date)
        saveState()
        return trip
    }

    @discardableResult
    func completeTrip(_ trip: Trip, postcard: Postcard? = nil) -> Bool {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) else {
            return false
        }

        if let postcard, !postcards.contains(where: { $0.id == postcard.id }) {
            postcards.insert(postcard, at: 0)
        }

        finishTrip(at: tripIndex, on: postcard?.sentAt ?? Date())
        saveState()
        return true
    }

    @discardableResult
    func markPostcardRead(_ postcard: Postcard) -> Bool {
        guard let index = postcards.firstIndex(where: { $0.id == postcard.id }),
              postcards[index].isRead == false else {
            return false
        }

        postcards[index].isRead = true
        store.markPostcardRead(postcardId: postcard.id)
        return true
    }

    private func ensureFirstAirportPostcardIfNeeded() {
        guard userFlags.firstAirportPostcardDelivered == false else { return }

        if postcards.contains(where: { Self.isFirstAirportPostcard($0) }) {
            userFlags.firstAirportPostcardDelivered = true
            saveState()
            return
        }

        guard userFlags.firstImmediateTicketGifted,
              let firstTrip = trips.sorted(by: { $0.departedAt < $1.departedAt }).first,
              let animal = animals.first(where: { $0.id == firstTrip.animalId }) else {
            return
        }

        postcards.insert(
            makeFirstAirportPostcard(for: firstTrip, animal: animal, date: firstTrip.departedAt),
            at: 0
        )
        userFlags.firstAirportPostcardDelivered = true
        saveState()
    }

    private static func isFirstAirportPostcard(_ postcard: Postcard) -> Bool {
        postcard.id.hasPrefix("postcard_first_airport_") ||
            postcard.destinationAssetName == "postcard_destination_airport" ||
            postcard.destinationAssetName == "postcard_airport_first_departure"
    }

    @discardableResult
    func revealEligiblePostcards(
        scheduler: PostcardScheduler,
        destinations: [ManifestDestination],
        on date: Date = Date()
    ) -> Bool {
        var didChange = false

        for index in trips.indices where trips[index].status == .traveling {
            let trip = trips[index]
            guard let animal = animals.first(where: { $0.id == trip.animalId }),
                  let destination = destinations.first(where: { $0.id == trip.destinationId || $0.displayName == trip.destination }) else {
                continue
            }

            if trip.postcardPlan.isEmpty {
                if scheduler.shouldRevealPostcard(for: trip, on: date),
                   postcards.contains(where: { $0.tripId == trip.id }) == false {
                    let postcard = makePostcard(
                        scheduler: scheduler,
                        for: trip,
                        animal: animal,
                        destination: destination,
                        on: date
                    )
                    postcards.insert(postcard, at: 0)
                    finishTrip(at: index, on: date)
                    didChange = true
                }
                continue
            }

            for planIndex in trips[index].postcardPlan.indices {
                let planItem = trips[index].postcardPlan[planIndex]
                guard scheduler.shouldRevealPostcard(for: planItem, on: date) else {
                    continue
                }

                let postcardId = "postcard_\(trips[index].id)_\(planItem.sequence)"
                guard postcards.contains(where: { $0.id == postcardId }) == false else {
                    trips[index].postcardPlan[planIndex].revealedAt = date
                    didChange = true
                    continue
                }

                let postcard = makePostcard(
                    scheduler: scheduler,
                    for: trips[index],
                    animal: animal,
                    destination: destination,
                    sequence: planItem.sequence,
                    on: date
                )
                postcards.insert(postcard, at: 0)
                trips[index].postcardPlan[planIndex].revealedAt = date
                didChange = true
            }

            if date >= trips[index].expectedReturnAt,
               trips[index].postcardPlan.allSatisfy({ $0.revealedAt != nil }) {
                finishTrip(at: index, on: date)
                didChange = true
            }
        }

        if didChange {
            saveState()
        }
        return didChange
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
                flags: userFlags,
                cabinLodging: cabinLodging,
                consumedPostcardTextIds: consumedPostcardTextIds
            )
        )
    }

    private func normalizePendingPostcardPlans() {
        for index in trips.indices where trips[index].status == .traveling || trips[index].status == .preparing {
            guard trips[index].postcardPlan.isEmpty == false else { continue }
            trips[index].postcardPlan = postcardScheduler.normalizedPostcardPlan(trips[index].postcardPlan)
        }
    }

    private func makePostcard(
        scheduler: PostcardScheduler,
        for trip: Trip,
        animal: Animal,
        destination: ManifestDestination,
        sequence: Int = 1,
        on date: Date
    ) -> Postcard {
        let narrative = PostcardTextLibrary.randomEntry(
            for: animal,
            on: date,
            calendar: calendar,
            excluding: consumedPostcardTextIds
        )
        if let narrative {
            consumedPostcardTextIds.insert(narrative.id)
        }
        return scheduler.makePostcard(
            for: trip,
            animal: animal,
            destination: destination,
            sequence: sequence,
            on: date,
            bodyOverride: narrative?.body
        )
    }

    private func finishTrip(at index: Int, on date: Date) {
        guard trips.indices.contains(index), trips[index].status != .completed else {
            return
        }

        let trip = trips[index]
        trips[index].status = .completed
        trips[index].completedAt = date

        if let wishIndex = travelWishes.firstIndex(where: {
            $0.animalId == trip.animalId &&
                $0.destinationId == trip.destinationId &&
                $0.status == .traveling
        }) {
            travelWishes[wishIndex].status = .completed
        }

        ensureOpenWish(for: trip.animalId, on: date)
        appendReturnedAnimalIfNeeded(trip.animalId, on: date)
    }

    private func makeFirstAirportPostcard(for trip: Trip, animal: Animal, date: Date) -> Postcard {
        Postcard(
            id: "postcard_first_airport_\(trip.id)",
            tripId: trip.id,
            destination: "机场",
            title: "\(animal.name)寄来的第一张明信片",
            body: "我到机场啦！谢谢你送我的机票。登机前先把第一张明信片寄回小屋，等我到了远方，再继续给你写信。",
            imageAssetName: "postcard_destination_airport",
            templateAssetName: "postcard_base_portrait",
            destinationAssetName: "postcard_destination_airport",
            stampAssetName: "postcard_stamp_airport",
            animalAssetName: animal.selfieAssetName,
            envelopeAssetName: "envelope_unread",
            sentAt: date,
            subtitle: "刚到机场",
            isRead: false
        )
    }

    private func ensureOpenWishes(on date: Date) {
        for animal in animals {
            ensureOpenWish(for: animal.id, on: date)
        }
    }

    private func ensureOpenWish(for animalId: String, on date: Date) {
        guard travelWishes.contains(where: {
            $0.animalId == animalId &&
                ($0.status == .waiting || $0.status == .ready || $0.status == .traveling)
        }) == false,
            let destination = nextDestination(for: animalId) else {
            return
        }

        travelWishes.append(
            TravelWish(
                id: "wish_\(destination.id)_\(animalId)_\(UUID().uuidString)",
                animalId: animalId,
                destinationId: destination.id,
                destination: destination.displayName,
                destinationAssetName: destination.landmarkAssetName,
                requiredTickets: 1,
                status: .waiting,
                createdAt: date
            )
        )
    }

    private func nextDestination(for animalId: String) -> ManifestDestination? {
        randomAvailableDestination(excludingAnimalId: animalId)
    }

    private func departureWish(for animalId: String, on date: Date) -> TravelWish? {
        guard var wish = activeWish(for: animalId) else { return nil }
        let needsReplacement = isDestinationOccupied(wish.destinationId, excludingAnimalId: animalId) ||
            isDestinationTooCloseToActiveTrips(wish.destinationId, excludingAnimalId: animalId)
        guard needsReplacement else {
            return wish
        }
        guard let replacement = randomAvailableDestination(excludingAnimalId: animalId) else {
            return nil
        }

        wish.destinationId = replacement.id
        wish.destination = replacement.displayName
        wish.destinationAssetName = replacement.landmarkAssetName
        wish.createdAt = date
        if let index = travelWishes.firstIndex(where: { $0.id == wish.id }) {
            travelWishes[index] = wish
        }
        return wish
    }

    private func randomAvailableDestination(excludingAnimalId animalId: String? = nil) -> ManifestDestination? {
        let availableDestinations = destinations.filter {
            isDestinationOccupied($0.id, excludingAnimalId: animalId) == false
        }
        guard availableDestinations.isEmpty == false else {
            return nil
        }

        let activeCoordinates = activeTripDestinationCoordinates(excludingAnimalId: animalId)
        let spacedDestinations = availableDestinations.filter {
            isDestination($0, farEnoughFrom: activeCoordinates)
        }
        let candidateDestinations = spacedDestinations.isEmpty ?
            farthestAvailableDestinations(from: availableDestinations, activeCoordinates: activeCoordinates) :
            spacedDestinations
        guard candidateDestinations.isEmpty == false else {
            return nil
        }

        let selectedIndex = randomDestinationIndex(candidateDestinations.count)
        return candidateDestinations[candidateDestinations.indices.contains(selectedIndex) ? selectedIndex : 0]
    }

    private func isDestinationOccupied(_ destinationId: String, excludingAnimalId animalId: String? = nil) -> Bool {
        trips.contains {
            ($0.status == .preparing || $0.status == .traveling) &&
                $0.destinationId == destinationId &&
                $0.animalId != animalId
        }
    }

    private func isDestinationTooCloseToActiveTrips(_ destinationId: String, excludingAnimalId animalId: String? = nil) -> Bool {
        guard let coordinate = destinationCoordinate(for: destinationId) else {
            return false
        }

        return activeTripDestinationCoordinates(excludingAnimalId: animalId).contains {
            coordinate.angularDistanceDegrees(to: $0) < Self.minimumDestinationSpacingDegrees
        }
    }

    private func isDestination(
        _ destination: ManifestDestination,
        farEnoughFrom activeCoordinates: [DestinationCoordinate]
    ) -> Bool {
        guard activeCoordinates.isEmpty == false else {
            return true
        }
        guard let coordinate = destinationCoordinate(for: destination.id) else {
            return false
        }

        return activeCoordinates.allSatisfy {
            coordinate.angularDistanceDegrees(to: $0) >= Self.minimumDestinationSpacingDegrees
        }
    }

    private func farthestAvailableDestinations(
        from availableDestinations: [ManifestDestination],
        activeCoordinates: [DestinationCoordinate]
    ) -> [ManifestDestination] {
        guard activeCoordinates.isEmpty == false else {
            return availableDestinations
        }

        let rankedDestinations = availableDestinations.compactMap { destination -> (destination: ManifestDestination, distance: Double)? in
            guard let coordinate = destinationCoordinate(for: destination.id),
                  let nearestDistance = activeCoordinates.map({ coordinate.angularDistanceDegrees(to: $0) }).min() else {
                return nil
            }

            return (destination, nearestDistance)
        }
        guard let farthestDistance = rankedDestinations.map(\.distance).max() else {
            return availableDestinations
        }

        return rankedDestinations
            .filter { abs($0.distance - farthestDistance) < 0.000001 }
            .map(\.destination)
    }

    private func activeTripDestinationCoordinates(excludingAnimalId animalId: String? = nil) -> [DestinationCoordinate] {
        trips.compactMap { trip in
            guard (trip.status == .preparing || trip.status == .traveling),
                  trip.animalId != animalId else {
                return nil
            }

            return destinationCoordinate(for: trip.destinationId)
        }
    }

    private func destinationCoordinate(for destinationId: String) -> DestinationCoordinate? {
        if let destination = destinations.first(where: { $0.id == destinationId }),
           let coordinate = DestinationCoordinate(destination: destination) {
            return coordinate
        }

        return DestinationCoordinate.legacyCoordinate(for: destinationId)
    }

    private func appendReturnedAnimalIfNeeded(_: String, on date: Date) {
        refreshCabinLodging(on: date)
    }

    private func isAnimalTraveling(_ animalId: String) -> Bool {
        let normalizedAnimalId = normalizedAnimalId(animalId)
        return trips.contains {
            $0.animalId == normalizedAnimalId && ($0.status == .preparing || $0.status == .traveling)
        }
    }

    private func refreshedCabinAnimalIds() -> [String] {
        if canUseFirstImmediateTicket() {
            guard let animalId = initialCabinAnimalId(),
                  isAnimalTraveling(animalId) == false else {
                return []
            }
            return [animalId]
        }

        return animals
            .filter { isAnimalTraveling($0.id) == false }
            .prefix(maxCabinAnimals)
            .map(\.id)
    }

    private func initialCabinAnimalId() -> String? {
        if animals.contains(where: { $0.id == Self.defaultInitialCabinAnimalId }) {
            return Self.defaultInitialCabinAnimalId
        }
        return residentAnimal?.id ?? animals.first?.id
    }

    private func normalizedAnimalId(_ animalId: String) -> String {
        Self.canonicalAnimalId(for: animalId, availableAnimalIds: Set(animals.map(\.id)))
    }

    private static let legacyAnimalIdMap: [String: String] = [
        "cat": "xiaoman_hamster",
        "dog": "tangyuan_puppy",
        "rabbit": "moji_cat",
        "map_cat": "deer_visitor",
        "post_dog": "fox_visitor",
        "fold_rabbit": "xiaolu_guinea_pig",
        "visitor_unknown": "dengdeng_rabbit",
        "quiet_cat": "feifei_parrot",
        "trail_dog": "bear_visitor"
    ]

    private static func canonicalAnimalId(for animalId: String, availableAnimalIds: Set<String>) -> String {
        guard let canonicalAnimalId = legacyAnimalIdMap[animalId],
              availableAnimalIds.contains(canonicalAnimalId) else {
            return animalId
        }
        return canonicalAnimalId
    }

    private static func migratedTravelWishes(_ wishes: [TravelWish], availableAnimalIds: Set<String>) -> [TravelWish] {
        wishes.map { wish in
            var migratedWish = wish
            migratedWish.animalId = canonicalAnimalId(for: wish.animalId, availableAnimalIds: availableAnimalIds)
            return migratedWish
        }
    }

    private static func migratedTrips(_ trips: [Trip], availableAnimalIds: Set<String>) -> [Trip] {
        trips.map { trip in
            var migratedTrip = trip
            migratedTrip.animalId = canonicalAnimalId(for: trip.animalId, availableAnimalIds: availableAnimalIds)
            return migratedTrip
        }
    }

    private static func migratedCabinLodging(
        _ cabinLodging: CabinLodgingState,
        availableAnimalIds: Set<String>
    ) -> CabinLodgingState {
        var migratedCabinLodging = cabinLodging
        var seen: Set<String> = []
        migratedCabinLodging.presentAnimalIds = cabinLodging.presentAnimalIds.compactMap { animalId in
            let normalizedAnimalId = canonicalAnimalId(for: animalId, availableAnimalIds: availableAnimalIds)
            guard availableAnimalIds.contains(normalizedAnimalId),
                  seen.contains(normalizedAnimalId) == false else {
                return nil
            }
            seen.insert(normalizedAnimalId)
            return normalizedAnimalId
        }
        return migratedCabinLodging
    }
}

private struct DestinationCoordinate {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init?(destination: ManifestDestination) {
        guard let latitude = destination.latitude,
              let longitude = destination.longitude else {
            return nil
        }

        self.init(latitude: latitude, longitude: longitude)
    }

    static func legacyCoordinate(for destinationId: String) -> DestinationCoordinate? {
        switch destinationId {
        case "paris":
            return DestinationCoordinate(latitude: 48.8566, longitude: 2.3522)
        case "iceland":
            return DestinationCoordinate(latitude: 64.1466, longitude: -21.9426)
        case "lisbon":
            return DestinationCoordinate(latitude: 38.7223, longitude: -9.1393)
        default:
            return nil
        }
    }

    func angularDistanceDegrees(to other: DestinationCoordinate) -> Double {
        let firstLatitude = latitude.radians
        let secondLatitude = other.latitude.radians
        let latitudeDelta = (other.latitude - latitude).radians
        let longitudeDelta = (other.longitude - longitude).radians
        let haversine = pow(sin(latitudeDelta / 2), 2) +
            cos(firstLatitude) * cos(secondLatitude) * pow(sin(longitudeDelta / 2), 2)
        let clampedHaversine = min(max(haversine, 0), 1)
        let angle = 2 * atan2(sqrt(clampedHaversine), sqrt(1 - clampedHaversine))
        return angle.degrees
    }
}

private extension Double {
    var radians: Double {
        self * .pi / 180
    }

    var degrees: Double {
        self * 180 / .pi
    }
}
