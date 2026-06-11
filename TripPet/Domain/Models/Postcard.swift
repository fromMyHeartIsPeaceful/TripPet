import Foundation

struct Postcard: Identifiable, Equatable {
    let id: String
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
}
