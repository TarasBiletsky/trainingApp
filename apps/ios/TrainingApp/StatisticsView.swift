import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            List {
                Section("Всего") {
                    Text(totalVolume, format: .number.precision(.fractionLength(0))) + Text(" кг")
                }
                Section("По упражнениям") {
                    ForEach(volumeByExercise, id: \.name) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.volume, format: .number.precision(.fractionLength(0))) + Text(" кг")
                        }
                    }
                }
            }
            .navigationTitle("Объём")
        }
    }

    private var totalVolume: Double { volumeByExercise.reduce(0) { $0 + $1.volume } }

    private var volumeByExercise: [(name: String, volume: Double)] {
        var totals: [String: Double] = [:]
        for exercise in workouts.flatMap(\.exercises) {
            totals[exercise.name, default: 0] += exercise.completedVolumeKg
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.volume > $1.volume }
    }
}
