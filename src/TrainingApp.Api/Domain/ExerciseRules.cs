namespace TrainingApp.Api.Domain;

public static class ExerciseRules
{
    public static bool Accepts(Exercise exercise, decimal? plannedWeightKg, decimal? actualWeightKg) =>
        exercise.AllowsNegativeWeight || (plannedWeightKg is null or >= 0) && (actualWeightKg is null or >= 0);
}
