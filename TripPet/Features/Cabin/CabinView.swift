import SwiftUI
import UIKit

struct CabinView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = CabinViewModel()
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                PaperBackground()

                VStack(spacing: 14) {
                    header
                    CabinSceneView(
                        animals: environment.repository.cabinAnimals,
                        isEmpty: environment.repository.isCabinEmpty || environment.repository.hasReachedDailyAnimalLimit
                    )

                    Spacer(minLength: 138)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                actionCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

            }
            .navigationBarHidden(true)
            .task {
                viewModel.bind(environment: environment)
                environment.revealEligiblePostcards()
                await environment.refreshStepsIfPossible()
                await viewModel.refresh()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
                    .environmentObject(environment)
            }
            .sheet(
                item: $viewModel.pendingGiftConfirmation,
                onDismiss: {
                    viewModel.finishGiftFlow()
                }
            ) { confirmation in
                TicketGiftConfirmationView(
                    confirmation: confirmation,
                    confirmedTrip: viewModel.confirmedGiftTrip,
                    confirmedAnimalName: viewModel.confirmedGiftTrip.map { environment.repository.animalName(for: $0.animalId) },
                    confirmedAnimalAssetName: confirmedAnimalAssetName(for: viewModel.confirmedGiftTrip),
                    isWorking: viewModel.isWorking,
                    onConfirm: { animalId in
                        Task {
                            await viewModel.confirmGiftTodaySteps(animalId: animalId)
                        }
                    },
                    onDone: {
                        viewModel.finishGiftFlow()
                    },
                    onCancel: {
                        viewModel.cancelGiftConfirmation()
                    }
                )
                .presentationDetents([.height(viewModel.confirmedGiftTrip == nil ? 430 : 500)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func confirmedAnimalAssetName(for trip: Trip?) -> String? {
        guard let trip else { return nil }
        return environment.repository.animal(for: trip.animalId)?.travelMarkerAssetName ?? "animal_visitor_unknown"
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(AppCopy.Cabin.title)
                .font(AppTheme.pageTitle)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Button {
                isShowingSettings = true
            } label: {
                ArtImage(name: "icon_settings", isDecorative: false)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(OutlineButtonStyle())
            .accessibilityLabel("设置")
        }
    }

    private var actionCard: some View {
        let isWaitingForAnimal = environment.repository.isCabinEmpty || environment.repository.hasReachedDailyAnimalLimit
        let canGiftTicket = viewModel.canGiftAvailableSteps

        return VStack(alignment: .center, spacing: 14) {
            Text(AppCopy.Cabin.todayStepsTitle)
                .font(AppTheme.cardTitle)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)

            StepCounterView(
                value: viewModel.availableStepsForDisplay,
                limit: environment.ticketRuleEngine.requiredStepsPerTicket
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(maxWidth: .infinity)

            if let giftedStepsSummaryText = viewModel.giftedStepsSummaryText {
                Text(giftedStepsSummaryText)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
            }

            if isWaitingForAnimal {
                Text(viewModel.actionMessage)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
            }

            if isWaitingForAnimal == false {
                Label {
                    Text(viewModel.isFirstImmediateTicketAvailable ? AppCopy.Cabin.firstTicketRuleHint : AppCopy.Cabin.ruleHint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.88)
                } icon: {
                    ArtImage(name: "icon_steps")
                        .frame(width: 16, height: 16)
                        .foregroundStyle(AppTheme.ochre)
                }
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.secondaryInk)

                if viewModel.requiresHealthConnection {
                    Text(viewModel.actionMessage)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task {
                            await viewModel.connectHealth()
                        }
                    } label: {
                        Text(primaryButtonTitle)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isPrimaryButtonDisabled)
                    .accessibilityLabel(primaryButtonTitle)
                } else {
                    GiftTicketButton(
                        isAvailable: canGiftTicket,
                        isWorking: viewModel.isWorking
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task {
                            await viewModel.prepareGiftConfirmation()
                        }
                    }
                    .accessibilityLabel(
                        canGiftTicket
                        ? (viewModel.isFirstImmediateTicketAvailable ? AppCopy.Cabin.firstTicketGiftButton : "赠送一张脚步机票")
                        : "达到3000步后可赠送一张机票"
                    )
                }

                if viewModel.requiresHealthConnection {
                    Button(AppCopy.Cabin.keepLookingButton) {
                        viewModel.keepLookingAroundCabin()
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, isWaitingForAnimal ? 22 : 18)
        .paperCard(cornerRadius: 24)
    }

    private var primaryButtonTitle: String {
        if viewModel.isWorking {
            return viewModel.requiresHealthConnection ? AppCopy.Cabin.connectingHealthButton : AppCopy.Cabin.readingStepsButton
        }
        return viewModel.requiresHealthConnection ? AppCopy.Cabin.connectButton : AppCopy.Cabin.giftButton
    }

    private var isPrimaryButtonDisabled: Bool {
        if viewModel.isWorking { return true }
        if viewModel.requiresHealthConnection { return false }
        return environment.repository.cabinAnimals.isEmpty
    }
}

private struct GiftTicketButton: View {
    var isAvailable: Bool
    var isWorking: Bool
    var action: () -> Void
    @State private var isGlowing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isAvailable {
                    TicketEdgeStroke()
                        .opacity(isGlowing ? 1 : 0.78)
                        .scaleEffect(isGlowing ? 1.16 : 0.92)
                }

                ArtImage(name: "prop_ticket_single")
                    .frame(width: isAvailable ? 174 : 164, height: isAvailable ? 78 : 74)
                    .scaleEffect(ticketScale)

                if isAvailable {
                    Text("点击赠送")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.paperWhite)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.ochre)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.paperWhite.opacity(0.82), lineWidth: AppTheme.hairline)
                        )
                        .shadow(color: AppTheme.ochre.opacity(0.4), radius: 5, x: 0, y: 2)
                        .offset(x: 68, y: -28)
                        .scaleEffect(isGlowing ? 1.08 : 0.96)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .contentShape(Rectangle())
        }
        .buttonStyle(TicketGiftButtonStyle(isAvailable: isAvailable))
        .disabled(isWorking || isAvailable == false)
        .accessibilityHint(isAvailable ? "点击后确认赠送今日脚步机票" : "当前可用步数不足3000")
        .onAppear {
            updateGlow()
        }
        .onChange(of: isAvailable) { _, _ in
            updateGlow()
        }
        .onChange(of: isWorking) { _, _ in
            updateGlow()
        }
    }

    private var glowIntensity: CGFloat {
        isAvailable ? 1 : 0.7
    }

    private var ticketScale: CGFloat {
        let baseScale: CGFloat = isAvailable ? 0.94 : 0.96
        let scaleRange: CGFloat = 0.18 * glowIntensity
        return isGlowing ? baseScale + scaleRange : baseScale
    }

    private func updateGlow() {
        isGlowing = false
        guard isWorking == false else { return }
        withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
            isGlowing = true
        }
    }
}

private struct TicketEdgeStroke: View {
    private let offsets: [CGSize] = [
        CGSize(width: -1.6, height: 0),
        CGSize(width: 1.6, height: 0),
        CGSize(width: 0, height: -1.6),
        CGSize(width: 0, height: 1.6),
        CGSize(width: -1.15, height: -1.15),
        CGSize(width: 1.15, height: -1.15),
        CGSize(width: -1.15, height: 1.15),
        CGSize(width: 1.15, height: 1.15)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(offsets.enumerated()), id: \.offset) { _, offset in
                Image("prop_ticket_single")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(AppTheme.ochre)
                    .offset(x: offset.width, y: offset.height)
            }
        }
        .frame(width: 164, height: 74)
        .blur(radius: 0.25)
        .shadow(color: AppTheme.ochre.opacity(0.62), radius: 11, x: 0, y: 0)
        .accessibilityHidden(true)
    }
}

private struct TicketGiftButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var isAvailable: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .shadow(
                color: AppTheme.ochre.opacity(isEnabled && isAvailable ? (configuration.isPressed ? 0.12 : 0.28) : 0),
                radius: configuration.isPressed ? 4 : 9,
                x: 0,
                y: configuration.isPressed ? 2 : 5
            )
            .opacity(isEnabled ? 1 : 0.62)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TicketGiftConfirmationView: View {
    let confirmation: TicketGiftConfirmation
    let confirmedTrip: Trip?
    let confirmedAnimalName: String?
    let confirmedAnimalAssetName: String?
    var isWorking: Bool
    var onConfirm: (String) -> Void
    var onDone: () -> Void
    var onCancel: () -> Void
    @State private var selectedAnimalId: String?

    var body: some View {
        ZStack {
            PaperBackground()

            if let confirmedTrip {
                departureContent(for: confirmedTrip)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                confirmationContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .onAppear {
            selectedAnimalId = selectedAnimalId ?? confirmation.animalOptions.first?.animalId
        }
        .animation(.easeOut(duration: 0.22), value: confirmedTrip?.id)
    }

    private var confirmationContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppCopy.GiftConfirmation.subtitle)
                .font(AppTheme.sheetDescription)
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                confirmationLine(
                    iconName: "icon_ticket",
                    text: confirmation.isFirstImmediateTicket
                        ? AppCopy.GiftConfirmation.firstTicketLine
                        : AppCopy.GiftConfirmation.ticketLine(count: confirmation.ticketCount)
                )

                Text(AppCopy.GiftConfirmation.chooseAnimalTitle)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(confirmation.animalOptions) { option in
                            animalChoice(option)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(14)
            .paperCard(cornerRadius: 18)

            Button(isWorking ? AppCopy.GiftConfirmation.workingButton : AppCopy.GiftConfirmation.confirmButton) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                guard let animalId = selectedAnimalId ?? confirmation.animalOptions.first?.animalId else { return }
                onConfirm(animalId)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isWorking || confirmation.animalOptions.isEmpty)
        }
        .padding(20)
    }

    private func departureContent(for trip: Trip) -> some View {
        VStack(spacing: 18) {
            Text(AppCopy.Cabin.gifted)
                .font(AppTheme.sheetDescription)
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            GiftDepartureCard(
                trip: trip,
                animalName: confirmedAnimalName ?? "小动物",
                animalAssetName: confirmedAnimalAssetName ?? "animal_visitor_unknown"
            )

            Button("知道了") {
                onDone()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(20)
    }

    private func confirmationLine(iconName: String, text: String) -> some View {
        HStack(spacing: 10) {
            ArtImage(name: iconName)
                .frame(width: 18, height: 18)
                .foregroundStyle(AppTheme.deepSage)
            Text(text)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.ink)
        }
    }

    private func animalChoice(_ option: TicketGiftAnimalOption) -> some View {
        let isSelected = (selectedAnimalId ?? confirmation.animalOptions.first?.animalId) == option.animalId

        return Button {
            selectedAnimalId = option.animalId
        } label: {
            VStack(spacing: 6) {
                ArtImage(name: option.assetName)
                    .frame(width: 54, height: 54)

                Text(option.animalName)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(option.destination)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 82, height: 100)
            .background(isSelected ? AppTheme.sage.opacity(0.18) : AppTheme.paperWhite.opacity(0.36))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? AppTheme.deepSage : AppTheme.sage.opacity(0.42), lineWidth: isSelected ? 1.4 : AppTheme.hairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.animalName)，想去\(option.destination)")
    }
}

private struct GiftDepartureCard: View {
    let trip: Trip
    let animalName: String
    let animalAssetName: String

    var body: some View {
        VStack(alignment: .center, spacing: 22) {
            ZStack {
                ArtImage(name: "trip_route_map_generic", cornerRadius: 18, showsShadow: true)
                    .frame(width: 268, height: 178)

                ArtImage(name: animalAssetName)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppTheme.paperWhite.opacity(0.9), lineWidth: 1.4)
                    )
                    .position(x: 144, y: 96)

                ArtImage(name: "prop_paper_plane")
                    .frame(width: 76, height: 54)
                    .rotationEffect(.degrees(-9))
                    .position(x: 216, y: 52)
            }
            .frame(width: 268, height: 178)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text(AppCopy.Cabin.tripTitle(animalName: animalName, destination: trip.destination))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(AppCopy.Cabin.tripReturnHint)
                    .font(AppTheme.body)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)

                Label {
                    Text(AppCopy.Cabin.tripStatus)
                } icon: {
                    ArtImage(name: "icon_ticket")
                        .frame(width: 15, height: 15)
                        .foregroundStyle(AppTheme.deepSage)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.deepSage)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .paperCard(cornerRadius: 22, stroke: AppTheme.sage.opacity(0.36))
    }
}

#Preview("Cabin authorized") {
    CabinView()
        .environmentObject(AppEnvironment.preview())
}

#Preview("Cabin Health denied") {
    CabinView()
        .environmentObject(
            AppEnvironment.preview(
                stepStatus: .sharingDenied,
                steps: 0
            )
        )
}

#Preview("Cabin traveling Iceland") {
    CabinView()
        .environmentObject(
            AppEnvironment.preview(
                seed: SeedData(
                    animals: SeedData.preview.animals,
                    travelWishes: [
                        TravelWish(
                            id: "wish_iceland_xiaoman",
                            animalId: "xiaoman_hamster",
                            destinationId: "iceland",
                            destination: "冰岛",
                            destinationAssetName: "destination_iceland_line",
                            requiredTickets: 1,
                            status: .traveling,
                            createdAt: Date()
                        )
                    ],
                    trips: [
                        Trip(
                            id: "preview_trip_iceland",
                            animalId: "xiaoman_hamster",
                            destinationId: "iceland",
                            destination: "冰岛",
                            departedAt: Date(),
                            expectedReturnAt: Date().addingTimeInterval(60 * 60 * 24),
                            status: .traveling
                        )
                    ],
                    postcards: []
                )
            )
        )
}
