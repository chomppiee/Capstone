import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

import 'admin_dashboard.dart'; // Make sure this import points to your actual file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyB32UlJfCkdICyjgPsBOPL-VFw-bmtuhR0",
      authDomain: "segregate-e6779.firebaseapp.com",
      projectId: "segregate-e6779",
      //storageBucket: "segregate-e6779.appspot.com",
      storageBucket: "segregate-e6779.firebasestorage.app",
      messagingSenderId: "879715528467",
      appId: "1:879715528467:web:906eb309eadc947b3a34e6",
    ),
  );

  // Optional: Logger configuration for cleaner debug logs
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SegreGate Admin Panel',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminDashboard(),
    );
  }
}
