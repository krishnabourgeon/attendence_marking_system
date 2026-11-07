import 'package:attendence_marking_system/service/app_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
 
  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey) != null;
  }
 
  static Future<String?> currentUser() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_userKey);
  }
 
  static Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password.length < 6) {
      throw Exception('Invalid email or password');
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, 'demo-token');
    await p.setString(_userKey, email);
  }
 
  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
    await p.remove(_userKey);
  }
}
 
class LocationException implements Exception {
  final String message;
  final bool openSettings;
  LocationException(this.message, {this.openSettings = false});
  @override
  String toString() => message;
}
 
class LocationService {
  static Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Location services are turned off.',
          openSettings: true);
    }
 
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
          'Location permission permanently denied. Enable it from app settings.',
          openSettings: true);
    }
 
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
 
  static double distanceToSite(Position p) => Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        AppConfig.siteLat,
        AppConfig.siteLng,
      );
}
 
class AttendanceRecord {
  final String type; // Check In / Check Out
  final DateTime time;
  final double distance;
  AttendanceRecord(this.type, this.time, this.distance);
}
 
class AttendanceService {
  static Future<void> mark({
    required String type,
    required Position position,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }
}