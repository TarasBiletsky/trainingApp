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

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730140000_AddExerciseWeightMultiplier') THEN
    ALTER TABLE training."WorkoutExercises" ADD "WeightMultiplier" integer NOT NULL DEFAULT 1;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730140000_AddExerciseWeightMultiplier') THEN
    ALTER TABLE training."TemplateExercises" ADD "WeightMultiplier" integer NOT NULL DEFAULT 1;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730140000_AddExerciseWeightMultiplier') THEN
    ALTER TABLE training."WorkoutExercises" ADD CONSTRAINT "CK_WorkoutExercises_WeightMultiplier" CHECK ("WeightMultiplier" IN (1, 2));
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730140000_AddExerciseWeightMultiplier') THEN
    ALTER TABLE training."TemplateExercises" ADD CONSTRAINT "CK_TemplateExercises_WeightMultiplier" CHECK ("WeightMultiplier" IN (1, 2));
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730140000_AddExerciseWeightMultiplier') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260730140000_AddExerciseWeightMultiplier', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730180000_AddUserColorTheme') THEN
    ALTER TABLE training."Users" ADD "ColorTheme" text NOT NULL DEFAULT 'purple';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730180000_AddUserColorTheme') THEN
    ALTER TABLE training."Users" ADD CONSTRAINT "CK_Users_ColorTheme" CHECK ("ColorTheme" IN ('purple', 'toxic', 'red'));
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730180000_AddUserColorTheme') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260730180000_AddUserColorTheme', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730190000_RemoveRpe') THEN
    ALTER TABLE training."TemplateSets" DROP COLUMN "Rpe";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730190000_RemoveRpe') THEN
    ALTER TABLE training."SetEntries" DROP COLUMN "ActualRpe";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730190000_RemoveRpe') THEN
    ALTER TABLE training."SetEntries" DROP COLUMN "PlannedRpe";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260730190000_RemoveRpe') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260730190000_RemoveRpe', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260806075815_AddExerciseReplacements') THEN
    CREATE TABLE training."ExerciseReplacements" (
        "ExerciseId" uuid NOT NULL,
        "ReplacementExerciseId" uuid NOT NULL,
        CONSTRAINT "PK_ExerciseReplacements" PRIMARY KEY ("ExerciseId", "ReplacementExerciseId"),
        CONSTRAINT "CK_ExerciseReplacements_DifferentExercises" CHECK ("ExerciseId" <> "ReplacementExerciseId"),
        CONSTRAINT "FK_ExerciseReplacements_Exercises_ExerciseId" FOREIGN KEY ("ExerciseId") REFERENCES training."Exercises" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_ExerciseReplacements_Exercises_ReplacementExerciseId" FOREIGN KEY ("ReplacementExerciseId") REFERENCES training."Exercises" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260806075815_AddExerciseReplacements') THEN
    CREATE INDEX "IX_ExerciseReplacements_ReplacementExerciseId" ON training."ExerciseReplacements" ("ReplacementExerciseId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260806075815_AddExerciseReplacements') THEN
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
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260806075815_AddExerciseReplacements') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260806075815_AddExerciseReplacements', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260812102519_ExpandExerciseReplacements') THEN
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
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM public."__EFMigrationsHistory" WHERE "MigrationId" = '20260812102519_ExpandExerciseReplacements') THEN
    INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260812102519_ExpandExerciseReplacements', '10.0.4');
    END IF;
END $EF$;
COMMIT;
