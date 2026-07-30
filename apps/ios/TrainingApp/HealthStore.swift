import Foundation
import HealthKit

@MainActor
final class HealthStore: ObservableObject {
    private let store = HKHealthStore()

    func requestReadAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let identifiers: [HKQuantityTypeIdentifier] = [
            .bodyMass, .stepCount, .activeEnergyBurned, .basalEnergyBurned,
            .heartRate, .restingHeartRate
        ]
        let types = Set(identifiers.compactMap(HKObjectType.quantityType(forIdentifier:)))
        try await store.requestAuthorization(toShare: [], read: types)
    }
}
