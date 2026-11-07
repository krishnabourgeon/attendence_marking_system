// import 'dart:async';

// import 'package:attendence_marking_system/service/app_config.dart';
// import 'package:attendence_marking_system/service/auth_service.dart';
// import 'package:attendence_marking_system/view/login_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

// class AttendanceScreen extends StatefulWidget {
//   const AttendanceScreen({super.key});
//   @override
//   State<AttendanceScreen> createState() => _AttendanceScreenState();
// }

// class _AttendanceScreenState extends State<AttendanceScreen> {
//   Position? _position;
//   double? _distance;
//   String? _error;
//   bool _openSettings = false;
//   bool _locating = false;
//   bool _marking = false;
//   bool _checkedIn = false;
//   String _user = '';
//   DateTime _now = DateTime.now();
//   Timer? _clock;
//   final List<AttendanceRecord> _records = [];

//   static const _bg = Color(0xFFF4F6FA);
//   static const _green = Color(0xFF2E9E5B);
//   static const _red = Color(0xFFE5484D);
//   static const _amber = Color(0xFFF59E0B);

//   bool get _inRange =>
//       _distance != null && _distance! <= AppConfig.radiusMeters;

//   bool get _canMark =>
//       !_marking && !_locating && _error == null && _inRange;

//   @override
//   void initState() {
//     super.initState();
//     _clock = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) setState(() => _now = DateTime.now());
//     });
//     AuthService.currentUser().then((u) {
//       if (mounted) setState(() => _user = u ?? '');
//     });
//     _refreshLocation();
//   }

//   @override
//   void dispose() {
//     _clock?.cancel();
//     super.dispose();
//   }

//   Future<Position?> _refreshLocation() async {
//     setState(() {
//       _locating = true;
//       _error = null;
//       _openSettings = false;
//     });
//     try {
//       final pos = await LocationService.getCurrentPosition();
//       if (!mounted) return null;
//       setState(() {
//         _position = pos;
//         _distance = LocationService.distanceToSite(pos);
//       });
//       return pos;
//     } on LocationException catch (e) {
//       if (mounted) {
//         setState(() {
//           _error = e.message;
//           _openSettings = e.openSettings;
//         });
//       }
//     } catch (_) {
//       if (mounted) setState(() => _error = 'Could not get your location.');
//     } finally {
//       if (mounted) setState(() => _locating = false);
//     }
//     return null;
//   }

//   Future<void> _mark() async {
//     setState(() => _marking = true);
//     try {
//       // Always take a fresh fix at the moment of marking
//       final pos = await _refreshLocation();
//       if (pos == null) return;

//       if (pos.isMocked) {
//         _toast('Mock location detected. Turn it off to mark attendance.');
//         return;
//       }
//       final distance = LocationService.distanceToSite(pos);
//       if (distance > AppConfig.radiusMeters) {
//         _toast(
//             'You are ${distance.toStringAsFixed(0)} m away. Move within ${AppConfig.radiusMeters.toStringAsFixed(0)} m.');
//         return;
//       }

//       final type = _checkedIn ? 'Check Out' : 'Check In';
//       await AttendanceService.mark(type: type, position: pos);
//       if (!mounted) return;
//       setState(() {
//         _checkedIn = !_checkedIn;
//         _records.insert(0, AttendanceRecord(type, DateTime.now(), distance));
//       });
//       _toast('$type successful');
//     } catch (_) {
//       _toast('Failed to mark attendance. Try again.');
//     } finally {
//       if (mounted) setState(() => _marking = false);
//     }
//   }

//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(SnackBar(
//         content: Text(msg),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ));
//   }

//   Future<void> _logout() async {
//     await AuthService.logout();
//     if (!mounted) return;
//     Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
//   }

//   // ---------------------------------------------------------------- helpers

//   String _fmt(DateTime t) {
//     final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
//     final m = t.minute.toString().padLeft(2, '0');
//     return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
//   }

//   String _fmtDate(DateTime t) {
//     const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
//     const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return '${days[t.weekday - 1]}, ${t.day} ${months[t.month - 1]} ${t.year}';
//   }

//   String get _greeting {
//     final h = _now.hour;
//     if (h < 12) return 'Good Morning';
//     if (h < 17) return 'Good Afternoon';
//     return 'Good Evening';
//   }

//   String get _name {
//     if (_user.isEmpty) return '';
//     final n = _user.contains('@') ? _user.split('@').first : _user;
//     return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
//   }

//   DateTime? get _firstIn {
//     for (final r in _records.reversed) {
//       if (r.type == 'Check In') return r.time;
//     }
//     return null;
//   }

//   DateTime? get _lastOut {
//     for (final r in _records) {
//       if (r.type == 'Check Out') return r.time;
//     }
//     return null;
//   }

//   String get _workingHours {
//     var total = Duration.zero;
//     DateTime? inTime;
//     for (final r in _records.reversed) {
//       if (r.type == 'Check In') {
//         inTime = r.time;
//       } else if (inTime != null) {
//         total += r.time.difference(inTime);
//         inTime = null;
//       }
//     }
//     if (inTime != null) total += _now.difference(inTime);
//     final h = total.inHours.toString().padLeft(2, '0');
//     final m = (total.inMinutes % 60).toString().padLeft(2, '0');
//     return '$h:$m';
//   }

//   // ------------------------------------------------------------------ build

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _bg,
//       body: RefreshIndicator(
//         onRefresh: _refreshLocation,
//         edgeOffset: 120,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Stack(
//             children: [
//               _buildHeader(context),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 210, 20, 32),
//                 child: Column(
//                   children: [
//                     _buildLocationCard(context),
//                     const SizedBox(height: 28),
//                     _buildPunchButton(context),
//                     const SizedBox(height: 28),
//                     _buildSummaryRow(context),
//                     const SizedBox(height: 24),
//                     _buildActivity(context),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     return Container(
//       height: 280,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.25)!],
//         ),
//         borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 22,
//                     backgroundColor: Colors.white.withOpacity(0.2),
//                     child: Text(
//                       _name.isEmpty ? '?' : _name[0],
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(_greeting,
//                             style: TextStyle(
//                                 color: Colors.white.withOpacity(0.8),
//                                 fontSize: 13)),
//                         Text(_name.isEmpty ? 'Welcome' : _name,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600)),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: _logout,
//                     tooltip: 'Logout',
//                     icon: const Icon(Icons.logout_rounded, color: Colors.white),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               Center(
//                 child: Column(
//                   children: [
//                     Text(_fmt(_now),
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 38,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 0.5)),
//                     const SizedBox(height: 2),
//                     Text(_fmtDate(_now),
//                         style: TextStyle(
//                             color: Colors.white.withOpacity(0.8),
//                             fontSize: 14)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _card({required Widget child, EdgeInsets? padding}) {
//     return Container(
//       width: double.infinity,
//       padding: padding ?? const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }

//   Widget _buildLocationCard(BuildContext context) {
//     final Color color;
//     final String chip;
//     final IconData icon;
//     if (_locating) {
//       color = Colors.blueGrey;
//       chip = 'Locating';
//       icon = Icons.my_location_rounded;
//     } else if (_error != null) {
//       color = _red;
//       chip = 'Unavailable';
//       icon = Icons.location_off_rounded;
//     } else if (_inRange) {
//       color = _green;
//       chip = 'In range';
//       icon = Icons.location_on_rounded;
//     } else {
//       color = _amber;
//       chip = 'Out of range';
//       icon = Icons.wrong_location_rounded;
//     }

//     return _card(
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 height: 46,
//                 width: 46,
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: _locating
//                     ? Padding(
//                         padding: const EdgeInsets.all(13),
//                         child: CircularProgressIndicator(
//                             strokeWidth: 2.5, color: color),
//                       )
//                     : Icon(icon, color: color),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(AppConfig.siteName,
//                         style: const TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.w600)),
//                     const SizedBox(height: 2),
//                     Text(
//                       _error ??
//                           (_distance == null
//                               ? 'Finding your location…'
//                               : '${_distance!.toStringAsFixed(0)} m away · allowed ${AppConfig.radiusMeters.toStringAsFixed(0)} m'),
//                       style: TextStyle(
//                           fontSize: 13, color: Colors.grey.shade600),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(chip,
//                     style: TextStyle(
//                         color: color,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600)),
//               ),
//             ],
//           ),
//           if (_position != null && _error == null) ...[
//             const SizedBox(height: 12),
//             Divider(height: 1, color: Colors.grey.shade200),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Icon(Icons.gps_fixed, size: 15, color: Colors.grey.shade500),
//                 const SizedBox(width: 6),
//                 Text('Accuracy ±${_position!.accuracy.toStringAsFixed(0)} m',
//                     style:
//                         TextStyle(fontSize: 12, color: Colors.grey.shade600)),
//                 const Spacer(),
//                 InkWell(
//                   onTap: _locating ? null : _refreshLocation,
//                   borderRadius: BorderRadius.circular(8),
//                   child: Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     child: Row(
//                       children: [
//                         Icon(Icons.refresh_rounded,
//                             size: 16,
//                             color: Theme.of(context).colorScheme.primary),
//                         const SizedBox(width: 4),
//                         Text('Refresh',
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: Theme.of(context).colorScheme.primary)),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//           if (_error != null) ...[
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton(
//                 onPressed: _openSettings
//                     ? () async {
//                         await Geolocator.openLocationSettings();
//                         await Geolocator.openAppSettings();
//                       }
//                     : _refreshLocation,
//                 style: OutlinedButton.styleFrom(
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: Text(_openSettings ? 'Open settings' : 'Retry'),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildPunchButton(BuildContext context) {
//     final base = _checkedIn ? _red : _green;
//     final enabled = _canMark;
//     final color = enabled ? base : Colors.grey.shade400;

//     return Column(
//       children: [
//         GestureDetector(
//           onTap: enabled ? _mark : null,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 250),
//             height: 168,
//             width: 168,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: color.withOpacity(0.12),
//             ),
//             alignment: Alignment.center,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 250),
//               height: 140,
//               width: 140,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [color, Color.lerp(color, Colors.black, 0.2)!],
//                 ),
//                 boxShadow: enabled
//                     ? [
//                         BoxShadow(
//                           color: color.withOpacity(0.4),
//                           blurRadius: 20,
//                           offset: const Offset(0, 8),
//                         ),
//                       ]
//                     : null,
//               ),
//               child: _marking
//                   ? const Center(
//                       child: SizedBox(
//                         height: 32,
//                         width: 32,
//                         child: CircularProgressIndicator(
//                             strokeWidth: 3, color: Colors.white),
//                       ),
//                     )
//                   : Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.fingerprint_rounded,
//                             size: 52, color: Colors.white),
//                         const SizedBox(height: 4),
//                         Text(_checkedIn ? 'Check Out' : 'Check In',
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600)),
//                       ],
//                     ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           enabled
//               ? 'Tap to ${_checkedIn ? 'check out' : 'check in'}'
//               : _error != null
//                   ? 'Enable location to continue'
//                   : _locating
//                       ? 'Verifying your location…'
//                       : 'Move within ${AppConfig.radiusMeters.toStringAsFixed(0)} m of ${AppConfig.siteName}',
//           style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
//         ),
//       ],
//     );
//   }

//   Widget _buildSummaryRow(BuildContext context) {
//     final inTime = _firstIn;
//     final outTime = _lastOut;

//     Widget tile(IconData icon, Color color, String value, String label) {
//       return Expanded(
//         child: _card(
//           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
//           child: Column(
//             children: [
//               Icon(icon, color: color, size: 22),
//               const SizedBox(height: 8),
//               Text(value,
//                   style: const TextStyle(
//                       fontSize: 15, fontWeight: FontWeight.w700)),
//               const SizedBox(height: 2),
//               Text(label,
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
//             ],
//           ),
//         ),
//       );
//     }

//     return Row(
//       children: [
//         tile(Icons.login_rounded, _green,
//             inTime == null ? '--:--' : _fmt(inTime), 'Check In'),
//         const SizedBox(width: 12),
//         tile(Icons.logout_rounded, _red,
//             outTime == null ? '--:--' : _fmt(outTime), 'Check Out'),
//         const SizedBox(width: 12),
//         tile(Icons.timer_outlined, _amber, _workingHours, 'Working hrs'),
//       ],
//     );
//   }

//   Widget _buildActivity(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Today's Activity",
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//         const SizedBox(height: 12),
//         _card(
//           padding: EdgeInsets.zero,
//           child: _records.isEmpty
//               ? Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 28),
//                   child: Center(
//                     child: Column(
//                       children: [
//                         Icon(Icons.history_rounded,
//                             size: 36, color: Colors.grey.shade400),
//                         const SizedBox(height: 8),
//                         Text('No activity yet',
//                             style: TextStyle(color: Colors.grey.shade600)),
//                       ],
//                     ),
//                   ),
//                 )
//               : Column(
//                   children: [
//                     for (var i = 0; i < _records.length; i++) ...[
//                       _activityTile(_records[i]),
//                       if (i != _records.length - 1)
//                         Divider(
//                             height: 1,
//                             indent: 72,
//                             color: Colors.grey.shade200),
//                     ],
//                   ],
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _activityTile(AttendanceRecord r) {
//     final isIn = r.type == 'Check In';
//     final color = isIn ? _green : _red;
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       leading: Container(
//         height: 42,
//         width: 42,
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.12),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Icon(isIn ? Icons.login_rounded : Icons.logout_rounded,
//             color: color, size: 20),
//       ),
//       title: Text(r.type,
//           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
//       subtitle: Text('${r.distance.toStringAsFixed(0)} m from site',
//           style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
//       trailing: Text(_fmt(r.time),
//           style: const TextStyle(fontWeight: FontWeight.w600)),
//     );
//   }
// }





import 'dart:async';

import 'package:attendence_marking_system/service/app_config.dart';
import 'package:attendence_marking_system/service/auth_service.dart';
import 'package:attendence_marking_system/service/notification_service.dart';
import 'package:attendence_marking_system/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// One "left the allowed area" episode, with the reason the user gave.
class ExitRecord {
  final DateTime left;
  final double distance;
  DateTime? returned;
  String? reason;
  ExitRecord({required this.left, required this.distance});
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const _monitorInterval = Duration(seconds: 5);

  Position? _position;
  double? _distance;
  String? _error;
  bool _openSettings = false;
  bool _locating = false;
  bool _marking = false;
  bool _checkedIn = false;
  String _user = '';
  DateTime _now = DateTime.now();
  Timer? _clock;
  Timer? _monitor;
  bool _ticking = false;
  bool _outside = false;
  bool _sheetOpen = false;
  final List<AttendanceRecord> _records = [];
  final List<ExitRecord> _exits = [];

  static const _bg = Color(0xFFF4F6FA);
  static const _green = Color(0xFF2E9E5B);
  static const _red = Color(0xFFE5484D);
  static const _amber = Color(0xFFF59E0B);

  bool get _inRange =>
      _distance != null && _distance! <= AppConfig.radiusMeters;

  bool get _canMark => !_marking && !_locating && _error == null && _inRange;

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    AuthService.currentUser().then((u) {
      if (mounted) setState(() => _user = u ?? '');
    });
    _refreshLocation();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _monitor?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ monitoring

  void _startMonitoring() {
    _monitor?.cancel();
    _monitor = Timer.periodic(_monitorInterval, (_) => _tick());
  }

  void _stopMonitoring() {
    _monitor?.cancel();
    _monitor = null;
    _outside = false;
  }

  /// Runs every 5 seconds while the user is checked in.
  Future<void> _tick() async {
    if (_ticking || !_checkedIn || !mounted) return;
    _ticking = true;
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted || !_checkedIn) return;

      final d = LocationService.distanceToSite(pos);
      setState(() {
        _position = pos;
        _distance = d;
        _error = null;
      });

      final out = d > AppConfig.radiusMeters;
      if (out && !_outside) {
        _onLeft(d);
      } else if (!out && _outside) {
        _onReturned();
      }
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _openSettings = e.openSettings;
        });
      }
    } catch (_) {
      // transient GPS failure – try again on next tick
    } finally {
      _ticking = false;
    }
  }

  void _onLeft(double distance) {
    final rec = ExitRecord(left: DateTime.now(), distance: distance);
    setState(() {
      _outside = true;
      _exits.insert(0, rec);
    });
    NotificationService.show(
      id: 1,
      title: 'You are outside ${AppConfig.siteName}',
      body:
          '${distance.toStringAsFixed(0)} m away. Please tell us the reason.',
    );
    _askReason(rec);
  }

  void _onReturned() {
    if (_exits.isNotEmpty) _exits.first.returned = DateTime.now();
    setState(() => _outside = false);
    NotificationService.show(
      id: 2,
      title: 'Back at ${AppConfig.siteName}',
      body: 'You are within the allowed area again.',
    );
    _toast('You are back in range');
  }

  Future<void> _askReason(ExitRecord rec) async {
    if (_sheetOpen || !mounted) return;
    _sheetOpen = true;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReasonSheet(
        siteName: AppConfig.siteName,
        distance: rec.distance,
      ),
    );
    _sheetOpen = false;
    if (reason != null && mounted) {
      setState(() => rec.reason = reason);
    }
  }

  // --------------------------------------------------------------- actions

  Future<Position?> _refreshLocation() async {
    setState(() {
      _locating = true;
      _error = null;
      _openSettings = false;
    });
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return null;
      setState(() {
        _position = pos;
        _distance = LocationService.distanceToSite(pos);
      });
      return pos;
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _openSettings = e.openSettings;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not get your location.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
    return null;
  }

  Future<void> _mark() async {
    setState(() => _marking = true);
    try {
      // Always take a fresh fix at the moment of marking
      final pos = await _refreshLocation();
      if (pos == null) return;

      if (pos.isMocked) {
        _toast('Mock location detected. Turn it off to mark attendance.');
        return;
      }
      final distance = LocationService.distanceToSite(pos);
      if (distance > AppConfig.radiusMeters) {
        _toast(
            'You are ${distance.toStringAsFixed(0)} m away. Move within ${AppConfig.radiusMeters.toStringAsFixed(0)} m.');
        return;
      }

      final type = _checkedIn ? 'Check Out' : 'Check In';
      await AttendanceService.mark(type: type, position: pos);
      if (!mounted) return;
      setState(() {
        _checkedIn = !_checkedIn;
        _records.insert(0, AttendanceRecord(type, DateTime.now(), distance));
      });
      if (_checkedIn) {
        _startMonitoring();
      } else {
        _stopMonitoring();
      }
      _toast('$type successful');
    } catch (_) {
      _toast('Failed to mark attendance. Try again.');
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  Future<void> _logout() async {
    _stopMonitoring();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  // --------------------------------------------------------------- helpers

  String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _fmtDate(DateTime t) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[t.weekday - 1]}, ${t.day} ${months[t.month - 1]} ${t.year}';
  }

  String _fmtDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _name {
    if (_user.isEmpty) return '';
    final n = _user.contains('@') ? _user.split('@').first : _user;
    return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
  }

  DateTime? get _firstIn {
    for (final r in _records.reversed) {
      if (r.type == 'Check In') return r.time;
    }
    return null;
  }

  DateTime? get _lastOut {
    for (final r in _records) {
      if (r.type == 'Check Out') return r.time;
    }
    return null;
  }

  String get _workingHours {
    var total = Duration.zero;
    DateTime? inTime;
    for (final r in _records.reversed) {
      if (r.type == 'Check In') {
        inTime = r.time;
      } else if (inTime != null) {
        total += r.time.difference(inTime);
        inTime = null;
      }
    }
    if (inTime != null) total += _now.difference(inTime);
    final h = total.inHours.toString().padLeft(2, '0');
    final m = (total.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final showBanner = _checkedIn && _outside && _exits.isNotEmpty;
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: _refreshLocation,
        edgeOffset: 120,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 210, 20, 32),
                child: Column(
                  children: [
                    _buildLocationCard(context),
                    if (showBanner) ...[
                      const SizedBox(height: 16),
                      _buildOutBanner(context),
                    ],
                    const SizedBox(height: 28),
                    _buildPunchButton(context),
                    const SizedBox(height: 28),
                    _buildSummaryRow(context),
                    const SizedBox(height: 24),
                    _buildActivity(context),
                    if (_exits.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildExitLog(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.25)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _name.isEmpty ? '?' : _name[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                        Text(_name.isEmpty ? 'Welcome' : _name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(_fmt(_now),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(_fmtDate(_now),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    final Color color;
    final String chip;
    final IconData icon;
    if (_locating) {
      color = Colors.blueGrey;
      chip = 'Locating';
      icon = Icons.my_location_rounded;
    } else if (_error != null) {
      color = _red;
      chip = 'Unavailable';
      icon = Icons.location_off_rounded;
    } else if (_inRange) {
      color = _green;
      chip = 'In range';
      icon = Icons.location_on_rounded;
    } else {
      color = _amber;
      chip = 'Out of range';
      icon = Icons.wrong_location_rounded;
    }

    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _locating
                    ? Padding(
                        padding: const EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: color),
                      )
                    : Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConfig.siteName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      _error ??
                          (_distance == null
                              ? 'Finding your location…'
                              : '${_distance!.toStringAsFixed(0)} m away · allowed ${AppConfig.radiusMeters.toStringAsFixed(0)} m'),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(chip,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (_position != null && _error == null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.gps_fixed, size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('Accuracy ±${_position!.accuracy.toStringAsFixed(0)} m',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (_checkedIn) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.sensors_rounded, size: 15, color: _green),
                  const SizedBox(width: 4),
                  const Text('Live tracking',
                      style: TextStyle(fontSize: 12, color: _green)),
                ],
                const Spacer(),
                InkWell(
                  onTap: _locating ? null : _refreshLocation,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Refresh',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openSettings
                    ? () async {
                        await Geolocator.openLocationSettings();
                        await Geolocator.openAppSettings();
                      }
                    : _refreshLocation,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_openSettings ? 'Open settings' : 'Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Shown while checked in and outside the allowed area.
  Widget _buildOutBanner(BuildContext context) {
    final rec = _exits.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _red),
              const SizedBox(width: 8),
              Expanded(
                child: Text('You are outside ${AppConfig.siteName}',
                    style: const TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Since ${_fmt(rec.left)} · ${_fmtDuration(_now.difference(rec.left))} · ${(_distance ?? rec.distance).toStringAsFixed(0)} m away',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          if (rec.reason != null)
            Text('Reason: ${rec.reason}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _askReason(rec),
                style: FilledButton.styleFrom(
                  backgroundColor: _red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add reason'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPunchButton(BuildContext context) {
    final base = _checkedIn ? _red : _green;
    final enabled = _canMark;
    final color = enabled ? base : Colors.grey.shade400;

    return Column(
      children: [
        GestureDetector(
          onTap: enabled ? _mark : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 168,
            width: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, Color.lerp(color, Colors.black, 0.2)!],
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: _marking
                  ? const Center(
                      child: SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fingerprint_rounded,
                            size: 52, color: Colors.white),
                        const SizedBox(height: 4),
                        Text(_checkedIn ? 'Check Out' : 'Check In',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          enabled
              ? 'Tap to ${_checkedIn ? 'check out' : 'check in'}'
              : _error != null
                  ? 'Enable location to continue'
                  : _locating
                      ? 'Verifying your location…'
                      : 'Move within ${AppConfig.radiusMeters.toStringAsFixed(0)} m of ${AppConfig.siteName}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    final inTime = _firstIn;
    final outTime = _lastOut;

    Widget tile(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: _card(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(Icons.login_rounded, _green,
            inTime == null ? '--:--' : _fmt(inTime), 'Check In'),
        const SizedBox(width: 12),
        tile(Icons.logout_rounded, _red,
            outTime == null ? '--:--' : _fmt(outTime), 'Check Out'),
        const SizedBox(width: 12),
        tile(Icons.timer_outlined, _amber, _workingHours, 'Working hrs'),
      ],
    );
  }

  Widget _buildActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Activity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _card(
          padding: EdgeInsets.zero,
          child: _records.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No activity yet',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _records.length; i++) ...[
                      _activityTile(_records[i]),
                      if (i != _records.length - 1)
                        Divider(
                            height: 1,
                            indent: 72,
                            color: Colors.grey.shade200),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _activityTile(AttendanceRecord r) {
    final isIn = r.type == 'Check In';
    final color = isIn ? _green : _red;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isIn ? Icons.login_rounded : Icons.logout_rounded,
            color: color, size: 20),
      ),
      title: Text(r.type,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text('${r.distance.toStringAsFixed(0)} m from site',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Text(_fmt(r.time),
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildExitLog(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Out of Range Log',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _exits.length; i++) ...[
                _exitTile(_exits[i]),
                if (i != _exits.length - 1)
                  Divider(height: 1, indent: 72, color: Colors.grey.shade200),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _exitTile(ExitRecord e) {
    final ongoing = e.returned == null;
    final duration = (e.returned ?? _now).difference(e.left);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: _amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.wrong_location_rounded,
            color: _amber, size: 20),
      ),
      title: Text(e.reason ?? 'Reason not provided',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(
        'Left ${_fmt(e.left)} · ${ongoing ? 'still outside' : 'back ${_fmt(e.returned!)}'}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Text(_fmtDuration(duration),
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ongoing ? _red : Colors.black87)),
    );
  }
}

/// Bottom sheet that forces the user to pick / type a reason.
class _ReasonSheet extends StatefulWidget {
  final String siteName;
  final double distance;
  const _ReasonSheet({required this.siteName, required this.distance});

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  static const _quickReasons = [
    'Lunch / tea break',
    'Official work',
    'Meeting',
    'Personal',
  ];

  final _controller = TextEditingController();

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(String reason) {
    _controller.text = reason;
    _controller.selection = TextSelection.collapsed(offset: reason.length);
    setState(() {});
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5484D).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.wrong_location_rounded,
                        color: Color(0xFFE5484D)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('You left the work location',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            '${widget.distance.toStringAsFixed(0)} m from ${widget.siteName}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Reason',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 4,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Why are you outside the work location?',
                  filled: true,
                  fillColor: const Color(0xFFF4F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Quick select',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _quickReasons)
                    ActionChip(
                      label: Text(r),
                      onPressed: () => _pick(r),
                      backgroundColor: _controller.text == r
                          ? cs.primaryContainer
                          : Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Submit reason'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}