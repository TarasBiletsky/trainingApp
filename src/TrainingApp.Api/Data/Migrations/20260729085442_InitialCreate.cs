using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace TrainingApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "training");

            migrationBuilder.CreateTable(
                name: "BodyMeasurements",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ExternalId = table.Column<string>(type: "text", nullable: false),
                    MeasuredAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    WeightKg = table.Column<decimal>(type: "numeric", nullable: false),
                    BodyFatPercent = table.Column<decimal>(type: "numeric", nullable: true),
                    MuscleMassKg = table.Column<decimal>(type: "numeric", nullable: true),
                    Impedance = table.Column<decimal>(type: "numeric", nullable: true),
                    Source = table.Column<string>(type: "text", nullable: false),
                    RawPayload = table.Column<string>(type: "text", nullable: false),
                    ImportedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BodyMeasurements", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Exercises",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    MuscleGroup = table.Column<string>(type: "text", nullable: false),
                    Equipment = table.Column<string>(type: "text", nullable: false),
                    IsArchived = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Exercises", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "HealthSamples",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "text", nullable: false),
                    StartAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    EndAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    NumericValue = table.Column<decimal>(type: "numeric", nullable: true),
                    Unit = table.Column<string>(type: "text", nullable: true),
                    SourceName = table.Column<string>(type: "text", nullable: true),
                    SourceBundleId = table.Column<string>(type: "text", nullable: true),
                    ExternalId = table.Column<string>(type: "text", nullable: false),
                    MetadataJson = table.Column<string>(type: "text", nullable: true),
                    ImportedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_HealthSamples", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TokenHash = table.Column<string>(type: "text", nullable: false),
                    ExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    RevokedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    ReplacedById = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RefreshTokens", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserName = table.Column<string>(type: "text", nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WorkoutTemplates",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    IsArchived = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorkoutTemplates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Workouts",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    ScheduledAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    StartedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CompletedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    Version = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Workouts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TemplateExercises",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkoutTemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    ExerciseId = table.Column<Guid>(type: "uuid", nullable: false),
                    Order = table.Column<int>(type: "integer", nullable: false),
                    RestSeconds = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplateExercises", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TemplateExercises_Exercises_ExerciseId",
                        column: x => x.ExerciseId,
                        principalSchema: "training",
                        principalTable: "Exercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TemplateExercises_WorkoutTemplates_WorkoutTemplateId",
                        column: x => x.WorkoutTemplateId,
                        principalSchema: "training",
                        principalTable: "WorkoutTemplates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WorkoutExercises",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkoutId = table.Column<Guid>(type: "uuid", nullable: false),
                    ExerciseId = table.Column<Guid>(type: "uuid", nullable: false),
                    Order = table.Column<int>(type: "integer", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    RestSeconds = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorkoutExercises", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WorkoutExercises_Exercises_ExerciseId",
                        column: x => x.ExerciseId,
                        principalSchema: "training",
                        principalTable: "Exercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WorkoutExercises_Workouts_WorkoutId",
                        column: x => x.WorkoutId,
                        principalSchema: "training",
                        principalTable: "Workouts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TemplateSets",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateExerciseId = table.Column<Guid>(type: "uuid", nullable: false),
                    Order = table.Column<int>(type: "integer", nullable: false),
                    WeightKg = table.Column<decimal>(type: "numeric", nullable: true),
                    Reps = table.Column<int>(type: "integer", nullable: true),
                    Rpe = table.Column<decimal>(type: "numeric", nullable: true),
                    IsWarmup = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplateSets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TemplateSets_TemplateExercises_TemplateExerciseId",
                        column: x => x.TemplateExerciseId,
                        principalSchema: "training",
                        principalTable: "TemplateExercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SetEntries",
                schema: "training",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkoutExerciseId = table.Column<Guid>(type: "uuid", nullable: false),
                    Order = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    PlannedWeightKg = table.Column<decimal>(type: "numeric", nullable: true),
                    PlannedReps = table.Column<int>(type: "integer", nullable: true),
                    PlannedRpe = table.Column<decimal>(type: "numeric", nullable: true),
                    ActualWeightKg = table.Column<decimal>(type: "numeric", nullable: true),
                    ActualReps = table.Column<int>(type: "integer", nullable: true),
                    ActualRpe = table.Column<decimal>(type: "numeric", nullable: true),
                    IsWarmup = table.Column<bool>(type: "boolean", nullable: false),
                    CompletedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    Version = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SetEntries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SetEntries_WorkoutExercises_WorkoutExerciseId",
                        column: x => x.WorkoutExerciseId,
                        principalSchema: "training",
                        principalTable: "WorkoutExercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                schema: "training",
                table: "Exercises",
                columns: new[] { "Id", "CreatedAt", "Description", "Equipment", "IsArchived", "MuscleGroup", "Name", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("11111111-1111-1111-1111-111111111111"), new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), null, "Barbell", false, "Chest", "Bench Press", new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), null, "Barbell", false, "Legs", "Squat", new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("33333333-3333-3333-3333-333333333333"), new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), null, "Barbell", false, "Hamstrings", "Romanian Deadlift", new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("44444444-4444-4444-4444-444444444444"), new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), null, "Cable", false, "Back", "Lat Pulldown", new DateTimeOffset(new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) }
                });

            migrationBuilder.CreateIndex(
                name: "IX_BodyMeasurements_Source_ExternalId",
                schema: "training",
                table: "BodyMeasurements",
                columns: new[] { "Source", "ExternalId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Exercises_Name",
                schema: "training",
                table: "Exercises",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_HealthSamples_Type_SourceBundleId_ExternalId",
                schema: "training",
                table: "HealthSamples",
                columns: new[] { "Type", "SourceBundleId", "ExternalId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_TokenHash",
                schema: "training",
                table: "RefreshTokens",
                column: "TokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SetEntries_WorkoutExerciseId_Order",
                schema: "training",
                table: "SetEntries",
                columns: new[] { "WorkoutExerciseId", "Order" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TemplateExercises_ExerciseId",
                schema: "training",
                table: "TemplateExercises",
                column: "ExerciseId");

            migrationBuilder.CreateIndex(
                name: "IX_TemplateExercises_WorkoutTemplateId",
                schema: "training",
                table: "TemplateExercises",
                column: "WorkoutTemplateId");

            migrationBuilder.CreateIndex(
                name: "IX_TemplateSets_TemplateExerciseId",
                schema: "training",
                table: "TemplateSets",
                column: "TemplateExerciseId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_UserName",
                schema: "training",
                table: "Users",
                column: "UserName",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WorkoutExercises_ExerciseId",
                schema: "training",
                table: "WorkoutExercises",
                column: "ExerciseId");

            migrationBuilder.CreateIndex(
                name: "IX_WorkoutExercises_WorkoutId_Order",
                schema: "training",
                table: "WorkoutExercises",
                columns: new[] { "WorkoutId", "Order" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BodyMeasurements",
                schema: "training");

            migrationBuilder.DropTable(
                name: "HealthSamples",
                schema: "training");

            migrationBuilder.DropTable(
                name: "RefreshTokens",
                schema: "training");

            migrationBuilder.DropTable(
                name: "SetEntries",
                schema: "training");

            migrationBuilder.DropTable(
                name: "TemplateSets",
                schema: "training");

            migrationBuilder.DropTable(
                name: "Users",
                schema: "training");

            migrationBuilder.DropTable(
                name: "WorkoutExercises",
                schema: "training");

            migrationBuilder.DropTable(
                name: "TemplateExercises",
                schema: "training");

            migrationBuilder.DropTable(
                name: "Workouts",
                schema: "training");

            migrationBuilder.DropTable(
                name: "Exercises",
                schema: "training");

            migrationBuilder.DropTable(
                name: "WorkoutTemplates",
                schema: "training");
        }
    }
}
