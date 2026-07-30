# Prompt for server Codex: calendar and training volume

Доработай существующий Training API для iOS-календаря тренировок и грубой статистики тренировочного объёма. Работай в текущей архитектуре, не переписывай backend и не добавляй новые framework/абстракции без необходимости. Не удаляй production-данные и не используй `docker compose down -v`.

## 1. Множитель веса упражнения

Добавь в `WorkoutExercise` поле `WeightMultiplier` (`int`, default `1`, допустимые значения только `1` и `2`). Множитель `2` используется, когда вес вводится для одной гантели. Не изменяй сами `ActualWeightKg` и `PlannedWeightKg`.

Добавь то же поле в `TemplateExercise`, чтобы оно переносилось в Workout при создании из шаблона.

Создай безопасную EF migration: все существующие записи получают `1`. Добавь DB check constraint и request validation для `1|2`.

## 2. Формула объёма

Считать только Completed sets, у которых есть actual weight и reps:

`setVolumeKg = ActualWeightKg * ActualReps * WorkoutExercise.WeightMultiplier`

Не включать Planned/Skipped sets. Warmup по умолчанию включать, но в API статистики добавить query `includeWarmups` с default `true`. Вычислять из истории, не хранить mutable total в таблице.

## 3. Calendar API

Проверь существующий `GET /api/v1/workouts`. Он должен принимать `from` и `to` как ISO-8601 UTC, возвращать тренировки текущего user в интервале `[from, to)` и не загружать лишние recursive navigation properties. Если это уже работает, не создавай новый endpoint.

Календарь iOS должен иметь возможность:

- загрузить все тренировки месяца;
- видеть status и total volume каждой тренировки;
- создать Planned workout на выбранную дату через существующий POST workouts.

Добавь в response DTO workout вычисляемое `totalVolumeKg`, если это не создаёт recursive/тяжёлый query. Иначе добавь его в лёгкий calendar DTO.

## 4. Statistics API

Добавь `GET /api/v1/statistics/volume`:

Query:

- `from` required UTC;
- `to` required UTC, exclusive;
- `exerciseId` optional;
- `includeWarmups` optional, default `true`;
- валидация `from < to` и разумный максимальный interval, например 5 лет.

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

Все результаты строго scoped текущим user. Агрегируй SQL/базой, не загружай всю историю в память.

## 5. Sync и контракты

- Включи `weightMultiplier` в WorkoutExercise read/write DTO, template DTO и bootstrap.
- Если workout-exercise ещё не поддерживает optimistic concurrency, не строй универсальный sync engine: добавь минимальный PUT/action для смены multiplier с expected version либо расширить текущий DTO, если version уже есть.
- Не меняй planned/actual данные при смене multiplier.
- Исправь точный retry `sync create`, чтобы он возвращал idempotent success/existing result, а не `409`, если server record совпадает с повтором. Настоящий conflict с другими данными должен остать `409`.

## 6. Tests

Добавь тесты:

- multiplier default/migration = 1;
- validation rejects values outside 1/2;
- dumbbell volume doubles, barbell does not;
- skipped/planned sets excluded;
- warmup include/exclude;
- user isolation;
- `[from,to)` date boundaries;
- template copies multiplier;
- calendar response volume;
- exact sync-create retry is idempotent, different payload remains conflict.

Запусти build, tests, EF migration на тестовой/текущей DB без потери данных и smoke tests через реальный HTTP API.

## 7. Handoff для iOS

После запуска реального API пересоздай папку `ios-handoff` без секретов. Положи туда:

- актуальный `openapi.json`, выгруженный из runtime Swagger, не отредактированный вручную;
- `IOS_BACKEND_HANDOFF.md` с LAN/Tailscale URL, migration status, формулой объёма, date semantics, enum и sync rules;
- реальные обезличенные examples: month workouts response, create workout, workout with multiplier 2, statistics response, template multiplier, sync retry success и sync conflict;
- точный список изменённых endpoints/DTO;
- все известные ограничения.

В финальном ответе сообщи абсолютный путь к `ios-handoff`, какие migration/build/tests/smoke checks прошли, и что именно должен изменить iOS-клиент.
