using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddExerciseReplacements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ExerciseReplacements",
                schema: "training",
                columns: table => new
                {
                    ExerciseId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReplacementExerciseId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExerciseReplacements", x => new { x.ExerciseId, x.ReplacementExerciseId });
                    table.CheckConstraint("CK_ExerciseReplacements_DifferentExercises", "\"ExerciseId\" <> \"ReplacementExerciseId\"");
                    table.ForeignKey(
                        name: "FK_ExerciseReplacements_Exercises_ExerciseId",
                        column: x => x.ExerciseId,
                        principalSchema: "training",
                        principalTable: "Exercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ExerciseReplacements_Exercises_ReplacementExerciseId",
                        column: x => x.ReplacementExerciseId,
                        principalSchema: "training",
                        principalTable: "Exercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ExerciseReplacements_ReplacementExerciseId",
                schema: "training",
                table: "ExerciseReplacements",
                column: "ReplacementExerciseId");

            migrationBuilder.Sql("""
                INSERT INTO training."Exercises"
                    ("Id", "Name", "Description", "MuscleGroup", "Equipment", "IsArchived", "CreatedAt", "UpdatedAt", "OwnerId")
                VALUES
                    ('50000000-0000-0000-0000-000000000001', 'Lat Pulldown - Wide Overhand Grip', 'Lat pulldown using a wide overhand lat bar.', 'Back', 'Cable (wide lat bar)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000002', 'Lat Pulldown - Medium Neutral Grip', 'Lat pulldown using a shoulder-width neutral-grip attachment.', 'Back', 'Cable (medium neutral-grip attachment)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000003', 'Lat Pulldown - Close Neutral Grip', 'Lat pulldown using a close neutral-grip attachment.', 'Back', 'Cable (close neutral-grip attachment)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000004', 'Lat Pulldown - Underhand Grip', 'Lat pulldown using an underhand grip on a straight bar.', 'Back', 'Cable (straight bar)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000005', 'Cable Pullover - Straight Bar', 'Standing cable pullover using a straight bar.', 'Back', 'Cable (straight bar)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000006', 'Cable Pullover - Rope', 'Standing cable pullover using a rope attachment.', 'Back', 'Cable (rope)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000007', 'Machine Pullover', 'Pullover performed on a dedicated plate-loaded or selectorized machine.', 'Back', 'Pullover machine', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000008', 'Cable Curl - Straight Bar', 'Standing cable curl using a straight bar.', 'Biceps', 'Cable (straight bar)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000009', 'Cable Curl - EZ-Bar', 'Standing cable curl using an angled EZ-bar attachment.', 'Biceps', 'Cable (EZ-bar attachment)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000010', 'Cable Hammer Curl - Rope', 'Standing cable hammer curl using a rope attachment and neutral grip.', 'Biceps', 'Cable (rope)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000011', 'Cable Triceps Pushdown - Straight Bar', 'Cable triceps pushdown using a straight bar.', 'Triceps', 'Cable (straight bar)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000012', 'Cable Triceps Pushdown - V-Bar', 'Cable triceps pushdown using a V-bar attachment.', 'Triceps', 'Cable (V-bar attachment)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000013', 'Cable Triceps Pushdown - Rope', 'Cable triceps pushdown using a rope attachment.', 'Triceps', 'Cable (rope)', FALSE, NOW(), NOW(), NULL),
                    ('50000000-0000-0000-0000-000000000014', 'Cable Overhead Triceps Extension - Rope', 'Overhead cable triceps extension using a rope attachment.', 'Triceps', 'Cable (rope)', FALSE, NOW(), NOW(), NULL)
                ON CONFLICT ("Id") DO NOTHING;

                WITH variants ("GroupName", "Id") AS (
                    VALUES
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000001'::uuid),
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000002'::uuid),
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000003'::uuid),
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000004'::uuid),
                        ('pullover', '50000000-0000-0000-0000-000000000005'::uuid),
                        ('pullover', '50000000-0000-0000-0000-000000000006'::uuid),
                        ('pullover', '50000000-0000-0000-0000-000000000007'::uuid),
                        ('cable-curl', '50000000-0000-0000-0000-000000000008'::uuid),
                        ('cable-curl', '50000000-0000-0000-0000-000000000009'::uuid),
                        ('cable-curl', '50000000-0000-0000-0000-000000000010'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000011'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000012'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000013'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000014'::uuid)
                )
                INSERT INTO training."ExerciseReplacements" ("ExerciseId", "ReplacementExerciseId")
                SELECT source."Id", replacement."Id"
                FROM variants source
                JOIN variants replacement ON replacement."GroupName" = source."GroupName" AND replacement."Id" <> source."Id"
                ON CONFLICT DO NOTHING;

                WITH variants ("GroupName", "Id") AS (
                    VALUES
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000001'::uuid),
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000002'::uuid),
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000003'::uuid),
                        ('lat-pulldown', '50000000-0000-0000-0000-000000000004'::uuid),
                        ('pullover', '50000000-0000-0000-0000-000000000005'::uuid),
                        ('pullover', '50000000-0000-0000-0000-000000000006'::uuid),
                        ('pullover', '50000000-0000-0000-0000-000000000007'::uuid),
                        ('cable-curl', '50000000-0000-0000-0000-000000000008'::uuid),
                        ('cable-curl', '50000000-0000-0000-0000-000000000009'::uuid),
                        ('cable-curl', '50000000-0000-0000-0000-000000000010'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000011'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000012'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000013'::uuid),
                        ('triceps-cable', '50000000-0000-0000-0000-000000000014'::uuid)
                ),
                aliases AS (
                    SELECT "Id",
                        CASE
                            WHEN "Name" IN ('Lat Pulldown', 'Lat Pulldown Machine') THEN 'lat-pulldown'
                            WHEN "Name" IN ('Pullover', 'Cable Pullover') THEN 'pullover'
                            WHEN "Name" IN ('Cable Curl', 'EZ-Bar Curl', 'Dumbbell Curl', 'Hammer Curl') THEN 'cable-curl'
                            WHEN "Name" IN ('Cable Pulldown', 'Rope Push Down', 'Cable Overhead Triceps Extension') THEN 'triceps-cable'
                        END AS "GroupName"
                    FROM training."Exercises"
                    WHERE "Name" IN ('Lat Pulldown', 'Lat Pulldown Machine', 'Pullover', 'Cable Pullover', 'Cable Curl',
                        'EZ-Bar Curl', 'Dumbbell Curl', 'Hammer Curl',
                        'Cable Pulldown', 'Rope Push Down', 'Cable Overhead Triceps Extension')
                ),
                links AS (
                    SELECT aliases."Id" AS "ExerciseId", variants."Id" AS "ReplacementExerciseId"
                    FROM aliases JOIN variants USING ("GroupName")
                    UNION
                    SELECT variants."Id", aliases."Id"
                    FROM aliases JOIN variants USING ("GroupName")
                )
                INSERT INTO training."ExerciseReplacements" ("ExerciseId", "ReplacementExerciseId")
                SELECT "ExerciseId", "ReplacementExerciseId" FROM links
                WHERE "ExerciseId" <> "ReplacementExerciseId"
                ON CONFLICT DO NOTHING;

                UPDATE training."TemplateExercises" SET "ExerciseId" = '50000000-0000-0000-0000-000000000001'
                WHERE "ExerciseId" IN (SELECT "Id" FROM training."Exercises" WHERE "Name" = 'Lat Pulldown');
                UPDATE training."WorkoutExercises" we SET "ExerciseId" = '50000000-0000-0000-0000-000000000001'
                FROM training."Workouts" w
                WHERE we."WorkoutId" = w."Id" AND w."Status" = 0
                    AND we."ExerciseId" IN (SELECT "Id" FROM training."Exercises" WHERE "Name" = 'Lat Pulldown');

                UPDATE training."TemplateExercises" SET "ExerciseId" = '50000000-0000-0000-0000-000000000005'
                WHERE "ExerciseId" IN (SELECT "Id" FROM training."Exercises" WHERE "Name" = 'Pullover');
                UPDATE training."WorkoutExercises" we SET "ExerciseId" = '50000000-0000-0000-0000-000000000005'
                FROM training."Workouts" w
                WHERE we."WorkoutId" = w."Id" AND w."Status" = 0
                    AND we."ExerciseId" IN (SELECT "Id" FROM training."Exercises" WHERE "Name" = 'Pullover');
                UPDATE training."TemplateSets" ts SET "WeightKg" = NULL
                FROM training."TemplateExercises" te
                WHERE ts."TemplateExerciseId" = te."Id" AND te."ExerciseId" = '50000000-0000-0000-0000-000000000005';
                UPDATE training."SetEntries" s SET "PlannedWeightKg" = NULL
                FROM training."WorkoutExercises" we, training."Workouts" w
                WHERE s."WorkoutExerciseId" = we."Id" AND we."WorkoutId" = w."Id" AND w."Status" = 0
                    AND we."ExerciseId" = '50000000-0000-0000-0000-000000000005';

                UPDATE training."TemplateExercises" SET "ExerciseId" = '50000000-0000-0000-0000-000000000013'
                WHERE "ExerciseId" IN (SELECT "Id" FROM training."Exercises" WHERE "Name" = 'Rope Push Down');
                UPDATE training."WorkoutExercises" we SET "ExerciseId" = '50000000-0000-0000-0000-000000000013'
                FROM training."Workouts" w
                WHERE we."WorkoutId" = w."Id" AND w."Status" = 0
                    AND we."ExerciseId" IN (SELECT "Id" FROM training."Exercises" WHERE "Name" = 'Rope Push Down');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExerciseReplacements",
                schema: "training");
        }
    }
}
