import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var isPreparing = true

    var body: some View {
        Group {
            if isPreparing {
                LoadingStoryView()
            } else if environment.repository.userFlags.onboardingCompleted == false {
                ComicStoryView(
                    onFinished: {
                        environment.repository.completeOnboarding()
                    }
                )
            } else if environment.repository.userFlags.healthGuideDismissed == false {
                HealthConnectView(
                    onFinished: {
                        environment.repository.dismissHealthGuide()
                    }
                )
            } else {
                RootTabView()
                    .task {
                        environment.revealEligiblePostcards()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: environment.repository.userFlags)
        .task {
            await environment.refreshStepsIfPossible()
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            isPreparing = false
        }
    }
}

struct LoadingStoryView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.paperWhite
                    .ignoresSafeArea()

                ArtImage(name: "launch_story_poster", contentMode: .fill)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                    )
                    .clipped()
                    .ignoresSafeArea()
            }
            .accessibilityLabel("步履小屋启动图，小屋前有准备旅行的小动物")
            .ignoresSafeArea()
        }
    }
}

struct ComicStoryView: View {
    private static let imageNames = (1...11).map { String(format: "story_comic_%02d", $0) }
    private static let arrowInitialOpacity = 0.06
    private static let timingDelay: UInt64 = 2_500_000_000
    private static let fadeDuration = 2.5

    @State private var currentIndex = 0
    @State private var arrowOpacity = arrowInitialOpacity
    @State private var isArrowEnabled = false

    var onFinished: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.paperWhite
                    .ignoresSafeArea()

                ArtImage(name: Self.imageNames[currentIndex], contentMode: .fill)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
                        alignment: storyImageAlignment
                    )
                    .clipped()
                    .ignoresSafeArea()
                    .id(currentIndex)
                    .transition(.opacity)

                HStack {
                    Spacer()

                    Button {
                        advanceStory()
                    } label: {
                        ComicNextArrow()
                    }
                    .buttonStyle(.plain)
                    .disabled(isArrowEnabled == false)
                    .opacity(arrowOpacity)
                    .accessibilityLabel(currentIndex == Self.imageNames.count - 1 ? "进入健康授权" : "下一张剧情")
                    .accessibilityHint("继续步履小屋的启动剧情")
                }
                .padding(.trailing, max(18, proxy.safeAreaInsets.trailing + 14))
                .padding(.top, proxy.safeAreaInsets.top + 24)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.24), value: currentIndex)
        .task(id: currentIndex) {
            await revealArrowAfterDelay()
        }
    }

    private func advanceStory() {
        guard isArrowEnabled else { return }

        if currentIndex == Self.imageNames.count - 1 {
            onFinished()
        } else {
            currentIndex += 1
        }
    }

    private var storyImageAlignment: Alignment {
        currentIndex == 5 ? .trailing : .center
    }

    @MainActor
    private func revealArrowAfterDelay() async {
        arrowOpacity = Self.arrowInitialOpacity
        isArrowEnabled = false

        try? await Task.sleep(nanoseconds: Self.timingDelay)
        guard Task.isCancelled == false else { return }

        withAnimation(.easeInOut(duration: Self.fadeDuration)) {
            arrowOpacity = 1
        }

        try? await Task.sleep(nanoseconds: Self.timingDelay)
        guard Task.isCancelled == false else { return }
        isArrowEnabled = true
    }
}

private struct ComicNextArrow: View {
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .frame(width: 58, height: 74)
            .background {
                Capsule(style: .continuous)
                    .fill(Color(red: 0.98, green: 0.82, blue: 0.42))
                    .overlay {
                        Capsule(style: .continuous)
                            .fill(AppTheme.paperWhite.opacity(0.28))
                            .padding(7)
                            .offset(x: -6, y: -10)
                    }
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(AppTheme.ink.opacity(0.82), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(isEnabled ? 0.24 : 0.1), radius: 10, x: 0, y: 5)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(AppTheme.peach)
                    .frame(width: 13, height: 13)
                    .overlay {
                        Circle()
                            .stroke(AppTheme.ink.opacity(0.58), lineWidth: 1)
                    }
                    .offset(x: 1, y: 1)
            }
            .scaleEffect(isEnabled ? 1 : 0.96)
            .contentShape(Capsule(style: .continuous))
    }
}

struct HealthConnectView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var status: StepCountAuthorizationStatus = .notDetermined
    @State private var message = AppCopy.Health.connectIntro
    @State private var isWorking = false

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 22) {
                Spacer(minLength: 14)

                ArtImage(name: "health_steps_ticket_cutout")
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .accessibilityLabel("脚步连接机票的插画")

                VStack(spacing: 12) {
                    Text(AppCopy.Health.connectTitle)
                        .font(AppTheme.pageTitle)
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)

                    HealthPermissionMessage(status: status, message: message)
                }

                VStack(spacing: 24) {
                    Button(primaryTitle) {
                        Task { await connectHealth() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isWorking || status == .unavailable)

                    Button(AppCopy.Health.laterButton) {
                        onFinished()
                    }
                    .buttonStyle(OutlineButtonStyle())
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 24)
        }
        .task {
            await environment.refreshStepsIfPossible()
            refreshStatus()
        }
        .onChange(of: environment.stepSnapshot) { _, _ in
            refreshStatus()
        }
    }

    private var primaryTitle: String {
        if isWorking {
            return AppCopy.Health.connectingButton
        }
        return status.canAttemptStepRead ? AppCopy.Health.enterCabinButton : AppCopy.Health.connectTitle
    }

    private func refreshStatus() {
        status = environment.stepSnapshot.status
        switch status {
        case .unavailable:
            message = AppCopy.Health.unavailable
        case .notDetermined:
            message = AppCopy.Health.connectIntro
        case .sharingDenied:
            message = AppCopy.Health.denied
        case .sharingAuthorized:
            if let steps = environment.stepSnapshot.steps {
                message = AppCopy.Health.todayStepsRead(steps)
            } else {
                message = AppCopy.Health.authorized
            }
        case .readPermissionRequested:
            if let steps = environment.stepSnapshot.steps {
                message = AppCopy.Health.todayStepsRead(steps)
            } else {
                message = AppCopy.Health.readPermissionRequested
            }
        }
    }

    private func connectHealth() async {
        if status.canAttemptStepRead {
            onFinished()
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let didRequest = try await environment.requestStepAuthorizationAndRefresh()
            refreshStatus()
            if status.canAttemptStepRead {
                onFinished()
            } else if didRequest == false {
                message = AppCopy.Health.requestUnchanged
            }
        } catch {
            refreshStatus()
            message = error.localizedDescription
        }
    }
}

private struct HealthPermissionMessage: View {
    let status: StepCountAuthorizationStatus
    let message: String

    var body: some View {
        if status == .notDetermined {
            VStack(alignment: .leading, spacing: 12) {
                permissionLine(iconName: "icon_health", text: AppCopy.Health.connectIntro)
                permissionLine(iconName: "icon_ticket", text: AppCopy.Health.localOnly)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(message)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func permissionLine(iconName: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ArtImage(name: iconName)
                .frame(width: 18, height: 18)
                .foregroundStyle(AppTheme.deepSage)
                .padding(.top, 2)

            Text(text)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Health Connect") {
    HealthConnectView {}
        .environmentObject(
            AppEnvironment.preview(
                flags: AppUserFlags(onboardingCompleted: true, healthGuideDismissed: false),
                stepStatus: .notDetermined
            )
        )
}
