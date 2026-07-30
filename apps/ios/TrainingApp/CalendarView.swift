import SwiftData
import SwiftUI

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.scheduledAt) private var workouts: [Workout]
    @State private var displayedMonth = Date.now
    @State private var selectedDate = Date.now
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                monthHeader
                weekdayHeader
                monthGrid
                List {
                    Section(selectedDate.formatted(date: .long, time: .omitted)) {
                        if selectedWorkouts.isEmpty {
                            Text("Нет тренировок").foregroundStyle(.secondary)
                        }
                        ForEach(selectedWorkouts) { workout in
                            NavigationLink {
                                WorkoutView(workout: workout)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(workout.name)
                                    Text("Объём: \(workout.volumeKg.formatted(.number.precision(.fractionLength(0)))) кг")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding(.horizontal)
            .navigationTitle("Календарь")
            .toolbar {
                Button("Добавить", systemImage: "plus") { addWorkout() }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button("Предыдущий", systemImage: "chevron.left") { moveMonth(-1) }.labelStyle(.iconOnly)
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year())).font(.headline)
            Spacer()
            Button("Следующий", systemImage: "chevron.right") { moveMonth(1) }.labelStyle(.iconOnly)
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns) {
            ForEach(weekdaySymbols, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(monthDates.indices, id: \.self) { index in
                if let date = monthDates[index] {
                    Button { selectedDate = date } label: {
                        VStack(spacing: 3) {
                            Text(date, format: .dateTime.day())
                            Circle().frame(width: 5, height: 5).opacity(hasWorkout(on: date) ? 1 : 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.accentColor.opacity(0.2) : .clear)
                        .clipShape(.rect(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 38)
                }
            }
        }
    }

    private var columns: [GridItem] { Array(repeating: GridItem(.flexible()), count: 7) }
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let split = calendar.firstWeekday - 1
        return Array(symbols[split...] + symbols[..<split])
    }
    private var selectedWorkouts: [Workout] { workouts.filter { calendar.isDate($0.scheduledAt, inSameDayAs: selectedDate) } }

    private var monthDates: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
              let days = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + days.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }.map(Optional.some)
    }

    private func hasWorkout(on date: Date) -> Bool { workouts.contains { calendar.isDate($0.scheduledAt, inSameDayAs: date) } }
    private func moveMonth(_ value: Int) { displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth }
    private func addWorkout() { context.insert(Workout(name: "Тренировка", scheduledAt: selectedDate)) }
}

private extension Workout {
    var volumeKg: Double { exercises.reduce(0) { $0 + $1.completedVolumeKg } }
}
