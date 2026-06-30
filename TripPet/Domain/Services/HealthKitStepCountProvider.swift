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
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    func authorizationStatus() -> StepCountAuthorizationStatus {
        #if canImport(HealthKit)
        guard isHealthDataAvailable,
              HKObjectType.quantityType(forIdentifier: .stepCount) != nil else {
            healthDebugLog("authorizationStatus unavailable healthDataAvailable=\(isHealthDataAvailable)")
            return .unavailable
        }

        if UserDefaults.standard.bool(forKey: Self.readPermissionRequestedKey) {
            healthDebugLog("authorizationStatus readPermissionRequested")
            return .readPermissionRequested
        }

        healthDebugLog("authorizationStatus notDetermined")
        return .notDetermined
        #else
        healthDebugLog("authorizationStatus unavailable no HealthKit import")
        return .unavailable
        #endif
    }

    func requestAuthorization() async throws -> Bool {
        #if canImport(HealthKit)
        guard isHealthDataAvailable else {
            throw StepCountProviderError.unavailable
        }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw StepCountProviderError.missingStepType
        }

        healthDebugLog("requestAuthorization start")
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
                if let error {
                    healthDebugLog("requestAuthorization error=\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    if success {
                        UserDefaults.standard.set(true, forKey: Self.readPermissionRequestedKey)
                    }
                    healthDebugLog("requestAuthorization success=\(success)")
                    continuation.resume(returning: success)
                }
            }
        }
        #else
        throw StepCountProviderError.unavailable
        #endif
    }

    func todayStepCount() async throws -> Int {
        #if canImport(HealthKit)
        guard isHealthDataAvailable else {
            throw StepCountProviderError.unavailable
        }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw StepCountProviderError.missingStepType
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        healthDebugLog("todayStepCount query startOfDay=\(startOfDay) end=\(endDate)")

        let strictResult = try await statisticsStepCount(
            stepType: stepType,
            startOfDay: startOfDay,
            endDate: endDate,
            predicateOptions: .strictStartDate,
            label: "strict"
        )
        if case .steps(let steps) = strictResult {
            return steps
        }

        let overlapResult = try await statisticsStepCount(
            stepType: stepType,
            startOfDay: startOfDay,
            endDate: endDate,
            predicateOptions: [],
            label: "overlap"
        )
        if case .steps(let steps) = overlapResult {
            return steps
        }

        let sampleResult = try await sampleStepCount(stepType: stepType, startOfDay: startOfDay, endDate: endDate)
        return Self.resolvedStepCount(from: [strictResult, overlapResult, sampleResult])
        #else
        throw StepCountProviderError.unavailable
        #endif
    }

    func startObservingStepChanges(onChange: @escaping @MainActor @Sendable () async -> Void) throws {
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
    }

    #if canImport(HealthKit)
    private func statisticsStepCount(
        stepType: HKQuantityType,
        startOfDay: Date,
        endDate: Date,
        predicateOptions: HKQueryOptions,
        label: String
    ) async throws -> HealthKitStepQueryResult {
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endDate,
            options: predicateOptions
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    if let noDataResult = Self.noDataQueryResultIfApplicable(for: error) {
                        healthDebugLog("todayStepCount \(label) statistics no data error=\(Self.errorSummary(error))")
                        continuation.resume(returning: noDataResult)
                        return
                    }

                    healthDebugLog("todayStepCount \(label) statistics error=\(Self.errorSummary(error))")
                    continuation.resume(throwing: StepCountProviderError.unableToReadSteps)
                    return
                }

                guard let quantity = result?.sumQuantity() else {
                    healthDebugLog("todayStepCount \(label) statistics nil sumQuantity")
                    continuation.resume(returning: .noData)
                    return
                }

                let steps = quantity.doubleValue(for: HKUnit.count())
                let normalizedSteps = Self.normalizedStepCount(steps)
                healthDebugLog("todayStepCount \(label) statistics raw=\(steps) rounded=\(normalizedSteps)")
                continuation.resume(returning: .steps(normalizedSteps))
            }

            healthStore.execute(query)
        }
    }

    private func sampleStepCount(
        stepType: HKQuantityType,
        startOfDay: Date,
        endDate: Date
    ) async throws -> HealthKitStepQueryResult {
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endDate,
            options: []
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    if let noDataResult = Self.noDataQueryResultIfApplicable(for: error) {
                        healthDebugLog("todayStepCount sample query no data error=\(Self.errorSummary(error))")
                        continuation.resume(returning: noDataResult)
                        return
                    }

                    healthDebugLog("todayStepCount sample query error=\(Self.errorSummary(error))")
                    continuation.resume(throwing: StepCountProviderError.unableToReadSteps)
                    return
                }

                let quantitySamples = samples as? [HKQuantitySample] ?? []
                guard quantitySamples.isEmpty == false else {
                    healthDebugLog("todayStepCount sample query no samples")
                    continuation.resume(returning: .noData)
                    return
                }

                let steps = quantitySamples.reduce(0.0) { partialResult, sample in
                    partialResult + sample.quantity.doubleValue(for: HKUnit.count())
                }
                let normalizedSteps = Self.normalizedStepCount(steps)
                healthDebugLog("todayStepCount sample query count=\(quantitySamples.count) raw=\(steps) rounded=\(normalizedSteps)")
                continuation.resume(returning: .steps(normalizedSteps))
            }

            healthStore.execute(query)
        }
    }
    #endif

    static func normalizedStepCount(_ steps: Double) -> Int {
        max(0, Int(steps.rounded(.down)))
    }

    static func resolvedStepCount(from results: [HealthKitStepQueryResult]) -> Int {
        for result in results {
            if case .steps(let steps) = result {
                return steps
            }
        }
        return 0
    }

    #if canImport(HealthKit)
    static func noDataQueryResultIfApplicable(for error: Error) -> HealthKitStepQueryResult? {
        let nsError = error as NSError
        guard nsError.domain == HKErrorDomain,
              nsError.code == HKError.Code.errorNoData.rawValue else {
            return nil
        }

        return .noData
    }

    private static func errorSummary(_ error: Error) -> String {
        let nsError = error as NSError
        return "domain=\(nsError.domain) code=\(nsError.code) message=\(nsError.localizedDescription)"
    }
    #endif
}

enum HealthKitStepQueryResult: Equatable {
    case steps(Int)
    case noData
}
