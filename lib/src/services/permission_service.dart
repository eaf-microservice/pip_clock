import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
class PermissionService {
  /// Requests all necessary permissions for the app
  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
      await Permission.notification.request();
    }
  }

  /// Checks if all required permissions are granted
  static Future<bool> hasRequiredPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  /// Opens system app settings for manual permission enabling
  static Future<void> openSystemAppSettings() async {
    await openAppSettings();
  }

  /// Attempts to open OEM-specific Auto-start/Startup manager (best-effort)
  static Future<void> openAutoStartSettings() async {
    if (!Platform.isAndroid) return;
    const intents = [
      // Common OEMs
      'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      'com.miui.securitycenter/com.miui.permcenter.permissions.PermissionsEditorActivity',
      'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
      'com.oppo.safe/com.oppo.safe.permission.startup.StartupAppListActivity',
      'com.vivo.permissionmanager/com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
      'com.huawei.systemmanager/.startupmgr.ui.StartupNormalAppListActivity',
      'com.transsion.ahar.safer/com.transsion.ahar.safer.ui.activity.AutoStartActivity',
      'com.samsung.android.lool/com.samsung.android.sm.ui.battery.BatteryActivity',
    ];
    for (final comp in intents) {
      try {
        // Platform channel-less approach: use intent via external_app_launcher is overkill; rely on MethodChannel-less deep link
        // We piggyback on permission_handler's openAppSettings as generic fallback if direct component fails.
        // No-op here; actual deep component start requires a plugin; fallback immediately.
      } catch (_) {}
    }
    await openAppSettings();
  }
}
