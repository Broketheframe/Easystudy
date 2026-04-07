# Архитектурная документация EasyStudy

Дата актуализации: 2026-04-07

## 1. Контекст
EasyStudy — кроссплатформенное Flutter-приложение для подготовки по билетам. Архитектура сочетает:
- локальное состояние прогресса и настроек,
- облачную синхронизацию через Firebase,
- UI-потоки обучения и статистики.

## 2. Архитектурные слои
### 2.1 Presentation (UI)
- Экраны (`lib/screens/*`) и переиспользуемые виджеты (`lib/widgets/*`).
- Основной контейнер: `HomeScreen` c `PageView` на 4 вкладки:
  - `ShopScreen`
  - `MapScreen`
  - `AchievementsScreen`
  - `GlobalStatsScreen`

### 2.2 Domain + State
- Единый источник истины: `GameState` (`ChangeNotifier`).
- Бизнес-логика:
  - прогресс по билетам,
  - XP/уровни/монеты,
  - достижения,
  - настройки и визуальная кастомизация.

### 2.3 Infrastructure
- Локальная персистентность: `SharedPreferences`.
- Облако: Firebase Authentication + Cloud Firestore.
- Аудио: `AudioManager` (singleton поверх `audioplayers`).

## 3. Композиция приложения
Точка входа (`main.dart`) выполняет:
1. Инициализацию Flutter bindings.
2. Инициализацию Firebase (`DefaultFirebaseOptions.currentPlatform`).
3. Загрузку `GameState` из локального хранилища.
4. Запуск `AccountSyncService`.
5. Создание `Provider<GameState>` и `MaterialApp`.

Маршруты:
- `/welcome`
- `/home`
- `/map`

## 4. Модель состояния
`GameState` разделен на расширения (`part`) и покрывает:
- профиль: `nickname`, `playerLevel`, `currentXP`, `coins`;
- настройки: звук/музыка/вибрация/громкость/тема;
- прогресс: текущий предмет, уровни, разблокировка, статусы билетов;
- магазин: owned/selected backgrounds/frames/avatars;
- достижения: `collectedAchievements`;
- метрики времени: `_totalPlaySeconds`.

Особенности:
- debounce-сохранение (`2 секунды`) и периодическое сохранение (`5 минут`);
- безопасная сериализация прогресса билетов (`TicketProgress.serialize`);
- сохранение состояния при lifecycle-событиях.

## 5. Архитектура аккаунта и sync
### 5.1 AccountService
Источник данных:
- FirebaseAuth для регистрации/входа/выхода.
- Firestore (`users/{uid}`) для хранения `config`.

Поток:
1. `register` -> создать пользователя -> отправить email verification -> сохранить конфиг -> sign out.
2. `login` -> проверить `emailVerified` -> скачать и применить конфиг (или создать удаленный).
3. `syncUp` / `syncDown` -> ручные операции синхронизации.

### 5.2 AccountSyncService
Фоновая синхронизация:
- слушает изменения `GameState`,
- слушает `authStateChanges`,
- выполняет flush по debounce и по таймеру,
- отправляет данные при уходе приложения в фон.

При новой авторизованной сессии:
- сначала `syncDown`,
- если удаленной конфигурации нет -> `syncUp`.

## 6. Ключевые пользовательские потоки
### 6.1 Первый запуск
1. `GameState.isFirstLaunch()`.
2. Показ `WelcomeScreen`.
3. Переход на `HomeScreen`.

### 6.2 Прохождение билета
1. `MapScreen` открывает `QuizScreen`.
2. `QuizScreen` грузит билет из `assets/questions/software_engineering.json`.
3. `SubquestionScreen` сохраняет ответы в `GameState.saveAnswer`.
4. После полного прохождения `finishTicket` начисляет XP, обновляет уровень и открывает следующий билет.
5. Показывается `TicketStatsScreen` со слабыми местами.

### 6.3 Глобальная статистика
1. `GlobalStatsScreen` доступен только авторизованным и подтвержденным пользователям.
2. Агрегация строится на основе `users/*/config.ticketsProgress`.
3. Текущие метрики считаются для chemistry-набора (по индексу предмета в сериализации).

## 7. Контент и масштабирование
- В модели состояния предусмотрено 3 предмета (`chemistry`, `math`, `history`).
- В текущем UI и контенте фактически используется один набор вопросов.
- Карта фиксирована на 25 уровней.

## 8. Визуальная система
- `AppTheme` поддерживает:
  - тему `classic` и `pulse`,
  - режимы `system/light/dark`.
- Цветовая система реализована через `ThemeExtension<AppColors>`.
- Выбранный фон хранится в `GameState`, а обновление UI дополнительно триггерится через `ValueNotifier<String> currentBackground`.

## 9. Legacy компоненты
- `backend/*` (FastAPI + file-based storage) остается в репозитории как legacy MVP backend.
- `lib/data/backend_client.dart` сохранен, но в текущем основном клиентском потоке не используется.

## 10. Архитектурные риски
- Нет стратегии merge-конфликтов между локальным и облачным прогрессом.
- Наличие двух подходов к backend (Firebase и legacy FastAPI) повышает стоимость поддержки.
- Linux-платформа не настроена в `firebase_options.dart`.
- Отсутствуют автоматизированные тесты.
