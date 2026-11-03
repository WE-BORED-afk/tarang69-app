import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/schedule_service.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.init();

  final scheduleService = ScheduleService();
  runApp(Tarang69App(scheduleService: scheduleService));
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
        fontFamily: 'Kanit',
      ),
      home: HomeScreen(scheduleService: scheduleService),
    );
  }
}
