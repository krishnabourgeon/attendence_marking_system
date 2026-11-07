import 'package:attendence_marking_system/service/notification_service.dart';
import 'package:attendence_marking_system/view/splash_screen.dart';
import 'package:flutter/material.dart';

Future<void> main() async {

    WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1F4E79),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const SplashGate(),
    );
  }
}