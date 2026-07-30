namespace TrainingApp.Api.Domain;

public enum WorkoutStatus { Planned, InProgress, Completed, Cancelled }
public enum SetStatus { Planned, Completed, Skipped }

public sealed class Exercise
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public string? Description { get; set; }
    public required string MuscleGroup { get; set; }
    public required string Equipment { get; set; }
    public string? ImageUrl { get; set; }
    public string? SourceUrl { get; set; }
    public string? LicenseName { get; set; }
    public string? LicenseUrl { get; set; }
    public string? SourceAuthor { get; set; }
    public bool IsArchived { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public Guid? OwnerId { get; set; }
}

public sealed class Workout
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public DateTimeOffset ScheduledAt { get; set; }
    public DateTimeOffset? StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public WorkoutStatus Status { get; set; } = WorkoutStatus.Planned;
    public string? Notes { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public long Version { get; set; } = 1;
    public Guid OwnerId { get; set; }
    public List<WorkoutExercise> Exercises { get; set; } = [];
}

public sealed class WorkoutExercise
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid WorkoutId { get; set; }
    public Workout? Workout { get; set; }
    public Guid ExerciseId { get; set; }
    public Exercise? Exercise { get; set; }
    public int Order { get; set; }
    public string? Notes { get; set; }
    public int RestSeconds { get; set; } = 90;
    public int WeightMultiplier { get; set; } = 1;
    public List<SetEntry> Sets { get; set; } = [];
}

public sealed class SetEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid WorkoutExerciseId { get; set; }
    public WorkoutExercise? WorkoutExercise { get; set; }
    public int Order { get; set; }
    public SetStatus Status { get; set; } = SetStatus.Planned;
    public decimal? PlannedWeightKg { get; set; }
    public int? PlannedReps { get; set; }
    public decimal? PlannedRpe { get; set; }
    public decimal? ActualWeightKg { get; set; }
    public int? ActualReps { get; set; }
    public decimal? ActualRpe { get; set; }
    public bool IsWarmup { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public string? Notes { get; set; }
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public long Version { get; set; } = 1;
}

public sealed class WorkoutTemplate
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public bool IsArchived { get; set; }
    public Guid OwnerId { get; set; }
    public List<TemplateExercise> Exercises { get; set; } = [];
}
public sealed class TemplateExercise
{
    public Guid Id { get; set; } = Guid.NewGuid(); public Guid WorkoutTemplateId { get; set; } public WorkoutTemplate? WorkoutTemplate { get; set; }
    public Guid ExerciseId { get; set; } public Exercise? Exercise { get; set; } public int Order { get; set; } public int RestSeconds { get; set; } = 90; public int WeightMultiplier { get; set; } = 1;
    public List<TemplateSet> Sets { get; set; } = [];
}
public sealed class TemplateSet
{
    public Guid Id { get; set; } = Guid.NewGuid(); public Guid TemplateExerciseId { get; set; } public TemplateExercise? TemplateExercise { get; set; }
    public int Order { get; set; } public decimal? WeightKg { get; set; } public int? Reps { get; set; } public decimal? Rpe { get; set; } public bool IsWarmup { get; set; }
}

public sealed class HealthSample
{
    public Guid Id { get; set; } = Guid.NewGuid(); public required string Type { get; set; } public DateTimeOffset StartAt { get; set; } public DateTimeOffset EndAt { get; set; }
    public decimal? NumericValue { get; set; } public string? Unit { get; set; } public string? SourceName { get; set; } public string? SourceBundleId { get; set; }
    public required string ExternalId { get; set; } public string? MetadataJson { get; set; } public DateTimeOffset ImportedAt { get; set; } = DateTimeOffset.UtcNow;
    public Guid OwnerId { get; set; }
}
public sealed class BodyMeasurement
{
    public Guid Id { get; set; } = Guid.NewGuid(); public required string ExternalId { get; set; } public DateTimeOffset MeasuredAt { get; set; }
    public decimal WeightKg { get; set; } public decimal? BodyFatPercent { get; set; } public decimal? MuscleMassKg { get; set; } public decimal? Impedance { get; set; }
    public required string Source { get; set; } public required string RawPayload { get; set; } public DateTimeOffset ImportedAt { get; set; } = DateTimeOffset.UtcNow;
    public Guid OwnerId { get; set; }
}
public sealed class LocalUser { public Guid Id { get; set; } = Guid.NewGuid(); public required string UserName { get; set; } public required string PasswordHash { get; set; } public bool IsAdmin { get; set; } public bool IsActive { get; set; } = true; public string ColorTheme { get; set; } = "purple"; public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow; }
public sealed class RefreshToken { public Guid Id { get; set; } = Guid.NewGuid(); public Guid UserId { get; set; } public LocalUser? User { get; set; } public required string TokenHash { get; set; } public DateTimeOffset ExpiresAt { get; set; } public DateTimeOffset? RevokedAt { get; set; } public Guid? ReplacedById { get; set; } }
