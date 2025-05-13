// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import 'LoginPage.dart';
import 'Admin_Dashboard.dart';
import 'SuperAdminPage.dart';
import 'unauthorized_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB32UlJfCkdICyjgPsBOPL-VFw-bmtuhR0",
      authDomain: "segregate-e6779.firebaseapp.com",
      projectId: "segregate-e6779",
      storageBucket: "segregate-e6779.firebasestorage.app",
      messagingSenderId: "879715528467",
      appId: "1:879715528467:web:906eb309eadc947b3a34e6",
    ),
  );
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    debugPrint('[${rec.level.name}] ${rec.loggerName}: ${rec.message}');
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
      routes: {
        '/login':        (_) => const LoginPage(),
        '/dashboard':    (_) => const AdminDashboard(),
        '/superadmin':   (_) => const SuperAdminPage(),
        '/unauthorized': (_) => const UnauthorizedPage(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, authSnap) {
        debugPrint('🔄 AuthGate: auth state=${authSnap.connectionState}, user=${authSnap.data?.uid}');
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = authSnap.data;
        if (user == null) {
          debugPrint('🔒 AuthGate: not signed in, showing LoginPage');
          return const LoginPage();
        }
        debugPrint('🔓 AuthGate: signed in as uid=${user.uid}, checking roles');
        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait([
            FirebaseFirestore.instance.collection('admins').doc(user.uid).get(),
            FirebaseFirestore.instance.collection('superadmins').doc(user.uid).get(),
          ]),
          builder: (ctx2, roleSnap) {
            if (roleSnap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final isAdmin = roleSnap.data![0].exists;
            final isSuper = roleSnap.data![1].exists;
            debugPrint('👮 AuthGate: isAdmin=$isAdmin, isSuper=$isSuper');
            if (!isAdmin && !isSuper) {
              debugPrint('⛔ AuthGate: no roles, signing out');
              FirebaseAuth.instance.signOut();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/unauthorized');
              });
              return const SizedBox.shrink();
            }
            if (isSuper) {
              debugPrint('🚀 AuthGate: routing to SuperAdminPage');
              return const SuperAdminPage();
            }
            debugPrint('✅ AuthGate: routing to AdminDashboard');
            return const AdminDashboard();
          },
        );
      },
    );
  }
}
