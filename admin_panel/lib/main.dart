import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyB32UlJfCkdICyjgPsBOPL-VFw-bmtuhR0",
      authDomain: "segregate-e6779.firebaseapp.com",
      projectId: "segregate-e6779",
      storageBucket: "segregate-e6779.appspot.com",
      messagingSenderId: "879715528467",
      appId: "1:879715528467:web:906eb309eadc947b3a34e6",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminDashboard(),
    );
  }
}
