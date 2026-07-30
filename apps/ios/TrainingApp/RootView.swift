import SwiftData
import SwiftUI

extension Color {
    static var trainingLime: Color { trainingAccent(UserDefaults.standard.string(forKey: "colorTheme") ?? "purple") }
    static let trainingPanel = Color(red: 0.06, green: 0.075, blue: 0.085)
    static func trainingAccent(_ theme: String) -> Color {
        switch theme {
        case "toxic": Color(red: 0.84, green: 1, blue: 0.24)
        case "red": Color(red: 1, green: 0.29, blue: 0.24)
        default: Color(red: 0.71, green: 0.61, blue: 1)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var auth: AuthSession
    @Environment(\.modelContext) private var context
    @AppStorage("apiBaseURL") private var baseURL = "http://192.168.31.45:8181/api/v1/"
    @State private var syncError: String?
    @State private var exerciseOptions: [ExerciseDTO] = []
    @AppStorage("colorTheme") private var colorTheme = "purple"
    @Query(sort: \Workout.scheduledAt) private var workouts: [Workout]

    private var currentWorkout: Workout? {
        workouts.first { $0.status == .inProgress }
            ?? workouts.first { $0.status == .planned && Calendar.current.isDateInToday($0.scheduledAt) }
            ?? workouts.first { $0.status == .completed && Calendar.current.isDateInToday($0.scheduledAt) }
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

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
        .tint(Color.trainingAccent(colorTheme))
        .toolbarBackground(Color.black, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    private var todayContent: some View {
        Group {
            Group {
                if let workout = currentWorkout {
                    WorkoutView(workout: workout, exerciseOptions: exerciseOptions)
                } else {
                    ContentUnavailableView {
                        Label("Нет тренировки", systemImage: "dumbbell")
                    } actions: {
                        Button("Создать тренировку") { Task { await createWorkout() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(currentWorkout == nil ? "СЕГОДНЯ" : "LOG SESSION")
            .navigationBarTitleDisplayMode(.inline)
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
                    Button("Новая", systemImage: "plus") { Task { await createWorkout() } }
                    Button("Выйти", systemImage: "rectangle.portrait.and.arrow.right") { auth.logout() }
                }
            }
        }
    }

    private func createWorkout() async {
        do {
            try await auth.send("workouts/", method: "POST", body: WorkoutWriteBody(name: "Новая тренировка", scheduledAt: .now, notes: nil, version: nil), baseURL: baseURL)
            await loadBootstrap()
        } catch { syncError = error.localizedDescription }
    }

    private func loadBootstrap() async {
        do {
            let response = try await auth.bootstrap(baseURL: baseURL)
            let user: UserProfileDTO = try await auth.get("users/me", baseURL: baseURL)
            colorTheme = user.colorTheme
            exerciseOptions = response.exercises.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            try BootstrapImporter.importResponse(response, into: context)
            syncError = nil
        } catch {
            syncError = "Сервер недоступен — работаем офлайн"
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var auth: AuthSession
    @AppStorage("apiBaseURL") private var baseURL = "http://192.168.31.45:8181/api/v1/"
    @AppStorage("colorTheme") private var colorTheme = "purple"
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Accent color") {
                    theme("Purple", value: "purple", color: Color(red: 0.71, green: 0.61, blue: 1))
                    theme("Toxic yellow", value: "toxic", color: Color(red: 0.84, green: 1, blue: 0.24))
                    theme("Red", value: "red", color: Color(red: 1, green: 0.29, blue: 0.24))
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .scrollContentBackground(.hidden).background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func theme(_ title: String, value: String, color: Color) -> some View {
        Button {
            colorTheme = value
            Task { await save(value) }
        } label: {
            HStack {
                RoundedRectangle(cornerRadius: 6).fill(color).frame(width: 24, height: 24)
                Text(title).foregroundStyle(.primary)
                Spacer()
                if colorTheme == value { Image(systemName: "checkmark").foregroundStyle(color) }
            }
        }
    }

    private func save(_ value: String) async {
        do {
            try await auth.send("users/me/preferences", method: "PUT", body: UserPreferencesBody(colorTheme: value), baseURL: baseURL)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct UserProfileDTO: Decodable { let colorTheme: String }
private struct UserPreferencesBody: Encodable { let colorTheme: String }

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
                        .textContentType(.username)
                        .autocorrectionDisabled()
                    SecureField("Пароль", text: $password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit {
                            Task { await auth.login(baseURL: baseURL, userName: userName, password: password) }
                        }
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
    @EnvironmentObject private var auth: AuthSession
    @Environment(\.modelContext) private var context
    @AppStorage("apiBaseURL") private var baseURL = "http://192.168.31.45:8181/api/v1/"
    @Bindable var workout: Workout
    var exerciseOptions: [ExerciseDTO] = []
    @State private var fetchedExerciseOptions: [ExerciseDTO] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                TextField("Workout name", text: $workout.name)
                    .submitLabel(.done)
                    .onSubmit { Task { await saveWorkout() } }
            }

            ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { exercise in
                Section {
                    Toggle("Weight entered per dumbbell (×2)", isOn: Binding(
                        get: { exercise.weightMultiplier == 2 },
                        set: { value in Task { await updateExercise(exercise, multiplier: value ? 2 : 1) } }
                    ))
                    ForEach(exercise.sets.sorted(by: { $0.order < $1.order })) { set in
                        SetRow(set: set,
                               onComplete: { await toggleSet(set) })
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) { Task { await removeSet(set) } }
                            }
                    }
                    HStack {
                        Button("Add set", systemImage: "plus") { Task { await addSet(to: exercise) } }
                        Spacer()
                        Button("Remove exercise", systemImage: "trash", role: .destructive) { Task { await removeExercise(exercise) } }
                    }
                } header: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Menu(exercise.name) {
                                ForEach(availableExerciseOptions) { option in
                                    Button(option.name) { Task { await replace(exercise, with: option) } }
                                }
                            }
                            .foregroundStyle(Color.trainingLime)
                            Text("\(exercise.sets.count) sets · \(exercise.restSeconds)s rest")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(exercise.completedVolumeKg, format: .number.precision(.fractionLength(0))) + Text(" kg")
                    }
                }
                .listRowBackground(Color.trainingPanel)
            }

            Menu("Add exercise", systemImage: "plus") {
                ForEach(availableExerciseOptions) { option in
                    Button(option.name) { Task { await addExercise(option) } }
                }
            }

            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .refreshable { await refresh() }
        .task { await loadExerciseOptions() }
    }

    private var availableExerciseOptions: [ExerciseDTO] {
        exerciseOptions.isEmpty ? fetchedExerciseOptions : exerciseOptions
    }

    private func loadExerciseOptions() async {
        guard exerciseOptions.isEmpty, fetchedExerciseOptions.isEmpty else { return }
        do { fetchedExerciseOptions = try await auth.get("exercises/", baseURL: baseURL) }
        catch { errorMessage = error.localizedDescription }
    }

    private func saveWorkout() async {
        await perform {
            try await auth.send("workouts/\(workout.id)", method: "PUT",
                                body: WorkoutWriteBody(name: workout.name, scheduledAt: workout.scheduledAt,
                                                       notes: workout.notes, version: workout.version), baseURL: baseURL)
        }
    }

    private func replace(_ exercise: WorkoutExercise, with option: ExerciseDTO) async {
        await perform {
            try await auth.send("workouts/\(workout.id)/exercises/\(exercise.id)", method: "PUT",
                                body: ExerciseWriteBody(exerciseId: option.id, order: exercise.order, notes: exercise.notes,
                                                        restSeconds: exercise.restSeconds, weightMultiplier: exercise.weightMultiplier),
                                baseURL: baseURL)
        }
    }

    private func updateExercise(_ exercise: WorkoutExercise, multiplier: Int) async {
        guard let exerciseId = exercise.exerciseId else { return }
        await perform {
            try await auth.send("workouts/\(workout.id)/exercises/\(exercise.id)", method: "PUT",
                                body: ExerciseWriteBody(exerciseId: exerciseId, order: exercise.order, notes: exercise.notes,
                                                        restSeconds: exercise.restSeconds, weightMultiplier: multiplier),
                                baseURL: baseURL)
        }
    }

    private func addExercise(_ option: ExerciseDTO) async {
        await perform {
            try await auth.send("workouts/\(workout.id)/exercises", method: "POST",
                                body: ExerciseWriteBody(exerciseId: option.id, order: workout.exercises.count, notes: "", restSeconds: 90, weightMultiplier: 1), baseURL: baseURL)
        }
    }

    private func removeExercise(_ exercise: WorkoutExercise) async {
        await perform {
            try await auth.send("workouts/\(workout.id)/exercises/\(exercise.id)", method: "DELETE", baseURL: baseURL)
        }
    }

    private func addSet(to exercise: WorkoutExercise) async {
        let previous = exercise.sets.max(by: { $0.order < $1.order })
        let body = SetWriteBody(order: (previous?.order ?? -1) + 1,
                                plannedWeightKg: previous?.actualWeightKg ?? previous?.plannedWeightKg,
                                plannedReps: previous?.actualReps ?? previous?.plannedReps,
                                actualWeightKg: nil, actualReps: nil, isWarmup: false, version: nil, completedAt: nil)
        await perform {
            try await auth.send("workouts/\(workout.id)/exercises/\(exercise.id)/sets", method: "POST", body: body, baseURL: baseURL)
        }
    }

    private func removeSet(_ set: SetEntry) async {
        await perform {
            try await auth.send("workouts/\(workout.id)/sets/\(set.id)", method: "DELETE", baseURL: baseURL)
        }
    }

    private func toggleSet(_ set: SetEntry) async {
        let completed = set.status == .completed
        if !completed {
            set.actualWeightKg = set.actualWeightKg ?? set.plannedWeightKg
            set.actualReps = set.actualReps ?? set.plannedReps
        }
        let body = SetWriteBody(order: set.order, plannedWeightKg: set.plannedWeightKg, plannedReps: set.plannedReps,
                                actualWeightKg: set.actualWeightKg, actualReps: set.actualReps, isWarmup: set.isWarmup,
                                version: set.version, completedAt: completed ? nil : .now)
        await perform {
            let action = completed ? "uncomplete" : "complete"
            try await auth.send("workouts/\(workout.id)/sets/\(set.id)/\(action)", method: "POST", body: body, baseURL: baseURL)
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        do { try await operation(); await refresh() }
        catch { errorMessage = error.localizedDescription }
    }

    private func refresh() async {
        do {
            if availableExerciseOptions.isEmpty { await loadExerciseOptions() }
            let remote: WorkoutDTO = try await auth.get("workouts/\(workout.id)", baseURL: baseURL)
            let response = BootstrapResponse(workout: remote, exercises: availableExerciseOptions, lastHealthSyncAt: nil)
            try BootstrapImporter.importResponse(response, into: context)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct SetRow: View {
    @Bindable var set: SetEntry
    let onComplete: () async -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text("\(set.order + 1)")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 18)
            compactField("KG", value: Binding(
                get: { set.actualWeightKg ?? set.plannedWeightKg },
                set: { set.actualWeightKg = $0 }
            ), keyboard: .decimalPad)
            compactField("REPS", value: Binding(
                get: { set.actualReps ?? set.plannedReps },
                set: { set.actualReps = $0 }
            ), keyboard: .numberPad)
            Button("Complete set", systemImage: set.status == .completed ? "checkmark.square.fill" : "square") {
                Task { await onComplete() }
            }
            .labelStyle(.iconOnly)
            .font(.title2)
            .foregroundStyle(set.status == .completed ? Color.trainingLime : .secondary)
            .frame(width: 34, height: 44)
        }
    }

    private func compactField(_ label: String, value: Binding<Int?>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            TextField("—", value: value, format: .number)
                .keyboardType(keyboard).multilineTextAlignment(.center)
                .padding(.horizontal, 8).frame(minHeight: 38)
                .background(Color.black.opacity(0.45), in: .rect(cornerRadius: 6))
        }
        .frame(maxWidth: .infinity)
    }

    private func compactField(_ label: String, value: Binding<Double?>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            TextField("—", value: value, format: .number)
                .keyboardType(keyboard).multilineTextAlignment(.center)
                .padding(.horizontal, 8).frame(minHeight: 38)
                .background(Color.black.opacity(0.45), in: .rect(cornerRadius: 6))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WorkoutWriteBody: Encodable {
    let name: String
    let scheduledAt: Date
    let notes: String?
    let version: Int?
}

private struct ExerciseWriteBody: Encodable {
    let exerciseId: UUID
    let order: Int
    let notes: String
    let restSeconds: Int
    let weightMultiplier: Int
}

private struct SetWriteBody: Encodable {
    let order: Int
    let plannedWeightKg: Double?
    let plannedReps: Int?
    let actualWeightKg: Double?
    let actualReps: Int?
    let isWarmup: Bool
    let version: Int?
    let completedAt: Date?
}
