using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class ExerciseLibraryAttribution : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                schema: "training",
                table: "Exercises",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LicenseName",
                schema: "training",
                table: "Exercises",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LicenseUrl",
                schema: "training",
                table: "Exercises",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SourceAuthor",
                schema: "training",
                table: "Exercises",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SourceUrl",
                schema: "training",
                table: "Exercises",
                type: "text",
                nullable: true);

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                columns: new[] { "ImageUrl", "LicenseName", "LicenseUrl", "SourceAuthor", "SourceUrl" },
                values: new object[] { null, null, null, null, null });

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                columns: new[] { "ImageUrl", "LicenseName", "LicenseUrl", "SourceAuthor", "SourceUrl" },
                values: new object[] { null, null, null, null, null });

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                columns: new[] { "ImageUrl", "LicenseName", "LicenseUrl", "SourceAuthor", "SourceUrl" },
                values: new object[] { null, null, null, null, null });

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "ImageUrl", "LicenseName", "LicenseUrl", "SourceAuthor", "SourceUrl" },
                values: new object[] { null, null, null, null, null });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageUrl",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropColumn(
                name: "LicenseName",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropColumn(
                name: "LicenseUrl",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropColumn(
                name: "SourceAuthor",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropColumn(
                name: "SourceUrl",
                schema: "training",
                table: "Exercises");
        }
    }
}
