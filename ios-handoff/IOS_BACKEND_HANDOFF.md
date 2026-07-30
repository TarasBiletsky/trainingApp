# Training API — iOS backend handoff

Состояние проверено 2026-07-30 по реально запущенному Docker Compose API. Файл `openapi.json` выгружен из `/swagger/v1/swagger.json`, вручную не редактировался. Секретов в этой папке нет.

## Адреса

- Рекомендуемый с iPhone внутри tailnet: `https://pc.tail9b847f.ts.net/api/v1`.
- Прямой Tailscale HTTP: `http://100.67.143.48:8181/api/v1`.
- В домашней локальной сети: `http://192.168.31.45:8181/api/v1`.
- Локально на сервере: `http://127.0.0.1:8181/api/v1`.
- Будущий публичный HTTPS: `https://<public-hostname>/api/v1` (пока не настроен).

API слушает TCP 8181 на всех интерфейсах сервера. В той же домашней сети iPhone подключается напрямую к `192.168.31.45`; VPN не нужен. Этот адрес выдаётся локальной сетью и может измениться после перезагрузки роутера — желательно закрепить DHCP reservation для сервера. Tailscale Serve активен и проксирует HTTPS на `127.0.0.1:8181`. Сертификат обслуживает Tailscale автоматически; отдельный сертификат и тем более private key приложению не нужны. Для доступа из интернета без VPN нужен публичный домен, TLS reverse proxy и безопасная публикация порта; это отдельный deployment, текущий контракт менять не требуется.

Ethernet-профиль Windows сейчас Private. Если iPhone не открывает health endpoint, один раз выполнить PowerShell **от имени администратора**:

```powershell
New-NetFirewallRule -DisplayName "Training API TCP 8181 (Private LAN)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8181 -Profile Private
```

## Авторизация

Все прикладные endpoints используют `Authorization: Bearer <accessToken>`, кроме health probes, Swagger, login, refresh, logout и защищённого отдельным API key Home Assistant endpoint. Публичной регистрации нет. Login: `POST /auth/login`; refresh: `POST /auth/refresh`; logout: `POST /auth/logout`. Access token живёт 15 минут, refresh token — 30 дней. Каждый успешный refresh ротирует refresh token; старый сразу становится недействительным (401). Logout идемпотентно отзывает переданный refresh token без требования действующего access token (204).

На iOS хранить оба токена в Keychain, обновлять access token через single-flight actor, атомарно заменять refresh token и никогда не повторять refresh старым значением. Примеры без настоящих credentials лежат в `examples/auth-*`.

## Контракты и endpoints

Точные required/nullable поля, enums, request/response schemas, security и документированные response codes находятся в `openapi.json`. Реальные JSON-примеры находятся в `examples/`.

Реализованы: auth login/refresh/logout; users/me и authenticated admin user management; exercises CRUD (DELETE архивирует), history, records и library search/import; workouts list/get/create/update, start/complete, добавление exercise, создание/update/complete/skip set, sync; templates list/create/create-workout; statistics/volume; health import/daily; export; bootstrap; Home Assistant body measurements; health/live, health/ready и Swagger. Публичного register endpoint нет.

### Bootstrap

`GET /bootstrap` возвращает `{ workout, exercises, lastHealthSyncAt }`. `examples/bootstrap.response.json` — полный реальный ответ с данными и вложенными exercise/sets. Для стартового экрана отдельно придётся запросить данные, которых bootstrap сейчас не содержит: профиль пользователя, templates, daily health summary, server time и sync cursor. Контракт не менялся. Приоритет выбора workout: InProgress, затем ближайший Planned не старше суток.

### Workouts и sync

Клиент генерирует UUID до отправки. Изменяемые Workout и SetEntry используют целочисленный `version`; при обновлении передаётся `expectedVersion`. Даты — ISO-8601 UTC, веса — decimal.

`POST /workouts/sync` принимает массив `SetSyncCommand` с `id`, `workoutExerciseId`, `expectedVersion`, `value`; `value.completedAt` опционален и передаётся как UTC ISO-8601. Для offline completion клиент передаёт фактическое время; если оно отсутствует, сервер использует текущее UTC. Planned/Skipped очищают `completedAt`. Статистика группирует по времени завершения set, а календарь включает workout по `scheduledAt`. Результат sync — массив `{ id, status, version, current }`. Реальные сценарии:

Редактор текущей тренировки использует `PUT /workouts/{workoutId}/exercises/{workoutExerciseId}` для замены упражнения без пересоздания `WorkoutExercise` и его sets. `DELETE /workouts/{workoutId}/sets/{setId}` удаляет только незавершённый set; Completed set защищён ответом 409.

- `sync-create.request.json` → `sync-create.response.json`: создание set с client UUID, 200.
- точный повтор того же create → `sync-retry.response.json`: 200 со status `existing` и подтверждённой server version.
- `sync-update.request.json` → `sync-update.response.json`: успешное обновление, 200 и новая version.
- устаревшая version → `sync-conflict.response-409.json`: status `conflict`, актуальные version и полный server record в `current`.

При 409 клиент не должен автоматически затирать серверную запись: сохранить local mutation, показать/выполнить merge и повторить с актуальной version. Другие реальные CRUD/start/complete/set/history/records/template ответы также сохранены в `examples/`.

## Health import

`POST /health/samples/import` принимает batch от 1 до 500 элементов. Поддерживаемые `type`: `bodyWeight`, `stepCount`, `activeEnergy`, `basalEnergy`, `heartRate`, `restingHeartRate`, `sleep`, `workout`.

Backend сейчас не валидирует `unit`; iOS должен стабильно использовать: `kg`, `count`, `kcal`, `bpm`, а длительность — `min` (или один заранее выбранный вариант во всём клиенте). `externalId` должен быть стабильным идентификатором исходной HealthKit-записи; рекомендуется UUID HealthKit sample. Уникальность определяется комбинацией `(ownerId, type, sourceBundleId, externalId)`. Дубликаты не создаются и учитываются в `{ created, alreadyExists }`; дубликаты внутри одного batch также схлопываются.

Sleep и workout передаются общей схемой sample: обязательны type/startAt/endAt/externalId; numericValue/unit опциональны; стадии сна или тип активности кладутся в `metadataJson` как JSON-строка. Backend пока не валидирует внутреннюю структуру metadata. Реальные workout import/create/duplicate и daily responses, а также пример sleep лежат в `examples/health-*`.

## Запуск и диагностика

Из корня репозитория:

```powershell
docker compose up --build -d
docker compose ps -a
docker compose logs api --tail 100
Invoke-WebRequest http://127.0.0.1:8181/health/live -UseBasicParsing
Invoke-WebRequest http://100.67.143.48:8181/health/ready -UseBasicParsing
Invoke-WebRequest http://192.168.31.45:8181/health/ready -UseBasicParsing
Invoke-WebRequest http://100.67.143.48:8181/swagger/v1/swagger.json -UseBasicParsing
tailscale status
tailscale serve status
```

Миграции запускаются сервисом `migrate`; `docker compose run --rm migrate` безопасно повторяется. Не использовать `docker compose down -v`, если данные PostgreSQL должны сохраниться.

## Ограничения и требования к iOS

- Прямой HTTP требует ATS exception; рекомендуется Tailscale HTTPS URL, где exception не нужен.
- Отличающийся create с существующим UUID и stale update возвращают 409; точный повтор подтверждается как `existing`.

## Calendar and volume changes (2026-07-30)

- `GET /workouts?from=&to=` uses the half-open UTC interval `[from,to)`, requires both bounds together, limits a range to five years, and returns `CalendarWorkout` including `totalVolumeKg`.
- `GET /statistics/volume?from=&to=&exerciseId=&includeWarmups=` returns SQL-aggregated totals by exercise and UTC day.
- `WorkoutExercise` and `TemplateExercise` include `weightMultiplier`, allowed values `1|2`, default `1`. Template workout creation copies it.
- Volume formula: completed sets with actual values only, `actualWeightKg * actualReps * weightMultiplier`; skipped/planned sets are excluded. Warmups are included unless `includeWarmups=false`.
- Anonymous registration was removed. User creation remains admin-only at `POST /users`.
- `POST /auth/logout` is idempotent and can revoke a refresh token without a valid access token.
- У workout нет DELETE/cancel endpoint.
- Exercise DELETE означает archive.
- Templates поддерживают list/create/create-workout, но не полный CRUD.
- Health units и `metadataJson` структурно не валидируются сервером.
- Base URL должен быть конфигурируемым, без зашитых credentials; Bearer injection, refresh rotation, UUID, version/409 merge и UTC ISO-8601 должны поддерживаться клиентом.
