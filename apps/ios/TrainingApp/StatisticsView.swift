import Charts
import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var auth: AuthSession
    @AppStorage("apiBaseURL") private var baseURL = "http://192.168.31.45:8181/api/v1/"
    @State private var statistics: VolumeStatisticsDTO?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    metrics
                    chart
                    exercises
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Progress")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            metric("VOLUME", value: statistics.map { String(format: "%.1f t", $0.totalVolumeKg / 1000) } ?? "—")
            metric("ACTIVE DAYS", value: statistics.map { "\($0.byDay.count)" } ?? "—")
            metric("SETS", value: statistics.map { "\($0.byExercise.reduce(0) { $0 + $1.completedSets })" } ?? "—")
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.title3.monospacedDigit().weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12).background(Color.trainingPanel, in: .rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1)) }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly volume").font(.headline)
            Chart(weeklyVolume, id: \.date) { item in
                BarMark(x: .value("Week", item.date, unit: .weekOfYear), y: .value("Volume", item.volume))
                    .foregroundStyle(item.date >= recentWeek ? Color.trainingLime : Color.gray.opacity(0.45))
            }
            .chartXAxis(.hidden).frame(height: 190)
        }
        .padding().background(Color.trainingPanel, in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1)) }
    }

    private var exercises: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Volume by exercise").font(.headline)
            ForEach(statistics?.byExercise.sorted { $0.totalVolumeKg > $1.totalVolumeKg } ?? []) { item in
                VStack(spacing: 5) {
                    HStack { Text(item.exerciseName); Spacer(); Text(item.totalVolumeKg, format: .number.precision(.fractionLength(0))) + Text(" kg") }
                    ProgressView(value: item.totalVolumeKg, total: maxExerciseVolume).tint(.trainingLime)
                }
            }
        }
        .padding().background(Color.trainingPanel, in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1)) }
    }

    private var maxExerciseVolume: Double { max(1, statistics?.byExercise.map(\.totalVolumeKg).max() ?? 1) }
    private var recentWeek: Date { Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now }
    private var weeklyVolume: [(date: Date, volume: Double)] {
        let calendar = Calendar.current
        return Dictionary(grouping: statistics?.byDay ?? []) { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start ?? $0.date }
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.totalVolumeKg }) }.sorted { $0.date < $1.date }
    }

    private func load() async {
        do {
            let from = Calendar.current.date(byAdding: .day, value: -84, to: .now) ?? .now
            statistics = try await auth.get("statistics/volume?from=\(from.ISO8601Format())&to=\(Date.now.ISO8601Format())&includeWarmups=false", baseURL: baseURL)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct VolumeStatisticsDTO: Decodable {
    let totalVolumeKg: Double
    let byExercise: [ExerciseVolumeDTO]
    let byDay: [DayVolumeDTO]
}

private struct ExerciseVolumeDTO: Decodable, Identifiable {
    let exerciseId: UUID
    let exerciseName: String
    let totalVolumeKg: Double
    let completedSets: Int
    var id: UUID { exerciseId }
}

private struct DayVolumeDTO: Decodable {
    let date: Date
    let totalVolumeKg: Double
}
