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
}

public sealed record RecordsResponse(
    [property: JsonPropertyName("maxWeightKg")] decimal? MaxWeightKg,
    [property: JsonPropertyName("maxRepsByWeight")] IReadOnlyList<RepsAtWeight> MaxRepsByWeight,
    [property: JsonPropertyName("epleyOneRepMax")] decimal? EpleyOneRepMax);
public sealed record RepsAtWeight(
    [property: JsonPropertyName("weightKg")] decimal? WeightKg,
    [property: JsonPropertyName("reps")] int? Reps);
