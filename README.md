# TrainingApp monorepo

TrainingApp contains the self-hosted backend, native iOS application area, tests, deployment files, and the shared API handoff. The backend targets .NET 10 LTS, ASP.NET Core, EF Core, and PostgreSQL. The native iOS contract is `/api/v1`; `/` is the browser administration interface. Swagger UI is at `/swagger`.

## Repository layout

- `src/TrainingApp.Api` — backend API and browser administration UI.
- `tests/TrainingApp.Tests` — backend tests.
- `apps/ios` — native iOS application workspace.
- `ios-handoff` — runtime OpenAPI contract, integration guide, and real JSON examples shared with frontend development.
- `database` — idempotent database migration script.
- `compose.yaml` and `Dockerfile` — local/self-hosted deployment.

## Start locally

```powershell
Copy-Item .env.example .env
# Replace every placeholder in .env, then:
docker compose up --build -d
Invoke-WebRequest http://127.0.0.1:8181/health/ready
```

## Build the iOS app

```bash
cd apps/ios
brew install xcodegen
xcodegen generate
open TrainingApp.xcodeproj
```

The generated project targets iOS 17+. Select a Personal Team in Signing & Capabilities before installing on a physical iPhone. API contracts and integration examples live in `ios-handoff`.

On first start the migrator applies the checked-in idempotent SQL and the API creates the initial administrator from `TRAINING_ADMIN_USERNAME` / `TRAINING_ADMIN_PASSWORD`. Administrators can create and deactivate additional accounts through `/api/v1/users`; there is no public registration endpoint. Workouts, templates and health data are isolated by user. All timestamps are UTC ISO 8601 values and all identifiers are UUIDs.

For a host SDK workflow, install the .NET 10 SDK and set the environment variables from `.env.example`, then run:

```powershell
dotnet restore TrainingApp.slnx
dotnet run --project src/TrainingApp.Api
```

## Production configuration

- Prefer HTTPS through Tailscale Serve. The persistent web auth cookie is `HttpOnly` and `SameSite=Strict`; it is marked `Secure` on HTTPS and supports trusted private-LAN HTTP access.
- Generate unrelated random values for the database password, JWT key (at least 32 random bytes), admin password, and Home Assistant API key. Never commit `.env`.
- Keep `TRAINING_AUTO_MIGRATE=true` for a single-instance home deployment. For controlled deployments, set it to `false` and run `dotnet ef database update` as a release step.
- Bind the published port only to a private interface/VPN when the service is not meant for the public internet. Keep PostgreSQL unpublished.
- Logs use ASP.NET Core's structured console logger. Configure levels with standard `Logging__LogLevel__...` environment variables.

## Authentication and users

Web login uses `POST /api/v1/auth/login?web=true` and a cookie. iOS calls the same endpoint without the query parameter, stores the short-lived access token and rotating refresh token in Keychain, sends `Authorization: Bearer ...`, and rotates via `/auth/refresh`. Logout revokes the supplied refresh token. A used refresh token cannot be replayed.

`GET /api/v1/users/me` returns the current account. Administrators use `GET|POST /api/v1/users` and `PUT /api/v1/users/{id}` to manage sharing. Users change their own password through `PUT /api/v1/users/me/password`; this revokes all existing refresh tokens.

## Tailscale access

Compose publishes the API on port `8181` for private LAN and Tailscale access. Current endpoints are `http://192.168.31.45:8181/api/v1`, `http://100.67.143.48:8181/api/v1`, and the preferred HTTPS endpoint `https://pc.tail9b847f.ts.net/api/v1`. Firewall access is restricted to local subnets and the Tailscale CGNAT range. LAN addresses should be reserved in DHCP rather than treated as permanent application configuration.

## iOS sync example

Client-generated UUIDs identify offline-created records. Each update supplies the last acknowledged version; a stale update returns `409` and the current server record. The current API also returns `409` for an exact retry of an already-created set, so clients must reconcile it instead of assuming an idempotent acknowledgement.

```http
POST /api/v1/workouts/sync
Authorization: Bearer ACCESS_TOKEN
Content-Type: application/json

[
  {
    "id": "7f7b7335-3c03-4e26-b18a-276e263ff86b",
    "workoutExerciseId": "9bd90d99-3c75-46ea-b9a6-cb7d1108bb9b",
    "expectedVersion": 1,
    "value": {
      "order": 1, "actualWeightKg": 100, "actualReps": 5,
      "isWarmup": false, "status": "Completed",
      "version": 1
    }
  }
]
```

Sync is intentionally limited to workout set changes; deletes are represented by status/archive flags. Health samples have a separate batch import (maximum 500 items). Daily health aggregates are computed from raw samples rather than stored as mutable truth.

## Home Assistant

The endpoint uses `X-Api-Key` and is idempotent by `(source, externalId)`. The automation passes the entity id as a variable instead of hard-coding one:

```yaml
rest_command:
  training_body_measurement:
    url: "http://training-api:8080/api/v1/integrations/home-assistant/body-measurements"
    method: POST
    headers:
      X-Api-Key: "{{ training_api_key }}"
      Content-Type: application/json
    payload: >-
      {"externalId":"{{ external_id }}","measuredAt":"{{ measured_at }}",
       "weightKg":{{ states(weight_entity) | float }},"bodyFatPercent":{{ body_fat | default('null') }},
       "source":"home-assistant","rawPayload":{{ raw_payload | tojson }}}
```

## Backup and restore

Create a consistent logical backup (the command prompts for the password unless `PGPASSWORD` is supplied):

```powershell
docker compose exec db pg_dump -U training -d training -Fc -f /tmp/training.dump
docker compose cp db:/tmp/training.dump ./training.dump
```

Restore into an empty database during a maintenance window:

```powershell
docker compose cp ./training.dump db:/tmp/training.dump
docker compose exec db pg_restore -U training -d training --clean --if-exists /tmp/training.dump
```

Back up `.env` separately in a secrets manager. Periodically perform a restore drill; a backup that has never been restored is unverified.

## Verification

```powershell
docker build -t trainingapp .
docker run --rm -v "${PWD}:/src" -w /src mcr.microsoft.com/dotnet/sdk:10.0 `
  bash -lc 'dotnet restore TrainingApp.slnx --force && dotnet test TrainingApp.slnx --no-restore -c Release'
docker compose config
```

Implemented: exercises, workout lifecycle and sets, separate templates, computed history/PRs, cookie and rotating-token auth, versioned set sync, HealthSample import/aggregation, bootstrap, Home Assistant ingestion, emergency web UI, PostgreSQL migration/seed, containers, health checks, tests and OpenAPI contract.

Consciously deferred: general-purpose sync, deletion sync, registration/roles, desktop admin, charts, direct HealthKit connection, AI and event-driven infrastructure.
