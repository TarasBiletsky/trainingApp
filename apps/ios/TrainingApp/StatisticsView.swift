import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            List {
                Section("Последние 12 недель") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ОБЪЁМ").font(.caption2).foregroundStyle(.secondary)
                            Text(totalVolume, format: .number.precision(.fractionLength(0))) + Text(" кг")
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("СЕССИИ").font(.caption2).foregroundStyle(.secondary)
                            Text("\(completedWorkouts)")
                        }
                    }
                    .font(.title2.monospacedDigit().weight(.semibold))
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
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Progress")
        }
    }

    private var totalVolume: Double { volumeByExercise.reduce(0) { $0 + $1.volume } }
    private var completedWorkouts: Int { workouts.filter { $0.status == .completed }.count }

    private var volumeByExercise: [(name: String, volume: Double)] {
        var totals: [String: Double] = [:]
        for exercise in workouts.flatMap(\.exercises) {
            totals[exercise.name, default: 0] += exercise.completedVolumeKg
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.volume > $1.volume }
    }
}
