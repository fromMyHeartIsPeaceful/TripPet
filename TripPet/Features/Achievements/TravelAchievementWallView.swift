import SwiftUI

struct AchievementWallView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var selectedAnimalIndex = 0
    @State private var selectedCategory: AchievementCategory = .travel
    var onBack: (() -> Void)?

    private let achievementEngine = AchievementEngine()
    private let cardHeight: CGFloat = 960
    private let medalContentHeight: CGFloat = 560

    private var progress: [AchievementAnimalProgress] {
        achievementEngine.progress(
            category: selectedCategory,
            animals: environment.repository.animals,
            trips: environment.repository.trips,
            tickets: environment.repository.tickets,
            postcards: environment.repository.postcards
        )
    }

    private var selectedProgress: AchievementAnimalProgress? {
        guard progress.isEmpty == false else { return nil }
        let index = min(selectedAnimalIndex, progress.count - 1)
        return progress[index]
    }

    var body: some View {
        ZStack {
            PaperBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if let selectedProgress {
                        achievementCard(for: selectedProgress)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        ZStack {
            Text(selectedCategory.title)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(AppTheme.deepSage)
                .frame(maxWidth: .infinity)
                .animation(nil, value: selectedCategory)

            Button {
                onBack?()
            } label: {
                HStack(spacing: 8) {
                    ArtImage(name: "icon_back")
                        .frame(width: 18, height: 18)
                    Text("返回")
                }
            }
            .buttonStyle(OutlineButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 44)
    }

    private func achievementCard(for progress: AchievementAnimalProgress) -> some View {
        VStack(spacing: 13) {
            animalHeader(for: progress.animal)
            categorySelector
            medalContentArea(for: progress.medals)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight, alignment: .top)
        .background(cardBackground(for: progress.animal))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.paperGray.opacity(0.85), lineWidth: AppTheme.hairline)
        )
        .shadow(color: AppTheme.oliveInk.opacity(0.09), radius: 12, x: 0, y: 6)
    }

    private func cardBackground(for animal: Animal) -> some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Image("postcard_base_portrait")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()

                Image(postcardEdgeAssetName(for: animal))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .opacity(0.48)
                    .clipped()

                Image(postcardMotifAssetName(for: animal))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(-10))
                    .opacity(0.42)
                    .position(x: size.width * 0.16, y: size.height * 0.13)

                Image(postcardMotifAssetName(for: animal))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(12))
                    .opacity(0.28)
                    .position(x: size.width * 0.84, y: size.height * 0.44)

                Image(postcardMotifAssetName(for: animal))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(7))
                    .opacity(0.22)
                    .position(x: size.width * 0.22, y: size.height * 0.78)

                AppTheme.paperWhite.opacity(0.18)
            }
        }
    }

    private func postcardEdgeAssetName(for animal: Animal) -> String {
        "postcard_edge_\(animalStyleKey(for: animal))"
    }

    private func postcardMotifAssetName(for animal: Animal) -> String {
        "postcard_motif_\(animalStyleKey(for: animal))"
    }

    private func animalStyleKey(for animal: Animal) -> String {
        if Self.supportedAnimalStyleKeys.contains(animal.id) {
            return animal.id
        }
        return Self.animalStyleByAssetName[animal.homeAssetName] ?? "xiaoman_hamster"
    }

    private static let supportedAnimalStyleKeys: Set<String> = [
        "xiaoman_hamster",
        "tangyuan_puppy",
        "moji_cat",
        "dengdeng_rabbit",
        "feifei_parrot",
        "xiaolu_guinea_pig",
        "deer_visitor",
        "fox_visitor",
        "bear_visitor",
    ]

    private static let animalStyleByAssetName: [String: String] = [
        "animal_home_xiaoman_hamster": "xiaoman_hamster",
        "animal_home_tangyuan_puppy": "tangyuan_puppy",
        "animal_home_moji_cat": "moji_cat",
        "animal_home_dengdeng_rabbit": "dengdeng_rabbit",
        "animal_home_feifei_parrot": "feifei_parrot",
        "animal_home_xiaolu_guinea_pig": "xiaolu_guinea_pig",
        "animal_home_jiujiu_deer": "deer_visitor",
        "animal_home_aini_fox": "fox_visitor",
        "animal_home_dundun_bear": "bear_visitor",
    ]

    private func animalHeader(for animal: Animal) -> some View {
        HStack(spacing: 12) {
            arrowButton(name: "map_scroll_arrow_left", direction: -1)

            VStack(spacing: 8) {
                ArtImage(name: animal.homeAssetName)
                    .frame(width: 112, height: 112)
                    .background(
                        Circle()
                            .fill(AppTheme.paperWhite.opacity(0.72))
                            .shadow(color: AppTheme.oliveInk.opacity(0.1), radius: 10, x: 0, y: 5)
                    )

                VStack(spacing: 2) {
                    Text(animal.name)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(animal.species)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
            .frame(maxWidth: .infinity)

            arrowButton(name: "map_scroll_arrow_right", direction: 1)
        }
    }

    private var categorySelector: some View {
        HStack(spacing: 8) {
            ForEach(AchievementCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedCategory = category
                    }
                } label: {
                    Text(category.buttonTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(category == selectedCategory ? AppTheme.paperWhite : AppTheme.deepSage)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            Capsule()
                                .fill(category == selectedCategory ? AppTheme.sage : AppTheme.paperWhite.opacity(0.62))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    category == selectedCategory ? AppTheme.deepSage.opacity(0.22) : AppTheme.paperGray.opacity(0.72),
                                    lineWidth: AppTheme.hairline
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("achievement-category-\(category.rawValue)")
            }
        }
        .padding(.top, 2)
        .animation(.easeInOut(duration: 0.18), value: selectedCategory)
    }

    private func arrowButton(name: String, direction: Int) -> some View {
        Button {
            selectAnimal(offset: direction)
        } label: {
            ArtImage(name: name)
                .frame(width: 38, height: 38)
                .padding(6)
        }
        .buttonStyle(.plain)
        .disabled(progress.count < 2)
        .opacity(progress.count < 2 ? 0.35 : 1)
    }

    private func medalGrid(for medals: [AchievementMedalProgress]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            ForEach(medals) { medal in
                AchievementMedalView(medal: medal)
            }
        }
        .accessibilityIdentifier("achievement-medal-grid-\(selectedCategory.rawValue)")
    }

    private func medalContentArea(for medals: [AchievementMedalProgress]) -> some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                medalGrid(for: medals)
                    .padding(.bottom, 10)
            }
            .id(selectedCategory)
            .transition(.opacity)
        }
        .frame(height: medalContentHeight)
        .clipped()
        .animation(.easeInOut(duration: 0.18), value: selectedCategory)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("成就墙")
                .font(AppTheme.pageTitle)
                .foregroundStyle(AppTheme.ink)
            Text("还没有可以展示的小动物。")
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .paperCard()
    }

    private func selectAnimal(offset: Int) {
        guard progress.isEmpty == false else { return }
        selectedAnimalIndex = (selectedAnimalIndex + offset + progress.count) % progress.count
    }
}

private struct AchievementMedalView: View {
    let medal: AchievementMedalProgress

    private var medalFill: Color {
        switch medal.state {
        case .collected:
            return AppTheme.ochre
        case .inProgress:
            return AppTheme.sage
        case .locked:
            return AppTheme.paperGray.opacity(0.72)
        }
    }

    private var medalStroke: Color {
        switch medal.state {
        case .collected:
            return AppTheme.oliveInk.opacity(0.28)
        case .inProgress:
            return AppTheme.deepSage.opacity(0.45)
        case .locked:
            return AppTheme.paperGray.opacity(0.72)
        }
    }

    private var primaryTextColor: Color {
        switch medal.state {
        case .collected:
            return AppTheme.ink
        case .inProgress:
            return AppTheme.deepSage
        case .locked:
            return AppTheme.secondaryInk.opacity(0.82)
        }
    }

    private var secondaryTextColor: Color {
        switch medal.state {
        case .collected:
            return AppTheme.secondaryInk
        case .inProgress:
            return AppTheme.deepSage.opacity(0.78)
        case .locked:
            return AppTheme.secondaryInk.opacity(0.66)
        }
    }

    private var valueTextColor: Color {
        switch medal.state {
        case .collected:
            return AppTheme.deepSage
        case .inProgress:
            return AppTheme.ochre
        case .locked:
            return AppTheme.secondaryInk.opacity(0.58)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(medalFill)
                    .overlay(
                        Circle()
                            .stroke(medalStroke, lineWidth: AppTheme.hairline)
                    )
                    .shadow(color: AppTheme.oliveInk.opacity(medal.isUnlocked ? 0.16 : 0.04), radius: 7, x: 0, y: 4)

                VStack(spacing: 1) {
                    Text(medal.tier.thresholdText)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(medal.tier.category.medalLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
                .foregroundStyle(medal.state == .locked ? AppTheme.secondaryInk : AppTheme.paperWhite)
                .padding(.horizontal, 5)
            }
            .frame(width: 58, height: 58)

            VStack(spacing: 3) {
                Text(medal.tier.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.64)

                if let subtitle = medal.tier.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                }

                Text(medal.valueText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(valueTextColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 132)
    }
}

#Preview {
    AchievementWallView()
        .environmentObject(AppEnvironment.preview())
}
