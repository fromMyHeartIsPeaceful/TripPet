import Foundation

enum AchievementCategory: String, CaseIterable, Identifiable, Equatable {
    case travel
    case steps
    case postcards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .travel:
            return "旅行勋章墙"
        case .steps:
            return "脚步勋章墙"
        case .postcards:
            return "明信片勋章墙"
        }
    }

    var buttonTitle: String {
        switch self {
        case .travel:
            return "旅行"
        case .steps:
            return "脚步"
        case .postcards:
            return "明信片"
        }
    }

    var medalLabel: String {
        switch self {
        case .travel:
            return "旅行"
        case .steps:
            return "脚步"
        case .postcards:
            return "明信片"
        }
    }

    var unit: String {
        switch self {
        case .travel:
            return "次"
        case .steps:
            return "步"
        case .postcards:
            return "张"
        }
    }
}

struct AchievementTier: Identifiable, Equatable {
    var id: String { "\(category.rawValue)-\(threshold)" }
    let category: AchievementCategory
    let threshold: Int
    let title: String
    let subtitle: String?
    let medalAssetName: String?

    init(
        category: AchievementCategory,
        threshold: Int,
        title: String,
        subtitle: String?,
        medalAssetName: String? = nil
    ) {
        self.category = category
        self.threshold = threshold
        self.title = title
        self.subtitle = subtitle
        self.medalAssetName = medalAssetName
    }

    var thresholdText: String {
        "\(formattedThreshold)\(category.unit)"
    }

    private var formattedThreshold: String {
        guard category == .steps else {
            return "\(threshold)"
        }
        if threshold >= 1_000_000 {
            return "\(threshold / 1_000_000)m"
        }
        if threshold >= 1_000 {
            return "\(threshold / 1_000)k"
        }
        return "\(threshold)"
    }
}

enum AchievementMedalState: Equatable {
    case collected
    case inProgress
    case locked
}

struct AchievementMedalProgress: Identifiable, Equatable {
    var id: String { tier.id }
    let tier: AchievementTier
    let currentValue: Int
    let state: AchievementMedalState

    var isUnlocked: Bool {
        state == .collected
    }

    var valueText: String {
        "\(min(currentValue, tier.threshold)) / \(tier.threshold)"
    }
}

struct AchievementAnimalProgress: Identifiable, Equatable {
    var id: String { "\(animal.id)-\(category.rawValue)" }
    let animal: Animal
    let category: AchievementCategory
    let totalValue: Int
    let medals: [AchievementMedalProgress]

    var completedMedalCount: Int {
        medals.filter(\.isUnlocked).count
    }

    var travelCount: Int {
        totalValue
    }
}

struct AchievementSummary: Equatable {
    let category: AchievementCategory
    let animals: [AchievementAnimalProgress]

    var collectedMedalCount: Int {
        animals.reduce(0) { total, progress in
            total + progress.completedMedalCount
        }
    }

    var availableMedalCount: Int {
        animals.reduce(0) { total, progress in
            total + progress.medals.count
        }
    }
}

struct AchievementMedalAward: Identifiable, Equatable {
    let animalId: String
    let animalName: String
    let medal: AchievementMedalProgress
    let tierOrdinal: Int

    var id: String {
        Self.notificationId(animalId: animalId, tier: medal.tier)
    }

    static func notificationId(animalId: String, tier: AchievementTier) -> String {
        "\(animalId)-\(tier.category.rawValue)-\(tier.threshold)"
    }
}
