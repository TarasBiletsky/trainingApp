import SwiftData
import SwiftUI

extension Color {
    static let trainingLime = Color(red: 0.84, green: 1, blue: 0.24)
    static let trainingPanel = Color(red: 0.06, green: 0.075, blue: 0.085)
}

struct RootView: View {
    @EnvironmentObject private var auth: AuthSession
    @Environment(\.modelContext) private var context
    @AppStorage("apiBaseURL") private var baseURL = "http://192.168.31.45:8181/api/v1/"
    @State private var syncError: String?
    @State private var exerciseOptions: [ExerciseDTO] = []
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
                    WorkoutView(workout: workout, exerciseOptions: exerciseOptions)
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
            exerciseOptions = response.exercises.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                TextField("Workout name", text: $workout.name)
                Button {
                    Task { await changeWorkoutStatus() }
                } label: {
                    Text(workout.status == .inProgress ? "Complete workout" : "Start workout")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 7))
                .tint(.trainingLime)
                .foregroundStyle(.black)
            }

            ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { exercise in
                Section {
                    Toggle("Weight entered per dumbbell (×2)", isOn: Binding(
                        get: { exercise.weightMultiplier == 2 },
                        set: { value in Task { await updateExercise(exercise, multiplier: value ? 2 : 1) } }
                    ))
                    ForEach(exercise.sets.sorted(by: { $0.order < $1.order })) { set in
                        SetRow(set: set,
                               onSave: { await saveSet(set) },
                               onComplete: { await completeSet(set) })
                    }
                    HStack {
                        Button("Remove set", systemImage: "minus") { Task { await removeLastSet(from: exercise) } }
                            .disabled(!exercise.sets.contains { $0.status != .completed })
                        Spacer()
                        Text("\(exercise.sets.count) sets").foregroundStyle(.secondary)
                        Spacer()
                        Button("Add set", systemImage: "plus") { Task { await addSet(to: exercise) } }
                    }
                } header: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Menu(exercise.name) {
                                ForEach(exerciseOptions) { option in
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

            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .refreshable { await refresh() }
    }

    private func changeWorkoutStatus() async {
        await perform {
            let action = workout.status == .inProgress ? "complete" : "start"
            try await auth.send("workouts/\(workout.id)/\(action)", method: "POST", baseURL: baseURL)
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

    private func removeLastSet(from exercise: WorkoutExercise) async {
        guard let set = exercise.sets.filter({ $0.status != .completed }).max(by: { $0.order < $1.order }) else { return }
        await perform {
            try await auth.send("workouts/\(workout.id)/sets/\(set.id)", method: "DELETE", baseURL: baseURL)
            context.delete(set)
            try context.save()
        }
    }

    private func saveSet(_ set: SetEntry) async {
        await write(set, complete: false)
    }

    private func completeSet(_ set: SetEntry) async {
        set.actualWeightKg = set.actualWeightKg ?? set.plannedWeightKg
        set.actualReps = set.actualReps ?? set.plannedReps
        await write(set, complete: true)
    }

    private func write(_ set: SetEntry, complete: Bool) async {
        let body = SetWriteBody(order: set.order, plannedWeightKg: set.plannedWeightKg, plannedReps: set.plannedReps,
                                actualWeightKg: set.actualWeightKg, actualReps: set.actualReps, isWarmup: set.isWarmup,
                                version: set.version, completedAt: complete ? .now : set.completedAt)
        await perform {
            let suffix = complete ? "/complete" : ""
            try await auth.send("workouts/\(workout.id)/sets/\(set.id)\(suffix)", method: complete ? "POST" : "PUT", body: body, baseURL: baseURL)
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        do { try await operation(); await refresh() }
        catch { errorMessage = error.localizedDescription }
    }

    private func refresh() async {
        do {
            let response = try await auth.bootstrap(baseURL: baseURL)
            try BootstrapImporter.importResponse(response, into: context)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct SetRow: View {
    @Bindable var set: SetEntry
    let onSave: () async -> Void
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
            Button("Save", systemImage: "square.and.arrow.down") { Task { await onSave() } }
                .labelStyle(.iconOnly)
                .foregroundStyle(Color.trainingLime)
                .frame(width: 34, height: 44)
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
