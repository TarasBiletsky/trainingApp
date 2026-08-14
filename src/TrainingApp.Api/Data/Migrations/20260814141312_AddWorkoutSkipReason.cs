using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkoutSkipReason : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SkipReason",
                schema: "training",
                table: "Workouts",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SkipReason",
                schema: "training",
                table: "Workouts");
        }
    }
}
