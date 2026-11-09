# Phase 2: Standalone Android Home Screen Widget Implementation Plan

> **For agentic workers:** Implementing via TDD task-by-task with Flutter tests, Kotlin JUnit tests, release build check, and live Galaxy A51 verification.

**Goal:** Enable `Tarang69WidgetProvider` on Android to recalculate current/next periods, breaks, weekends, bell plans (`plan1`–`plan4`), and live countdowns independently when the Flutter app is closed, refreshing automatically at period boundaries.

**Architecture:** Flutter caches raw `schedule_json` and `selected_plan_id` into `HomeWidgetPreferences` whenever loaded, switched, or synced from GitHub. Native Android reads those preferences (falling back to APK asset `flutter_assets/assets/data/schedule.json`), computes status via a pure Kotlin `WidgetScheduleCalculator`, renders live countdown via `Chronometer` when exact alarms are available (or minute `TextView` fallback), and schedules `AlarmManager` transition broadcasts at period/break boundaries and midnight.

**Tech Stack:** Dart/Flutter (`home_widget`, `flutter_test`), Kotlin (`org.json`, `AlarmManager`, `AppWidgetProvider`, `RemoteViews`, `Chronometer`), JUnit 4 + `org.json:json` (unit tests only).

## Global Constraints
- Maintain parity with `ScheduleService.getCurrentStatus` (`lib/services/schedule_service.dart`).
- Keep widget UI minimal 3×1 light card layout with room badge hidden (`View.GONE`).
- Preserve Time Simulator preview (`simulated_active == true`) without breaking normal real-time standalone behavior.
- Never show negative countdown values on `Chronometer`; fall back to `TextView` if exact boundary alarms cannot be scheduled.

## Review Focus
- Before-school countdown before period 1 (`08:00` on `plan1`) transitions cleanly to period 1 at start minute (`08:20`).
- Double/triple periods (`คาบที่ 3 - 4`, `คาบที่ 6 - 8`) compute full combined duration and transition at the combined end time (`12:00`, `16:10`).
- Break & extended lunch (`plan4` lunch `11:20–13:10`) calculate correct break status and next subject.
- Friday after-school transitions at midnight to Saturday weekend holiday; Sunday transitions at Monday `00:00` to before-school state.
- Cold widget placement before opening the Flutter app once falls back to `flutter_assets/assets/data/schedule.json` cleanly; malformed JSON returns `null` safely.

---

### Task 1: Sync Raw Schedule JSON & Plan State from Flutter to `HomeWidgetPreferences`
- **Files:** `lib/services/widget_service.dart`, `lib/services/schedule_service.dart`, `test/schedule_test.dart`
- **Steps:**
  1. Write failing Dart test verifying `ScheduleService` preserves `rawScheduleJson` across asset load & `fetchRemoteUpdate` and supplies it with `selectedPlanId` to widget updates.
  2. Run `flutter test test/schedule_test.dart` -> confirm RED.
  3. Extend `WidgetService.updateWidgetData` with optional `scheduleJson`, `selectedPlanId`, `isSimulatedTime` parameters and pass them from `ScheduleService`.
  4. Run `flutter test` & `flutter analyze` -> confirm GREEN.

### Task 2: Implement Pure Kotlin `WidgetScheduleCalculator` (TDD)
- **Files:** `android/app/build.gradle.kts` (test deps only), `android/app/src/main/kotlin/com/example/tarang69/WidgetScheduleCalculator.kt`, `android/app/src/test/kotlin/com/example/tarang69/WidgetScheduleCalculatorTest.kt`
- **Steps:**
  1. Add `junit` & `org.json:json` under `testImplementation` in `android/app/build.gradle.kts` and write failing JUnit tests covering before-school, morning break, double period, lunch, after-school, weekend, `plan4`, midnight transition timestamps, and malformed JSON.
  2. Run `.\android\gradlew.bat :app:testDebugUnitTest` -> confirm RED.
  3. Implement minimal `WidgetScheduleCalculator` with `calculate(jsonString, planId, nowMillis, timeZone)` matching Dart `ScheduleService`.
  4. Run `.\android\gradlew.bat :app:testDebugUnitTest` -> confirm GREEN.

### Task 3: Wire Self-Updating `Tarang69WidgetProvider`, Live `Chronometer`, & Boundary Alarms
- **Files:** `android/app/src/main/res/layout/widget_layout.xml`, `android/app/src/main/kotlin/com/example/tarang69/Tarang69WidgetProvider.kt`, `android/app/src/main/AndroidManifest.xml`
- **Steps:**
  1. Add `widget_chronometer` (`Chronometer`, `countDown="true"`, `visibility="gone"`) alongside `widget_countdown_badge` in `widget_layout.xml`.
  2. Update `Tarang69WidgetProvider` to compute live `WidgetStatus` (unless `simulated_active == true`), toggle live `Chronometer` vs static `TextView` safely, schedule next boundary/refresh alarm (`nextTransitionMillis + 500L`), and cancel alarms in `onDisabled`.
  3. Add `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, and broadcast intent actions (`BOOT_COMPLETED`, `TIME_SET`, `TIMEZONE_CHANGED`, `DATE_CHANGED`, `MY_PACKAGE_REPLACED`, `ACTION_WIDGET_REFRESH`) to `AndroidManifest.xml`.
  4. Run `flutter analyze`, `flutter test`, `.\android\gradlew.bat :app:testDebugUnitTest`, and `flutter build apk --release` to verify end-to-end compilation and tests, then deploy and verify on Galaxy A51.
