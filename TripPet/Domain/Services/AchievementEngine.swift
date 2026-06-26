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
            subtitle: "我在旅行生涯中一分钱没出过你敢信",
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
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_001"
        ),
        AchievementTier(
            category: .steps,
            threshold: 9_000,
            title: "没病走两步",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_002"
        ),
        AchievementTier(
            category: .steps,
            threshold: 20_000,
            title: "佛山无影脚在世传人",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_003"
        ),
        AchievementTier(
            category: .steps,
            threshold: 30_000,
            title: "要啥自行车",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_004"
        ),
        AchievementTier(
            category: .steps,
            threshold: 50_000,
            title: "有了闪现技能还想去送外卖的热爱走路人士",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_005"
        ),
        AchievementTier(
            category: .steps,
            threshold: 100_000,
            title: "您真是白脚起家呀！",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_006"
        ),
        AchievementTier(
            category: .steps,
            threshold: 200_000,
            title: "一人之力托举起9个小动物的奉献之神",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_007"
        ),
        AchievementTier(
            category: .steps,
            threshold: 300_000,
            title: "这地球，这世界，全是您走出来的！",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_008"
        ),
        AchievementTier(
            category: .steps,
            threshold: 400_000,
            title: "不知道您是否听说过一个叫骆驼祥子的人？",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_009"
        ),
        AchievementTier(
            category: .steps,
            threshold: 500_000,
            title: "11路公交车司机",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_010"
        ),
        AchievementTier(
            category: .steps,
            threshold: 600_000,
            title: "你的腿不是腿，是塞纳河畔的春水",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_011"
        ),
        AchievementTier(
            category: .steps,
            threshold: 700_000,
            title: "踏破铁鞋无觅处，蓦然回首，那人却在灯火阑珊处",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_012"
        ),
        AchievementTier(
            category: .steps,
            threshold: 800_000,
            title: "铁板烧！不，是铁脚板！",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_013"
        ),
        AchievementTier(
            category: .steps,
            threshold: 1_000_000,
            title: "宇也球说“我是谁呀，我是您脚底的一颗痣而已”",
            subtitle: nil,
            medalAssetName: "achievement_medal_steps_tier_014"
        )
    ]

    static let postcardTiers: [AchievementTier] = [
        AchievementTier(
            category: .postcards,
            threshold: 1,
            title: "初次相识",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_001"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 10,
            title: "些许相知",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_002"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 50,
            title: "你也有点可爱",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_003"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 100,
            title: "有钱人也不会是无情无义之人",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_004"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 200,
            title: "谁说的有钱人无情无义！",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_005"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 300,
            title: "你说什么都对，My Lord",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_006"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 500,
            title: "很难想象世界上还有你这样完美的人",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_007"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 800,
            title: "我要打包银河系的爱给你",
            subtitle: nil,
            medalAssetName: "achievement_medal_postcards_tier_008"
        ),
        AchievementTier(
            category: .postcards,
            threshold: 1_000,
            title: "还是打包整个宇宙吧，全是我的真心",
            subtitle: nil,
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
            mode = .cumulative
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
            } else if didAssignActiveMedal == false {
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
            } else if didAssignActiveMedal == false {
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
