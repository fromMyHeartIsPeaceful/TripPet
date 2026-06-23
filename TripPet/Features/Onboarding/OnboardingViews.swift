import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var isPreparing = true

    var body: some View {
        Group {
            if isPreparing {
                LoadingStoryView()
            } else if environment.repository.userFlags.onboardingCompleted == false {
                OnboardingView(
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

struct OnboardingView: View {
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 28) {
                Spacer(minLength: 32)

                VStack(spacing: 14) {
                    Text(AppCopy.Onboarding.title)
                        .font(AppTheme.pageTitle)
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)

                    Text(AppCopy.Onboarding.body)
                        .font(AppTheme.sheetDescription)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(AppCopy.Onboarding.startButton) {
                    onFinished()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 28)
        }
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
        if environment.stepSnapshot.steps != nil {
            return AppCopy.Health.enterCabinButton
        }
        return status.canAttemptStepRead ? AppCopy.Health.retryReadButton : AppCopy.Health.connectTitle
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
        if environment.stepSnapshot.steps != nil {
            onFinished()
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            if status.canAttemptStepRead {
                _ = try await environment.readTodaySteps()
                refreshStatus()
                onFinished()
            } else {
                let didRequest = try await environment.requestStepAuthorizationAndRefresh()
                refreshStatus()
                if environment.stepSnapshot.steps != nil {
                    onFinished()
                } else if didRequest == false {
                    message = AppCopy.Health.requestUnchanged
                }
            }
        } catch {
            refreshStatus()
            message = status == .readPermissionRequested
                ? AppCopy.Health.settingsRequestFailed
                : error.localizedDescription
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
