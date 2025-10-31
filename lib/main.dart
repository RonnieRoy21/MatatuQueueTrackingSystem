import 'package:flutter/material.dart';
import 'screens/login_page.dart'; // This now points to LoginPage
import 'screens/signup_screen.dart'; // Optional, used for navigation from login
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // The file you have with your Firebase config

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use your generated config
  );
  runApp(const QueueTrackApp());
}

class QueueTrackApp extends StatelessWidget {
  const QueueTrackApp({super.key});

  @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QueueTrack',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/login',  // ✅ Start with login page
        routes: {
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignUpScreen(),
          // dashboards we’ll navigate to manually
        },
      );
    }
  }
