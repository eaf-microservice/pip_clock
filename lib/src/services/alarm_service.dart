import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
  DateTime? _lastAlarmTime;

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

  /// Stops the currently playing alarm
  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }

  /// Disposes resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
