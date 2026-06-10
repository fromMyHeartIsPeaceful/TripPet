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
                name: "墨迹",
                species: "cat",
                personality: "安静、机敏、记性好，喜欢把小事准确记下来",
                profileId: "moji_cat",
                canTravel: true,
                displayRoleType: "见证者",
                homeAssetName: "animal_cat_home",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_cat_home",
                discoveredAt: Date(),
                isResident: true
            ),
            Animal(
                id: "dog",
                name: "汤圆",
                species: "dog",
                personality: "热闹、反应快，常把尴尬讲成一场小事故",
                profileId: "tangyuan_puppy",
                canTravel: true,
                displayRoleType: "荒诞喜剧者",
                homeAssetName: "animal_dog_home",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_dog_visitor",
                discoveredAt: Date(),
                isResident: false
            ),
            Animal(
                id: "rabbit",
                name: "灯灯",
                species: "rabbit",
                personality: "温和、容易停步，常被一盏灯或一扇窗牵住",
                profileId: "dengdeng_rabbit",
                canTravel: true,
                displayRoleType: "归乡者",
                homeAssetName: "animal_rabbit_home",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_rabbit_visitor",
                discoveredAt: Date(),
                isResident: false
            ),
            Animal(
                id: "visitor_unknown",
                name: "新伙伴",
                species: "unknown",
                personality: "偶尔从门边探头",
                profileId: "visitor_unknown",
                canTravel: false,
                displayRoleType: "",
                homeAssetName: "animal_visitor_unknown",
                selfieAssetName: "animal_cat_selfie",
                visitorAssetName: "animal_visitor_unknown",
                discoveredAt: nil,
                isResident: false
            )
        ],
        travelWishes: [
            TravelWish(
                id: "wish_paris_cat",
                animalId: "cat",
                destinationId: "fr_paris",
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
                id: "fr_paris",
                cityId: "fr_paris",
                displayName: "巴黎",
                landmarkAssetName: "destination_paris_line",
                stampAssetName: "stamp_paris",
                routeMapAssetName: "trip_route_map_paris",
                postcardTemplateAssetName: "postcard_template_landscape_v102",
                travelKind: "standard",
                primaryColor: "#D8B36A",
                postcardTitleTemplate: "{animal}寄来的巴黎明信片",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "我在巴黎的街角停了一会儿，把一件小事寄回小屋。",
                scenes: []
            ),
            ManifestDestination(
                id: "is_reykjavik",
                cityId: "is_reykjavik",
                displayName: "雷克雅未克",
                landmarkAssetName: "destination_iceland_line",
                stampAssetName: "stamp_iceland",
                routeMapAssetName: "trip_route_map_iceland",
                postcardTemplateAssetName: "postcard_template_landscape_v102",
                travelKind: "long",
                primaryColor: "#A9C9D8",
                postcardTitleTemplate: "{animal}寄来的雷克雅未克明信片",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "我在雷克雅未克听见风从纸边跑过去。",
                scenes: []
            ),
            ManifestDestination(
                id: "pt_lisbon",
                cityId: "pt_lisbon",
                displayName: "里斯本",
                landmarkAssetName: "destination_lisbon_line",
                stampAssetName: "stamp_lisbon",
                routeMapAssetName: "trip_route_map_lisbon",
                postcardTemplateAssetName: "postcard_template_landscape_v102",
                travelKind: "short",
                primaryColor: "#C9895F",
                postcardTitleTemplate: "{animal}寄来的里斯本明信片",
                postcardSubtitle: "旅途中寄来",
                postcardBodyTemplate: "我在里斯本的坡道边停了一会儿。",
                scenes: []
            )
        ]
    )

    static let previewPostcards = [
        Postcard(
            id: "postcard_paris_day_2",
            tripId: "seed_trip_paris",
            animalId: "cat",
            profileId: "moji_cat",
            destination: "巴黎",
            cityId: "fr_paris",
            sceneId: "fr_paris_old_street_doorplate_02",
            postcardType: "daily_observation",
            microArc: "旁观型",
            emotionalWeight: 1,
            revealBudget: "tiny",
            relationshipStageAtSend: "testing",
            title: "墨迹寄来的巴黎明信片",
            body: "巴黎的旧街转角很安静，楼道灯挨着门牌。我没有急着走，只把数字慢慢抄下来。",
            imageAssetName: "postcard_paris_day_2",
            templateAssetName: "postcard_template_landscape_v102",
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
            animalId: "rabbit",
            profileId: "dengdeng_rabbit",
            destination: "雷克雅未克",
            cityId: "is_reykjavik",
            sceneId: "is_reykjavik_harbor_wait_03",
            postcardType: "motif_echo",
            microArc: "回声型",
            emotionalWeight: 2,
            revealBudget: "small",
            relationshipStageAtSend: "familiar",
            title: "灯灯寄来的雷克雅未克明信片",
            body: "雷克雅未克港边有低云，围巾角被风按在栏杆上。我等风过去，才把这点光写下来。",
            imageAssetName: "postcard_iceland_old",
            templateAssetName: "postcard_template_landscape_v102",
            destinationAssetName: "destination_iceland_line",
            stampAssetName: "stamp_iceland",
            animalAssetName: "animal_cat_selfie",
            envelopeAssetName: "envelope_old",
            sentAt: Date().addingTimeInterval(-60 * 60 * 24 * 12),
            subtitle: "旧明信片",
            isRead: true
        )
    ]
}
