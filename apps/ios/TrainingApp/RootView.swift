import SwiftData
import SwiftUI

extension Color {
    static let trainingLime = Color(red: 0.78, green: 1, blue: 0.18)
    static let trainingPanel = Color(red: 0.06, green: 0.075, blue: 0.085)
}

struct RootView: View {
    @EnvironmentObject private var auth: AuthSession
    @Environment(\.modelContext) private var context
    @AppStorage("apiBaseURL") private var baseURL = "http://192.168.31.45:8181/api/v1/"
    @State private var syncError: String?
    @Query(sort: \Workout.scheduledAt) private var workouts: [Workout]

    private var currentWorkout: Workout? {
        workouts.first { $0.status == .inProgress }
            ?? workouts.first { $0.status == .planned }
    }

    var body: some View {
        Group {
            if auth.isAuthenticated {
                workoutContent.task { await loadBootstrap() }
            } else {
                LoginView()
            }
        }
    }

    private var workoutContent: some View {
        TabView {
            NavigationStack {
                todayContent
            }
            .tabItem { Label("Сегодня", systemImage: "dumbbell") }

            CalendarView()
                .tabItem { Label("Календарь", systemImage: "calendar") }

            StatisticsView()
                .tabItem { Label("Объём", systemImage: "chart.bar") }
        }
        .toolbarBackground(Color.black, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    private var todayContent: some View {
        Group {
            Group {
                if let workout = currentWorkout {
                    WorkoutView(workout: workout)
                } else {
                    ContentUnavailableView {
                        Label("Нет тренировки", systemImage: "dumbbell")
                    } actions: {
                        Button("Создать тренировку") { createWorkout() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("LOG SESSION")
            .safeAreaInset(edge: .bottom) {
                if let syncError {
                    Text(syncError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(8)
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button("Новая", systemImage: "plus") { createWorkout() }
                    Button("Выйти", systemImage: "rectangle.portrait.and.arrow.right") { auth.logout() }
                }
            }
        }
    }

    private func createWorkout() {
        let workout = Workout(name: "Новая тренировка")
        let exercise = WorkoutExercise(name: "Жим лёжа", order: 0)
        exercise.sets = (0..<3).map { SetEntry(order: $0) }
        workout.exercises = [exercise]
        context.insert(workout)
    }

    private func loadBootstrap() async {
        do {
            let response = try await auth.bootstrap(baseURL: baseURL)
            try BootstrapImporter.importResponse(response, into: context)
            syncError = nil
        } catch {
            syncError = "Сервер недоступен — работаем офлайн"
        }
    }
}

private struct LoginView: View {
    @EnvironmentObject private var auth: AuthSession
    @AppStorage("apiBaseURL") private var baseURL = "http://192.168.31.45:8181/api/v1/"
    @State private var userName = "taras"
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Сервер") {
                    TextField("API URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                Section("Вход") {
                    TextField("Логин", text: $userName)
                        .textInputAutocapitalization(.never)
                    SecureField("Пароль", text: $password)
                    if let error = auth.errorMessage {
                        Text(error).foregroundStyle(.red)
                    }
                    Button("Войти") {
                        Task { await auth.login(baseURL: baseURL, userName: userName, password: password) }
                    }
                    .disabled(auth.isLoading || userName.isEmpty || password.isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Training")
        }
    }
}

struct WorkoutView: View {
    @Bindable var workout: Workout

    var body: some View {
        List {
            Section {
                TextField("Название", text: $workout.name)
                Button(workout.status == .inProgress ? "Завершить" : "Начать") {
                    if workout.status == .inProgress {
                        workout.status = .completed
                        workout.completedAt = .now
                    } else {
                        workout.status = .inProgress
                        workout.startedAt = .now
                    }
                    workout.updatedAt = .now
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 7))
            }

            ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { exercise in
                Section {
                    Toggle("Вес на одну гантель (×2)", isOn: Binding(
                        get: { exercise.weightMultiplier == 2 },
                        set: { exercise.weightMultiplier = $0 ? 2 : 1 }
                    ))
                    ForEach(exercise.sets.sorted(by: { $0.order < $1.order })) { set in
                        SetRow(set: set)
                    }
                    Button("Добавить подход", systemImage: "plus") {
                        exercise.sets.append(SetEntry(order: exercise.sets.count))
                    }
                } header: {
                    HStack {
                        Text(exercise.name)
                        Spacer()
                        Text(exercise.completedVolumeKg, format: .number.precision(.fractionLength(0)))
                            + Text(" кг")
                    }
                }
                .listRowBackground(Color.trainingPanel)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }
}

private struct SetRow: View {
    @Bindable var set: SetEntry

    var body: some View {
        HStack(spacing: 10) {
            Text("\(set.order + 1)").foregroundStyle(.secondary)
            TextField("кг", value: $set.actualWeightKg, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            Text("×")
            TextField("повт.", value: $set.actualReps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            Button {
                set.actualWeightKg = set.actualWeightKg ?? set.plannedWeightKg
                set.actualReps = set.actualReps ?? set.plannedReps
                set.status = .completed
                set.completedAt = .now
                set.updatedAt = .now
                set.needsSync = true
            } label: {
                Image(systemName: set.status == .completed ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(set.status == .completed ? Color.trainingLime : .secondary)
            }
            .accessibilityLabel("Завершить подход")
        }
    }
}
