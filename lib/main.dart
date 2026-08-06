import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'view/alarm_ringing_screen.dart';
import 'view/main_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  runApp(const ProviderScope(child: MunjangSigyeApp()));
}

class MunjangSigyeApp extends StatefulWidget {
  const MunjangSigyeApp({super.key});

  @override
  State<MunjangSigyeApp> createState() => _MunjangSigyeAppState();
}

class _MunjangSigyeAppState extends State<MunjangSigyeApp> {
  @override
  void initState() {
    super.initState();
    Alarm.ringStream.stream.listen((settings) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => AlarmRingingScreen(alarmSettings: settings)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '문장시계',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}
