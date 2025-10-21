<!-- Copilot / AI agent instructions for the pip_oclock Flutter app -->

# Pip Clock — AI coding agent instructions

Short mission: maintain and evolve a small Flutter app that plays an hourly chime and optionally runs a foreground service on Android.

What this repo contains (quick):

- Flutter app root: `lib/main.dart` → `lib/src/app.dart` (app entry + theme bootstrapping).
- UI: `lib/src/screens/*` and `lib/src/widgets/*` (HomeScreen, SettingsScreen, ClockWidget, AlarmStatusWidget).
- Services: `lib/src/services/*` (AlarmService, BackgroundService, SettingsService, PermissionService).
- Theme: `lib/src/theme/*` (AppTheme, ThemeController using Provider).
- Assets: `assets/` (audio in `assets/sounds/`, background `assets/bg.jpg`). See `pubspec.yaml`.

Key patterns and project-specific rules (do not change lightly):

- Foreground/background behavior is Android-first. `BackgroundService` uses `flutter_foreground_task` and defines
  a `@pragma('vm:entry-point') static void startCallback()` — preserving this pragma is critical when editing startup code.
- Audio playback uses `audioplayers` with `AssetSource(...)`. `SettingsService._normalizeAssetPath` returns paths like
  `sounds/default.mp3` (note: AssetSource expects paths relative to `assets/`, without leading `assets/`). When adding new sound files, update `pubspec.yaml`'s `assets:` and keep the stored keys consistent with this normalization.
- Settings live in `SharedPreferences` via `SettingsService`. Prefer adding getters/setters to `SettingsService` for any new persisted values.
- Permission checks and OEM battery hints live in `PermissionService` and `SettingsScreen` — Android-only special casing exists (see `Platform.isAndroid` checks).
- Theme is managed with a `ThemeController` (Provider). When changing theme persistence, update `lib/src/theme/theme_controller.dart` and `lib/src/app.dart` initialization.

Integration and edge cases to watch for:

- Foreground service needs a real Android device to fully test; emulator behaviour is limited. When changing `flutter_foreground_task` usage or Android manifest, test on device.
- Audio assets missing → code uses fallbacks (see `AlarmService.playAlarm()` and `SettingsScreen` preview logic). When modifying playback code, keep the fallback behavior intact.
- Many places swallow exceptions intentionally (try/catch { } ). Preserve these guards unless intentionally replacing with explicit error handling and logging.

Common dev workflows / commands (how to build, run, and test locally):

- Install deps: `flutter pub get`
- Analyze: `flutter analyze` (project uses `flutter_lints`)
- Run app on Android device: `flutter run -d <device-id>` (foreground service testing requires physical Android device)
- Run tests: `flutter test` (there is `test/widget_test.dart`)
- Format code: `dart format .`

Files to reference when making changes (examples):

- `lib/src/services/background_service.dart` — foreground task init, `startCallback` entry.
- `lib/src/services/alarm_service.dart` — audio playback + fallback behavior.
- `lib/src/services/settings_service.dart` — asset path normalization and SharedPreferences keys.
- `lib/src/screens/settings_screen.dart` — UI actions that call service methods (sound preview, toggling foreground service).
- `lib/main.dart` — initial permission request via `PermissionService.requestPermissions()` (wrapped in try/catch).

Editing guidelines for AI agents:

- Preserve platform entry points and annotations: keep `@pragma('vm:entry-point')` and any public APIs used by `flutter_foreground_task`.
- When changing asset filenames or paths, update `pubspec.yaml` and `SettingsService._normalizeAssetPath` expectations.
- Prefer adding small, focused tests for behavioral changes. There's one widget test; add targeted unit tests under `test/` for new logic.
- Keep log/debug lines (use `debugPrint` or `print`) when touching audio/background code to ease manual device testing.

If you need more context or want me to update/expand these instructions, tell me which area to expand (e.g., Android manifest, CI setup, or adding a new service).
