import Foundation

struct SeedData {
    var animals: [Animal]
    var travelWishes: [TravelWish]
    var trips: [Trip]
    var postcards: [Postcard]
    var destinations: [ManifestDestination]

    init(
        animals: [Animal],
        travelWishes: [TravelWish],
        trips: [Trip],
        postcards: [Postcard],
        destinations: [ManifestDestination] = []
    ) {
        self.animals = animals
        self.travelWishes = travelWishes
        self.trips = trips
        self.postcards = postcards
        self.destinations = destinations
    }

    static let preview = SeedData(
        animals: [
            Animal(
                id: "cat",
                name: "小猫",
                species: "cat",
                personality: "安静、好奇、喜欢地图",
                homeAssetName: "animal_cat_home",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_cat_home",
                discoveredAt: Date(),
                isResident: true
            ),
            Animal(
                id: "visitor_unknown",
                name: "新伙伴",
                species: "unknown",
                personality: "偶尔从门边探头",
                homeAssetName: "animal_visitor_unknown",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_visitor_unknown",
                discoveredAt: nil,
                isResident: false
            ),
            Animal(
                id: "dog",
                name: "小狗",
                species: "dog",
                personality: "喜欢沿着邮路闻风",
                homeAssetName: "animal_dog_home",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_dog_visitor",
                discoveredAt: nil,
                isResident: false
            ),
            Animal(
                id: "rabbit",
                name: "小兔",
                species: "rabbit",
                personality: "会把地图角折得很整齐",
                homeAssetName: "animal_rabbit_home",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_rabbit_visitor",
                discoveredAt: nil,
                isResident: false
            )
        ],
        travelWishes: [
            TravelWish(
                id: "wish_paris_cat",
                animalId: "cat",
                destinationId: "paris",
                destination: "巴黎",
                destinationAssetName: "destination_paris_line",
                requiredTickets: 1,
                status: .waiting,
                createdAt: Date()
            )
        ],
        trips: [],
        postcards: [
            Postcard(
                id: "postcard_paris_day_2",
                tripId: "seed_trip_paris",
                destination: "巴黎",
                title: "小猫寄来的明信片",
                body: "清晨的街边很安静。它站在铁塔很远的地方，把自己的影子也拍进了照片里。",
                imageAssetName: "postcard_paris_day_2",
                templateAssetName: "postcard_template_classic",
                destinationAssetName: "destination_paris_line",
                stampAssetName: "stamp_paris",
                animalAssetName: "animal_cat_selfie",
                envelopeAssetName: "envelope_unread",
                sentAt: Date().addingTimeInterval(-60 * 60 * 8),
                subtitle: "第 2 天清晨",
                isRead: false
            ),
            Postcard(
                id: "postcard_iceland_old",
                tripId: "seed_trip_iceland",
                destination: "冰岛",
                title: "云下面的远方",
                body: "这是一张旧明信片。云压得很低，路边只有风和一盏小小的灯。",
                imageAssetName: "postcard_iceland_old",
                templateAssetName: "postcard_template_classic",
                destinationAssetName: "destination_iceland_line",
                stampAssetName: "stamp_iceland",
                animalAssetName: "animal_cat_selfie",
                envelopeAssetName: "envelope_old",
                sentAt: Date().addingTimeInterval(-60 * 60 * 24 * 12),
                subtitle: "旧明信片",
                isRead: true
            )
        ],
        destinations: [
            ManifestDestination(
                id: "paris",
                displayName: "巴黎",
                landmarkAssetName: "destination_paris_line",
                stampAssetName: "stamp_paris",
                routeMapAssetName: "trip_route_map_paris",
                primaryColor: "#D8B36A",
                postcardTitleTemplate: "{animal}寄来的巴黎早安",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "清晨的巴黎还没有完全醒来。{animal}在远远能看见铁塔的街角停了一会儿，把面包香、石板路上的光和一点点风，都轻轻收进了这张明信片。"
            ),
            ManifestDestination(
                id: "iceland",
                displayName: "冰岛",
                landmarkAssetName: "destination_iceland_line",
                stampAssetName: "stamp_iceland",
                routeMapAssetName: "trip_route_map_iceland",
                primaryColor: "#A9C9D8",
                postcardTitleTemplate: "{animal}寄来的风声",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "冰岛的云压得很低，路边的灯像一粒小小的星。{animal}把围巾裹紧，听见风从黑色海岸跑过去，于是给小屋寄回这一点安静的远方。"
            )
        ]
    )
}
