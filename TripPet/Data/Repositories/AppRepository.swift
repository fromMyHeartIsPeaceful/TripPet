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

    private let store: AppUserStateStore
    private let calendar: Calendar
    private let maxDailyAnimalDepartures = 3
    private let emptyCabinDuration: TimeInterval = 60 * 60

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

    var hasReachedDailyAnimalLimit: Bool {
        cabinLodging.currentAnimalId == nil && cabinLodging.dispatchedCount >= maxDailyAnimalDepartures
    }

    var activeWish: TravelWish? {
        travelWishes.first { $0.status == .waiting || $0.status == .ready }
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
    func giftTicket(sourceSteps: Int, ticketCount: Int, date: Date = Date()) -> Trip? {
        refreshCabinLodging(on: date)
        guard cabinLodging.dispatchedCount < maxDailyAnimalDepartures,
              let animal = currentCabinAnimal else {
            return nil
        }

        let wish = activeWish ?? travelWishes.first
        guard let resolvedWish = wish else { return nil }

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

        let trip = Trip(
            id: UUID().uuidString,
            animalId: animal.id,
            destinationId: resolvedWish.destinationId,
            destination: resolvedWish.destination,
            departedAt: date,
            expectedReturnAt: date.addingTimeInterval(60 * 60 * 24),
            status: .traveling
        )
        trips.append(trip)

        cabinLodging.statusDate = calendar.startOfDay(for: date)
        cabinLodging.dispatchedCount += 1
        cabinLodging.currentAnimalId = nil
        cabinLodging.emptyUntil = cabinLodging.dispatchedCount >= maxDailyAnimalDepartures
            ? nil
            : date.addingTimeInterval(emptyCabinDuration)
        saveState()
        return trip
    }

    @discardableResult
    func completeTrip(_ trip: Trip, postcard: Postcard? = nil) -> Bool {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) else {
            return false
        }

        trips[tripIndex].status = .completed

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
        on date: Date = Date()
    ) -> Bool {
        var didReveal = false

        for trip in trips where trip.status == .traveling {
            guard scheduler.shouldRevealPostcard(for: trip, on: date),
                  postcards.contains(where: { $0.tripId == trip.id }) == false,
                  let animal = animals.first(where: { $0.id == trip.animalId }),
                  let destination = destinations.first(where: { $0.id == trip.destinationId || $0.displayName == trip.destination }) else {
                continue
            }

            let postcard = scheduler.makePostcard(
                for: trip,
                animal: animal,
                destination: destination,
                on: date
            )
            didReveal = completeTrip(trip, postcard: postcard) || didReveal
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
                flags: userFlags,
                cabinLodging: cabinLodging
            )
        )
    }

    private func firstCabinAnimalId(forDispatchIndex dispatchIndex: Int) -> String? {
        let residentAnimals = animals.filter(\.isResident)
        let orderedAnimals = residentAnimals.isEmpty ? animals : residentAnimals
        guard orderedAnimals.isEmpty == false else { return nil }
        return orderedAnimals[min(dispatchIndex, orderedAnimals.count - 1)].id
    }
}
