using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using System.Text.Json;
using System.Text.Json.Serialization;
using TrainingApp.Api.Data;
using TrainingApp.Api.Domain;
using Xunit;

namespace TrainingApp.Tests;

public sealed class SyncSetRulesTests
{
    private static readonly DateTimeOffset Now = new(2026, 7, 30, 12, 0, 0, TimeSpan.Zero);

    [Fact] public void Completed_UsesOfflineUtcTimestamp() { var requested = Now.AddHours(-2); Assert.Equal(requested, SyncSetRules.CompletionTime(SetStatus.Completed, requested, Now)); }
    [Fact] public void Completed_UsesServerFallback() => Assert.Equal(Now, SyncSetRules.CompletionTime(SetStatus.Completed, null, Now));
    [Theory, InlineData(SetStatus.Planned), InlineData(SetStatus.Skipped)] public void NonCompleted_ClearsTimestamp(SetStatus status) => Assert.Null(SyncSetRules.CompletionTime(status, Now, Now));
    [Fact] public void ClientTimestamp_MustBeUtc() => Assert.False(SyncSetRules.ValidClientTime(Now.ToOffset(TimeSpan.FromHours(2)), Now));
    [Fact] public void ClientTimestamp_RejectsImplausibleFuture() => Assert.False(SyncSetRules.ValidClientTime(Now.AddMinutes(6), Now));
    [Fact] public void ClientTimestamp_RejectsOlderThanTenYears() => Assert.False(SyncSetRules.ValidClientTime(Now.AddYears(-10).AddSeconds(-1), Now));
    [Fact] public void ExactRetry_PreservesServerFallbackTimestamp()
    {
        var entry = Entry(); entry.CompletedAt = Now;
        Assert.True(SyncSetRules.SameSet(entry, Write(completedAt: null)));
        Assert.Equal(Now, entry.CompletedAt);
    }
    [Fact] public void DifferentRetry_IsNotEquivalent() { var entry = Entry(); Assert.False(SyncSetRules.SameSet(entry, Write(actualReps: 9))); }
    [Fact] public void ExplicitDifferentCompletionTime_IsNotEquivalent() { var entry = Entry(); entry.CompletedAt = Now; Assert.False(SyncSetRules.SameSet(entry, Write(completedAt: Now.AddMinutes(-1)))); }
    [Fact] public void WeightMultiplier_DefaultsToOne() { Assert.Equal(1, new WorkoutExercise().WeightMultiplier); Assert.Equal(1, new TemplateExercise().WeightMultiplier); }
    [Fact] public void WeightMultiplier_HasDatabaseChecks()
    {
        using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        var model = db.GetService<IDesignTimeModel>().Model;
        Assert.Contains(model.FindEntityType(typeof(WorkoutExercise))!.GetCheckConstraints(), x => x.Sql!.Contains("IN (1, 2)"));
        Assert.Contains(model.FindEntityType(typeof(TemplateExercise))!.GetCheckConstraints(), x => x.Sql!.Contains("IN (1, 2)"));
    }
    [Fact] public void StatusEnums_SerializeAsStrings()
    {
        var options = new JsonSerializerOptions(); options.Converters.Add(new JsonStringEnumConverter());
        Assert.Equal("\"Completed\"", JsonSerializer.Serialize(SetStatus.Completed, options));
        Assert.Equal("\"InProgress\"", JsonSerializer.Serialize(WorkoutStatus.InProgress, options));
    }

    private static SetEntry Entry() => new() { Order = 1, Status = SetStatus.Completed, PlannedWeightKg = 60, PlannedReps = 8, PlannedRpe = 7, ActualWeightKg = 60, ActualReps = 8, ActualRpe = 7.5m, Notes = "offline" };
    private static SetWrite Write(int actualReps = 8, DateTimeOffset? completedAt = null) => new(null, 1, 60, 8, 7, 60, actualReps, 7.5m, false, "offline", null, SetStatus.Completed, completedAt);
}
