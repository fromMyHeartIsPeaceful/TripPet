import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

final class HealthKitStepCountProvider: StepCountProvider {
    private static let readPermissionRequestedKey = "TripPet.healthKitStepReadPermissionRequested"

    #if canImport(HealthKit)
    private let healthStore = HKHealthStore()
    private var stepObserverQuery: HKObserverQuery?
    #endif

    var isHealthDataAvailable: Bool {
        #if DEBUG && targetEnvironment(simulator)
        return true
        #else
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
        #endif
    }

    func authorizationStatus() -> StepCountAuthorizationStatus {
        #if DEBUG && targetEnvironment(simulator)
        return UserDefaults.standard.bool(forKey: Self.readPermissionRequestedKey)
            ? .readPermissionRequested
            : .notDetermined
        #else
        #if canImport(HealthKit)
        guard isHealthDataAvailable,
              HKObjectType.quantityType(forIdentifier: .stepCount) != nil else {
            return .unavailable
        }

        if UserDefaults.standard.bool(forKey: Self.readPermissionRequestedKey) {
            return .readPermissionRequested
        }

        return .notDetermined
        #else
        return .unavailable
        #endif
        #endif
    }

    func requestAuthorization() async throws -> Bool {
        #if DEBUG && targetEnvironment(simulator)
        UserDefaults.standard.set(true, forKey: Self.readPermissionRequestedKey)
        return true
        #else
        #if canImport(HealthKit)
        guard isHealthDataAvailable else {
            throw StepCountProviderError.unavailable
        }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw StepCountProviderError.missingStepType
        }

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    if success {
                        UserDefaults.standard.set(true, forKey: Self.readPermissionRequestedKey)
                    }
                    continuation.resume(returning: success)
                }
            }
        }
        #else
        throw StepCountProviderError.unavailable
        #endif
        #endif
    }

    func todayStepCount() async throws -> Int {
        #if DEBUG && targetEnvironment(simulator)
        return 0
        #else
        #if canImport(HealthKit)
        guard isHealthDataAvailable else {
            throw StepCountProviderError.unavailable
        }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw StepCountProviderError.missingStepType
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if error != nil {
                    continuation.resume(throwing: StepCountProviderError.unableToReadSteps)
                    return
                }

                let steps = result?
                    .sumQuantity()?
                    .doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: max(0, Int(steps.rounded(.down))))
            }

            healthStore.execute(query)
        }
        #else
        throw StepCountProviderError.unavailable
        #endif
        #endif
    }

    func startObservingStepChanges(onChange: @escaping @MainActor @Sendable () async -> Void) throws {
        #if DEBUG && targetEnvironment(simulator)
        return
        #else
        #if canImport(HealthKit)
        guard isHealthDataAvailable else {
            throw StepCountProviderError.unavailable
        }
        guard stepObserverQuery == nil else { return }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw StepCountProviderError.missingStepType
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completionHandler, error in
            completionHandler()

            if error == nil {
                Task { @MainActor in
                    await onChange()
                }
            }
        }

        stepObserverQuery = query
        healthStore.execute(query)
        #else
        throw StepCountProviderError.unavailable
        #endif
        #endif
    }
}
