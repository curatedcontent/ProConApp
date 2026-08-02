import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'services/unload_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cloud sync (Firebase Auth + Firestore) is currently only configured for
  // web; native builds keep working local-only, unchanged.
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  await DbService().init();

  registerUnloadGuard(
    () => !AuthService().isSignedIn && DbService().hasLocalEntriesSync,
  );

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
