import SwiftUI

struct AchievementWallView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedAnimalIndex = 0
    @State private var selectedCategory: AchievementCategory = .travel
    @State private var animalPageDirection = 1
    @State private var selectedMedalDetail: AchievementMedalSelection?
    var onBack: (() -> Void)?

    private let achievementEngine = AchievementEngine()
    private let contentLift: CGFloat = 10
    private let animalHeaderHeight: CGFloat = 148

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
        .sheet(item: $selectedMedalDetail) { selection in
            AchievementMedalDetailView(selection: selection) {
                selectedMedalDetail = nil
            }
            .appActionSheetPresentation()
        }
    }

    private var header: some View {
        ZStack {
            Text(selectedCategory.title)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(AppTheme.deepSage)
                .frame(maxWidth: .infinity)
                .animation(nil, value: selectedCategory)

            if let onBack {
                Button {
                    onBack()
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
        }
        .frame(height: 44)
    }

    private func achievementCard(for progress: AchievementAnimalProgress, availableHeight: CGFloat) -> some View {
        VStack(spacing: 13) {
            ZStack {
                animalHeader(for: progress.animal)
                    .id(progress.animal.id)
                    .transition(animalPageTransition)
            }
            .frame(height: animalHeaderHeight)
            .clipped()

            categorySelector
                .padding(.horizontal, 12)

            ZStack {
                medalContentArea(for: progress.medals, availableHeight: availableHeight)
                    .id(progress.animal.id)
                    .transition(animalPageTransition)
                    .zIndex(1)

                animalPagingControls
                    .zIndex(2)
            }
            .padding(.horizontal, 12)
        }
        .padding(.top, 0)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(minHeight: max(availableHeight - 86, 760), alignment: .top)
        .clipped()
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
        VStack(spacing: 7) {
            ArtImage(name: animal.homeAssetName)
                .frame(width: 104, height: 104)
                .background(
                    Circle()
                        .fill(AppTheme.paperWhite.opacity(0.72))
                        .shadow(color: AppTheme.oliveInk.opacity(0.1), radius: 10, x: 0, y: 5)
                )

            Text(animal.name)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(animal.name)
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
                let tierOrdinal = index + 1

                Button {
                    selectedMedalDetail = AchievementMedalSelection(
                        medal: medals[index],
                        tierOrdinal: tierOrdinal
                    )
                } label: {
                    AchievementMedalView(medal: medals[index], tierOrdinal: tierOrdinal)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(medals[index].tier.title)
                .accessibilityIdentifier("achievement-medal-\(selectedCategory.rawValue)-\(tierOrdinal)")
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
        guard progress.count > 1 else { return }
        animalPageDirection = offset >= 0 ? 1 : -1
        withAnimation(animalPageAnimation) {
            selectedAnimalIndex = (selectedAnimalIndex + offset + progress.count) % progress.count
        }
    }

    private var animalPageTransition: AnyTransition {
        guard reduceMotion == false else {
            return .opacity
        }

        let insertionEdge: Edge = animalPageDirection >= 0 ? .trailing : .leading
        let removalEdge: Edge = animalPageDirection >= 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge),
            removal: .move(edge: removalEdge)
        )
    }

    private var animalPageAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.14)
            : .smooth(duration: 0.58, extraBounce: 0)
    }
}

private struct AchievementMedalSelection: Identifiable {
    let medal: AchievementMedalProgress
    let tierOrdinal: Int

    var id: String {
        "\(medal.id)-\(tierOrdinal)"
    }
}

struct AchievementMedalSharePayload: Equatable {
    let title: String
    let categoryTitle: String
    let completionDescription: String
    let note: String?
}

enum AchievementMedalSharePolicy {
    static func payload(for medal: AchievementMedalProgress) -> AchievementMedalSharePayload? {
        guard medal.isUnlocked else { return nil }
        return AchievementMedalSharePayload(
            title: medal.tier.title,
            categoryTitle: "\(medal.tier.category.medalLabel)勋章",
            completionDescription: completionDescription(for: medal),
            note: medal.tier.subtitle
        )
    }

    static func filename(for medal: AchievementMedalProgress) -> String {
        "bulu-medal-\(medal.tier.category.rawValue)-\(medal.tier.threshold).png"
    }

    static func completionDescription(for medal: AchievementMedalProgress) -> String {
        switch medal.tier.category {
        case .travel:
            return "完成 \(formattedThreshold(for: medal)) 次旅行即可获得。当前进度：\(medal.valueText)。"
        case .steps:
            return "累计行走 \(formattedThreshold(for: medal)) 步即可获得。当前进度：\(medal.valueText)。"
        case .postcards:
            return "收到 \(formattedThreshold(for: medal)) 张明信片即可获得。当前进度：\(medal.valueText)。"
        }
    }

    private static func formattedThreshold(for medal: AchievementMedalProgress) -> String {
        medal.tier.threshold.formatted(.number.grouping(.automatic))
    }
}

private struct AchievementMedalView: View {
    let medal: AchievementMedalProgress
    let tierOrdinal: Int

    private var primaryTextColor: Color {
        medal.isUnlocked ? AppTheme.ink : AppTheme.secondaryInk.opacity(0.82)
    }

    var body: some View {
        VStack(spacing: 7) {
            AchievementMedalArtwork(
                medal: medal,
                tierOrdinal: tierOrdinal,
                size: 106
            )
                .frame(width: 106, height: 106)

            Text(medal.tier.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(primaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .frame(height: 44, alignment: .top)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 142, alignment: .top)
    }
}

private struct AchievementMedalDetailView: View {
    let selection: AchievementMedalSelection
    var onDone: () -> Void

    private var medal: AchievementMedalProgress {
        selection.medal
    }

    private var sharePayload: AchievementMedalSharePayload? {
        AchievementMedalSharePolicy.payload(for: medal)
    }

    var body: some View {
        AppActionBottomSheet(
            buttonAccessibilityIdentifier: "achievement-medal-detail-done",
            onButton: onDone
        ) {
            VStack(spacing: 14) {
                if let sharePayload {
                    HStack {
                        Spacer()

                        RenderedShareLink(
                            title: sharePayload.title,
                            filename: AchievementMedalSharePolicy.filename(for: medal),
                            accessibilityLabel: AppCopy.Share.medalAccessibilityLabel
                        ) {
                            AchievementMedalShareImage(
                                medal: medal,
                                tierOrdinal: selection.tierOrdinal,
                                payload: sharePayload
                            )
                        }
                    }
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        AchievementMedalArtwork(
                            medal: medal,
                            tierOrdinal: selection.tierOrdinal,
                            size: 190
                        )
                        .frame(width: 190, height: 190)
                        .padding(.top, 6)

                        detailCard
                    }
                    .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
        }
        .accessibilityIdentifier("achievement-medal-detail")
    }

    private var detailCard: some View {
        VStack(spacing: 12) {
            Text(medal.tier.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)

            Text(completionDescription)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let note = medal.tier.subtitle, note.isEmpty == false {
                Text(note)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.deepSage)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .paperCard(cornerRadius: 18, stroke: AppTheme.sage.opacity(0.36))
    }

    private var completionDescription: String {
        AchievementMedalSharePolicy.completionDescription(for: medal)
    }
}

private struct AchievementMedalShareImage: View {
    let medal: AchievementMedalProgress
    let tierOrdinal: Int
    let payload: AchievementMedalSharePayload

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 5) {
                Text("我获得了\(payload.categoryTitle)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.deepSage)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("小动物旅行手帐的新收藏")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.top, 8)

            AchievementMedalArtwork(
                medal: medal,
                tierOrdinal: tierOrdinal,
                size: 206
            )
            .frame(width: 206, height: 206)
            .padding(.top, 4)

            VStack(spacing: 12) {
                Text(payload.title)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.68)

                Text(payload.completionDescription)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let note = payload.note, note.isEmpty == false {
                    Text(note)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.deepSage)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .paperCard(cornerRadius: 20, stroke: AppTheme.sage.opacity(0.34))

            Spacer(minLength: 0)

            ShareBrandFooter()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(width: ShareImageRenderer.pointSize.width, height: ShareImageRenderer.pointSize.height)
        .background(ShareCanvasBackground())
    }
}

private struct AchievementMedalArtwork: View {
    let medal: AchievementMedalProgress
    let tierOrdinal: Int
    let size: CGFloat

    private var scale: CGFloat {
        size / 106
    }

    private var visualState: AchievementMedalArtworkVisualState {
        AchievementMedalArtworkVisualState.forMedalState(medal.state)
    }

    var body: some View {
        medalArtwork
            .frame(width: size, height: size)
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
            .shadow(color: AppTheme.oliveInk.opacity(0.03), radius: 4 * scale, x: 0, y: 2 * scale)
        }
    }

    private func formalMedalArtwork(assetName: String) -> some View {
        let state = visualState

        return ZStack {
            Circle()
                .fill(AppTheme.paperWhite.opacity(state.baseFillOpacity))
                .frame(width: 100 * scale, height: 100 * scale)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(state.baseHighlightOpacity),
                                    AppTheme.oliveInk.opacity(state.baseStrokeOpacity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2 * scale
                        )
                )
                .shadow(color: Color.white.opacity(state.baseLightShadowOpacity), radius: 2 * scale, x: -1.5 * scale, y: -1.5 * scale)
                .shadow(color: AppTheme.oliveInk.opacity(state.baseDropShadowOpacity), radius: 7 * scale, x: 3.5 * scale, y: 5 * scale)

            ArtImage(name: assetName)
                .frame(width: 104 * scale, height: 104 * scale)
                .saturation(state.saturation)
                .contrast(state.contrast)
                .brightness(state.brightness)
                .opacity(state.assetOpacity)
                .shadow(color: Color.white.opacity(state.assetLightShadowOpacity), radius: 1.5 * scale, x: -1 * scale, y: -1 * scale)
                .shadow(color: AppTheme.oliveInk.opacity(state.assetDropShadowOpacity), radius: 4 * scale, x: 1.5 * scale, y: 2.5 * scale)

            if state.veilOpacity > 0 {
                Circle()
                    .fill(AppTheme.oliveInk.opacity(state.veilOpacity))
                    .frame(width: 99 * scale, height: 99 * scale)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct AchievementMedalArtworkVisualState {
    let assetOpacity: Double
    let saturation: Double
    let contrast: Double
    let brightness: Double
    let veilOpacity: Double
    let baseFillOpacity: Double
    let baseHighlightOpacity: Double
    let baseStrokeOpacity: Double
    let baseLightShadowOpacity: Double
    let baseDropShadowOpacity: Double
    let assetLightShadowOpacity: Double
    let assetDropShadowOpacity: Double

    static func forMedalState(_ state: AchievementMedalState) -> AchievementMedalArtworkVisualState {
        switch state {
        case .collected:
            return AchievementMedalArtworkVisualState(
                assetOpacity: 1,
                saturation: 1,
                contrast: 1,
                brightness: 0,
                veilOpacity: 0,
                baseFillOpacity: 0.58,
                baseHighlightOpacity: 0.82,
                baseStrokeOpacity: 0.13,
                baseLightShadowOpacity: 0.58,
                baseDropShadowOpacity: 0.16,
                assetLightShadowOpacity: 0.42,
                assetDropShadowOpacity: 0.12
            )
        case .inProgress:
            return AchievementMedalArtworkVisualState(
                assetOpacity: 0.74,
                saturation: 0,
                contrast: 0.68,
                brightness: -0.08,
                veilOpacity: 0.06,
                baseFillOpacity: 0.32,
                baseHighlightOpacity: 0.48,
                baseStrokeOpacity: 0.08,
                baseLightShadowOpacity: 0.28,
                baseDropShadowOpacity: 0.05,
                assetLightShadowOpacity: 0.14,
                assetDropShadowOpacity: 0.03
            )
        case .locked:
            return AchievementMedalArtworkVisualState(
                assetOpacity: 0.56,
                saturation: 0,
                contrast: 0.52,
                brightness: -0.2,
                veilOpacity: 0.12,
                baseFillOpacity: 0.22,
                baseHighlightOpacity: 0.34,
                baseStrokeOpacity: 0.07,
                baseLightShadowOpacity: 0.2,
                baseDropShadowOpacity: 0.04,
                assetLightShadowOpacity: 0.09,
                assetDropShadowOpacity: 0.02
            )
        }
    }
}

#Preview {
    AchievementWallView()
        .environmentObject(AppEnvironment.preview())
}
