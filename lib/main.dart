import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:queuetrack/Database/driver.dart';
import 'package:queuetrack/screens/Authentication/role_selection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Supabase.initialize(
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJubnZjdnJla25peGxvZmVwYWZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxNzM0NTksImV4cCI6MjA4MTc0OTQ1OX0.LWf0H0E7ZgT6OUEVOrtknhXRKg5cBO5Eigw9a4jllmg',
      url: 'https://bnnvcvreknixlofepafz.supabase.co',
    );
    OneSignal.initialize('fb4a4b27-a6d7-44d4-ab55-d418d082ba74');
    await OneSignal.Notifications.requestPermission(true);
    final LocationPermission hasPermission =
    await Geolocator.checkPermission();
    if (hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Cant Proceed without permission');
        final res=await Geolocator.requestPermission();
        if(res ==LocationPermission.denied){
          return;
        }
      }
    }
    runApp(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => Driver())],
        child: const QueueTrackApp(),
      ),
    );
  } catch (err) {
    Fluttertoast.showToast(msg: 'Error : ${err.toString()}');
  }
}

class QueueTrackApp extends StatelessWidget {
  const QueueTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QueueTrack',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/roleselection', 
      routes: {
        '/roleselection': (_) => const RoleSelection(),
       
      },
    );
  }
}
