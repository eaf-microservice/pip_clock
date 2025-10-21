import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings and preferences
class SettingsService {
  static const String _alarmSoundKey = 'alarm_sound';
  static const String _autoStartKey = 'auto_start_enabled';
  static const String _alarmEnabledKey = 'alarm_enabled';
  static const String _themeModeKey = 'theme_mode';

  /// Gets the current alarm sound path
  static Future<String> getAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_alarmSoundKey);
    final normalized = _normalizeAssetPath(stored);
    return normalized ?? 'sounds/default.mp3';
  }

  /// Sets the alarm sound path
  static Future<void> setAlarmSound(String soundPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alarmSoundKey, _normalizeAssetPath(soundPath) ?? soundPath);
  }

  static Future<bool> getAutoStartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoStartKey) ?? false;
  }

  static Future<void> setAutoStartEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoStartKey, enabled);
  }

  /// Ensures stored and returned asset keys include the assets/ prefix
  static String? _normalizeAssetPath(String? path) {
    if (path == null || path.isEmpty) return path;
    // For audioplayers AssetSource, pass keys relative to Flutter assets root (no leading 'assets/')
    if (path.startsWith('assets/sounds/')) return path.substring('assets/'.length);
    if (path.startsWith('sounds/')) return path;
    return path;
  }

  /// Checks if the alarm is enabled
  static Future<bool> isAlarmEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alarmEnabledKey) ?? true;
  }

  /// Enables or disables the alarm
  static Future<void> setAlarmEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alarmEnabledKey, enabled);
  }

  /// Gets the current theme mode (light/dark)
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  /// Sets the theme mode
  static Future<void> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode);
  }
}
