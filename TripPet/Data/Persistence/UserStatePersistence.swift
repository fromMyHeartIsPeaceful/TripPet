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
    var flags: AppUserFlags
    var cabinLodging: CabinLodgingState

    init(seed: SeedData, flags: AppUserFlags = AppUserFlags()) {
        travelWishes = seed.travelWishes
        trips = seed.trips
        postcards = seed.postcards
        tickets = []
        self.flags = flags
        cabinLodging = CabinLodgingState.initial(
            on: Date(),
            animalId: seed.animals.first(where: \.isResident)?.id ?? seed.animals.first?.id
        )
    }

    init(
        travelWishes: [TravelWish],
        trips: [Trip],
        postcards: [Postcard],
        tickets: [Ticket],
        flags: AppUserFlags,
        cabinLodging: CabinLodgingState
    ) {
        self.travelWishes = travelWishes
        self.trips = trips
        self.postcards = postcards
        self.tickets = tickets
        self.flags = flags
        self.cabinLodging = cabinLodging
    }
}

struct CabinLodgingState: Equatable {
    var statusDate: Date
    var dispatchedCount: Int
    var presentAnimalIds: [String]
    var emptyUntil: Date?

    var currentAnimalId: String? {
        get { presentAnimalIds.first }
        set { presentAnimalIds = newValue.map { [$0] } ?? [] }
    }

    init(
        statusDate: Date,
        dispatchedCount: Int,
        presentAnimalIds: [String],
        emptyUntil: Date?
    ) {
        self.statusDate = statusDate
        self.dispatchedCount = dispatchedCount
        self.presentAnimalIds = presentAnimalIds
        self.emptyUntil = emptyUntil
    }

    static func initial(
        on date: Date,
        animalId: String?,
        calendar: Calendar = .current
    ) -> CabinLodgingState {
        initial(on: date, animalIds: animalId.map { [$0] } ?? [], calendar: calendar)
    }

    static func initial(
        on date: Date,
        animalIds: [String],
        calendar: Calendar = .current
    ) -> CabinLodgingState {
        CabinLodgingState(
            statusDate: calendar.startOfDay(for: date),
            dispatchedCount: 0,
            presentAnimalIds: animalIds,
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
    var postcardPlanJSON: String?
    var completedAt: Date?

    init(trip: Trip) {
        id = trip.id
        animalId = trip.animalId
        destinationId = trip.destinationId
        destination = trip.destination
        departedAt = trip.departedAt
        expectedReturnAt = trip.expectedReturnAt
        statusRawValue = trip.status.rawValue
        postcardPlanJSON = Self.encodePostcardPlan(trip.postcardPlan)
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
            postcardPlan: Self.decodePostcardPlan(postcardPlanJSON),
            completedAt: completedAt
        )
    }

    private static func encodePostcardPlan(_ plan: [TripPostcardPlanItem]) -> String? {
        guard plan.isEmpty == false,
              let data = try? JSONEncoder().encode(plan) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func decodePostcardPlan(_ json: String?) -> [TripPostcardPlanItem] {
        guard let json,
              let data = json.data(using: .utf8),
              let plan = try? JSONDecoder().decode([TripPostcardPlanItem].self, from: data) else {
            return []
        }
        return plan
    }
}

@Model
final class PersistedPostcard {
    @Attribute(.unique) var id: String
    var tripId: String
    var destination: String
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
        destination = postcard.destination
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
            destination: destination,
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
    var presentAnimalIdsJSON: String?
    var emptyUntil: Date?

    init(state: CabinLodgingState) {
        key = "cabinLodging"
        statusDate = state.statusDate
        dispatchedCount = state.dispatchedCount
        currentAnimalId = state.currentAnimalId
        presentAnimalIdsJSON = Self.encodeAnimalIds(state.presentAnimalIds)
        emptyUntil = state.emptyUntil
    }

    var state: CabinLodgingState {
        CabinLodgingState(
            statusDate: statusDate,
            dispatchedCount: dispatchedCount,
            presentAnimalIds: Self.decodeAnimalIds(presentAnimalIdsJSON, fallback: currentAnimalId),
            emptyUntil: emptyUntil
        )
    }

    private static func encodeAnimalIds(_ animalIds: [String]) -> String? {
        guard animalIds.isEmpty == false,
              let data = try? JSONEncoder().encode(animalIds) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func decodeAnimalIds(_ json: String?, fallback: String?) -> [String] {
        if let json,
           let data = json.data(using: .utf8),
           let animalIds = try? JSONDecoder().decode([String].self, from: data) {
            return animalIds
        }
        return fallback.map { [$0] } ?? []
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
            PersistedCabinLodgingState.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
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

        return AppUserState(
            travelWishes: wishes.isEmpty ? seed.travelWishes : rehydrate(wishes: wishes, seed: seed),
            trips: rehydrate(trips: trips, seed: seed),
            postcards: postcards,
            tickets: tickets,
            flags: flags,
            cabinLodging: cabinLodging
        )
    }

    func save(_ state: AppUserState) {
        replace(PersistedTicket.self, with: state.tickets.map(PersistedTicket.init(ticket:)))
        replace(PersistedTrip.self, with: state.trips.map(PersistedTrip.init(trip:)))
        replace(PersistedPostcard.self, with: state.postcards.map(PersistedPostcard.init(postcard:)))
        replace(PersistedTravelWishState.self, with: state.travelWishes.map(PersistedTravelWishState.init(wish:)))
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
            animalId: seed.animals.first(where: \.isResident)?.id ?? seed.animals.first?.id
        )
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

private enum AppFlagKey {
    static let onboardingCompleted = "onboardingCompleted"
    static let healthGuideDismissed = "healthGuideDismissed"
    static let firstImmediateTicketGifted = "firstImmediateTicketGifted"
    static let firstAirportPostcardDelivered = "firstAirportPostcardDelivered"
}
