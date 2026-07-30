using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260730140000_AddExerciseWeightMultiplier")]
public partial class AddExerciseWeightMultiplier : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<int>(name: "WeightMultiplier", schema: "training", table: "WorkoutExercises", type: "integer", nullable: false, defaultValue: 1);
        migrationBuilder.AddColumn<int>(name: "WeightMultiplier", schema: "training", table: "TemplateExercises", type: "integer", nullable: false, defaultValue: 1);
        migrationBuilder.AddCheckConstraint(name: "CK_WorkoutExercises_WeightMultiplier", schema: "training", table: "WorkoutExercises", sql: "\"WeightMultiplier\" IN (1, 2)");
        migrationBuilder.AddCheckConstraint(name: "CK_TemplateExercises_WeightMultiplier", schema: "training", table: "TemplateExercises", sql: "\"WeightMultiplier\" IN (1, 2)");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "WeightMultiplier", schema: "training", table: "WorkoutExercises");
        migrationBuilder.DropColumn(name: "WeightMultiplier", schema: "training", table: "TemplateExercises");
    }
}
