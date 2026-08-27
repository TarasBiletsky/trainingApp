using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddExerciseWeightOptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "AllowsNegativeWeight",
                schema: "training",
                table: "Exercises",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "CountWeightAsDouble",
                schema: "training",
                table: "Exercises",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.Sql("""
                UPDATE training."Exercises"
                SET "AllowsNegativeWeight" = TRUE
                WHERE "Name" IN ('Dips', 'Pull Up', 'Revers Grip Pull Up', 'Rope Pull Up');

                UPDATE training."Exercises"
                SET "CountWeightAsDouble" = TRUE
                WHERE "Name" IN (
                    'Cable Crossover',
                    'Cable Lateral Raise',
                    'Dumbbell Concentration Curl',
                    'Dumbbell Curl',
                    'Dumbbell Hammer Curl',
                    'Dumbbell Row',
                    'Flat Dumbbell Bench Press',
                    'Flat Dumbbell Fly',
                    'Incline Dumbbell Bench Press',
                    'Incline Dumbbell Fly',
                    'Lateral Dumbbell Raise',
                    'Rear Delt Cable Fly',
                    'Seated Dumbbell Press',
                    'Single-Arm Cable Row'
                );
                """);

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                columns: new[] { "AllowsNegativeWeight", "CountWeightAsDouble" },
                values: new object[] { false, false });

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                columns: new[] { "AllowsNegativeWeight", "CountWeightAsDouble" },
                values: new object[] { false, false });

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                columns: new[] { "AllowsNegativeWeight", "CountWeightAsDouble" },
                values: new object[] { false, false });

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "AllowsNegativeWeight", "CountWeightAsDouble" },
                values: new object[] { false, false });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AllowsNegativeWeight",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropColumn(
                name: "CountWeightAsDouble",
                schema: "training",
                table: "Exercises");
        }
    }
}
