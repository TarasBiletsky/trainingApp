# Backend requests from iOS — follow-up required

Reviewed backend commit `b2c774e` on 2026-07-30. The main feature surface was added and OpenAPI copies are byte-identical, but the items below block reliable offline volume statistics. Do not mark this file completed until these checks pass.

## Open backend follow-up

### P0 — synced completed sets disappear from volume statistics

`POST /workouts/sync` updates `Status` but does not set or clear `SetEntry.CompletedAt`. `/statistics/volume` filters and groups strictly by `SetEntry.CompletedAt`. Therefore a set completed offline and later updated through sync can have `status = Completed` with `completedAt = null`, and is omitted from all volume statistics.

- Add an optional `completedAt` to the sync/write contract so iOS can preserve the real offline completion time. Require UTC and reject implausible values; alternatively define and document a safe server timestamp fallback.
- On transition to `Completed`, persist a non-null completion time.
- On transition from `Completed` to `Planned` or `Skipped`, clear it.
- An exact idempotent retry must preserve the original completion time.
- Decide date semantics explicitly: statistics use set completion time, while calendar membership uses workout `scheduledAt`.
- Regenerate all OpenAPI copies and sync examples after the contract changes.

Add integration/service tests proving:

- a set created as Completed through sync appears in `/statistics/volume`;
- an existing Planned set completed through sync appears in the correct UTC day;
- a skipped set is removed from volume;
- exact retry does not change `completedAt`;
- offline client timestamp survives sync;
- user and `[from,to)` boundaries remain isolated.

### P0 — requested tests were not added

`dotnet test` still reports only the original 4 tests. The previous acceptance request required coverage for registration removal, logout revocation, enum/OpenAPI contract, sync create/retry/conflict, multiplier validation, template copying, volume aggregation, warmups, date bounds, and user isolation.

- Add the missing tests; do not treat runtime smoke testing as a replacement for deterministic regression coverage.
- The final report must include the new total test count and names/categories of the covered scenarios.

### P1 — clean stale handoff statements

The beginning of `ios-handoff/IOS_BACKEND_HANDOFF.md` still lists `login/register/refresh` as anonymous and says `login/register/refresh/logout` are implemented, while a later appended section correctly says registration was removed. The address section also omits the currently used LAN endpoint.

- Remove all stale registration references instead of appending a correction later.
- Add `http://192.168.31.45:8181/api/v1` and its LAN/firewall note.
- Keep a single internally consistent description of auth and endpoints.
- Re-run `scripts/verify-ios-handoff.ps1`.

## Implemented in `b2c774e`

Implemented: public registration removal; string enums in OpenAPI; exact set-only sync contract and idempotent exact create retry; anonymous/idempotent refresh-token logout; weight multiplier migration and constraints; calendar DTO with volume; volume statistics; updated runtime artifacts.

## Remaining iOS work

- Decode and persist `weightMultiplier` in `WorkoutExerciseDTO`.
- Load calendar months from `GET /workouts?from=&to=` instead of deriving history from the single bootstrap workout.
- Load statistics from `GET /statistics/volume`.
- Upload local `needsSync` set changes through `/workouts/sync`, handling `existing` and 409 conflicts.
- Call `/auth/logout` with the refresh token before clearing Keychain.

The detailed sections below are retained for traceability and should not be treated as open backend tasks.

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
