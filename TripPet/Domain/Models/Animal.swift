import Foundation

enum AnimalPool: String, Equatable, Codable {
    case primary
    case backup
}

struct Animal: Identifiable, Equatable {
    let id: String
    var name: String
    var species: String
    var personality: String
    var homeAssetName: String
    var selfieAssetName: String
    var visitorAssetName: String
    var discoveredAt: Date?
    var isResident: Bool
    var pool: AnimalPool = .primary
}

extension Animal {
    var travelMarkerAssetName: String {
        homeAssetName
    }
}
