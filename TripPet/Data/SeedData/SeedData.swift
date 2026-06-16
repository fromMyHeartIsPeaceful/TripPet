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
                id: "xiaoman_hamster",
                name: "小满",
                species: "仓鼠",
                personality: "温柔克制，喜欢把旅行里的小东西收进明信片",
                homeAssetName: "animal_home_xiaoman_hamster",
                selfieAssetName: "animal_home_xiaoman_hamster",
                visitorAssetName: "animal_home_xiaoman_hamster",
                discoveredAt: Date(),
                isResident: true,
                pool: .primary
            ),
            Animal(
                id: "tangyuan_puppy",
                name: "糖圆",
                species: "小狗",
                personality: "活力过剩，喜欢把旅途小事故讲成现场播报",
                homeAssetName: "animal_home_tangyuan_puppy",
                selfieAssetName: "animal_home_tangyuan_puppy",
                visitorAssetName: "animal_home_tangyuan_puppy",
                discoveredAt: nil,
                isResident: false,
                pool: .primary
            ),
            Animal(
                id: "moji_cat",
                name: "墨迹",
                species: "猫",
                personality: "冷眼但记性很好，擅长记录城市边角",
                homeAssetName: "animal_home_moji_cat",
                selfieAssetName: "animal_home_moji_cat",
                visitorAssetName: "animal_home_moji_cat",
                discoveredAt: nil,
                isResident: false,
                pool: .primary
            ),
            Animal(
                id: "dengdeng_rabbit",
                name: "灯灯",
                species: "兔子",
                personality: "软乎乎又恋家，会判断陌生地方像不像家",
                homeAssetName: "animal_home_dengdeng_rabbit",
                selfieAssetName: "animal_home_dengdeng_rabbit",
                visitorAssetName: "animal_home_dengdeng_rabbit",
                discoveredAt: nil,
                isResident: false,
                pool: .primary
            ),
            Animal(
                id: "feifei_parrot",
                name: "飞飞",
                species: "鹦鹉",
                personality: "华丽跑题，喜欢把普通场景讲成小舞台",
                homeAssetName: "animal_home_feifei_parrot",
                selfieAssetName: "animal_home_feifei_parrot",
                visitorAssetName: "animal_home_feifei_parrot",
                discoveredAt: nil,
                isResident: false,
                pool: .primary
            ),
            Animal(
                id: "xiaolu_guinea_pig",
                name: "小炉",
                species: "豚鼠",
                personality: "可靠但操心，旅途中总先检查路线和座位",
                homeAssetName: "animal_home_xiaolu_guinea_pig",
                selfieAssetName: "animal_home_xiaolu_guinea_pig",
                visitorAssetName: "animal_home_xiaolu_guinea_pig",
                discoveredAt: nil,
                isResident: false,
                pool: .primary
            ),
            Animal(
                id: "deer_visitor",
                name: "啾啾",
                species: "小鹿",
                personality: "高敏感的风向侦察员，会先听风和出口",
                homeAssetName: "animal_home_jiujiu_deer",
                selfieAssetName: "animal_home_jiujiu_deer",
                visitorAssetName: "animal_home_jiujiu_deer",
                discoveredAt: nil,
                isResident: false,
                pool: .backup
            ),
            Animal(
                id: "fox_visitor",
                name: "埃尼",
                species: "小狐狸",
                personality: "机灵嘴硬，越在意越说刚好路过",
                homeAssetName: "animal_home_aini_fox",
                selfieAssetName: "animal_home_aini_fox",
                visitorAssetName: "animal_home_aini_fox",
                discoveredAt: nil,
                isResident: false,
                pool: .backup
            ),
            Animal(
                id: "bear_visitor",
                name: "墩墩",
                species: "小熊",
                personality: "慢热笨重但让人安心，喜欢确认能坐稳的地方",
                homeAssetName: "animal_home_dundun_bear",
                selfieAssetName: "animal_home_dundun_bear",
                visitorAssetName: "animal_home_dundun_bear",
                discoveredAt: nil,
                isResident: false,
                pool: .backup
            )
        ],
        travelWishes: [
            TravelWish(
                id: "wish_paris_cat",
                animalId: "xiaoman_hamster",
                destinationId: "paris",
                destination: "巴黎",
                destinationAssetName: "destination_paris_line",
                requiredTickets: 1,
                status: .waiting,
                createdAt: Date()
            )
        ],
        trips: [],
        postcards: [],
        destinations: [
            ManifestDestination(
                id: "paris",
                displayName: "巴黎",
                landmarkAssetName: "postcard_destination_paris",
                stampAssetName: "postcard_stamp_paris",
                routeMapAssetName: "trip_route_map_paris",
                primaryColor: "#D8B36A",
                postcardTitleTemplate: "{animal}寄来的巴黎早安",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "清晨的巴黎还没有完全醒来。{animal}在远远能看见铁塔的街角停了一会儿，把面包香、石板路上的光和一点点风，都轻轻收进了这张明信片。"
            ),
            ManifestDestination(
                id: "iceland",
                displayName: "冰岛",
                landmarkAssetName: "postcard_destination_reykjavik",
                stampAssetName: "postcard_stamp_reykjavik",
                routeMapAssetName: "trip_route_map_iceland",
                primaryColor: "#A9C9D8",
                postcardTitleTemplate: "{animal}寄来的风声",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "冰岛的云压得很低，路边的灯像一粒小小的星。{animal}把围巾裹紧，听见风从黑色海岸跑过去，于是给小屋寄回这一点安静的远方。"
            )
        ]
    )

    static let previewPostcards = [
        Postcard(
            id: "postcard_paris_day_2",
            tripId: "seed_trip_paris",
            destination: "巴黎",
            title: "小满寄来的明信片",
            body: "清晨的街边很安静。它站在铁塔很远的地方，把自己的影子也拍进了照片里。",
            imageAssetName: "postcard_paris_day_2",
            templateAssetName: "postcard_template_classic",
            destinationAssetName: "postcard_destination_paris",
            stampAssetName: "postcard_stamp_paris",
            animalAssetName: "animal_home_xiaoman_hamster",
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
            destinationAssetName: "postcard_destination_reykjavik",
            stampAssetName: "postcard_stamp_reykjavik",
            animalAssetName: "animal_home_xiaoman_hamster",
            envelopeAssetName: "envelope_old",
            sentAt: Date().addingTimeInterval(-60 * 60 * 24 * 12),
            subtitle: "旧明信片",
            isRead: true
        )
    ]
}
