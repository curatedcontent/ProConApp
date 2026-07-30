import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_screen.dart';
import 'services/db_service.dart';
import 'services/speech_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Services will be initialized on first use to speed up launch
  runApp(const ProConApp());
}

class ProConApp extends StatelessWidget {
  const ProConApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pros & Cons',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
