using Microsoft.EntityFrameworkCore;
using System.Text.Json.Serialization;
using TrainingApp.Api.Data;
using TrainingApp.Api.Domain;

namespace TrainingApp.Api.Services;

public static class RecordsService
{
    public static decimal EpleyOneRepMax(decimal weightKg, int reps) => reps <= 1 ? weightKg : decimal.Round(weightKg * (1m + reps / 30m), 2);
    public static async Task<RecordsResponse> GetAsync(AppDbContext db, Guid exerciseId, Guid ownerId, CancellationToken ct)
    {
        var sets = await db.SetEntries.Where(x => x.WorkoutExercise!.ExerciseId == exerciseId && x.WorkoutExercise.Workout!.OwnerId == ownerId && x.Status == SetStatus.Completed && !x.IsWarmup && x.ActualWeightKg != null && x.ActualReps != null).AsNoTracking().ToListAsync(ct);
        return new RecordsResponse(sets.MaxBy(x => x.ActualWeightKg)?.ActualWeightKg, sets.GroupBy(x => x.ActualWeightKg).Select(g => new RepsAtWeight(g.Key, g.Max(x => x.ActualReps))).OrderByDescending(x => x.WeightKg).ToList(), sets.Count == 0 ? null : sets.Max(x => EpleyOneRepMax(x.ActualWeightKg!.Value, x.ActualReps!.Value)));
    }

    public static async Task MarkRepRecordsAsync(AppDbContext db, Workout workout, CancellationToken ct)
    {
        var current = workout.Exercises.SelectMany(e => e.Sets.Where(s => s.Status == SetStatus.Completed && !s.IsWarmup && s.ActualWeightKg != null && s.ActualReps > 0).Select(s => new RepSet(s, e.ExerciseId))).ToList();
        if (current.Count == 0) return;

        var exerciseIds = current.Select(x => x.ExerciseId).Distinct().ToList();
        var prior = await db.SetEntries.Where(s => exerciseIds.Contains(s.WorkoutExercise!.ExerciseId) && s.WorkoutExercise.Workout!.OwnerId == workout.OwnerId && s.WorkoutExercise.Workout.ScheduledAt < workout.ScheduledAt && s.Status == SetStatus.Completed && !s.IsWarmup && s.ActualWeightKg != null && s.ActualReps > 0).Select(s => new { s.WorkoutExercise!.ExerciseId, WeightKg = s.ActualWeightKg!.Value, Reps = s.ActualReps!.Value }).AsNoTracking().ToListAsync(ct);
        foreach (var item in current)
            item.Set.IsRepRecord = !prior.Any(x => x.ExerciseId == item.ExerciseId && x.WeightKg >= item.Set.ActualWeightKg && x.Reps >= item.Set.ActualReps)
                && !current.Any(x => x.ExerciseId == item.ExerciseId && (x.Set.ActualWeightKg > item.Set.ActualWeightKg && x.Set.ActualReps >= item.Set.ActualReps || x.Set.ActualWeightKg >= item.Set.ActualWeightKg && x.Set.ActualReps > item.Set.ActualReps));
    }

    private sealed record RepSet(SetEntry Set, Guid ExerciseId);
}

public sealed record RecordsResponse(
    [property: JsonPropertyName("maxWeightKg")] decimal? MaxWeightKg,
    [property: JsonPropertyName("maxRepsByWeight")] IReadOnlyList<RepsAtWeight> MaxRepsByWeight,
    [property: JsonPropertyName("epleyOneRepMax")] decimal? EpleyOneRepMax);
public sealed record RepsAtWeight(
    [property: JsonPropertyName("weightKg")] decimal? WeightKg,
    [property: JsonPropertyName("reps")] int? Reps);
