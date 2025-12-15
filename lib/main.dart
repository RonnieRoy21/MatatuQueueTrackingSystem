import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:queuetrack/screens/Authentication/role_selection.dart';

import 'firebase_options.dart'; // The file you have with your Firebase config
// This now points to LoginPage
// Optional, used for navigation from login

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // Use your generated config
  );
  runApp(
      const QueueTrackApp(
  ),

  );
}

class QueueTrackApp extends StatelessWidget {
  const QueueTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QueueTrack',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/roleselection', // ✅ Start with login page
      routes: {
        '/roleselection': (_) => const RoleSelection(),
        // dashboards we’ll navigate to manually
      },
    );
  }
}
