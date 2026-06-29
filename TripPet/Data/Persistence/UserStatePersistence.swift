import Foundation
import SwiftData

struct AppUserFlags: Equatable {
    var onboardingCompleted: Bool = false
    var healthGuideDismissed: Bool = false
    var firstImmediateTicketGifted: Bool = false
    var firstAirportPostcardDelivered: Bool = false
}

struct AppUserState: Equatable {
    private static let defaultInitialCabinAnimalId = "moji_cat"

    var travelWishes: [TravelWish]
    var trips: [Trip]
    var postcards: [Postcard]
    var tickets: [Ticket]
    var flags: AppUserFlags
    var cabinLodging: CabinLodgingState
    var consumedPostcardTextIds: Set<String>

    init(seed: SeedData, flags: AppUserFlags = AppUserFlags()) {
        travelWishes = seed.travelWishes
        trips = seed.trips
        postcards = seed.postcards
        tickets = []
        self.flags = flags
        cabinLodging = CabinLodgingState.initial(
            on: Date(),
            animalId: Self.initialCabinAnimalId(in: seed)
        )
        consumedPostcardTextIds = []
    }

    init(
        travelWishes: [TravelWish],
        trips: [Trip],
        postcards: [Postcard],
        tickets: [Ticket],
        flags: AppUserFlags,
        cabinLodging: CabinLodgingState,
        consumedPostcardTextIds: Set<String> = []
    ) {
        self.travelWishes = travelWishes
        self.trips = trips
        self.postcards = postcards
        self.tickets = tickets
        self.flags = flags
        self.cabinLodging = cabinLodging
        self.consumedPostcardTextIds = consumedPostcardTextIds
    }

    private static func initialCabinAnimalId(in seed: SeedData) -> String? {
        if seed.animals.contains(where: { $0.id == defaultInitialCabinAnimalId }) {
            return defaultInitialCabinAnimalId
        }
        return seed.animals.first(where: \.isResident)?.id ?? seed.animals.first?.id
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
    func markPostcardRead(postcardId: String)
}

@MainActor
final class InMemoryUserStateStore: AppUserStateStore {
    private var savedState: AppUserState?

    init(savedState: AppUserState? = nil) {
        self.savedState = savedState
    }

    func load(seed: SeedData) -> AppUserState {
        if let savedState {
            return savedState
        }

        let state = AppUserState(seed: seed)
        savedState = state
        return state
    }

    func save(_ state: AppUserState) {
        savedState = state
    }

    func markPostcardRead(postcardId: String) {
        guard let index = savedState?.postcards.firstIndex(where: { $0.id == postcardId }) else { return }
        savedState?.postcards[index].isRead = true
    }
}

@Model
final class PersistedTicket {
    var id: UUID = UUID()
    var date: Date = Date.distantPast
    var ticketCount: Int = 0
    var giftedAt: Date = Date.distantPast
    var grantTypeRawValue: String = "stepFunded"

    init(ticket: Ticket) {
        id = ticket.id
        date = ticket.date
        ticketCount = ticket.ticketCount
        giftedAt = ticket.giftedAt
        grantTypeRawValue = ticket.grantType.rawValue
    }

    var ticket: Ticket {
        let grantType = TicketGrantType(rawValue: grantTypeRawValue) ?? .stepFunded
        return Ticket(
            id: id,
            date: date,
            sourceSteps: grantType == .stepFunded ? 1 : 0,
            ticketCount: ticketCount,
            giftedAt: giftedAt,
            grantType: grantType
        )
    }

    func update(from ticket: Ticket) {
        date = ticket.date
        ticketCount = ticket.ticketCount
        giftedAt = ticket.giftedAt
        grantTypeRawValue = ticket.grantType.rawValue
    }
}

@Model
final class PersistedTrip {
    var id: String = ""
    var animalId: String = ""
    var destinationId: String = ""
    var destination: String = ""
    var departedAt: Date = Date.distantPast
    var expectedReturnAt: Date = Date.distantPast
    var statusRawValue: String = "traveling"
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

    func update(from trip: Trip) {
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
    var id: String = ""
    var tripId: String = ""
    var destination: String = ""
    var title: String = ""
    var body: String = ""
    var imageAssetName: String = ""
    var templateAssetName: String = ""
    var destinationAssetName: String = ""
    var stampAssetName: String = ""
    var animalAssetName: String = ""
    var envelopeAssetName: String = ""
    var sentAt: Date = Date.distantPast
    var subtitle: String = ""
    var isRead: Bool = false

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

    func update(from postcard: Postcard) {
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
        isRead = isRead || postcard.isRead
    }
}

@Model
final class PersistedTravelWishState {
    var id: String = ""
    var animalId: String = ""
    var destinationId: String = ""
    var destination: String = ""
    var destinationAssetName: String = ""
    var requiredTickets: Int = 0
    var statusRawValue: String = "waiting"
    var createdAt: Date = Date.distantPast

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

    func update(from wish: TravelWish) {
        animalId = wish.animalId
        destinationId = wish.destinationId
        destination = wish.destination
        destinationAssetName = wish.destinationAssetName
        requiredTickets = wish.requiredTickets
        statusRawValue = wish.status.rawValue
        createdAt = wish.createdAt
    }
}

@Model
final class PersistedAppFlag {
    var key: String = ""
    var boolValue: Bool = false

    init(key: String, boolValue: Bool) {
        self.key = key
        self.boolValue = boolValue
    }

    func update(boolValue: Bool) {
        self.boolValue = boolValue
    }
}

@Model
final class PersistedCabinLodgingState {
    var key: String = ""
    var statusDate: Date = Date.distantPast
    var dispatchedCount: Int = 0
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

    func update(from state: CabinLodgingState) {
        statusDate = state.statusDate
        dispatchedCount = state.dispatchedCount
        currentAnimalId = state.currentAnimalId
        presentAnimalIdsJSON = Self.encodeAnimalIds(state.presentAnimalIds)
        emptyUntil = state.emptyUntil
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

@Model
final class PersistedConsumedPostcardText {
    var id: String = ""

    init(id: String) {
        self.id = id
    }
}

@MainActor
final class SwiftDataUserStateStore: AppUserStateStore {
    static let cloudKitContainerIdentifier = "iCloud.com.qianyu.TripPet"

    private static let defaultInitialCabinAnimalId = "moji_cat"

    private let context: ModelContext

    init(inMemory: Bool = false) throws {
        let schema = Schema([
            PersistedTicket.self,
            PersistedTrip.self,
            PersistedPostcard.self,
            PersistedTravelWishState.self,
            PersistedAppFlag.self,
            PersistedCabinLodgingState.self,
            PersistedConsumedPostcardText.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .private(Self.cloudKitContainerIdentifier)
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
        let consumedPostcardTextIds = Set(
            (try? context.fetch(FetchDescriptor<PersistedConsumedPostcardText>()))?
                .map(\.id) ?? []
        )

        return AppUserState(
            travelWishes: wishes.isEmpty ? seed.travelWishes : rehydrate(wishes: wishes, seed: seed),
            trips: rehydrate(trips: trips, seed: seed),
            postcards: postcards,
            tickets: tickets,
            flags: flags,
            cabinLodging: cabinLodging,
            consumedPostcardTextIds: consumedPostcardTextIds
        )
    }

    func save(_ state: AppUserState) {
        saveTickets(state.tickets)
        saveTrips(state.trips)
        savePostcards(state.postcards)
        saveTravelWishes(state.travelWishes)
        saveFlags(state.flags)
        saveCabinLodging(state.cabinLodging)
        saveConsumedPostcardTextIds(state.consumedPostcardTextIds)
        try? context.save()
    }

    func markPostcardRead(postcardId: String) {
        let descriptor = FetchDescriptor<PersistedPostcard>(
            predicate: #Predicate { postcard in
                postcard.id == postcardId
            }
        )
        guard let postcard = try? context.fetch(descriptor).first else { return }
        postcard.isRead = true
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
            animalId: initialCabinAnimalId(in: seed)
        )
    }

    private func initialCabinAnimalId(in seed: SeedData) -> String? {
        if seed.animals.contains(where: { $0.id == Self.defaultInitialCabinAnimalId }) {
            return Self.defaultInitialCabinAnimalId
        }
        return seed.animals.first(where: \.isResident)?.id ?? seed.animals.first?.id
    }

    private func saveTickets(_ tickets: [Ticket]) {
        let existing = (try? context.fetch(FetchDescriptor<PersistedTicket>())) ?? []
        let byId = Dictionary(grouping: existing, by: \.id)
        let desiredIds = Set(tickets.map(\.id))

        for ticket in tickets {
            if let model = byId[ticket.id]?.first {
                model.update(from: ticket)
            } else {
                context.insert(PersistedTicket(ticket: ticket))
            }
        }
        existing
            .filter { desiredIds.contains($0.id) == false }
            .forEach { context.delete($0) }
        deleteDuplicateModels(in: byId)
    }

    private func saveTrips(_ trips: [Trip]) {
        let existing = (try? context.fetch(FetchDescriptor<PersistedTrip>())) ?? []
        let byId = Dictionary(grouping: existing, by: \.id)
        let desiredIds = Set(trips.map(\.id))

        for trip in trips {
            if let model = byId[trip.id]?.first {
                model.update(from: trip)
            } else {
                context.insert(PersistedTrip(trip: trip))
            }
        }
        existing
            .filter { desiredIds.contains($0.id) == false }
            .forEach { context.delete($0) }
        deleteDuplicateModels(in: byId)
    }

    private func savePostcards(_ postcards: [Postcard]) {
        let existing = (try? context.fetch(FetchDescriptor<PersistedPostcard>())) ?? []
        let byId = Dictionary(grouping: existing, by: \.id)
        let desiredIds = Set(postcards.map(\.id))

        for postcard in postcards {
            if let model = byId[postcard.id]?.first {
                model.update(from: postcard)
            } else {
                context.insert(PersistedPostcard(postcard: postcard))
            }
        }
        existing
            .filter { desiredIds.contains($0.id) == false }
            .forEach { context.delete($0) }
        deleteDuplicateModels(in: byId)
    }

    private func saveTravelWishes(_ wishes: [TravelWish]) {
        let existing = (try? context.fetch(FetchDescriptor<PersistedTravelWishState>())) ?? []
        let byId = Dictionary(grouping: existing, by: \.id)
        let desiredIds = Set(wishes.map(\.id))

        for wish in wishes {
            if let model = byId[wish.id]?.first {
                model.update(from: wish)
            } else {
                context.insert(PersistedTravelWishState(wish: wish))
            }
        }
        existing
            .filter { desiredIds.contains($0.id) == false }
            .forEach { context.delete($0) }
        deleteDuplicateModels(in: byId)
    }

    private func saveFlags(_ flags: AppUserFlags) {
        let values = [
            AppFlagKey.onboardingCompleted: flags.onboardingCompleted,
            AppFlagKey.healthGuideDismissed: flags.healthGuideDismissed,
            AppFlagKey.firstImmediateTicketGifted: flags.firstImmediateTicketGifted,
            AppFlagKey.firstAirportPostcardDelivered: flags.firstAirportPostcardDelivered
        ]
        let existing = (try? context.fetch(FetchDescriptor<PersistedAppFlag>())) ?? []
        let byKey = Dictionary(grouping: existing, by: \.key)

        for (key, value) in values {
            if let model = byKey[key]?.first {
                model.update(boolValue: value)
            } else {
                context.insert(PersistedAppFlag(key: key, boolValue: value))
            }
        }
        let desiredKeys = Set(values.keys)
        existing
            .filter { desiredKeys.contains($0.key) == false }
            .forEach { context.delete($0) }
        deleteDuplicateModels(in: byKey)
    }

    private func saveCabinLodging(_ state: CabinLodgingState) {
        let existing = (try? context.fetch(FetchDescriptor<PersistedCabinLodgingState>())) ?? []
        if let model = existing.first {
            model.update(from: state)
        } else {
            context.insert(PersistedCabinLodgingState(state: state))
        }
        existing.dropFirst().forEach { context.delete($0) }
    }

    private func saveConsumedPostcardTextIds(_ ids: Set<String>) {
        let existing = (try? context.fetch(FetchDescriptor<PersistedConsumedPostcardText>())) ?? []
        let byId = Dictionary(grouping: existing, by: \.id)

        for id in ids where byId[id]?.first == nil {
            context.insert(PersistedConsumedPostcardText(id: id))
        }
        existing
            .filter { ids.contains($0.id) == false }
            .forEach { context.delete($0) }
        deleteDuplicateModels(in: byId)
    }

    private func deleteDuplicateModels<Key: Hashable, Model: PersistentModel>(in groupedModels: [Key: [Model]]) {
        for models in groupedModels.values where models.count > 1 {
            models.dropFirst().forEach { context.delete($0) }
        }
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
