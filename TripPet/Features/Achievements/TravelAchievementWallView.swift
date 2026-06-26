import SwiftUI

struct AchievementWallView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var selectedAnimalIndex = 0
    @State private var selectedCategory: AchievementCategory = .travel
    var onBack: (() -> Void)?

    private let achievementEngine = AchievementEngine()
    private let contentLift: CGFloat = 36

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
        GeometryReader { proxy in
            ZStack {
                pageBackground(for: selectedProgress?.animal)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                            .padding(.horizontal, 18)
                            .padding(.top, 18)

                        if let selectedProgress {
                            achievementCard(for: selectedProgress, availableHeight: proxy.size.height)
                                .padding(.top, -contentLift)
                        } else {
                            emptyState
                                .padding(.horizontal, 18)
                        }
                    }
                    .padding(.bottom, 28)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
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

    private func achievementCard(for progress: AchievementAnimalProgress, availableHeight: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 13) {
                animalHeader(for: progress.animal)
                categorySelector
                medalContentArea(for: progress.medals, availableHeight: availableHeight)
            }
            .padding(.horizontal, 12)
            .padding(.top, 0)
            .padding(.bottom, 20)

            animalPagingControls
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: max(availableHeight - 86, 760), alignment: .top)
    }

    @ViewBuilder
    private func pageBackground(for _: Animal?) -> some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Image("achievement_wall_album_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()

                AppTheme.paperWhite.opacity(0.04)
            }
        }
    }

    private func animalHeader(for animal: Animal) -> some View {
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
                .frame(width: 54, height: 54)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(progress.count < 2)
        .opacity(progress.count < 2 ? 0.35 : 1)
    }

    private var animalPagingControls: some View {
        GeometryReader { proxy in
            let arrowY = proxy.size.height * 0.47

            ZStack {
                arrowButton(name: "map_scroll_arrow_left", direction: -1)
                    .position(x: 28, y: arrowY)

                arrowButton(name: "map_scroll_arrow_right", direction: 1)
                    .position(x: proxy.size.width - 28, y: arrowY)
            }
        }
        .allowsHitTesting(progress.count >= 2)
    }

    private func medalGrid(for medals: [AchievementMedalProgress]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(medals.indices, id: \.self) { index in
                AchievementMedalView(medal: medals[index], tierOrdinal: index + 1)
            }
        }
        .accessibilityIdentifier("achievement-medal-grid-\(selectedCategory.rawValue)")
    }

    private func medalContentArea(for medals: [AchievementMedalProgress], availableHeight: CGFloat) -> some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                medalGrid(for: medals)
                    .padding(.bottom, 14)
            }
            .id(selectedCategory)
            .transition(.opacity)
        }
        .frame(height: max(430, availableHeight - 440))
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
    let tierOrdinal: Int

    private var medalOpacity: Double {
        switch medal.state {
        case .collected:
            return 1
        case .inProgress:
            return 0.94
        case .locked:
            return 0.72
        }
    }

    private var medalSaturation: Double {
        medal.state == .locked ? 0.35 : 1
    }

    private var medalStroke: Color {
        switch medal.state {
        case .collected:
            return AppTheme.oliveInk.opacity(0.18)
        case .inProgress:
            return AppTheme.deepSage.opacity(0.38)
        case .locked:
            return AppTheme.paperGray.opacity(0.7)
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
        VStack(spacing: 7) {
            medalArtwork
                .frame(width: 106, height: 106)

            Text(medal.tier.thresholdText)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(valueTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 7)
                .frame(height: 18)
                .background(AppTheme.paperWhite.opacity(medal.state == .locked ? 0.38 : 0.72))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(medalStroke, lineWidth: AppTheme.hairline)
                )

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
        .frame(minHeight: 162)
    }

    @ViewBuilder
    private var medalArtwork: some View {
        if let medalAssetName = medal.tier.medalAssetName {
            formalMedalArtwork(assetName: medalAssetName)
        } else {
            ZStack {
                Circle()
                    .fill(AppTheme.paperWhite.opacity(0.26))
                Circle()
                    .stroke(
                        AppTheme.paperGray.opacity(0.72),
                        style: StrokeStyle(lineWidth: AppTheme.hairline, dash: [5, 5])
                    )
                Text("待美术")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryInk.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .shadow(color: AppTheme.oliveInk.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }

    private func formalMedalArtwork(assetName: String) -> some View {
        let ring = MedalRingStyle.forTierOrdinal(tierOrdinal)

        return ZStack {
            Circle()
                .fill(AppTheme.paperWhite.opacity(medal.state == .locked ? 0.26 : 0.58))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(medal.state == .locked ? 0.54 : 0.82),
                                    AppTheme.oliveInk.opacity(medal.state == .locked ? 0.08 : 0.13)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.white.opacity(medal.state == .locked ? 0.32 : 0.58), radius: 2, x: -1.5, y: -1.5)
                .shadow(color: AppTheme.oliveInk.opacity(medal.isUnlocked ? 0.16 : 0.05), radius: 7, x: 3.5, y: 5)

            ArtImage(name: assetName)
                .frame(width: 98, height: 98)
                .saturation(medalSaturation)
                .opacity(medalOpacity)
                .shadow(color: Color.white.opacity(medal.state == .locked ? 0.18 : 0.42), radius: 1.5, x: -1, y: -1)
                .shadow(color: AppTheme.oliveInk.opacity(medal.isUnlocked ? 0.12 : 0.03), radius: 4, x: 1.5, y: 2.5)

            Circle()
                .stroke(AppTheme.oliveInk.opacity(medal.state == .locked ? 0.08 : 0.12), lineWidth: 0.8)
                .frame(width: 86, height: 86)

            Circle()
                .stroke(ring.underlayColor, lineWidth: ring.lineWidth + 1.5)
                .frame(width: 92, height: 92)
                .opacity(ring.underlayOpacity)

            Circle()
                .stroke(ring.color, lineWidth: ring.lineWidth)
                .frame(width: 92, height: 92)
                .opacity(medal.state == .locked ? 0.72 : 1)
                .shadow(color: ring.color.opacity(ring.glowOpacity), radius: ring.glowRadius, x: 0, y: 0)
        }
    }
}

private struct MedalRingStyle {
    let color: Color
    let lineWidth: CGFloat
    let glowRadius: CGFloat
    let glowOpacity: Double
    let underlayColor: Color
    let underlayOpacity: Double

    static func forTierOrdinal(_ tierOrdinal: Int) -> MedalRingStyle {
        let clampedOrdinal = max(1, min(tierOrdinal, 18))
        let colorIndex = (clampedOrdinal - 1) / 2
        let palette = [
            Color(red: 0.549, green: 0.569, blue: 0.537),
            Color(red: 1.0, green: 0.973, blue: 0.929),
            Color(red: 0.749, green: 0.863, blue: 0.753),
            Color(red: 0.62, green: 0.784, blue: 0.863),
            Color(red: 0.969, green: 0.91, blue: 0.651),
            Color(red: 0.741, green: 0.655, blue: 0.847),
            Color(red: 0.878, green: 0.702, blue: 0.306),
            Color(red: 0.91, green: 0.592, blue: 0.271),
            Color(red: 0.91, green: 0.475, blue: 0.2)
        ]
        let baseLineWidth = 1.25 + CGFloat(colorIndex) * 0.22
        let lineWidth = colorIndex == 8 ? baseLineWidth + 0.65 : baseLineWidth
        let isWhiteRing = colorIndex == 1
        let isGlowRing = colorIndex == 8

        return MedalRingStyle(
            color: palette[colorIndex],
            lineWidth: lineWidth,
            glowRadius: isGlowRing ? 5 : (isWhiteRing ? 3 : 1.5),
            glowOpacity: isGlowRing ? 0.42 : (isWhiteRing ? 0.2 : 0.1),
            underlayColor: isWhiteRing ? AppTheme.pencilGray.opacity(0.5) : AppTheme.paperWhite.opacity(0.68),
            underlayOpacity: isWhiteRing ? 0.72 : 0.38
        )
    }
}

#Preview {
    AchievementWallView()
        .environmentObject(AppEnvironment.preview())
}
