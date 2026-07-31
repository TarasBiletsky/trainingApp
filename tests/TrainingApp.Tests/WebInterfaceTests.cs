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

    [Fact]
    public void WorkoutCardsUseLongPressReorderingWithoutHandleButtons()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.DoesNotContain("class=\"reorder-handle\"", html);
        Assert.Contains("hold card to reorder", html);
        Assert.Contains("setTimeout(()=>", html);
        Assert.Contains("onpointerdown=\"startReorder(event,'exercise')\"", html);
        Assert.Contains("onpointerdown=\"startReorder(event,'set')\"", html);
        Assert.Contains("ontouchstart=\"startTouchReorder(event,'exercise')\"", html);
        Assert.Contains("function moveTouchReorder(event)", html);
        Assert.Contains("classList.add('drag-ghost')", html);
        Assert.Contains("reorderDrag.ghost.style.top", html);
        Assert.Contains("function autoScrollReorder()", html);
        Assert.Contains("scrollBy(0,reorderDrag.scrollSpeed)", html);
    }

    [Fact]
    public void WorkoutDisplaySortsExercisesAndSetsByPersistedOrder()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains("w.exercises=(w.exercises||[]).sort((a,b)=>a.order-b.order)", html);
        Assert.Contains("e.sets=(e.sets||[]).sort((a,b)=>a.order-b.order)", html);
    }
}
