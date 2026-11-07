import 'package:attendence_marking_system/service/auth_service.dart';
import 'package:attendence_marking_system/view/attendance_screen.dart';
import 'package:attendence_marking_system/view/login_screen.dart';
import 'package:flutter/material.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}
 
class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }
 
  Future<void> _check() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => loggedIn ? const AttendanceScreen() : const LoginScreen(),
    ));
  }
 
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}