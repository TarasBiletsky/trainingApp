using Microsoft.EntityFrameworkCore;
using TrainingApp.Api.Domain;

namespace TrainingApp.Api.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Exercise> Exercises => Set<Exercise>(); public DbSet<Workout> Workouts => Set<Workout>(); public DbSet<WorkoutExercise> WorkoutExercises => Set<WorkoutExercise>();
    public DbSet<SetEntry> SetEntries => Set<SetEntry>(); public DbSet<WorkoutTemplate> WorkoutTemplates => Set<WorkoutTemplate>(); public DbSet<TemplateExercise> TemplateExercises => Set<TemplateExercise>();
    public DbSet<TemplateSet> TemplateSets => Set<TemplateSet>(); public DbSet<HealthSample> HealthSamples => Set<HealthSample>(); public DbSet<BodyMeasurement> BodyMeasurements => Set<BodyMeasurement>();
    public DbSet<LocalUser> Users => Set<LocalUser>(); public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.HasDefaultSchema("training");
        b.Entity<Exercise>().HasIndex(x => new { x.OwnerId, x.Name }).IsUnique();
        b.Entity<Workout>().Property(x => x.Version).IsConcurrencyToken(); b.Entity<SetEntry>().Property(x => x.Version).IsConcurrencyToken();
        b.Entity<WorkoutExercise>().Property(x => x.WeightMultiplier).HasDefaultValue(1); b.Entity<WorkoutExercise>().ToTable(t => t.HasCheckConstraint("CK_WorkoutExercises_WeightMultiplier", "\"WeightMultiplier\" IN (1, 2)"));
        b.Entity<TemplateExercise>().Property(x => x.WeightMultiplier).HasDefaultValue(1); b.Entity<TemplateExercise>().ToTable(t => t.HasCheckConstraint("CK_TemplateExercises_WeightMultiplier", "\"WeightMultiplier\" IN (1, 2)"));
        b.Entity<WorkoutExercise>().HasIndex(x => new { x.WorkoutId, x.Order }).IsUnique(); b.Entity<SetEntry>().HasIndex(x => new { x.WorkoutExerciseId, x.Order }).IsUnique();
        b.Entity<HealthSample>().HasIndex(x => new { x.OwnerId, x.Type, x.SourceBundleId, x.ExternalId }).IsUnique();
        b.Entity<BodyMeasurement>().HasIndex(x => new { x.OwnerId, x.Source, x.ExternalId }).IsUnique(); b.Entity<LocalUser>().HasIndex(x => x.UserName).IsUnique(); b.Entity<RefreshToken>().HasIndex(x => x.TokenHash).IsUnique();
        b.Entity<LocalUser>().Property(x => x.ColorTheme).HasDefaultValue("purple"); b.Entity<LocalUser>().ToTable(t => t.HasCheckConstraint("CK_Users_ColorTheme", "\"ColorTheme\" IN ('purple', 'toxic', 'red')"));
        b.Entity<Exercise>().HasData(Seed("Bench Press", "Chest", "Barbell"), Seed("Squat", "Legs", "Barbell"), Seed("Romanian Deadlift", "Hamstrings", "Barbell"), Seed("Lat Pulldown", "Back", "Cable"));
    }
    private static Exercise Seed(string name, string group, string equipment) => new() { Id = Guid.Parse(name switch { "Bench Press" => "11111111-1111-1111-1111-111111111111", "Squat" => "22222222-2222-2222-2222-222222222222", "Romanian Deadlift" => "33333333-3333-3333-3333-333333333333", _ => "44444444-4444-4444-4444-444444444444" }), Name = name, MuscleGroup = group, Equipment = equipment, CreatedAt = DateTimeOffset.UnixEpoch, UpdatedAt = DateTimeOffset.UnixEpoch };
}
