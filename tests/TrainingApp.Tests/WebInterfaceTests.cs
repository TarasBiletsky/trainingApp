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
}
