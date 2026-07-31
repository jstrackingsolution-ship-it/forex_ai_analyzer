import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const ForexAIApp());
}

class ForexAIApp extends StatelessWidget {
  const ForexAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forex AI Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF448AFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        cardTheme: const CardThemeData(
          color: Color(0xFF181B21),
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
