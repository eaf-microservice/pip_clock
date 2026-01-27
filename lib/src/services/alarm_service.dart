import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'settings_service.dart';

/// Service responsible for managing alarm functionality
class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer()
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

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  DateTime? _lastAlarmTime;

  AlarmService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  /// Plays the alarm sound if not played in the last minute
  Future<void> playAlarm() async {
    final now = DateTime.now();
    if (_lastAlarmTime == null ||
        now.difference(_lastAlarmTime!) > const Duration(minutes: 1)) {
      _lastAlarmTime = now;
      try {
        final selectedPath = await SettingsService.getAlarmSound();
        debugPrint('[AlarmService] selectedPath: $selectedPath');
        debugPrint('[AlarmService] playing alarm from UI/background');
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(AssetSource(selectedPath));
        debugPrint('[AlarmService] alarm played');
      } catch (e) {
        debugPrint('[AlarmService] playAlarm error: $e');
        // Fallback to default tone if selected asset is missing
        try {
          await _audioPlayer.setReleaseMode(ReleaseMode.stop);
          await _audioPlayer.setVolume(1.0);
          await _audioPlayer.play(AssetSource('sounds/default.mp3'));
          debugPrint('[AlarmService] fallback default played');
        } catch (e2) {
          debugPrint('[AlarmService] fallback play error: $e2');
          rethrow;
        }
      }
    }
  }

  /// Schedules a local notification for the next top of the hour
  Future<void> scheduleNextHourNotification() async {
    // Only needed for iOS really, but harmless on Android
    // if (!Platform.isIOS) return;

    final now = DateTime.now();
    var nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);

    // If we are very close to the hour (e.g. 59:59), make sure we don't schedule for the past
    if (nextHour.isBefore(now)) {
      nextHour = nextHour.add(const Duration(hours: 1));
    }

    final tzNextHour = tz.TZDateTime.from(nextHour, tz.local);

    debugPrint('[AlarmService] Scheduling notification for $tzNextHour');

    await _notificationsPlugin.zonedSchedule(
      0,
      'Pip Clock',
      'It is ${nextHour.hour}:00',
      tzNextHour,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBanner: true,
          sound: 'default', // Ideally we'd use the selected custom sound
        ),
        android: AndroidNotificationDetails(
          'pip_clock_alarm',
          'Hourly Alarm',
          channelDescription: 'Notifications for hourly alarms',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents
          .time, // Valid for recurring, but here we schedule one-shot for next hour usually.
    );
  }

  /// Cancels all scheduled notifications
  Future<void> cancelNotifications() async {
    debugPrint('[AlarmService] Cancelling all notifications');
    await _notificationsPlugin.cancelAll();
  }

  /// Stops the currently playing alarm
  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }

  /// Disposes resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
