import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class PipClockApp extends StatefulWidget {
  const PipClockApp({super.key});

  @override
  State<PipClockApp> createState() => _PipClockAppState();
}

class _PipClockAppState extends State<PipClockApp> with WidgetsBindingObserver {
  late Future<SharedPreferences> _prefs;
  String _themeMode = 'system';
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prefs = SharedPreferences.getInstance();
    _loadTheme();
    _themeController.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await _prefs;
    setState(() {
      _themeMode = prefs.getString('theme_mode') ?? 'system';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ChangeNotifierProvider<ThemeController>.value(
            value: _themeController,
            child: Consumer<ThemeController>(
              builder: (context, ctrl, _) {
                return MaterialApp(
                  title: 'Pip Clock',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: ctrl.themeMode,
                  home: const HomeScreen(),
                  debugShowCheckedModeBanner: false,
                );
              },
            ),
          );
        }
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}
