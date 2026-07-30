# Backend requests from iOS

Checked against backend commit `ecfc602` and the iOS client on 2026-07-30. Implement these items in priority order. Keep this file until the runtime API, tests, and `ios-handoff` artifacts have been updated. Do not include credentials or tokens in commits.

## P0 — security and contract correctness

### Remove public registration

The repository documentation says there is no public registration, but `POST /api/v1/auth/register` is currently anonymous and creates an active user without the 12-character password validation used by the admin endpoint.

- Remove `/api/v1/auth/register` from runtime routes and OpenAPI.
- Keep user creation only at authenticated admin `POST /api/v1/users`.
- Add a test proving anonymous registration is unavailable.

### Make OpenAPI match runtime JSON

ASP.NET serializes `WorkoutStatus` and `SetStatus` as strings (`"Planned"`, `"Completed"`, etc.), while the current OpenAPI describes integer enums. This is unsafe for generated iOS DTOs.

- Configure Swagger to publish the actual string enum values.
- Verify required/nullable fields against real responses.
- Prefer response DTOs over returning cyclic EF entities; conflict responses currently contain recursive objects and `null` placeholders because `ReferenceHandler.IgnoreCycles` hides cycles.
- Regenerate OpenAPI from the running API, never by editing JSON manually.

### Align sync documentation with the actual endpoint

The handoff says `/workouts/sync` accepts `{ entityType, operation, id, expectedVersion, payload }`, but runtime/OpenAPI accept `SetSyncCommand { id, workoutExerciseId, expectedVersion, value }`.

- Keep the current set-only command unless a broader engine is genuinely required.
- Update documentation and examples to exactly match runtime.
- Make an exact retry of a successfully created set idempotent: return `200` with `existing`/acknowledged version when the payload is equivalent.
- Return `409` only when the existing record differs or `expectedVersion` is stale.
- Add tests for create, exact retry, different-payload retry, update, stale update, user isolation, and batches with mixed results.

### Allow refresh-token revocation when access token expired

`POST /auth/logout` currently requires a valid access token. A user whose 15-minute access token has expired cannot revoke the still-valid 30-day refresh token.

- Permit logout using the refresh token without requiring a valid access token, or document and implement another safe revocation flow.
- Always return a non-secret response and keep the operation idempotent.
- Add tests for valid, expired/reused, unknown, and already-revoked refresh tokens.

## P1 — calendar and dumbbell volume

Detailed original planning notes are in [`../planning/BACKEND_CALENDAR_VOLUME_PROMPT.md`](../planning/BACKEND_CALENDAR_VOLUME_PROMPT.md). The acceptance contract is summarized here.

### Weight multiplier

- Add `WeightMultiplier` to `WorkoutExercise` and `TemplateExercise`.
- Allowed values: `1` or `2`; default existing and new records to `1`.
- Add request validation and PostgreSQL check constraints.
- Include `weightMultiplier` in read/write DTOs, bootstrap, templates, workout creation, export, and any relevant sync/update path.
- Creating a workout from a template must copy the multiplier.
- Changing the multiplier must not modify planned or actual weights.
- Generate and apply a non-destructive EF migration; update `database/migrations.sql` and the model snapshot.

### Volume formula

Use completed sets with non-null actual values:

```text
setVolumeKg = ActualWeightKg * ActualReps * WorkoutExercise.WeightMultiplier
```

Planned and skipped sets are excluded. Warmups are included by default and can be excluded with `includeWarmups=false`. Compute totals from history; do not store a mutable total column.

### Calendar workouts

The existing `GET /api/v1/workouts?from=&to=` already uses `[from,to)` semantics, but currently returns lightweight entities without volume.

- Require/validate `from < to` when a range is supplied and reject unreasonable ranges.
- Return a stable calendar DTO with at least `id`, `name`, `scheduledAt`, `startedAt`, `completedAt`, `status`, `version`, and `totalVolumeKg`.
- Keep results scoped to the authenticated user and ordered by `scheduledAt`.
- Avoid recursive navigation graphs.
- Existing `POST /workouts` remains the creation endpoint for a planned workout on a selected date.

### Volume statistics

Add authenticated `GET /api/v1/statistics/volume` with:

- required UTC `from` and exclusive `to`;
- optional `exerciseId`;
- optional `includeWarmups`, default `true`;
- validation for `from < to` and a maximum interval of five years;
- SQL-side aggregation scoped to the current user.

Response:

```json
{
  "from": "2026-07-01T00:00:00Z",
  "to": "2026-08-01T00:00:00Z",
  "totalVolumeKg": 123456.5,
  "byExercise": [
    {
      "exerciseId": "uuid",
      "exerciseName": "Dumbbell Bench Press",
      "totalVolumeKg": 24500,
      "completedSets": 24,
      "totalReps": 192
    }
  ],
  "byDay": [
    {
      "date": "2026-07-15",
      "totalVolumeKg": 8500
    }
  ]
}
```

Tests must cover multiplier 1/2, planned/skipped exclusion, warmup inclusion/exclusion, date boundaries, template copying, aggregation, and user isolation.

## P1 — artifacts required by iOS

After deploying and smoke-testing the updated API, replace the shared `ios-handoff` artifacts in the same commit:

- `ios-handoff/openapi.json`, exported from runtime Swagger;
- `openapi/openapi.json` and `openapi/training-api-v1.json`, if both remain supported copies;
- `ios-handoff/IOS_BACKEND_HANDOFF.md` with LAN and Tailscale URLs and exact runtime behavior;
- anonymized examples for monthly workout list, multiplier 2, volume statistics, template multiplier, idempotent sync retry, and real conflict;
- an explicit list of changed endpoints and DTOs.

Remove or replace stale examples such as `sync-retry.response-409.json` after behavior changes. Run the handoff verification script and ensure duplicated OpenAPI files are byte-identical or document why they are intentionally different.

## Completion report

In the final server-agent response include:

- commit SHA;
- migration name and confirmation it ran without data loss;
- build/test/smoke-test results;
- exact changed endpoints and DTO fields;
- absolute path to the updated `ios-handoff` folder;
- remaining known limitations that require iOS handling.
