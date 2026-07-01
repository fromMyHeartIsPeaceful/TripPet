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

struct AchievementMedalSelection: Identifiable {
    let medal: AchievementMedalProgress
    let tierOrdinal: Int

    var id: String {
        "\(medal.id)-\(tierOrdinal)"
    }
}

struct AchievementMedalSharePayload: Equatable {
    let title: String
    let categoryTitle: String
    let requirementDescription: String
    let progressDescription: String
    let note: String?
}

enum AchievementMedalSharePolicy {
    static func payload(for medal: AchievementMedalProgress) -> AchievementMedalSharePayload? {
        guard medal.isUnlocked else { return nil }
        return AchievementMedalSharePayload(
            title: medal.tier.title,
            categoryTitle: "\(medal.tier.category.medalLabel)勋章",
            requirementDescription: requirementDescription(for: medal),
            progressDescription: progressDescription(for: medal),
            note: medal.tier.subtitle
        )
    }

    static func filename(for medal: AchievementMedalProgress) -> String {
        "bulu-medal-\(medal.tier.category.rawValue)-\(medal.tier.threshold).png"
    }

    static func requirementDescription(for medal: AchievementMedalProgress) -> String {
        switch medal.tier.category {
        case .travel:
            return "完成 \(formattedThreshold(for: medal)) 次旅行即可获得"
        case .steps:
            return "累计赠送\(formattedThreshold(for: medal))步即可获得"
        case .postcards:
            return "收到 \(formattedThreshold(for: medal)) 张明信片即可获得"
        }
    }

    static func progressDescription(for medal: AchievementMedalProgress) -> String {
        "当前进度：\(formattedCurrentValue(for: medal))/\(formattedThreshold(for: medal))"
    }

    private static func formattedThreshold(for medal: AchievementMedalProgress) -> String {
        "\(medal.tier.threshold)"
    }

    private static func formattedCurrentValue(for medal: AchievementMedalProgress) -> String {
        "\(max(0, min(medal.currentValue, medal.tier.threshold)))"
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
                size: 106,
                showsAcquiredShine: true
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

private enum AchievementMedalDetailMode {
    case wallDetail
    case awardNotice

    var buttonAccessibilityIdentifier: String {
        switch self {
        case .wallDetail:
            return "achievement-medal-detail-done"
        case .awardNotice:
            return "achievement-medal-award-done"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .wallDetail:
            return "achievement-medal-detail"
        case .awardNotice:
            return "achievement-medal-award"
        }
    }
}

struct AchievementMedalDetailView: View {
    let selection: AchievementMedalSelection
    private let mode: AchievementMedalDetailMode
    private let awardAnimalName: String?
    var onDone: () -> Void

    init(selection: AchievementMedalSelection, onDone: @escaping () -> Void) {
        self.selection = selection
        mode = .wallDetail
        awardAnimalName = nil
        self.onDone = onDone
    }

    init(award: AchievementMedalAward, onDone: @escaping () -> Void) {
        selection = AchievementMedalSelection(
            medal: award.medal,
            tierOrdinal: award.tierOrdinal
        )
        mode = .awardNotice
        awardAnimalName = award.animalName
        self.onDone = onDone
    }

    private var medal: AchievementMedalProgress {
        selection.medal
    }

    private var sharePayload: AchievementMedalSharePayload? {
        AchievementMedalSharePolicy.payload(for: medal)
    }

    var body: some View {
        AppActionBottomSheet(
            buttonAccessibilityIdentifier: mode.buttonAccessibilityIdentifier,
            onButton: onDone
        ) {
            VStack(spacing: 14) {
                topControl

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        AchievementMedalArtwork(
                            medal: medal,
                            tierOrdinal: selection.tierOrdinal,
                            size: 190
                        )
                        .frame(width: 190, height: 190)

                        detailCard
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityIdentifier(mode.accessibilityIdentifier)
    }

    @ViewBuilder
    private var topControl: some View {
        switch mode {
        case .wallDetail:
            HStack {
                Spacer()
                shareControl
            }
        case .awardNotice:
            VStack(spacing: 4) {
                Text("获得新勋章")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.deepSage)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                if let awardAnimalName {
                    Text("\(awardAnimalName)的\(medal.tier.category.medalLabel)勋章")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var shareControl: some View {
        if let sharePayload {
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
        } else {
            Button {} label: {
                shareIconLabel
            }
            .disabled(true)
            .opacity(0.38)
            .accessibilityLabel("收集后可分享勋章")
        }
    }

    private var shareIconLabel: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .frame(width: 36, height: 36)
            .background(AppTheme.ivory)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.paperGray, lineWidth: AppTheme.hairline)
            )
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

            if let note = medal.tier.subtitle, note.isEmpty == false {
                Text(note)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.deepSage)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            VStack(spacing: 4) {
                Text(requirementDescription)
                Text(progressDescription)
            }
            .font(AppTheme.body)
            .foregroundStyle(AppTheme.secondaryInk)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .paperCard(cornerRadius: 18, stroke: AppTheme.sage.opacity(0.36))
    }

    private var requirementDescription: String {
        AchievementMedalSharePolicy.requirementDescription(for: medal)
    }

    private var progressDescription: String {
        AchievementMedalSharePolicy.progressDescription(for: medal)
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

                if let note = payload.note, note.isEmpty == false {
                    Text(note)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.deepSage)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 4) {
                    Text(payload.requirementDescription)
                    Text(payload.progressDescription)
                }
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let medal: AchievementMedalProgress
    let tierOrdinal: Int
    let size: CGFloat
    var showsAcquiredShine = false

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
            ArtImage(name: assetName)
                .frame(width: 104 * scale, height: 104 * scale)
                .saturation(state.saturation)
                .contrast(state.contrast)
                .brightness(state.brightness)
                .opacity(state.assetOpacity)
                .shadow(color: Color.white.opacity(state.assetLightShadowOpacity), radius: 1.5 * scale, x: -1 * scale, y: -1 * scale)
                .shadow(color: AppTheme.oliveInk.opacity(state.assetDropShadowOpacity), radius: 4 * scale, x: 1.5 * scale, y: 2.5 * scale)

            if state.maskOpacity > 0 {
                AppTheme.paperWhite
                    .opacity(state.maskOpacity)
                    .frame(width: 104 * scale, height: 104 * scale)
                    .mask(
                        ArtImage(name: assetName)
                            .frame(width: 104 * scale, height: 104 * scale)
                    )
                    .allowsHitTesting(false)
            }

            if showsAcquiredShine, medal.isUnlocked, reduceMotion == false {
                AchievementMedalAcquiredShine(assetName: assetName, size: 104 * scale)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct AchievementMedalAcquiredShine: View {
    let assetName: String
    let size: CGFloat

    private let activeDuration: TimeInterval = 1.5
    private let pauseDuration: TimeInterval = 2.0
    private var period: TimeInterval { activeDuration + pauseDuration }

    var body: some View {
        TimelineView(.animation) { timeline in
            if let phase = normalizedPhase(for: timeline.date) {
                AchievementMedalShineBand(phase: phase, size: size)
                    .frame(width: size, height: size)
                    .mask(
                        ArtImage(name: assetName)
                            .frame(width: size, height: size)
                    )
                    .blendMode(.screen)
                    .compositingGroup()
            } else {
                Color.clear
                    .frame(width: size, height: size)
            }
        }
    }

    private func normalizedPhase(for date: Date) -> Double? {
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
        guard elapsed < activeDuration else { return nil }
        return elapsed / activeDuration
    }
}

private struct AchievementMedalShineBand: View {
    let phase: Double
    let size: CGFloat

    private var easedFlashOpacity: Double {
        pow(sin(phase * .pi), 0.72)
    }

    var body: some View {
        let travelDistance = size * 2.15
        let x = CGFloat(phase) * travelDistance - size * 1.08
        let y = CGFloat(phase - 0.5) * size * 0.34

        ZStack {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.28),
                    .init(color: Color.white.opacity(0.16), location: 0.40),
                    .init(color: Color(red: 1, green: 0.96, blue: 0.74).opacity(0.58), location: 0.50),
                    .init(color: Color.white.opacity(0.34), location: 0.58),
                    .init(color: .clear, location: 0.73),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: size * 0.46, height: size * 1.72)
            .rotationEffect(.degrees(-28))
            .offset(x: x, y: y)
            .blur(radius: 1.2)
            .opacity(0.92 * easedFlashOpacity)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.34),
                    Color(red: 1, green: 0.93, blue: 0.62).opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: size * 0.36
            )
            .frame(width: size * 0.72, height: size * 0.72)
            .offset(x: x + size * 0.03, y: y - size * 0.06)
            .opacity(0.5 * easedFlashOpacity)
        }
    }
}

private struct AchievementMedalArtworkVisualState {
    let assetOpacity: Double
    let saturation: Double
    let contrast: Double
    let brightness: Double
    let maskOpacity: Double
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
                maskOpacity: 0,
                assetLightShadowOpacity: 0.42,
                assetDropShadowOpacity: 0.12
            )
        case .inProgress:
            return AchievementMedalArtworkVisualState(
                assetOpacity: 0.86,
                saturation: 0.82,
                contrast: 0.9,
                brightness: 0.02,
                maskOpacity: 0.16,
                assetLightShadowOpacity: 0.08,
                assetDropShadowOpacity: 0.02
            )
        case .locked:
            return AchievementMedalArtworkVisualState(
                assetOpacity: 0.72,
                saturation: 0.66,
                contrast: 0.82,
                brightness: 0.04,
                maskOpacity: 0.28,
                assetLightShadowOpacity: 0.05,
                assetDropShadowOpacity: 0.01
            )
        }
    }
}

#Preview {
    AchievementWallView()
        .environmentObject(AppEnvironment.preview())
}
