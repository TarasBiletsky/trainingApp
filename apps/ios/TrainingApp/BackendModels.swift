import Foundation
import SwiftData

struct BootstrapResponse: Decodable {
    let workout: WorkoutDTO?
    let exercises: [ExerciseDTO]
    let lastHealthSyncAt: Date?
}

struct ExerciseDTO: Decodable {
    let id: UUID
    let name: String
}

struct WorkoutDTO: Decodable {
    let id: UUID
    let name: String
    let scheduledAt: Date
    let startedAt: Date?
    let completedAt: Date?
    let status: String
    let notes: String?
    let updatedAt: Date
    let version: Int
    let exercises: [WorkoutExerciseDTO]?
}

struct WorkoutExerciseDTO: Decodable {
    let id: UUID
    let exerciseId: UUID
    let order: Int
    let notes: String?
    let restSeconds: Int
    let sets: [SetEntryDTO]?
}

struct SetEntryDTO: Decodable {
    let id: UUID
    let order: Int
    let status: String
    let plannedWeightKg: Double?
    let plannedReps: Int?
    let plannedRpe: Double?
    let actualWeightKg: Double?
    let actualReps: Int?
    let actualRpe: Double?
    let isWarmup: Bool
    let completedAt: Date?
    let notes: String?
    let updatedAt: Date
    let version: Int
}

@MainActor
enum BootstrapImporter {
    static func importResponse(_ response: BootstrapResponse, into context: ModelContext) throws {
        guard let remote = response.workout else { return }
        let id = remote.id
        let existing = try context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })).first
        let workout = existing ?? Workout(id: id, name: remote.name, scheduledAt: remote.scheduledAt)
        if existing == nil { context.insert(workout) }

        workout.name = remote.name
        workout.scheduledAt = remote.scheduledAt
        workout.startedAt = remote.startedAt
        workout.completedAt = remote.completedAt
        workout.statusRaw = remote.status.lowercasingFirstLetter
        workout.notes = remote.notes ?? ""
        workout.updatedAt = remote.updatedAt
        workout.version = remote.version

        let exerciseNames = Dictionary(uniqueKeysWithValues: response.exercises.map { ($0.id, $0.name) })
        for remoteExercise in remote.exercises ?? [] {
            let exercise = workout.exercises.first { $0.id == remoteExercise.id }
                ?? WorkoutExercise(id: remoteExercise.id,
                                   exerciseId: remoteExercise.exerciseId,
                                   name: exerciseNames[remoteExercise.exerciseId] ?? "Упражнение",
                                   order: remoteExercise.order)
            if exercise.workout == nil { workout.exercises.append(exercise) }
            exercise.notes = remoteExercise.notes ?? ""
            exercise.restSeconds = remoteExercise.restSeconds

            for remoteSet in remoteExercise.sets ?? [] {
                if let local = exercise.sets.first(where: { $0.id == remoteSet.id }), local.needsSync { continue }
                let set = exercise.sets.first { $0.id == remoteSet.id }
                    ?? SetEntry(id: remoteSet.id, order: remoteSet.order)
                if set.workoutExercise == nil { exercise.sets.append(set) }
                set.statusRaw = remoteSet.status.lowercasingFirstLetter
                set.plannedWeightKg = remoteSet.plannedWeightKg
                set.plannedReps = remoteSet.plannedReps
                set.plannedRPE = remoteSet.plannedRpe
                set.actualWeightKg = remoteSet.actualWeightKg
                set.actualReps = remoteSet.actualReps
                set.actualRPE = remoteSet.actualRpe
                set.isWarmup = remoteSet.isWarmup
                set.completedAt = remoteSet.completedAt
                set.notes = remoteSet.notes ?? ""
                set.updatedAt = remoteSet.updatedAt
                set.version = remoteSet.version
                set.needsSync = false
            }
        }
        try context.save()
    }
}

private extension String {
    var lowercasingFirstLetter: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
}
