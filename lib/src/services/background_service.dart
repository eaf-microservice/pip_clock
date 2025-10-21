import 'dart:async';
import 'dart:isolate';
import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundService {
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'pip_clock_channel',
        channelName: 'Pip Clock Service',
        channelDescription: 'Notification for Pip Clock',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.MAX,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
    );

    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    await FlutterForegroundTask.startService(
      notificationTitle: 'Pip Clock • $hh:$mm',
      notificationText: 'Tap to open',
      callback: startCallback,
    );
  }

  @pragma('vm:entry-point')
  static void startCallback() {
    FlutterForegroundTask.setTaskHandler(PipClockTaskHandler());
  }
}

class PipClockTaskHandler extends TaskHandler {
  DateTime? _lastHourPlayed;
  AudioPlayer? _player;
  Timer? _minuteTimer;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _player = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      );

    await _updateTitle();

    _minuteTimer?.cancel();
    // Reduce interval to 1 second for more current notification time
    _minuteTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _updateTitle();
      final now = DateTime.now();
      final isTop = now.minute == 0 && now.second <= 10;
      final already = _lastHourPlayed != null &&
          _lastHourPlayed!.year == now.year &&
          _lastHourPlayed!.month == now.month &&
          _lastHourPlayed!.day == now.day &&
          _lastHourPlayed!.hour == now.hour;
      if (isTop && !already) {
        // Try to notify main isolate if present
        try {
          sendPort?.send('play_hour');
        } catch (_) {}
        // Also play alarm directly from background task so it works when app is closed
        try {
          final selectedPath = await SettingsService.getAlarmSound();
          await _player?.setReleaseMode(ReleaseMode.stop);
          await _player?.setVolume(1.0);
          await _player?.play(AssetSource(selectedPath));
        } catch (e) {
          try {
            await _player?.setReleaseMode(ReleaseMode.stop);
            await _player?.setVolume(1.0);
            await _player?.play(AssetSource('sounds/default.mp3'));
          } catch (_) {}
        }
        _lastHourPlayed = now;
      }
    });
  }

  Future<void> _updateTitle() async {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    // Diagnostic log to confirm background task is running
    print('[BackgroundService] Updating notification: $hh:$mm');
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Pip Clock • $hh:$mm',
      notificationText: 'Tap to open',
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    await _updateTitle();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    try {
      _minuteTimer?.cancel();
    } catch (_) {}
    try {
      await _player?.dispose();
    } catch (_) {}
  }
}
