# Training

Нативный iOS-клиент TrainingApp: SwiftUI, SwiftData, HealthKit, offline-хранение и REST-интеграция с backend из этого же репозитория.

## Первый запуск

1. Установить Xcode из App Store и открыть его один раз.
2. Установить XcodeGen: `brew install xcodegen`.
3. В этой папке выполнить `xcodegen generate`.
4. Открыть `TrainingApp.xcodeproj`.
5. В Signing & Capabilities выбрать свой Personal Team и уникальный Bundle Identifier.
6. Проверить, что добавлена capability HealthKit, выбрать iPhone и нажать Run.

Если iPhone Simulator не виден, докачать iOS runtime в `Xcode → Settings → Components`.

Актуальные API-контракты и примеры лежат в [`../../ios-handoff`](../../ios-handoff). Пароли, token, signing certificates и developer-specific Xcode data нельзя коммитить.

Адрес backend в домашней сети: `http://192.168.31.45:8181/api/v1/`. Желательно закрепить `192.168.31.45` за PC в DHCP-настройках роутера.
