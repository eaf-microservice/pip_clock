import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/alarm_service.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/theme_controller.dart';
import '../services/permission_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedTheme;
  String? _selectedSound;
  bool _isLoading = true;
  bool _autoStart = false;
  AudioPlayer? _previewPlayer;

  final List<Map<String, String>> _themeOptions = [
    {'value': 'system', 'label': 'System Default'},
    {'value': 'light', 'label': 'Light'},
    {'value': 'dark', 'label': 'Dark'},
  ];

  final List<Map<String, String>> _soundOptions = [
    {'value': 'sounds/default.mp3', 'label': 'Default Alarm'},
    {'value': 'sounds/chime.mp3', 'label': 'Chime'},
    {'value': 'sounds/beep.mp3', 'label': 'Beep'},
  ];

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer()
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
    _loadSettings();
  }

  @override
  void dispose() {
    try {
      _previewPlayer?.stop();
    } catch (_) {}
    try {
      _previewPlayer?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final themeMode = await SettingsService.getThemeMode();
    final alarmSound = await SettingsService.getAlarmSound();
    final autoStart = await SettingsService.getAutoStartEnabled();

    if (mounted) {
      setState(() {
        _selectedTheme = themeMode;
        _selectedSound = alarmSound;
        _isLoading = false;
        _autoStart = autoStart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildAutoStartSection(),
                _buildThemeSection(),
                _buildSoundSection(),
                _buildServiceToggleSection(),
                _buildBatteryHelpSection(),
                _buildDeveloperCard(),
              ],
            ),
    );
  }

  Widget _buildDeveloperCard() {
    const developerName = 'EAF Microservice';
    const developerEmail = 'EAF.microservice@gmail.com';
    const developerWebsite = 'https://eaf-microservice.netlify.app/';
    const appVersion = '1.1.6';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Developer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Name: $developerName'),
            const SizedBox(height: 4),
            Text('Email: $developerEmail'),
            const SizedBox(height: 4),
            Text('Website: $developerWebsite'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                        const ClipboardData(text: developerEmail));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Developer email copied')));
                    }
                  },
                  child: const Text('Copy email'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Pip Clock',
                      applicationVersion: appVersion,
                      children: [
                        const SizedBox(height: 8),
                        Text('Developer: $developerName'),
                        Text('Website: $developerWebsite'),
                      ],
                    );
                  },
                  child: const Text('About'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoStartSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SwitchListTile(
        title: const Text('Auto-start Pip clock'),
        subtitle: const Text('Start background service automatically on boot'),
        value: _autoStart,
        onChanged: (value) async {
          await SettingsService.setAutoStartEnabled(value);
          setState(() {
            _autoStart = value;
          });
        },
      ),
    );
  }

  Widget _buildServiceToggleSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FutureBuilder<bool>(
        future: FlutterForegroundTask.isRunningService,
        initialData: false,
        builder: (context, snapshot) {
          final isRunning = snapshot.data ?? false;
          return SwitchListTile(
            title: const Text('Background Service'),
            subtitle: const Text('Keeps hourly chime and notification active.'),
            value: isRunning,
            onChanged: (bool value) async {
              if (value) {
                await BackgroundService.initialize();
              } else {
                await FlutterForegroundTask.stopService();
              }
              setState(() {});
            },
          );
        },
      ),
    );
  }

  Widget _buildBatteryHelpSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background reliability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Some devices pause background services. To keep hourly chime and time updates active, allow battery optimization exemption and enable auto-start.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final status =
                          await Permission.ignoreBatteryOptimizations.request();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Battery optimization: ${status.isGranted ? 'Allowed' : 'Not allowed'}')),
                        );
                      }
                    },
                    child: const Text("Allow 'Don't optimize battery'"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await PermissionService.openSystemAppSettings();
                    },
                    child: const Text('Open app settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ..._themeOptions.map((theme) => RadioListTile<String>(
                title: Text(theme['label']!),
                value: theme['value']!,
                groupValue: _selectedTheme,
                onChanged: (value) async {
                  if (value != null) {
                    await SettingsService.setThemeMode(value);
                    final ctrl = context.read<ThemeController>();
                    switch (value) {
                      case 'light':
                        await ctrl.setThemeMode(ThemeMode.light);
                        break;
                      case 'dark':
                        await ctrl.setThemeMode(ThemeMode.dark);
                        break;
                      default:
                        await ctrl.setThemeMode(ThemeMode.system);
                    }
                    setState(() {
                      _selectedTheme = value;
                    });
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget _buildSoundSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                // Manual test: play the hourly beep now via AlarmService
                try {
                  final svc = AlarmService();
                  await svc.playAlarm();
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Played hourly beep (manual)')));
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Play failed: $e')));
                }
              },
              child: const Text('Play hourly beep now'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Alarm Sound',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ..._soundOptions.map((sound) => ListTile(
                title: Text(sound['label']!),
                trailing: _selectedSound == sound['value']!
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () async {
                  final value = sound['value']!;
                  debugPrint('[Settings] Tap select & preview: $value');
                  // Persist selection first so the checkmark updates immediately
                  await SettingsService.setAlarmSound(value);
                  if (mounted) {
                    setState(() {
                      _selectedSound = value;
                    });
                  }
                  // Preview
                  try {
                    await _previewPlayer?.stop();
                    await _previewPlayer?.setVolume(1.0);
                    await _previewPlayer?.play(AssetSource(value));
                    debugPrint('[Settings] play started for $value');
                  } catch (e) {
                    debugPrint('[Settings] play error: $e');
                    // Fallback to default if asset missing, show a hint
                    try {
                      await _previewPlayer
                          ?.play(AssetSource('sounds/default.mp3'));
                      debugPrint('[Settings] fallback play started');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Selected tone not found. Played default.')),
                        );
                      }
                    } catch (e2) {
                      debugPrint('[Settings] fallback play error: $e2');
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tone set: ${sound['label']!}')),
                    );
                  }
                },
                onLongPress: () async {
                  final value = sound['value']!;
                  debugPrint('[Settings] Persist tone: $value');
                  await SettingsService.setAlarmSound(value);
                  if (mounted) {
                    setState(() {
                      _selectedSound = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tone set: ${sound['label']!}')),
                    );
                  }
                },
              )),
        ],
      ),
    );
  }
}
