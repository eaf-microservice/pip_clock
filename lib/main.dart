import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/services/permission_service.dart';
import 'src/services/settings_service.dart';
import 'src/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Request notification permission
    await PermissionService.requestPermissions();
  } catch (_) {}
  try {
    // If user enabled auto-start, ensure foreground service is initialized on app start.
    final autoStart = await SettingsService.getAutoStartEnabled();
    if (autoStart) {
      try {
        await BackgroundService.initialize();
      } catch (_) {}
    }
  } catch (_) {}
  runApp(const PipClockApp());
}
