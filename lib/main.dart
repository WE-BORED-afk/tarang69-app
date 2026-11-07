import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/schedule_service.dart';
import 'services/widget_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app immediately so Android never stays on the white splash screen
  final scheduleService = ScheduleService();
  runApp(Tarang69App(scheduleService: scheduleService));

  // Initialize widget service in background safely
  scheduleMicrotask(() async {
    try {
      await WidgetService.init();
    } catch (e) {
      debugPrint('WidgetService init error: $e');
    }
  });
}

class Tarang69App extends StatelessWidget {
  final ScheduleService scheduleService;

  const Tarang69App({super.key, required this.scheduleService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TARANG69',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
          surface: const Color(0xFFF8FAFC),
        ),
      ),
      home: HomeScreen(scheduleService: scheduleService),
    );
  }
}
