using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class MultiUserOwnership : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_HealthSamples_Type_SourceBundleId_ExternalId",
                schema: "training",
                table: "HealthSamples");

            migrationBuilder.DropIndex(
                name: "IX_Exercises_Name",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropIndex(
                name: "IX_BodyMeasurements_Source_ExternalId",
                schema: "training",
                table: "BodyMeasurements");

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerId",
                schema: "training",
                table: "Workouts",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerId",
                schema: "training",
                table: "WorkoutTemplates",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "CreatedAt",
                schema: "training",
                table: "Users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                schema: "training",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsAdmin",
                schema: "training",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                schema: "training",
                table: "RefreshTokens",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerId",
                schema: "training",
                table: "HealthSamples",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerId",
                schema: "training",
                table: "Exercises",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerId",
                schema: "training",
                table: "BodyMeasurements",
                type: "uuid",
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE training."Users" SET "IsActive" = TRUE;
                UPDATE training."Users" SET "IsAdmin" = TRUE
                WHERE "Id" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1);
                UPDATE training."Workouts" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
                UPDATE training."WorkoutTemplates" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
                UPDATE training."HealthSamples" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
                UPDATE training."BodyMeasurements" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
                UPDATE training."RefreshTokens" SET "UserId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "UserId" IS NULL;
                """);

            migrationBuilder.AlterColumn<Guid>(name: "OwnerId", schema: "training", table: "Workouts", type: "uuid", nullable: false, oldClrType: typeof(Guid), oldType: "uuid", oldNullable: true);
            migrationBuilder.AlterColumn<Guid>(name: "OwnerId", schema: "training", table: "WorkoutTemplates", type: "uuid", nullable: false, oldClrType: typeof(Guid), oldType: "uuid", oldNullable: true);
            migrationBuilder.AlterColumn<Guid>(name: "OwnerId", schema: "training", table: "HealthSamples", type: "uuid", nullable: false, oldClrType: typeof(Guid), oldType: "uuid", oldNullable: true);
            migrationBuilder.AlterColumn<Guid>(name: "OwnerId", schema: "training", table: "BodyMeasurements", type: "uuid", nullable: false, oldClrType: typeof(Guid), oldType: "uuid", oldNullable: true);
            migrationBuilder.AlterColumn<Guid>(name: "UserId", schema: "training", table: "RefreshTokens", type: "uuid", nullable: false, oldClrType: typeof(Guid), oldType: "uuid", oldNullable: true);

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "OwnerId",
                value: null);

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "OwnerId",
                value: null);

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "OwnerId",
                value: null);

            migrationBuilder.UpdateData(
                schema: "training",
                table: "Exercises",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "OwnerId",
                value: null);

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserId",
                schema: "training",
                table: "RefreshTokens",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_HealthSamples_OwnerId_Type_SourceBundleId_ExternalId",
                schema: "training",
                table: "HealthSamples",
                columns: new[] { "OwnerId", "Type", "SourceBundleId", "ExternalId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Exercises_OwnerId_Name",
                schema: "training",
                table: "Exercises",
                columns: new[] { "OwnerId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_BodyMeasurements_OwnerId_Source_ExternalId",
                schema: "training",
                table: "BodyMeasurements",
                columns: new[] { "OwnerId", "Source", "ExternalId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_RefreshTokens_Users_UserId",
                schema: "training",
                table: "RefreshTokens",
                column: "UserId",
                principalSchema: "training",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RefreshTokens_Users_UserId",
                schema: "training",
                table: "RefreshTokens");

            migrationBuilder.DropIndex(
                name: "IX_RefreshTokens_UserId",
                schema: "training",
                table: "RefreshTokens");

            migrationBuilder.DropIndex(
                name: "IX_HealthSamples_OwnerId_Type_SourceBundleId_ExternalId",
                schema: "training",
                table: "HealthSamples");

            migrationBuilder.DropIndex(
                name: "IX_Exercises_OwnerId_Name",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropIndex(
                name: "IX_BodyMeasurements_OwnerId_Source_ExternalId",
                schema: "training",
                table: "BodyMeasurements");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                schema: "training",
                table: "Workouts");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                schema: "training",
                table: "WorkoutTemplates");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                schema: "training",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsActive",
                schema: "training",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsAdmin",
                schema: "training",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "UserId",
                schema: "training",
                table: "RefreshTokens");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                schema: "training",
                table: "HealthSamples");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                schema: "training",
                table: "Exercises");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                schema: "training",
                table: "BodyMeasurements");

            migrationBuilder.CreateIndex(
                name: "IX_HealthSamples_Type_SourceBundleId_ExternalId",
                schema: "training",
                table: "HealthSamples",
                columns: new[] { "Type", "SourceBundleId", "ExternalId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Exercises_Name",
                schema: "training",
                table: "Exercises",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_BodyMeasurements_Source_ExternalId",
                schema: "training",
                table: "BodyMeasurements",
                columns: new[] { "Source", "ExternalId" },
                unique: true);
        }
    }
}
