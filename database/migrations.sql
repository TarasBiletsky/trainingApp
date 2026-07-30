CREATE TABLE IF NOT EXISTS public."__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
        IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'training') THEN
            CREATE SCHEMA training;
        END IF;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."BodyMeasurements" (
        "Id" uuid NOT NULL,
        "ExternalId" text NOT NULL,
        "MeasuredAt" timestamp with time zone NOT NULL,
        "WeightKg" numeric NOT NULL,
        "BodyFatPercent" numeric,
        "MuscleMassKg" numeric,
        "Impedance" numeric,
        "Source" text NOT NULL,
        "RawPayload" text NOT NULL,
        "ImportedAt" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_BodyMeasurements" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."Exercises" (
        "Id" uuid NOT NULL,
        "Name" text NOT NULL,
        "Description" text,
        "MuscleGroup" text NOT NULL,
        "Equipment" text NOT NULL,
        "IsArchived" boolean NOT NULL,
        "CreatedAt" timestamp with time zone NOT NULL,
        "UpdatedAt" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_Exercises" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."HealthSamples" (
        "Id" uuid NOT NULL,
        "Type" text NOT NULL,
        "StartAt" timestamp with time zone NOT NULL,
        "EndAt" timestamp with time zone NOT NULL,
        "NumericValue" numeric,
        "Unit" text,
        "SourceName" text,
        "SourceBundleId" text,
        "ExternalId" text NOT NULL,
        "MetadataJson" text,
        "ImportedAt" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_HealthSamples" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."RefreshTokens" (
        "Id" uuid NOT NULL,
        "TokenHash" text NOT NULL,
        "ExpiresAt" timestamp with time zone NOT NULL,
        "RevokedAt" timestamp with time zone,
        "ReplacedById" uuid,
        CONSTRAINT "PK_RefreshTokens" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."Users" (
        "Id" uuid NOT NULL,
        "UserName" text NOT NULL,
        "PasswordHash" text NOT NULL,
        CONSTRAINT "PK_Users" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."WorkoutTemplates" (
        "Id" uuid NOT NULL,
        "Name" text NOT NULL,
        "IsArchived" boolean NOT NULL,
        CONSTRAINT "PK_WorkoutTemplates" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."Workouts" (
        "Id" uuid NOT NULL,
        "Name" text NOT NULL,
        "ScheduledAt" timestamp with time zone NOT NULL,
        "StartedAt" timestamp with time zone,
        "CompletedAt" timestamp with time zone,
        "Status" integer NOT NULL,
        "Notes" text,
        "CreatedAt" timestamp with time zone NOT NULL,
        "UpdatedAt" timestamp with time zone NOT NULL,
        "Version" bigint NOT NULL,
        CONSTRAINT "PK_Workouts" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."TemplateExercises" (
        "Id" uuid NOT NULL,
        "WorkoutTemplateId" uuid NOT NULL,
        "ExerciseId" uuid NOT NULL,
        "Order" integer NOT NULL,
        "RestSeconds" integer NOT NULL,
        CONSTRAINT "PK_TemplateExercises" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_TemplateExercises_Exercises_ExerciseId" FOREIGN KEY ("ExerciseId") REFERENCES training."Exercises" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_TemplateExercises_WorkoutTemplates_WorkoutTemplateId" FOREIGN KEY ("WorkoutTemplateId") REFERENCES training."WorkoutTemplates" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."WorkoutExercises" (
        "Id" uuid NOT NULL,
        "WorkoutId" uuid NOT NULL,
        "ExerciseId" uuid NOT NULL,
        "Order" integer NOT NULL,
        "Notes" text,
        "RestSeconds" integer NOT NULL,
        CONSTRAINT "PK_WorkoutExercises" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_WorkoutExercises_Exercises_ExerciseId" FOREIGN KEY ("ExerciseId") REFERENCES training."Exercises" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_WorkoutExercises_Workouts_WorkoutId" FOREIGN KEY ("WorkoutId") REFERENCES training."Workouts" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."TemplateSets" (
        "Id" uuid NOT NULL,
        "TemplateExerciseId" uuid NOT NULL,
        "Order" integer NOT NULL,
        "WeightKg" numeric,
        "Reps" integer,
        "Rpe" numeric,
        "IsWarmup" boolean NOT NULL,
        CONSTRAINT "PK_TemplateSets" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_TemplateSets_TemplateExercises_TemplateExerciseId" FOREIGN KEY ("TemplateExerciseId") REFERENCES training."TemplateExercises" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE TABLE training."SetEntries" (
        "Id" uuid NOT NULL,
        "WorkoutExerciseId" uuid NOT NULL,
        "Order" integer NOT NULL,
        "Status" integer NOT NULL,
        "PlannedWeightKg" numeric,
        "PlannedReps" integer,
        "PlannedRpe" numeric,
        "ActualWeightKg" numeric,
        "ActualReps" integer,
        "ActualRpe" numeric,
        "IsWarmup" boolean NOT NULL,
        "CompletedAt" timestamp with time zone,
        "Notes" text,
        "UpdatedAt" timestamp with time zone NOT NULL,
        "Version" bigint NOT NULL,
        CONSTRAINT "PK_SetEntries" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_SetEntries_WorkoutExercises_WorkoutExerciseId" FOREIGN KEY ("WorkoutExerciseId") REFERENCES training."WorkoutExercises" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    INSERT INTO training."Exercises" ("Id", "CreatedAt", "Description", "Equipment", "IsArchived", "MuscleGroup", "Name", "UpdatedAt")
    VALUES ('11111111-1111-1111-1111-111111111111', TIMESTAMPTZ '1970-01-01T00:00:00+00:00', NULL, 'Barbell', FALSE, 'Chest', 'Bench Press', TIMESTAMPTZ '1970-01-01T00:00:00+00:00');
    INSERT INTO training."Exercises" ("Id", "CreatedAt", "Description", "Equipment", "IsArchived", "MuscleGroup", "Name", "UpdatedAt")
    VALUES ('22222222-2222-2222-2222-222222222222', TIMESTAMPTZ '1970-01-01T00:00:00+00:00', NULL, 'Barbell', FALSE, 'Legs', 'Squat', TIMESTAMPTZ '1970-01-01T00:00:00+00:00');
    INSERT INTO training."Exercises" ("Id", "CreatedAt", "Description", "Equipment", "IsArchived", "MuscleGroup", "Name", "UpdatedAt")
    VALUES ('33333333-3333-3333-3333-333333333333', TIMESTAMPTZ '1970-01-01T00:00:00+00:00', NULL, 'Barbell', FALSE, 'Hamstrings', 'Romanian Deadlift', TIMESTAMPTZ '1970-01-01T00:00:00+00:00');
    INSERT INTO training."Exercises" ("Id", "CreatedAt", "Description", "Equipment", "IsArchived", "MuscleGroup", "Name", "UpdatedAt")
    VALUES ('44444444-4444-4444-4444-444444444444', TIMESTAMPTZ '1970-01-01T00:00:00+00:00', NULL, 'Cable', FALSE, 'Back', 'Lat Pulldown', TIMESTAMPTZ '1970-01-01T00:00:00+00:00');
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_BodyMeasurements_Source_ExternalId" ON training."BodyMeasurements" ("Source", "ExternalId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_Exercises_Name" ON training."Exercises" ("Name");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_HealthSamples_Type_SourceBundleId_ExternalId" ON training."HealthSamples" ("Type", "SourceBundleId", "ExternalId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_RefreshTokens_TokenHash" ON training."RefreshTokens" ("TokenHash");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_SetEntries_WorkoutExerciseId_Order" ON training."SetEntries" ("WorkoutExerciseId", "Order");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE INDEX "IX_TemplateExercises_ExerciseId" ON training."TemplateExercises" ("ExerciseId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE INDEX "IX_TemplateExercises_WorkoutTemplateId" ON training."TemplateExercises" ("WorkoutTemplateId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE INDEX "IX_TemplateSets_TemplateExerciseId" ON training."TemplateSets" ("TemplateExerciseId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_Users_UserName" ON training."Users" ("UserName");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE INDEX "IX_WorkoutExercises_ExerciseId" ON training."WorkoutExercises" ("ExerciseId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_WorkoutExercises_WorkoutId_Order" ON training."WorkoutExercises" ("WorkoutId", "Order");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729085442_InitialCreate') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260729085442_InitialCreate', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    DROP INDEX training."IX_HealthSamples_Type_SourceBundleId_ExternalId";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    DROP INDEX training."IX_Exercises_Name";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    DROP INDEX training."IX_BodyMeasurements_Source_ExternalId";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."Workouts" ADD "OwnerId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."WorkoutTemplates" ADD "OwnerId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."Users" ADD "CreatedAt" timestamp with time zone NOT NULL DEFAULT (CURRENT_TIMESTAMP);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."Users" ADD "IsActive" boolean NOT NULL DEFAULT TRUE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."Users" ADD "IsAdmin" boolean NOT NULL DEFAULT FALSE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."RefreshTokens" ADD "UserId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."HealthSamples" ADD "OwnerId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."Exercises" ADD "OwnerId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."BodyMeasurements" ADD "OwnerId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    UPDATE training."Users" SET "IsActive" = TRUE;
    UPDATE training."Users" SET "IsAdmin" = TRUE
    WHERE "Id" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1);
    UPDATE training."Workouts" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
    UPDATE training."WorkoutTemplates" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
    UPDATE training."HealthSamples" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
    UPDATE training."BodyMeasurements" SET "OwnerId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "OwnerId" IS NULL;
    UPDATE training."RefreshTokens" SET "UserId" = (SELECT "Id" FROM training."Users" ORDER BY "CreatedAt", "Id" LIMIT 1) WHERE "UserId" IS NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."Workouts" ALTER COLUMN "OwnerId" SET NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."WorkoutTemplates" ALTER COLUMN "OwnerId" SET NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."HealthSamples" ALTER COLUMN "OwnerId" SET NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."BodyMeasurements" ALTER COLUMN "OwnerId" SET NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."RefreshTokens" ALTER COLUMN "UserId" SET NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    UPDATE training."Exercises" SET "OwnerId" = NULL
    WHERE "Id" = '11111111-1111-1111-1111-111111111111';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    UPDATE training."Exercises" SET "OwnerId" = NULL
    WHERE "Id" = '22222222-2222-2222-2222-222222222222';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    UPDATE training."Exercises" SET "OwnerId" = NULL
    WHERE "Id" = '33333333-3333-3333-3333-333333333333';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    UPDATE training."Exercises" SET "OwnerId" = NULL
    WHERE "Id" = '44444444-4444-4444-4444-444444444444';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    CREATE INDEX "IX_RefreshTokens_UserId" ON training."RefreshTokens" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    CREATE UNIQUE INDEX "IX_HealthSamples_OwnerId_Type_SourceBundleId_ExternalId" ON training."HealthSamples" ("OwnerId", "Type", "SourceBundleId", "ExternalId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    CREATE UNIQUE INDEX "IX_Exercises_OwnerId_Name" ON training."Exercises" ("OwnerId", "Name");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    CREATE UNIQUE INDEX "IX_BodyMeasurements_OwnerId_Source_ExternalId" ON training."BodyMeasurements" ("OwnerId", "Source", "ExternalId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    ALTER TABLE training."RefreshTokens" ADD CONSTRAINT "FK_RefreshTokens_Users_UserId" FOREIGN KEY ("UserId") REFERENCES training."Users" ("Id") ON DELETE CASCADE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260729143350_MultiUserOwnership') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260729143350_MultiUserOwnership', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    ALTER TABLE training."Exercises" ADD "ImageUrl" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    ALTER TABLE training."Exercises" ADD "LicenseName" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    ALTER TABLE training."Exercises" ADD "LicenseUrl" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    ALTER TABLE training."Exercises" ADD "SourceAuthor" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    ALTER TABLE training."Exercises" ADD "SourceUrl" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    UPDATE training."Exercises" SET "ImageUrl" = NULL, "LicenseName" = NULL, "LicenseUrl" = NULL, "SourceAuthor" = NULL, "SourceUrl" = NULL
    WHERE "Id" = '11111111-1111-1111-1111-111111111111';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    UPDATE training."Exercises" SET "ImageUrl" = NULL, "LicenseName" = NULL, "LicenseUrl" = NULL, "SourceAuthor" = NULL, "SourceUrl" = NULL
    WHERE "Id" = '22222222-2222-2222-2222-222222222222';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    UPDATE training."Exercises" SET "ImageUrl" = NULL, "LicenseName" = NULL, "LicenseUrl" = NULL, "SourceAuthor" = NULL, "SourceUrl" = NULL
    WHERE "Id" = '33333333-3333-3333-3333-333333333333';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    UPDATE training."Exercises" SET "ImageUrl" = NULL, "LicenseName" = NULL, "LicenseUrl" = NULL, "SourceAuthor" = NULL, "SourceUrl" = NULL
    WHERE "Id" = '44444444-4444-4444-4444-444444444444';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730083631_ExerciseLibraryAttribution') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260730083631_ExerciseLibraryAttribution', '10.0.4');
    END IF;
END $EF$;
COMMIT;

