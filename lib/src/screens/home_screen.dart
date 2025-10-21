import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/alarm_service.dart';
import '../services/permission_service.dart';
import '../services/settings_service.dart';
import '../widgets/alarm_status_widget.dart';
import '../widgets/clock_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final AlarmService _alarmService;
  bool _isAlarmEnabled = true;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  AudioPlayer? _testPlayer;
  AudioPlayer? _mediaTestPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _startTimer();
    _loadSettings();
    _testPlayer = AudioPlayer()
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
    _testPlayer?.onPlayerStateChanged.listen((state) {
      debugPrint('[Home] _testPlayer state: $state');
    });
    _testPlayer?.onPlayerComplete.listen((_) {
      debugPrint('[Home] _testPlayer complete');
    });
    _mediaTestPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    _mediaTestPlayer?.onPlayerStateChanged.listen((state) {
      debugPrint('[Home] _mediaTestPlayer state: $state');
    });
    _mediaTestPlayer?.onPlayerComplete.listen((_) {
      debugPrint('[Home] _mediaTestPlayer complete');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alarmService.dispose();
    try {
      _testPlayer?.dispose();
    } catch (_) {}
    try {
      _mediaTestPlayer?.dispose();
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _alarmService = AlarmService();
    await PermissionService.requestPermissions();
    // Foreground service start is user-controlled from Settings now
  }

  Future<void> _loadSettings() async {
    final isEnabled = await SettingsService.isAlarmEnabled();
    setState(() {
      _isAlarmEnabled = isEnabled;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      if (mounted) {
        setState(() {
          _currentTime = now;
        });
      }
      if (now.second % 10 == 0) {
        debugPrint('[UI] tick now=${now.toIso8601String()}');
      }

      // Keep foreground notification title in sync while app is in foreground
      try {
        final isRunning = await FlutterForegroundTask.isRunningService;
        if (isRunning) {
          final hh = now.hour.toString().padLeft(2, '0');
          final mm = now.minute.toString().padLeft(2, '0');
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Pip Clock • $hh:$mm',
            notificationText: 'Tap to open',
          );
        }
      } catch (_) {}

      _checkAlarm(now);
    });
  }

  void _checkAlarm(DateTime now) async {
    if (!_isAlarmEnabled) return;
    // Fire at the top of the hour, allow a wider window to avoid missing ticks
    final isTop = now.minute == 0 && now.second <= 10;
    debugPrint(
        '[Home] _checkAlarm now=${now.toIso8601String()} isTop=$isTop isAlarmEnabled=$_isAlarmEnabled');
    if (isTop) {
      try {
        await _alarmService.playAlarm();
        debugPrint('[Home] _checkAlarm triggered playAlarm');
      } catch (e, st) {
        debugPrint('[Home] _checkAlarm playAlarm error: $e\n$st');
      }
    }
  }

  void _toggleAlarm() async {
    final newState = !_isAlarmEnabled;
    await SettingsService.setAlarmEnabled(newState);
    setState(() {
      _isAlarmEnabled = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pip Clock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClockWidget(currentTime: _currentTime),
              const SizedBox(height: 32),
              // Moved beep toggle to Settings
            ],
          ),
        ),
      ),
    );
  }
}
