import Foundation

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
}
