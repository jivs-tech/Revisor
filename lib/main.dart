import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/main_nav_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'NeuroRevise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: const Color(0xFF191919),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.grey,
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
      ),
      home: const MainNavScreen(),
    );
  }
}
