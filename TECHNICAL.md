# Техническая документация EasyStudy

Дата актуализации: 2026-04-07

## 1. Назначение
Документ описывает текущее техническое состояние приложения: зависимости, запуск, архитектурные компоненты, хранение данных и ограничения.

## 2. Технологический стек
- Flutter / Dart (`sdk: ^3.9.2`)
- State management: `provider`
- Локальное хранилище: `shared_preferences`
- Аутентификация и облачное хранилище: `firebase_auth`, `cloud_firestore`, `firebase_core`
- Аудио: `audioplayers`
- Дополнительно: `vibration`, `http`, `shimmer`

## 3. Текущее состояние инфраструктуры
- Основной продакшн-поток синхронизации в клиенте реализован через Firebase.
- В репозитории остается legacy FastAPI backend (`backend/*`) и legacy клиент `lib/data/backend_client.dart`.
- Legacy backend не используется текущим UI-потоком аккаунта и синхронизации.

## 4. Сборка и запуск клиента
```bash
flutter pub get
flutter run
```

Сборка релиза:
```bash
flutter build apk
flutter build ios
flutter build web
flutter build macos
flutter build windows
```

Примечание по платформам:
- `DefaultFirebaseOptions` настроен для Android, iOS, Web, macOS, Windows.
- Для Linux сейчас выбрасывается `UnsupportedError`.

## 5. Точка входа и инициализация
`lib/main.dart`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp(...)`
3. `GameState.load()`
4. `GameState.isFirstLaunch()`
5. `AccountSyncService(state: gameState).start()`
6. Запуск `MaterialApp` с `Provider<GameState>`

Маршруты:
- `/welcome` -> `WelcomeScreen`
- `/home` -> `HomeScreen`
- `/map` -> `MapScreen`

## 6. Управление состоянием (`GameState`)
`GameState` разнесен по `part`-файлам:
- `state_core.dart` - основные поля, загрузка, жизненный цикл.
- `state_storage.dart` - запись в `SharedPreferences`.
- `state_settings.dart` - настройки (звук/музыка/вибрация/тема/предмет).
- `state_tickets.dart` - ответы и прогресс билетов.
- `state_progress.dart` - XP/монеты/разблокировка.
- `state_shop.dart` - покупки и выбор предметов кастомизации.
- `state_config.dart` - экспорт/импорт облачного конфига.
- `state_reset.dart` - сброс прогресса.

Ключевые особенности:
- Автосохранение: debounce `2s` + периодическое сохранение `5m`.
- Трекинг времени игры: `_totalPlaySeconds` с фиксацией при lifecycle-событиях.
- XP за завершение билета: `50`.
- Порог уровня: `150 XP`.
- Награда монетами за уровень: `(((level - 1) ~/ 5) + 1) * 100`.

## 7. Формат прогресса билетов
`TicketProgress.serialize()` сохраняет строку формата:
`subjectIndex|ticketNumber|lastAnsweredIndex|isCompleted|q1:v1,q2:v2,...`

Где `v`:
- `1` -> правильный ответ
- `0` -> неправильный ответ

## 8. Аккаунт и синхронизация
### 8.1 `AccountService`
- `register(...)`: создает Firebase-пользователя, отправляет verification email, сохраняет конфиг в Firestore, выполняет sign out.
- `login(...)`: вход + проверка `emailVerified`; при наличии удаленного конфига применяет его в `GameState`.
- `syncUp(...)`: выгрузка локального конфига.
- `syncDown(...)`: загрузка удаленного конфига.
- `fetchGlobalTicketStats(...)`: собирает агрегаты по другим аккаунтам.

Firestore модель:
- Коллекция: `users`
- Документ: `{uid}`
- Поля: `config`, `updatedAt`, `version`

### 8.2 `AccountSyncService`
- Подписывается на `authStateChanges`.
- Ставит состояние в dirty при изменениях `GameState`.
- Выполняет:
  - debounce-синхронизацию (`2s`),
  - периодическую синхронизацию (`5m`),
  - синхронизацию при уходе приложения в фон.
- При новой сессии пользователя: сначала `syncDown`, если удаленного конфига нет -> `syncUp`.

## 9. UI и пользовательские потоки
`HomeScreen` содержит `PageView` из 4 экранов:
1. `ShopScreen`
2. `MapScreen`
3. `AchievementsScreen`
4. `GlobalStatsScreen`

Ключевые экраны:
- `MapScreen`: карта из 25 уровней/билетов, запуск `QuizScreen`.
- `QuizScreen`: описание билета, теория, прогресс, переход в `SubquestionScreen`.
- `SubquestionScreen`: прохождение подвопросов с объяснениями и повторными попытками.
- `TicketStatsScreen`: итог по билету и список слабых мест.
- `SettingsScreen`: настройки темы/аудио и управление аккаунтом.

## 10. Контент
- Источник вопросов: `assets/questions/software_engineering.json`.
- В модели есть 3 предмета (`chemistry`, `math`, `history`), но текущий UI и статистика привязаны к одному фактическому набору контента.

## 11. Аудио
`AudioManager` (singleton):
- Фоновая музыка (loop) из `assets/audio/background_music.mp3`.
- Эффекты: `tap`, `swipe`.
- Управление через `setMusicEnabled`, `setSoundEnabled`, `setMusicVolume`, `setSoundVolume`.

## 12. Тема
`lib/theme/app_theme.dart`:
- Два стиля: `classic` и `pulse`.
- Режимы: `system`, `light`, `dark`.
- Цвета инкапсулированы в `ThemeExtension<AppColors>`.

## 13. Ограничения и технический долг
- Конфликты между локальными и облачными изменениями явно не разрешаются (последняя запись побеждает).
- В `lib/data` остается неиспользуемый legacy `BackendClient`.
- Linux-платформа не настроена в `firebase_options.dart`.
- Автотесты в репозитории отсутствуют.
