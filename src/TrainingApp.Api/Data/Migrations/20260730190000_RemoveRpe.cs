using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class RemoveRpe : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Rpe",
                schema: "training",
                table: "TemplateSets");

            migrationBuilder.DropColumn(
                name: "ActualRpe",
                schema: "training",
                table: "SetEntries");

            migrationBuilder.DropColumn(
                name: "PlannedRpe",
                schema: "training",
                table: "SetEntries");

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "Rpe",
                schema: "training",
                table: "TemplateSets",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ActualRpe",
                schema: "training",
                table: "SetEntries",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "PlannedRpe",
                schema: "training",
                table: "SetEntries",
                type: "numeric",
                nullable: true);

        }
    }
}
