using Xunit;

namespace TrainingApp.Tests;

public class WebInterfaceTests
{
    [Fact]
    public void ExercisePickerUsesCategoriesWithoutPerCardAddButtons()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.DoesNotContain("importExercise(", html);
        Assert.Contains("id=\"exercisePicker\"", html);
        Assert.Contains("openExercisePicker()", html);
        foreach (var category in new[] { "Back", "Chest", "Triceps", "Biceps", "Legs", "Shoulders" })
            Assert.Contains($"<option>{category}</option>", html);
    }

    [Fact]
    public void ProgressSupportsDateRangesAndClickableWeeks()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains("id=\"progressFrom\"", html);
        Assert.Contains("id=\"progressTo\"", html);
        Assert.Contains("function selectProgressWeek(key)", html);
        Assert.Contains("class=\"week-column\"", html);
        Assert.Contains("aria-pressed=", html);
    }
}
