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
    public void ExerciseReplacementPickerPrioritizesSuggestedAlternatives()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains(">Potential replacements</button>", html);
        Assert.Contains(">All exercises</button>", html);
        Assert.Contains("/replacements`)", html);
        Assert.Contains("exercisePickerTab==='potential'?exerciseReplacementCache:exerciseCache", html);
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
    public void WorkoutEditorUsesAccessibleMobileActionsAndSetColumns()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.DoesNotContain("class=\"reorder-handle\"", html);
        Assert.Contains("class=\"exercise-menu\"", html);
        Assert.Contains("Delete exercise", html);
        Assert.DoesNotContain("Reorder sets", html);
        Assert.DoesNotContain("toggleReorderMode", html);
        Assert.Contains("Skip exercise", html);
        Assert.Contains("Unskip exercise", html);
        Assert.Contains("classList.contains('skip-exercise')", html);
        Assert.Contains("/exercises/${id}/${skipped?'unskip':'skip'}", html);
        Assert.Contains("class=\"set-labels\"", html);
        Assert.Contains("<span>SET</span><span>KG</span><span class=\"planned-label\">PLAN</span><span>REPS</span><span>DONE</span>", html);
        Assert.DoesNotContain("class=\"delete-set", html);
        Assert.Contains("setTimeout(()=>", html);
        Assert.Contains("onpointerdown=\"startReorder(event,'exercise')\"", html);
        Assert.Contains("onpointerdown=\"startReorder(event,'set')\"", html);
        Assert.Contains("ontouchstart=\"startTouchReorder(event,'exercise')\"", html);
        Assert.Contains("function moveTouchReorder(event)", html);
        Assert.Contains("classList.add('drag-ghost')", html);
        Assert.Contains("reorderDrag.ghost.style.top", html);
        Assert.Contains("function autoScrollReorder()", html);
        Assert.Contains("scrollBy(0,reorderDrag.scrollSpeed)", html);
        Assert.Contains("desktop?null:setTimeout(()=>activateReorder(),350)", html);
        Assert.Contains("activateReorder(reorderDrag.pointerId)", html);
        Assert.Contains("siblings.find(x=>{let rect=x.getBoundingClientRect();return y<rect.top+rect.height/2})", html);
        Assert.DoesNotContain("document.elementFromPoint(x,y)", html);
    }

    [Fact]
    public void WorkoutDisplaySortsExercisesAndSetsByPersistedOrder()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains("w.exercises=(w.exercises||[]).sort((a,b)=>a.order-b.order)", html);
        Assert.Contains("e.sets=(e.sets||[]).sort((a,b)=>a.order-b.order)", html);
    }

    [Fact]
    public void WorkoutPageHasDayNavigationActionsAndResponsiveMenu()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains("function moveWorkoutDay(days)", html);
        Assert.Contains("class=\"today-button secondary\" onclick=\"loadToday()\"", html);
        Assert.Contains("Skip workout", html);
        Assert.Contains("Delete workout", html);
        Assert.Contains("class=\"workout-menu\"", html);
        Assert.Contains("id=\"menuToggle\"", html);
        Assert.Contains("setMenu(innerWidth>600)", html);
        Assert.Contains("classList.toggle('skipped-workout',skipped)", html);
        Assert.Contains("x.disabled=!x.closest('.date-nav,.workout-menu')", html);
        Assert.Contains("class=\"mobile-header\"", html);
        Assert.Contains("class=\"drawer-head\"", html);
        Assert.Contains("width:min(320px,88vw)", html);
        Assert.Contains("inset:0 auto 0 0", html);
        Assert.Contains("transform:translateX(-100%)", html);
        Assert.DoesNotContain("Training history · programming · access · data", html);
        Assert.DoesNotContain("<h1>Logbook</h1>", html);
        Assert.Contains("body:has(#app.menu-open){overflow:hidden}", html);
    }

    [Fact]
    public void RestTimerAndLibraryUseMobileFirstControls()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains("class=\"rest-bar\"", html);
        Assert.Contains("Start 90s", html);
        Assert.Contains("function addTimer(n)", html);
        Assert.Contains("navigator.vibrate", html);
        Assert.Contains("oninput=\"scheduleLibrarySearch()\"", html);
        Assert.Contains("setTimeout(()=>loadLibrary(0),300)", html);
        Assert.Contains(">Load more</button>", html);
    }

    [Fact]
    public void CalendarUsesSegmentedViewsAndRealMobileMonthGrid()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains("class=\"calendar-tools views\"", html);
        Assert.Contains(".calendar.month{display:grid;grid-template-columns:repeat(7,minmax(0,1fr))", html);
        Assert.Contains("aria-label=\"Previous period\"", html);
        Assert.Contains("aria-label=\"Next period\"", html);
    }

    [Fact]
    public void MobileSetsSupportPlanActualRepsAndSwipeDelete()
    {
        var html = File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/TrainingApp.Api/wwwroot/index.html")));

        Assert.Contains("font-size:16px", html);
        Assert.Contains("Edit workout", html);
        Assert.Contains("aria-label=\"Planned repetitions\"", html);
        Assert.Contains("aria-label=\"Actual repetitions\"", html);
        Assert.Contains("${workoutEditMode?'':'disabled'}", html);
        Assert.DoesNotContain(".planned-reps,.set-labels .planned-label{display:none}", html);
        Assert.Contains("plannedReps:num(document.getElementById('p'+id)?.value)", html);
        Assert.Contains("deleteBySwipe=event.type==='touchend'&&drag.swiping&&drag.swipeX>=80", html);
        Assert.Contains("aria-label=\"Set effort\"", html);
        Assert.Contains(">1–2 reps left</option>", html);
        Assert.Contains("effort:document.getElementById('e'+id)?.value||null", html);
    }
}
