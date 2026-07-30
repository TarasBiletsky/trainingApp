# Промпт для Codex: backend Training

Создай backend личной системы силовых тренировок. Это self-hosted modular monolith для одного пользователя. Клиенты: нативное iOS-приложение, будущая desktop web-админка и минимальная аварийная mobile web-страница. Сначала покажи короткий план, затем реализуй, запусти сборку/тесты и исправь ошибки.

## Стек и границы

- актуальный стабильный .NET, ASP.NET Core REST API, EF Core, PostgreSQL, OpenAPI;
- Dockerfile и Docker Compose с persistent volume и health checks;
- конфигурация и секреты только через environment variables;
- структурированные логи;
- `/api/v1`, UUID, ISO 8601, UTC;
- модульный монолит. Не добавляй микросервисы, MediatR, generic repository, event bus, CQRS и интерфейсы с одной реализацией без реальной необходимости;
- бизнес-логика не в endpoints/controllers;
- один локальный пользователь, безопасный password hash и cookie auth для web; для iOS — короткоживущий access token + rotating refresh token в Keychain. Без регистрации, ролей и Basic Auth;
- выдай OpenAPI JSON как артефакт: он станет контрактом iOS-клиента.

## Данные

Exercise: Id, Name, Description, MuscleGroup, Equipment, IsArchived, CreatedAt, UpdatedAt.

Workout: Id, Name, ScheduledAt, StartedAt?, CompletedAt?, Status (Planned/InProgress/Completed/Cancelled), Notes, CreatedAt, UpdatedAt, Version.

WorkoutExercise: Id, WorkoutId, ExerciseId, Order, Notes, RestSeconds.

SetEntry: Id, WorkoutExerciseId, Order, Status (Planned/Completed/Skipped), PlannedWeightKg?, PlannedReps?, PlannedRpe?, ActualWeightKg?, ActualReps?, ActualRpe?, IsWarmup, CompletedAt?, Notes, UpdatedAt, Version.

Плановые и фактические значения всегда раздельны. Рекорды вычисляются из истории, а не хранятся как единственная изменяемая истина.

WorkoutTemplate и связанные template exercise/set сущности должны быть отдельны от фактических Workout.

HealthSample: Id, Type, StartAt, EndAt, NumericValue?, Unit?, SourceName?, SourceBundleId?, ExternalId, MetadataJson?, ImportedAt. Unique constraint по `(Type, SourceBundleId, ExternalId)` для идемпотентности. Начальные типы: bodyWeight, stepCount, activeEnergy, basalEnergy, heartRate, restingHeartRate, sleep, workout. API должен принимать батчи данных из iOS; сырые значения сохранять, дневные агрегаты считать запросом/проекцией.

## Первый вертикальный срез API

- login, refresh, logout;
- CRUD упражнений;
- список тренировок по диапазону дат;
- создать/получить/изменить тренировку, начать и завершить её;
- добавить/изменить/завершить/пропустить подход;
- шаблоны и создание Workout из шаблона;
- история упражнения;
- PR: максимальный вес, максимум повторений для конкретного веса, Epley 1RM;
- batch import HealthSample;
- bootstrap endpoint для iOS: текущая/ближайшая тренировка, справочник упражнений и дата последней health-синхронизации.

## Синхронизация iOS

Реализуй простой sync только для тренировок, без универсального sync engine:

- UUID создаёт клиент;
- upsert-команды идемпотентны;
- Version/ETag защищает optimistic concurrency;
- повтор команды не создаёт дубликат;
- конфликт возвращает `409` с актуальной серверной записью;
- сервер никогда молча не затирает введённый пользователем факт;
- один endpoint принимает небольшой batch локальных изменений и возвращает подтверждённые версии;
- удаления пока не синхронизировать: использовать статусы/архивацию.

## Аварийная web-страница

Добавь минимальный responsive web client любым встроенным в ASP.NET способом (Razor Pages предпочтительнее отдельного React build). Только: логин, сегодняшняя тренировка, старт, ввод веса/повторов/RPE, добавить/завершить/пропустить подход, таймер отдыха и завершение тренировки. Никаких графиков, AI, админки или дизайн-системы.

## Health и Home Assistant

HealthKit читает только iOS-приложение; backend принимает нормализованные samples и не изображает прямое подключение к Apple Health.

Также добавь `POST /api/v1/integrations/home-assistant/body-measurements`, защищённый отдельным API key. Payload: externalId, measuredAt, weightKg, bodyFatPercent?, muscleMassKg?, impedance?, source, rawPayload. Endpoint валидирует данные, идемпотентен и отвечает created/alreadyExists/rejected. Добавь пример Home Assistant REST command без жёсткого entity ID.

## Тесты и seed

Минимальные тесты: Epley 1RM, PR по весу, PR повторов при конкретном весе, новый PR, независимость planned/actual, idempotent set sync, conflict response, idempotent health import. Seed: Bench Press, Squat, Romanian Deadlift, Lat Pulldown.

## Результат

Нужны рабочие миграции, `.env.example`, Docker Compose, OpenAPI JSON и README: локальный запуск, production configuration, backup/restore PostgreSQL и пример запросов iOS sync. В конце перечисли реализованное, сознательно отложенное и точные команды проверки. Не подключай OpenAI и не строй AI-модуль сейчас — его контракт определим после появления реальной тренировочной истории.
