// lib/Widgets/AdminPage.dart

import 'package:flutter/material.dart';
import 'package:segregate1/Authentication/QRScannerPage.dart';
import 'package:segregate1/Authentication/RedeemScannerPage.dart';  // <-- new import

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  void _navigateToAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );
  }

  void _navigateToUsePoints(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigating to Use Points...")),
    );
  }

  void _navigateToRedeemScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RedeemScannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"), backgroundColor: Colors.red),
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
              onPressed: () => _navigateToUsePoints(context),
              child: const Text("Use Points"),
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
