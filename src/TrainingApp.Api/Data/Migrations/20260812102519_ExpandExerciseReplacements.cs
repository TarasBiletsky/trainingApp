using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class ExpandExerciseReplacements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO training."Exercises"
                    ("Id", "Name", "Description", "MuscleGroup", "Equipment", "IsArchived", "CreatedAt", "UpdatedAt", "OwnerId")
                VALUES
                    ('60000000-0000-0000-0000-000000000001', 'Barbell Bench Press - Paused', 'Flat barbell bench press with a controlled pause on the chest.', 'Chest', 'Barbell and flat bench', FALSE, NOW(), NOW(), NULL),
                    ('60000000-0000-0000-0000-000000000002', 'Barbell Bench Press - Close Grip', 'Flat barbell bench press using a close grip.', 'Chest', 'Barbell and flat bench', FALSE, NOW(), NOW(), NULL),
                    ('60000000-0000-0000-0000-000000000003', 'Smith Machine Incline Press', 'Incline bench press performed in a Smith machine.', 'Chest', 'Smith machine and incline bench', FALSE, NOW(), NOW(), NULL),
                    ('60000000-0000-0000-0000-000000000004', 'Machine Shoulder Press', 'Seated overhead press on a selectorized or plate-loaded machine.', 'Shoulders', 'Shoulder press machine', FALSE, NOW(), NOW(), NULL),
                    ('60000000-0000-0000-0000-000000000005', 'Single-Arm Cable Row', 'Horizontal cable row performed one arm at a time.', 'Back', 'Cable (single handle)', FALSE, NOW(), NOW(), NULL),
                    ('60000000-0000-0000-0000-000000000006', 'Chest-Supported T-Bar Row', 'T-bar row performed with the chest supported on a pad.', 'Back', 'Chest-supported T-bar machine', FALSE, NOW(), NOW(), NULL)
                ON CONFLICT ("Id") DO NOTHING;

                WITH groups ("GroupName", "ExerciseName") AS (
                    VALUES
                        ('chest-press', 'Bench Press'),
                        ('chest-press', 'Barbell Bench Press - Paused'),
                        ('chest-press', 'Barbell Bench Press - Close Grip'),
                        ('chest-press', 'Flat Dumbbell Bench Press'),
                        ('chest-press', 'Smith Machine Flat Barbell Press'),
                        ('chest-press', 'Chest Press Machine'),
                        ('chest-press', 'Wide Chest Press Machine'),
                        ('chest-press', 'Incline Barbell Bench Press'),
                        ('chest-press', 'Incline Dumbbell Bench Press'),
                        ('chest-press', 'Incline Chest Press'),
                        ('chest-press', 'Incline Chest Press Machine'),
                        ('chest-press', 'Smith Machine Incline Press'),
                        ('chest-press', 'Dips'),
                        ('chest-fly', 'Cable Crossover'),
                        ('chest-fly', 'Flat Dumbbell Fly'),
                        ('chest-fly', 'Incline Dumbbell Fly'),
                        ('chest-fly', 'Pec Deck Chest'),
                        ('chest-fly', 'Seated Machine Fly'),
                        ('horizontal-row', 'Barbell Row'),
                        ('horizontal-row', 'Chest Supported Row'),
                        ('horizontal-row', 'Chest-Supported T-Bar Row'),
                        ('horizontal-row', 'Dumbbell Row'),
                        ('horizontal-row', 'Single-Arm Cable Row'),
                        ('horizontal-row', 'Low Row Machine'),
                        ('horizontal-row', 'Row Machine'),
                        ('horizontal-row', 'Seated Cable Row'),
                        ('horizontal-row', 'Smith Machine Row'),
                        ('horizontal-row', 'T-Bar Row'),
                        ('horizontal-row', 'Upper Back Machine'),
                        ('vertical-pull', 'Lat Pulldown'),
                        ('vertical-pull', 'Lat Pulldown - Wide Overhand Grip'),
                        ('vertical-pull', 'Lat Pulldown - Medium Neutral Grip'),
                        ('vertical-pull', 'Lat Pulldown - Close Neutral Grip'),
                        ('vertical-pull', 'Lat Pulldown - Underhand Grip'),
                        ('vertical-pull', 'Lat Pulldown Machine'),
                        ('vertical-pull', 'Pull Down'),
                        ('vertical-pull', 'Pull Down Machine'),
                        ('vertical-pull', 'Pull Up'),
                        ('vertical-pull', 'Revers Grip Pull Up'),
                        ('shoulder-press', 'Overhead Press'),
                        ('shoulder-press', 'Push Press'),
                        ('shoulder-press', 'Seated Barbell Press'),
                        ('shoulder-press', 'Seated Dumbbell Press'),
                        ('shoulder-press', 'Shoulder Press'),
                        ('shoulder-press', 'Smith Machine Seated Press'),
                        ('shoulder-press', 'Machine Shoulder Press'),
                        ('lateral-raise', 'Barbell Lateral Raise'),
                        ('lateral-raise', 'Cable Lateral Raise'),
                        ('lateral-raise', 'Delt Machine'),
                        ('lateral-raise', 'Lateral Dumbbell Raise'),
                        ('rear-delt', 'Bent Over Lateral Raise'),
                        ('rear-delt', 'Cable Face Pull'),
                        ('rear-delt', 'Pec Deck'),
                        ('rear-delt', 'Rear Delt Cable Fly'),
                        ('rear-delt', 'Rear Delt Machine Fly'),
                        ('rear-delt', 'Reverse Pec Deck'),
                        ('squat-pattern', 'Squat'),
                        ('squat-pattern', 'Barbell Full Squat'),
                        ('squat-pattern', 'Belt Squat'),
                        ('squat-pattern', 'Hack Squat'),
                        ('squat-pattern', 'Leg Press'),
                        ('squat-pattern', 'Smith Machine Squat'),
                        ('squat-pattern', 'Zercher Squat'),
                        ('hip-hinge', 'Romanian Deadlift'),
                        ('hip-hinge', 'Deadlift'),
                        ('hip-hinge', 'Hyperextension'),
                        ('hip-hinge', 'Roman Chair Back Extension'),
                        ('hamstring-curl', 'Lying Leg Curl'),
                        ('hamstring-curl', 'Seated Leg Curl'),
                        ('hip-extension', 'Barbell Glute Bridge'),
                        ('hip-extension', 'Hip Thrust'),
                        ('hip-extension', 'Rear Kick'),
                        ('biceps-curl', 'Barbell Curl'),
                        ('biceps-curl', 'Cable Curl'),
                        ('biceps-curl', 'Cable Curl - EZ-Bar'),
                        ('biceps-curl', 'Cable Curl - Straight Bar'),
                        ('biceps-curl', 'Cable Hammer Curl - Rope'),
                        ('biceps-curl', 'Dumbbell Concentration Curl'),
                        ('biceps-curl', 'Dumbbell Curl'),
                        ('biceps-curl', 'Dumbbell Hammer Curl'),
                        ('biceps-curl', 'EZ-Bar Curl'),
                        ('biceps-curl', 'EZ-Bar Preacher Curl'),
                        ('triceps-extension', 'Barbell Skullcrusher'),
                        ('triceps-extension', 'Cable Overhead Triceps Extension'),
                        ('triceps-extension', 'Cable Overhead Triceps Extension - Rope'),
                        ('triceps-extension', 'Cable Pulldown'),
                        ('triceps-extension', 'Cable Triceps Pushdown - Rope'),
                        ('triceps-extension', 'Cable Triceps Pushdown - Straight Bar'),
                        ('triceps-extension', 'Cable Triceps Pushdown - V-Bar'),
                        ('triceps-extension', 'Dumbbell Overhead Triceps Extension'),
                        ('triceps-extension', 'EZ-Bar Skullcrusher'),
                        ('triceps-extension', 'Rope Push Down'),
                        ('triceps-extension', 'Seated Dip'),
                        ('triceps-extension', 'Smith Machine Close Grip Bench Press')
                ),
                members AS (
                    SELECT groups."GroupName", exercises."Id"
                    FROM groups
                    JOIN training."Exercises" exercises ON exercises."Name" = groups."ExerciseName"
                    WHERE NOT exercises."IsArchived"
                )
                INSERT INTO training."ExerciseReplacements" ("ExerciseId", "ReplacementExerciseId")
                SELECT source."Id", replacement."Id"
                FROM members source
                JOIN members replacement ON replacement."GroupName" = source."GroupName" AND replacement."Id" <> source."Id"
                ON CONFLICT DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM training."Exercises"
                WHERE "Id" IN (
                    '60000000-0000-0000-0000-000000000001',
                    '60000000-0000-0000-0000-000000000002',
                    '60000000-0000-0000-0000-000000000003',
                    '60000000-0000-0000-0000-000000000004',
                    '60000000-0000-0000-0000-000000000005',
                    '60000000-0000-0000-0000-000000000006'
                );
                """);
        }
    }
}
