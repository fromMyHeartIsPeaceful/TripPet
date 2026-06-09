import SwiftUI
import UIKit

struct CabinView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = CabinViewModel()
    @State private var isShowingSettings = false
    @State private var isShowingGiftFlight = false
    @State private var travelModalTrip: Trip?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                PaperBackground()

                VStack(spacing: 14) {
                    header
                    CabinSceneView(
                        resident: environment.repository.currentCabinAnimal,
                        visitor: nil,
                        isEmpty: environment.repository.isCabinEmpty || environment.repository.hasReachedDailyAnimalLimit
                    )

                    Spacer(minLength: 138)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                actionCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                if isShowingGiftFlight && reduceMotion == false {
                    GiftFlightOverlay()
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .padding(.horizontal, 34)
                        .padding(.bottom, 180)
                }

                if let trip = travelModalTrip {
                    TravelStatusModal(
                        trip: trip,
                        animalName: environment.repository.animalName(for: trip.animalId),
                        routeMapAssetName: environment.destination(for: trip)?.routeMapAssetName ?? "trip_route_map_paris"
                    ) {
                        withAnimation(.easeOut(duration: 0.18)) {
                            travelModalTrip = nil
                        }
                    }
                    .transition(.opacity)
                }
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
            .sheet(item: $viewModel.pendingGiftConfirmation) { confirmation in
                TicketGiftConfirmationView(
                    confirmation: confirmation,
                    isWorking: viewModel.isWorking,
                    onConfirm: {
                        Task {
                            let trip = await viewModel.confirmGiftTodaySteps()
                            if let trip {
                                showGiftFlight()
                                withAnimation(.easeOut(duration: 0.22)) {
                                    travelModalTrip = trip
                                }
                            }
                        }
                    },
                    onCancel: {
                        viewModel.cancelGiftConfirmation()
                    }
                )
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            }
        }
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
                    Text(AppCopy.Cabin.ruleHint)
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
                        isWorking: viewModel.isWorking,
                        reduceMotion: reduceMotion
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task {
                            await viewModel.prepareGiftConfirmation()
                        }
                    }
                    .accessibilityLabel(canGiftTicket ? "赠送一张脚步机票" : "达到3000步后可赠送一张机票")
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

    private func showGiftFlight() {
        guard reduceMotion == false else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            isShowingGiftFlight = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.22)) {
                    isShowingGiftFlight = false
                }
            }
        }
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
        return environment.repository.currentCabinAnimal == nil
    }
}

private struct GiftTicketButton: View {
    var isAvailable: Bool
    var isWorking: Bool
    var reduceMotion: Bool
    var action: () -> Void
    @State private var isGlowing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isAvailable {
                    TicketEdgeStroke()
                        .opacity(reduceMotion ? 0.86 : (isGlowing ? 0.96 : 0.62))
                        .scaleEffect(reduceMotion ? 1 : (isGlowing ? 1.025 : 0.995))
                }

                ArtImage(name: "prop_ticket_single")
                    .frame(width: 164, height: 74)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
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
    }

    private func updateGlow() {
        isGlowing = false
        guard isAvailable, reduceMotion == false else { return }
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
        .shadow(color: AppTheme.ochre.opacity(0.48), radius: 8, x: 0, y: 0)
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
    var isWorking: Bool
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(alignment: .leading, spacing: 16) {
                Text(AppCopy.GiftConfirmation.subtitle)
                    .font(AppTheme.sheetDescription)
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    confirmationLine(iconName: "icon_ticket", text: AppCopy.GiftConfirmation.ticketLine(count: confirmation.ticketCount))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(14)
                .paperCard(cornerRadius: 18)

                Button(isWorking ? AppCopy.GiftConfirmation.workingButton : AppCopy.GiftConfirmation.confirmButton) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onConfirm()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isWorking)
            }
            .padding(20)
        }
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
}

private struct TravelStatusModal: View {
    let trip: Trip
    let animalName: String
    let routeMapAssetName: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 20) {
                TripStatusCard(
                    trip: trip,
                    animalName: animalName,
                    routeMapAssetName: routeMapAssetName,
                    isLarge: true
                )

                Button("知道了") {
                    onDismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
            .frame(maxWidth: 360)
            .frame(minHeight: 560)
            .paperCard(cornerRadius: 30, stroke: AppTheme.sage.opacity(0.42))
            .padding(.horizontal, 28)
        }
    }
}

private struct TripStatusCard: View {
    let trip: Trip
    let animalName: String
    let routeMapAssetName: String
    var isLarge = false

    var body: some View {
        if isLarge {
            largeLayout
        } else {
            compactLayout
        }
    }

    private var compactLayout: some View {
        HStack(spacing: isLarge ? 16 : 14) {
            ZStack {
                ArtImage(name: routeMapAssetName)
                    .frame(width: isLarge ? 170 : 132, height: isLarge ? 106 : 82)
                    .cornerRadius(16)

                ArtImage(name: "trip_marker_cat")
                    .frame(width: isLarge ? 52 : 42, height: isLarge ? 52 : 42)
                    .position(x: isLarge ? 92 : 72, y: isLarge ? 58 : 45)

                ArtImage(name: "prop_paper_plane")
                    .frame(width: isLarge ? 58 : 48, height: isLarge ? 40 : 34)
                    .rotationEffect(.degrees(-9))
                    .position(x: isLarge ? 134 : 105, y: isLarge ? 32 : 25)
            }
            .frame(width: isLarge ? 170 : 132, height: isLarge ? 106 : 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(AppCopy.Cabin.tripTitle(animalName: animalName, destination: trip.destination))
                    .font(.system(size: isLarge ? 22 : 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                Text(AppCopy.Cabin.tripReturnHint)
                    .font(isLarge ? AppTheme.body : AppTheme.caption)
                    .foregroundStyle(AppTheme.secondaryInk)

                Label {
                    Text(AppCopy.Cabin.tripStatus)
                } icon: {
                    ArtImage(name: "icon_ticket")
                        .frame(width: 14, height: 14)
                        .foregroundStyle(AppTheme.deepSage)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.deepSage)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .paperCard(cornerRadius: 20, stroke: AppTheme.sage.opacity(0.36))
    }

    private var largeLayout: some View {
        VStack(alignment: .center, spacing: 22) {
            ZStack {
                ArtImage(name: routeMapAssetName, cornerRadius: 18, showsShadow: true)
                    .frame(width: 268, height: 178)

                ArtImage(name: "trip_marker_cat")
                    .frame(width: 72, height: 72)
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

private struct GiftFlightOverlay: View {
    @State private var isFlying = false

    var body: some View {
        ZStack(alignment: .leading) {
            ArtImage(name: "ticket_flight_trail")
                .frame(maxWidth: .infinity)
                .frame(height: 86)
                .opacity(isFlying ? 0.9 : 0.1)

            ArtImage(name: "prop_paper_plane")
                .frame(width: 58, height: 42)
                .rotationEffect(.degrees(-10))
                .offset(x: isFlying ? 220 : 8, y: isFlying ? -28 : 26)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                isFlying = true
            }
        }
        .accessibilityHidden(true)
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
                            id: "wish_iceland_cat",
                            animalId: "cat",
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
                            animalId: "cat",
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
