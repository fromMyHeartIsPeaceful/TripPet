import Foundation

struct AnimalVisitService {
    func visitingAnimal(from animals: [Animal], on date: Date = Date()) -> Animal? {
        let calendar = Calendar.current
        let dayOrdinal = calendar.ordinality(of: .day, in: .era, for: date) ?? calendar.component(.day, from: date)
        let namedVisitors = animals.filter { animal in
            animal.isResident == false && animal.id != "visitor_unknown"
        }
        let visitors = namedVisitors.isEmpty ? animals.filter { $0.isResident == false } : namedVisitors
        guard visitors.isEmpty == false else { return nil }
        guard dayOrdinal.isMultiple(of: 3) else { return nil }
        return visitors[(dayOrdinal / 3) % visitors.count]
    }
}
