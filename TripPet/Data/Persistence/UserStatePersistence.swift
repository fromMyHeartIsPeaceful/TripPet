import Foundation
import SwiftData

struct AppUserFlags: Equatable {
    var onboardingCompleted: Bool = false
    var healthGuideDismissed: Bool = false
    var firstImmediateTicketGifted: Bool = false
    var firstAirportPostcardDelivered: Bool = false
}

struct AppUserState: Equatable {
    var travelWishes: [TravelWish]
    var trips: [Trip]
    var postcards: [Postcard]
    var tickets: [Ticket]
    var relationshipMemories: [AnimalRelationshipMemory]
    var flags: AppUserFlags
    var cabinLodging: CabinLodgingState

    init(seed: SeedData, flags: AppUserFlags = AppUserFlags()) {
        travelWishes = seed.travelWishes
        trips = seed.trips
        postcards = seed.postcards
        tickets = []
        relationshipMemories = seed.animals
            .filter(\.canTravel)
            .map { AnimalRelationshipMemory(animalId: $0.id, encounterCount: $0.isResident ? 1 : 0) }
        self.flags = flags
        cabinLodging = CabinLodgingState.initial(
            on: Date(),
            animalId: seed.animals.first(where: \.canTravel)?.id ?? seed.animals.first?.id
        )
    }

    init(
        travelWishes: [TravelWish],
        trips: [Trip],
        postcards: [Postcard],
        tickets: [Ticket],
        relationshipMemories: [AnimalRelationshipMemory] = [],
        flags: AppUserFlags,
        cabinLodging: CabinLodgingState
    ) {
        self.travelWishes = travelWishes
        self.trips = trips
        self.postcards = postcards
        self.tickets = tickets
        self.relationshipMemories = relationshipMemories
        self.flags = flags
        self.cabinLodging = cabinLodging
    }
}

struct CabinLodgingState: Equatable {
    var statusDate: Date
    var dispatchedCount: Int
    var currentAnimalId: String?
    var emptyUntil: Date?

    static func initial(
        on date: Date,
        animalId: String?,
        calendar: Calendar = .current
    ) -> CabinLodgingState {
        CabinLodgingState(
            statusDate: calendar.startOfDay(for: date),
            dispatchedCount: 0,
            currentAnimalId: animalId,
            emptyUntil: nil
        )
    }
}

@MainActor
protocol AppUserStateStore {
    func load(seed: SeedData) -> AppUserState
    func save(_ state: AppUserState)
}

@MainActor
final class InMemoryUserStateStore: AppUserStateStore {
    private var savedState: AppUserState?

    init(savedState: AppUserState? = nil) {
        self.savedState = savedState
    }

    func load(seed: SeedData) -> AppUserState {
        savedState ?? AppUserState(seed: seed)
    }

    func save(_ state: AppUserState) {
        savedState = state
    }
}

@Model
final class PersistedTicket {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sourceSteps: Int
    var ticketCount: Int
    var giftedAt: Date

    init(ticket: Ticket) {
        id = ticket.id
        date = ticket.date
        sourceSteps = ticket.sourceSteps
        ticketCount = ticket.ticketCount
        giftedAt = ticket.giftedAt
    }

    var ticket: Ticket {
        Ticket(
            id: id,
            date: date,
            sourceSteps: sourceSteps,
            ticketCount: ticketCount,
            giftedAt: giftedAt
        )
    }
}

@Model
final class PersistedTrip {
    @Attribute(.unique) var id: String
    var animalId: String
    var destinationId: String
    var destination: String
    var departedAt: Date
    var expectedReturnAt: Date
    var statusRawValue: String
    var travelKindRawValue: String?
    var postcardPlanJSON: String?
    var revealedPostcardCount: Int?
    var completedAt: Date?

    init(trip: Trip) {
        id = trip.id
        animalId = trip.animalId
        destinationId = trip.destinationId
        destination = trip.destination
        departedAt = trip.departedAt
        expectedReturnAt = trip.expectedReturnAt
        statusRawValue = trip.status.rawValue
        travelKindRawValue = trip.travelKind.rawValue
        postcardPlanJSON = JSONCoding.encode(trip.postcardPlan)
        revealedPostcardCount = trip.revealedPostcardCount
        completedAt = trip.completedAt
    }

    var trip: Trip {
        Trip(
            id: id,
            animalId: animalId,
            destinationId: destinationId,
            destination: destination,
            departedAt: departedAt,
            expectedReturnAt: expectedReturnAt,
            status: TripStatus(rawValue: statusRawValue) ?? .traveling,
            travelKind: TravelKind(rawValue: travelKindRawValue ?? "") ?? .standard,
            postcardPlan: JSONCoding.decode([TripPostcardPlanItem].self, from: postcardPlanJSON ?? "") ?? [],
            revealedPostcardCount: revealedPostcardCount ?? 0,
            completedAt: completedAt
        )
    }
}

@Model
final class PersistedPostcard {
    @Attribute(.unique) var id: String
    var tripId: String
    var animalId: String?
    var profileId: String?
    var destination: String
    var cityId: String?
    var sceneId: String?
    var postcardType: String?
    var microArc: String?
    var emotionalWeight: Int?
    var revealBudget: String?
    var relationshipStageAtSend: String?
    var title: String
    var body: String
    var imageAssetName: String
    var templateAssetName: String
    var destinationAssetName: String
    var stampAssetName: String
    var animalAssetName: String
    var envelopeAssetName: String
    var sentAt: Date
    var subtitle: String
    var isRead: Bool

    init(postcard: Postcard) {
        id = postcard.id
        tripId = postcard.tripId
        animalId = postcard.animalId
        profileId = postcard.profileId
        destination = postcard.destination
        cityId = postcard.cityId
        sceneId = postcard.sceneId
        postcardType = postcard.postcardType
        microArc = postcard.microArc
        emotionalWeight = postcard.emotionalWeight
        revealBudget = postcard.revealBudget
        relationshipStageAtSend = postcard.relationshipStageAtSend
        title = postcard.title
        body = postcard.body
        imageAssetName = postcard.imageAssetName
        templateAssetName = postcard.templateAssetName
        destinationAssetName = postcard.destinationAssetName
        stampAssetName = postcard.stampAssetName
        animalAssetName = postcard.animalAssetName
        envelopeAssetName = postcard.envelopeAssetName
        sentAt = postcard.sentAt
        subtitle = postcard.subtitle
        isRead = postcard.isRead
    }

    var postcard: Postcard {
        Postcard(
            id: id,
            tripId: tripId,
            animalId: animalId ?? "",
            profileId: profileId ?? "",
            destination: destination,
            cityId: cityId ?? "",
            sceneId: sceneId ?? "",
            postcardType: postcardType ?? "daily_observation",
            microArc: microArc ?? "动作型",
            emotionalWeight: emotionalWeight ?? 0,
            revealBudget: revealBudget ?? "none",
            relationshipStageAtSend: relationshipStageAtSend ?? "stranger",
            title: title,
            body: body,
            imageAssetName: imageAssetName,
            templateAssetName: templateAssetName,
            destinationAssetName: destinationAssetName,
            stampAssetName: stampAssetName,
            animalAssetName: animalAssetName,
            envelopeAssetName: envelopeAssetName,
            sentAt: sentAt,
            subtitle: subtitle,
            isRead: isRead
        )
    }
}

@Model
final class PersistedTravelWishState {
    @Attribute(.unique) var id: String
    var animalId: String
    var destinationId: String
    var destination: String
    var destinationAssetName: String
    var requiredTickets: Int
    var statusRawValue: String
    var createdAt: Date

    init(wish: TravelWish) {
        id = wish.id
        animalId = wish.animalId
        destinationId = wish.destinationId
        destination = wish.destination
        destinationAssetName = wish.destinationAssetName
        requiredTickets = wish.requiredTickets
        statusRawValue = wish.status.rawValue
        createdAt = wish.createdAt
    }

    var wish: TravelWish {
        TravelWish(
            id: id,
            animalId: animalId,
            destinationId: destinationId,
            destination: destination,
            destinationAssetName: destinationAssetName,
            requiredTickets: requiredTickets,
            status: TravelWishStatus(rawValue: statusRawValue) ?? .waiting,
            createdAt: createdAt
        )
    }
}

@Model
final class PersistedAppFlag {
    @Attribute(.unique) var key: String
    var boolValue: Bool

    init(key: String, boolValue: Bool) {
        self.key = key
        self.boolValue = boolValue
    }
}

@Model
final class PersistedCabinLodgingState {
    @Attribute(.unique) var key: String
    var statusDate: Date
    var dispatchedCount: Int
    var currentAnimalId: String?
    var emptyUntil: Date?

    init(state: CabinLodgingState) {
        key = "cabinLodging"
        statusDate = state.statusDate
        dispatchedCount = state.dispatchedCount
        currentAnimalId = state.currentAnimalId
        emptyUntil = state.emptyUntil
    }

    var state: CabinLodgingState {
        CabinLodgingState(
            statusDate: statusDate,
            dispatchedCount: dispatchedCount,
            currentAnimalId: currentAnimalId,
            emptyUntil: emptyUntil
        )
    }
}

@Model
final class PersistedAnimalRelationshipMemory {
    @Attribute(.unique) var animalId: String
    var memoryJSON: String

    init(memory: AnimalRelationshipMemory) {
        animalId = memory.animalId
        memoryJSON = JSONCoding.encode(memory)
    }

    var memory: AnimalRelationshipMemory? {
        JSONCoding.decode(AnimalRelationshipMemory.self, from: memoryJSON)
    }
}

@MainActor
final class SwiftDataUserStateStore: AppUserStateStore {
    private let context: ModelContext

    init(inMemory: Bool = false) throws {
        let schema = Schema([
            PersistedTicket.self,
            PersistedTrip.self,
            PersistedPostcard.self,
            PersistedTravelWishState.self,
            PersistedAppFlag.self,
            PersistedCabinLodgingState.self,
            PersistedAnimalRelationshipMemory.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
    }

    func load(seed: SeedData) -> AppUserState {
        let tickets = (try? context.fetch(FetchDescriptor<PersistedTicket>()))?
            .map(\.ticket)
            .sorted { $0.giftedAt < $1.giftedAt } ?? []
        let trips = (try? context.fetch(FetchDescriptor<PersistedTrip>()))?
            .map(\.trip)
            .sorted { $0.departedAt < $1.departedAt } ?? seed.trips
        let postcards = (try? context.fetch(FetchDescriptor<PersistedPostcard>()))?
            .map(\.postcard)
            .sorted { $0.sentAt > $1.sentAt } ?? []
        let wishes = (try? context.fetch(FetchDescriptor<PersistedTravelWishState>()))?
            .map(\.wish)
            .sorted { $0.createdAt < $1.createdAt } ?? []
        let flags = loadFlags()
        let cabinLodging = loadCabinLodging(seed: seed)
        let relationshipMemories = loadRelationshipMemories(seed: seed)

        return AppUserState(
            travelWishes: wishes.isEmpty ? seed.travelWishes : rehydrate(wishes: wishes, seed: seed),
            trips: rehydrate(trips: trips, seed: seed),
            postcards: postcards,
            tickets: tickets,
            relationshipMemories: relationshipMemories,
            flags: flags,
            cabinLodging: cabinLodging
        )
    }

    func save(_ state: AppUserState) {
        replace(PersistedTicket.self, with: state.tickets.map(PersistedTicket.init(ticket:)))
        replace(PersistedTrip.self, with: state.trips.map(PersistedTrip.init(trip:)))
        replace(PersistedPostcard.self, with: state.postcards.map(PersistedPostcard.init(postcard:)))
        replace(PersistedTravelWishState.self, with: state.travelWishes.map(PersistedTravelWishState.init(wish:)))
        replace(PersistedAnimalRelationshipMemory.self, with: state.relationshipMemories.map(PersistedAnimalRelationshipMemory.init(memory:)))
        replace(PersistedAppFlag.self, with: [
            PersistedAppFlag(key: AppFlagKey.onboardingCompleted, boolValue: state.flags.onboardingCompleted),
            PersistedAppFlag(key: AppFlagKey.healthGuideDismissed, boolValue: state.flags.healthGuideDismissed),
            PersistedAppFlag(key: AppFlagKey.firstImmediateTicketGifted, boolValue: state.flags.firstImmediateTicketGifted),
            PersistedAppFlag(key: AppFlagKey.firstAirportPostcardDelivered, boolValue: state.flags.firstAirportPostcardDelivered)
        ])
        replace(PersistedCabinLodgingState.self, with: [
            PersistedCabinLodgingState(state: state.cabinLodging)
        ])
        try? context.save()
    }

    private func loadFlags() -> AppUserFlags {
        let flags = (try? context.fetch(FetchDescriptor<PersistedAppFlag>())) ?? []
        return AppUserFlags(
            onboardingCompleted: flags.first { $0.key == AppFlagKey.onboardingCompleted }?.boolValue ?? false,
            healthGuideDismissed: flags.first { $0.key == AppFlagKey.healthGuideDismissed }?.boolValue ?? false,
            firstImmediateTicketGifted: flags.first { $0.key == AppFlagKey.firstImmediateTicketGifted }?.boolValue ?? false,
            firstAirportPostcardDelivered: flags.first { $0.key == AppFlagKey.firstAirportPostcardDelivered }?.boolValue ?? false
        )
    }

    private func loadCabinLodging(seed: SeedData) -> CabinLodgingState {
        let state = try? context.fetch(FetchDescriptor<PersistedCabinLodgingState>()).first?.state
        return state ?? CabinLodgingState.initial(
            on: Date(),
            animalId: seed.animals.first(where: \.canTravel)?.id ?? seed.animals.first?.id
        )
    }

    private func loadRelationshipMemories(seed: SeedData) -> [AnimalRelationshipMemory] {
        let stored = (try? context.fetch(FetchDescriptor<PersistedAnimalRelationshipMemory>()))?
            .compactMap(\.memory) ?? []
        let storedByAnimal = Dictionary(uniqueKeysWithValues: stored.map { ($0.animalId, $0) })
        return seed.animals
            .filter(\.canTravel)
            .map { animal in
                storedByAnimal[animal.id] ?? AnimalRelationshipMemory(
                    animalId: animal.id,
                    encounterCount: animal.isResident ? 1 : 0
                )
            }
    }

    private func replace<T: PersistentModel>(_ type: T.Type, with models: [T]) {
        let descriptor = FetchDescriptor<T>()
        if let existing = try? context.fetch(descriptor) {
            existing.forEach { context.delete($0) }
        }
        models.forEach { context.insert($0) }
    }

    private func rehydrate(wishes: [TravelWish], seed: SeedData) -> [TravelWish] {
        wishes.map { wish in
            var rehydratedWish = wish
            if let destination = seed.destinations.first(where: { $0.id == wish.destinationId }) {
                rehydratedWish.destination = destination.displayName
                rehydratedWish.destinationAssetName = destination.landmarkAssetName
            }
            return rehydratedWish
        }
    }

    private func rehydrate(trips: [Trip], seed: SeedData) -> [Trip] {
        trips.map { trip in
            var rehydratedTrip = trip
            if let destination = seed.destinations.first(where: { $0.id == trip.destinationId }) {
                rehydratedTrip.destination = destination.displayName
            }
            return rehydratedTrip
        }
    }
}

private enum JSONCoding {
    static func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

private enum AppFlagKey {
    static let onboardingCompleted = "onboardingCompleted"
    static let healthGuideDismissed = "healthGuideDismissed"
    static let firstImmediateTicketGifted = "firstImmediateTicketGifted"
    static let firstAirportPostcardDelivered = "firstAirportPostcardDelivered"
}
