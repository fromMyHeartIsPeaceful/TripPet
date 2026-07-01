import Foundation

struct AchievementEngine {
    static let travelTiers: [AchievementTier] = [
        AchievementTier(
            category: .travel,
            threshold: 1,
            title: "穷人乍富",
            subtitle: "初次体验旅游乐趣",
            medalAssetName: "achievement_medal_travel_tier_001"
        ),
        AchievementTier(
            category: .travel,
            threshold: 10,
            title: "小富即安",
            subtitle: "逐渐变为出行常客",
            medalAssetName: "achievement_medal_travel_tier_002"
        ),
        AchievementTier(
            category: .travel,
            threshold: 20,
            title: "观光达人",
            subtitle: "认识个有钱朋友可真好",
            medalAssetName: "achievement_medal_travel_tier_003"
        ),
        AchievementTier(
            category: .travel,
            threshold: 30,
            title: "游玩专家",
            subtitle: "永远享受别人买单的旅行真是惬意",
            medalAssetName: "achievement_medal_travel_tier_004"
        ),
        AchievementTier(
            category: .travel,
            threshold: 50,
            title: "探险大师",
            subtitle: "我的旅行生涯机票全是朋友买单",
            medalAssetName: "achievement_medal_travel_tier_005"
        ),
        AchievementTier(
            category: .travel,
            threshold: 100,
            title: "环球旅人",
            subtitle: "我的成就来源于背后有一个贼有实力的大佬",
            medalAssetName: "achievement_medal_travel_tier_006"
        )
    ]

    static let stepTiers: [AchievementTier] = [
        AchievementTier(
            category: .steps,
            threshold: 3_000,
            title: "您也是辛苦了",
            subtitle: "都是您的脚托举我出去旅行",
            medalAssetName: "achievement_medal_steps_tier_001"
        ),
        AchievementTier(
            category: .steps,
            threshold: 9_000,
            title: "没病走两步",
            subtitle: "为了您的健康，记得多运动，哈拉少！",
            medalAssetName: "achievement_medal_steps_tier_002"
        ),
        AchievementTier(
            category: .steps,
            threshold: 20_000,
            title: "佛山无影脚在世传人",
            subtitle: "这一脚，十年的功力，你顶得住吗？",
            medalAssetName: "achievement_medal_steps_tier_003"
        ),
        AchievementTier(
            category: .steps,
            threshold: 30_000,
            title: "要啥自行车",
            subtitle: "我妹说要自行车啊！",
            medalAssetName: "achievement_medal_steps_tier_004"
        ),
        AchievementTier(
            category: .steps,
            threshold: 50_000,
            title: "劳动人民最光荣",
            subtitle: "有了闪现技能还想去送外卖的热爱走路人士",
            medalAssetName: "achievement_medal_steps_tier_005"
        ),
        AchievementTier(
            category: .steps,
            threshold: 100_000,
            title: "您真是白脚起家呀",
            subtitle: "无敌之人拥有无敌膝盖和脚踝",
            medalAssetName: "achievement_medal_steps_tier_006"
        ),
        AchievementTier(
            category: .steps,
            threshold: 200_000,
            title: "奉献之神",
            subtitle: "知名脚步慈善家",
            medalAssetName: "achievement_medal_steps_tier_007"
        ),
        AchievementTier(
            category: .steps,
            threshold: 300_000,
            title: "我们的世界是您走出来的",
            subtitle: "照顾9个小动物去旅行的一家之主",
            medalAssetName: "achievement_medal_steps_tier_008"
        ),
        AchievementTier(
            category: .steps,
            threshold: 400_000,
            title: "骆驼祥子",
            subtitle: "不知道您是否听说过一个叫骆驼祥子的人？",
            medalAssetName: "achievement_medal_steps_tier_009"
        ),
        AchievementTier(
            category: .steps,
            threshold: 500_000,
            title: "11路公交车",
            subtitle: "听上去就是二十年前的玩笑话，一点都不时髦",
            medalAssetName: "achievement_medal_steps_tier_010"
        ),
        AchievementTier(
            category: .steps,
            threshold: 600_000,
            title: "你的腿不是腿，是塞纳河畔的春水",
            subtitle: "据说巴黎人民在这个夏天因为空调在吵架呢",
            medalAssetName: "achievement_medal_steps_tier_011"
        ),
        AchievementTier(
            category: .steps,
            threshold: 700_000,
            title: "踏破铁鞋无觅处",
            subtitle: "我是铁臂阿童木！",
            medalAssetName: "achievement_medal_steps_tier_012"
        ),
        AchievementTier(
            category: .steps,
            threshold: 800_000,
            title: "铁板烧！不，是铁脚板",
            subtitle: "别人有炽热的心，我有炽热的脚",
            medalAssetName: "achievement_medal_steps_tier_013"
        ),
        AchievementTier(
            category: .steps,
            threshold: 1_000_000,
            title: "地球在我脚下",
            subtitle: "人在地球上，不就相当于脚下有个巨大的溜溜球？",
            medalAssetName: "achievement_medal_steps_tier_014"
        )
    ]

    static let postcardTiers: [AchievementTier] = [
        AchievementTier(
            category: .postcards,
            threshold: 1,
            title: "初次相识",
            subtitle: "对陌生人有一些好感",
            medalAssetName: "achievement_medal_postcards_tier_001"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 10,
            title: "些许相知",
            subtitle: "被免费机票砸晕头脑，产生情愫",
            medalAssetName: "achievement_medal_postcards_tier_002"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 50,
            title: "你也有点可爱",
            subtitle: "物质还是有点用的",
            medalAssetName: "achievement_medal_postcards_tier_003"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 100,
            title: "有钱人也不全是无情无义之人",
            subtitle: "辩证法如此教育我们",
            medalAssetName: "achievement_medal_postcards_tier_004"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 200,
            title: "谁说的有钱人无情无义！",
            subtitle: "尽信书不如无书",
            medalAssetName: "achievement_medal_postcards_tier_005"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 300,
            title: "你说什么都对，My Lord",
            subtitle: "您忠心耿耿的亲密伙伴",
            medalAssetName: "achievement_medal_postcards_tier_006"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 500,
            title: "很难想象世界上还有你这样完美的人",
            subtitle: "要让别人认为你是完美的，首先要敢于肯定自己",
            medalAssetName: "achievement_medal_postcards_tier_007"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 800,
            title: "我要打包银河系的爱给你",
            subtitle: "这年头呀，连爱都可以外卖了",
            medalAssetName: "achievement_medal_postcards_tier_008"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 1_000,
            title: "还是打包整个宇宙吧，全是我的真心",
            subtitle: "希望您可以获得这个勋章，这意味着您仍然健康",
            medalAssetName: "achievement_medal_postcards_tier_009"
        )
    ]

    func progress(
        category: AchievementCategory,
        animals: [Animal],
        trips: [Trip],
        tickets: [Ticket],
        postcards: [Postcard]
    ) -> [AchievementAnimalProgress] {
        let valuesByAnimal: [String: Int]
        let tiers: [AchievementTier]
        let mode: ProgressMode

        switch category {
        case .travel:
            valuesByAnimal = Dictionary(grouping: trips, by: \.animalId)
                .mapValues { $0.count }
            tiers = Self.travelTiers
            mode = .segmented
        case .steps:
            valuesByAnimal = stepValuesByAnimal(tickets: tickets, trips: trips)
            tiers = Self.stepTiers
            mode = .cumulative
        case .postcards:
            valuesByAnimal = postcardValuesByAnimal(postcards: postcards, trips: trips)
            tiers = Self.postcardTiers
            mode = .segmented
        }

        return animals.map { animal in
            let value = valuesByAnimal[animal.id, default: 0]
            return AchievementAnimalProgress(
                animal: animal,
                category: category,
                totalValue: value,
                medals: medals(for: value, tiers: tiers, mode: mode)
            )
        }
    }

    func summary(
        category: AchievementCategory,
        animals: [Animal],
        trips: [Trip],
        tickets: [Ticket],
        postcards: [Postcard]
    ) -> AchievementSummary {
        AchievementSummary(
            category: category,
            animals: progress(
                category: category,
                animals: animals,
                trips: trips,
                tickets: tickets,
                postcards: postcards
            )
        )
    }

    func travelProgress(animals: [Animal], trips: [Trip]) -> [AchievementAnimalProgress] {
        progress(category: .travel, animals: animals, trips: trips, tickets: [], postcards: [])
    }

    func travelSummary(animals: [Animal], trips: [Trip]) -> AchievementSummary {
        summary(category: .travel, animals: animals, trips: trips, tickets: [], postcards: [])
    }

    private func medals(
        for value: Int,
        tiers: [AchievementTier],
        mode: ProgressMode
    ) -> [AchievementMedalProgress] {
        switch mode {
        case .segmented:
            return segmentedMedals(for: value, tiers: tiers)
        case .cumulative:
            return cumulativeMedals(for: value, tiers: tiers)
        }
    }

    private func segmentedMedals(for value: Int, tiers: [AchievementTier]) -> [AchievementMedalProgress] {
        var consumedValue = 0
        var didAssignActiveMedal = false
        return tiers.map { tier in
            let segmentedValue = max(0, min(value - consumedValue, tier.threshold))
            let state: AchievementMedalState
            if segmentedValue >= tier.threshold {
                state = .collected
            } else if segmentedValue > 0, didAssignActiveMedal == false {
                state = .inProgress
                didAssignActiveMedal = true
            } else {
                state = .locked
            }
            consumedValue += tier.threshold
            return AchievementMedalProgress(
                tier: tier,
                currentValue: segmentedValue,
                state: state
            )
        }
    }

    private func cumulativeMedals(for value: Int, tiers: [AchievementTier]) -> [AchievementMedalProgress] {
        var didAssignActiveMedal = false
        return tiers.map { tier in
            let state: AchievementMedalState
            let currentValue: Int
            if value >= tier.threshold {
                state = .collected
                currentValue = tier.threshold
            } else if value > 0, didAssignActiveMedal == false {
                state = .inProgress
                currentValue = max(0, value)
                didAssignActiveMedal = true
            } else {
                state = .locked
                currentValue = 0
            }
            return AchievementMedalProgress(
                tier: tier,
                currentValue: currentValue,
                state: state
            )
        }
    }

    private func stepValuesByAnimal(tickets: [Ticket], trips: [Trip]) -> [String: Int] {
        var values: [String: Int] = [:]
        for ticket in tickets where ticket.sourceSteps > 0 {
            guard let animalId = animalId(for: ticket, trips: trips) else { continue }
            values[animalId, default: 0] += ticket.sourceSteps
        }
        return values
    }

    private func postcardValuesByAnimal(postcards: [Postcard], trips: [Trip]) -> [String: Int] {
        let animalIdByTripId = Dictionary(uniqueKeysWithValues: trips.map { ($0.id, $0.animalId) })
        var values: [String: Int] = [:]
        for postcard in postcards {
            guard let animalId = animalIdByTripId[postcard.tripId] else { continue }
            values[animalId, default: 0] += 1
        }
        return values
    }

    private func animalId(for ticket: Ticket, trips: [Trip]) -> String? {
        if let animalId = ticket.animalId {
            return animalId
        }
        return trips.first { abs($0.departedAt.timeIntervalSince(ticket.giftedAt)) < 1 }?.animalId
    }
}

private enum ProgressMode {
    case segmented
    case cumulative
}
