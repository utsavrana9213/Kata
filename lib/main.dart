import 'package:flutter/material.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/splash_screen.dart';
import 'package:servekeen/theme/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A fresh install always opens in Light mode; a user selection is restored.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

Future<void> setAppThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode', mode.name);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadSession();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == null) return;
    appThemeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'ServeKeen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppPalette.primaryBlue),
          scaffoldBackgroundColor: AppPalette.softBlendBackground,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: AppPalette.primaryBlue,
            unselectedItemColor: Color(0x99204670),
            type: BottomNavigationBarType.fixed,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppPalette.primaryBlue,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          canvasColor: Colors.black,
          cardColor: const Color(0xFF121212),
          dividerColor: Colors.white24,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Color(0xFF75AFFF),
            unselectedItemColor: Color(0xFF7F8FA3),
            type: BottomNavigationBarType.fixed,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF1A2027),
            surfaceTintColor: Colors.transparent,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF151F2A),
            labelStyle: const TextStyle(color: Color(0xFFB4C3D5)),
            hintStyle: const TextStyle(color: Color(0xFFB4C3D5)),
            prefixIconColor: const Color(0xFF75AFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF75AFFF)),
            ),
          ),
          useMaterial3: true,
        ),
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
