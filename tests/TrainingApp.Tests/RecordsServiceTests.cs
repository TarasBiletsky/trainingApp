using Microsoft.EntityFrameworkCore;
using TrainingApp.Api.Data;
using TrainingApp.Api.Domain;
using TrainingApp.Api.Services;
using Xunit;

namespace TrainingApp.Tests;

public sealed class RecordsServiceTests
{
    [Fact] public void Epley_IsExactForOneRep() => Assert.Equal(100m, RecordsService.EpleyOneRepMax(100m, 1));
    [Fact] public void Epley_ComputesEstimatedMaximum() => Assert.Equal(116.67m, RecordsService.EpleyOneRepMax(100m, 5));
    [Fact] public async Task RepRecord_IsNotDominatedByPriorOrCurrentWeightAndReps()
    {
        await using var db = Db(); var owner = Guid.NewGuid(); var exercise = new Exercise { Name = "Press", MuscleGroup = "Chest", Equipment = "Barbell" }; var priorWorkout = new Workout { OwnerId = owner, Name = "Prior", ScheduledAt = DateTimeOffset.UtcNow.AddDays(-7) }; db.Add(new WorkoutExercise { Workout = priorWorkout, Exercise = exercise, Order = 1, Sets = [new SetEntry { Order = 1, Status = SetStatus.Completed, ActualWeightKg = 80, ActualReps = 10 }] }); await db.SaveChangesAsync();
        var current = new Workout { OwnerId = owner, Name = "Current", ScheduledAt = DateTimeOffset.UtcNow, Exercises = [new WorkoutExercise { ExerciseId = exercise.Id, Order = 1, Sets = [new SetEntry { Order = 1, Status = SetStatus.Completed, ActualWeightKg = 105, ActualReps = 1 }, new SetEntry { Order = 2, Status = SetStatus.Completed, ActualWeightKg = 100, ActualReps = 2 }, new SetEntry { Order = 3, Status = SetStatus.Completed, ActualWeightKg = 90, ActualReps = 10 }, new SetEntry { Order = 4, Status = SetStatus.Completed, ActualWeightKg = 60, ActualReps = 10 }, new SetEntry { Order = 5, Status = SetStatus.Completed, ActualWeightKg = 90, ActualReps = 9 }] }] };

        await RecordsService.MarkRepRecordsAsync(db, current, default);

        Assert.True(current.Exercises[0].Sets[0].IsRepRecord);
        Assert.True(current.Exercises[0].Sets[1].IsRepRecord);
        Assert.True(current.Exercises[0].Sets[2].IsRepRecord);
        Assert.False(current.Exercises[0].Sets[3].IsRepRecord);
        Assert.False(current.Exercises[0].Sets[4].IsRepRecord);
    }
    [Fact] public async Task RepRecord_RemainsMarkedWhenALaterSetImprovesIt()
    {
        await using var db = Db(); var owner = Guid.NewGuid(); var exercise = new Exercise { Name = "Press", MuscleGroup = "Chest", Equipment = "Barbell" }; var workout = new Workout { OwnerId = owner, Name = "Current", ScheduledAt = DateTimeOffset.UtcNow, Exercises = [new WorkoutExercise { ExerciseId = exercise.Id, Order = 1, Sets = [new SetEntry { Order = 1, Status = SetStatus.Completed, ActualWeightKg = 100, ActualReps = 2 }, new SetEntry { Order = 2, Status = SetStatus.Completed, ActualWeightKg = 105, ActualReps = 2 }] }] };

        await RecordsService.MarkRepRecordsAsync(db, workout, default);

        Assert.True(workout.Exercises[0].Sets[0].IsRepRecord);
        Assert.True(workout.Exercises[0].Sets[1].IsRepRecord);
    }
    [Fact] public async Task Records_UseActualValuesAndIgnorePlansAndWarmups()
    {
        await using var db = Db(); var owner = Guid.NewGuid(); var exercise = new Exercise { Name="Test", MuscleGroup="Chest", Equipment="Barbell" }; var workout = new Workout { OwnerId=owner, Name="Day", ScheduledAt=DateTimeOffset.UtcNow }; var we = new WorkoutExercise { Workout=workout, Exercise=exercise, Order=1 };
        we.Sets.AddRange([new SetEntry { Order=1, Status=SetStatus.Completed, PlannedWeightKg=300, PlannedReps=50, ActualWeightKg=100, ActualReps=5 }, new SetEntry { Order=2, Status=SetStatus.Completed, ActualWeightKg=120, ActualReps=2, IsWarmup=true }, new SetEntry { Order=3, Status=SetStatus.Completed, ActualWeightKg=100, ActualReps=8 }]); db.Add(we); await db.SaveChangesAsync();
        db.Add(new WorkoutExercise { Workout = new Workout { OwnerId = Guid.NewGuid(), Name = "Someone else's day", ScheduledAt = DateTimeOffset.UtcNow }, Exercise = exercise, Order = 1, Sets = [new SetEntry { Order = 1, Status = SetStatus.Completed, ActualWeightKg = 999, ActualReps = 20 }] }); await db.SaveChangesAsync();
        var json = System.Text.Json.JsonSerializer.Serialize(await RecordsService.GetAsync(db, exercise.Id, owner, default)); Assert.Contains("\"maxWeightKg\":100", json); Assert.Contains("\"reps\":8", json); Assert.DoesNotContain("300", json);
    }
    [Fact] public void HealthNaturalKeyIsUnique()
    {
        using var db = Db(); var entity = db.Model.FindEntityType(typeof(HealthSample))!; var index = entity.GetIndexes().Single(x => x.Properties.Select(p => p.Name).SequenceEqual([nameof(HealthSample.OwnerId), nameof(HealthSample.Type), nameof(HealthSample.SourceBundleId), nameof(HealthSample.ExternalId)])); Assert.True(index.IsUnique);
    }
    private static AppDbContext Db() => new(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
}
