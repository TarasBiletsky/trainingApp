import Foundation
import SwiftData

enum WorkoutStatus: String, Codable, CaseIterable {
    case planned, inProgress, completed, cancelled
}

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var name: String
    var scheduledAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var statusRaw: String
    var notes: String
    var updatedAt: Date
    var version: Int
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]

    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), name: String, scheduledAt: Date = .now) {
        self.id = id
        self.name = name
        self.scheduledAt = scheduledAt
        statusRaw = WorkoutStatus.planned.rawValue
        notes = ""
        updatedAt = .now
        version = 0
        exercises = []
    }
}

@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: UUID
    var exerciseId: UUID?
    var name: String
    var order: Int
    var notes: String
    var restSeconds: Int
    var weightMultiplier: Int = 1
    var workout: Workout?
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.workoutExercise)
    var sets: [SetEntry]

    init(id: UUID = UUID(), exerciseId: UUID? = nil, name: String, order: Int) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.order = order
        notes = ""
        restSeconds = 180
        weightMultiplier = 1
        sets = []
    }

    var completedVolumeKg: Double {
        sets.reduce(0) { total, set in
            guard set.status == .completed,
                  let weight = set.actualWeightKg,
                  let reps = set.actualReps else { return total }
            return total + weight * Double(reps) * Double(weightMultiplier)
        }
    }
}

enum SetStatus: String, Codable {
    case planned, completed, skipped
}

@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var order: Int
    var statusRaw: String
    var plannedWeightKg: Double?
    var plannedReps: Int?
    var actualWeightKg: Double?
    var actualReps: Int?
    var isWarmup: Bool
    var completedAt: Date?
    var notes: String
    var updatedAt: Date
    var needsSync: Bool
    var version: Int
    var workoutExercise: WorkoutExercise?

    var status: SetStatus {
        get { SetStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), order: Int, plannedWeightKg: Double? = nil, plannedReps: Int? = nil) {
        self.id = id
        self.order = order
        statusRaw = SetStatus.planned.rawValue
        self.plannedWeightKg = plannedWeightKg
        self.plannedReps = plannedReps
        isWarmup = false
        notes = ""
        updatedAt = .now
        needsSync = true
        version = 0
    }
}
