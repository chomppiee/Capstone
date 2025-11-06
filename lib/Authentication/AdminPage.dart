// lib/Widgets/AdminPage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:segregate1/Authentication/QRScannerPage.dart';
import 'package:segregate1/Authentication/ReceiveScannerPage.dart';
import 'package:segregate1/Authentication/RedeemScannerPage.dart';
import 'package:segregate1/Authentication/Loginpage.dart'; 
import 'package:shared_preferences/shared_preferences.dart';


class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  void _navigateToAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );
  }

  void _navigateToReceiveDropoff(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceiveScannerPage()),
    );
  }

  void _navigateToRedeemScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RedeemScannerPage()),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

if (shouldLogout == true) {
  await FirebaseAuth.instance.signOut();

  // ✅ Clear saved Remember Me info
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('saved_email');
  await prefs.remove('saved_password');
  await prefs.remove('saved_remember');

  if (context.mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToAttendance(context),
              child: const Text("Scan Attendance QR"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToReceiveDropoff(context),
              child: const Text("Scan Drop-off QR"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToRedeemScan(context),
              child: const Text("Scan Redemption QR"),
            ),
          ],
        ),
      ),
    );
  }
}
