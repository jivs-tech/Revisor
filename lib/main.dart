import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/main_nav_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SmartRevisionApp(),
    ),
  );
}

class SmartRevisionApp extends StatelessWidget {
  const SmartRevisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppState>(context).isDarkMode;

    return MaterialApp(
      title: 'NeuroRevise',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavScreen(),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFF191919),
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.grey,
        surface: Color(0xFF262626),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF151515),
        indicatorColor: Colors.white12,
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)
        ),
        iconTheme: MaterialStateProperty.resolveWith(
          (states) => const IconThemeData(color: Colors.white70)
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData.light().copyWith(
      primaryColor: const Color(0xFF4B3621), // Brown
      scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Off-white
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4B3621),
        secondary: Color(0xFF8B4513),
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF4B3621)),
        bodyMedium: TextStyle(color: Color(0xFF5D4037)),
        headlineLarge: TextStyle(color: Color(0xFF4B3621), fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFF4B3621), fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Color(0xFF4B3621)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF4B3621).withValues(alpha: 0.1),
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B3621))
        ),
        iconTheme: MaterialStateProperty.resolveWith(
          (states) => const IconThemeData(color: Color(0xFF4B3621))
        ),
      ),
    );
  }
}
