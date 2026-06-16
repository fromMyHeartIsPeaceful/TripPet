import Foundation

enum StepCountAuthorizationStatus: Equatable {
    case unavailable
    case notDetermined
    case sharingDenied
    case sharingAuthorized
    /// HealthKit does not expose reliable read authorization status. This means
    /// the app has shown the system request before, not that reading is granted.
    case readPermissionRequested

    var canAttemptStepRead: Bool {
        self == .sharingAuthorized || self == .readPermissionRequested
    }
}

protocol StepCountProvider {
    var isHealthDataAvailable: Bool { get }
    func authorizationStatus() -> StepCountAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func todayStepCount() async throws -> Int
    func startObservingStepChanges(onChange: @escaping @MainActor @Sendable () async -> Void) throws
}

extension StepCountProvider {
    var isHealthDataAvailable: Bool {
        authorizationStatus() != .unavailable
    }

    func startObservingStepChanges(onChange: @escaping @MainActor @Sendable () async -> Void) throws {}
}

final class FakeStepCountProvider: StepCountProvider {
    var status: StepCountAuthorizationStatus
    var steps: Int
    var requestSucceeds: Bool
    var throwsOnStepRead: Bool

    init(
        status: StepCountAuthorizationStatus = .sharingAuthorized,
        steps: Int = 4_200,
        requestSucceeds: Bool = true,
        throwsOnStepRead: Bool = false
    ) {
        self.status = status
        self.steps = steps
        self.requestSucceeds = requestSucceeds
        self.throwsOnStepRead = throwsOnStepRead
    }

    func authorizationStatus() -> StepCountAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        if requestSucceeds {
            status = .sharingAuthorized
        }
        return requestSucceeds
    }

    func todayStepCount() async throws -> Int {
        if throwsOnStepRead {
            throw StepCountProviderError.unableToReadSteps
        }
        return max(0, steps)
    }
}

enum StepCountProviderError: LocalizedError {
    case unavailable
    case missingStepType
    case authorizationDenied
    case unableToReadSteps

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "这台设备暂时不能读取 Health 步数。"
        case .missingStepType:
            "无法读取 Apple 健康的步数字段。"
        case .authorizationDenied:
            "尚未获得 Apple 健康步数读取权限。"
        case .unableToReadSteps:
            "暂时没有读到今天的脚步。可以稍后再试，或在设置里检查 Health 权限。"
        }
    }
}
