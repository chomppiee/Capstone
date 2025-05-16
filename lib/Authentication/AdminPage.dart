// lib/Widgets/AdminPage.dart

import 'package:flutter/material.dart';
import 'package:segregate1/Authentication/QRScannerPage.dart';
import 'package:segregate1/Authentication/ReceiveScannerPage.dart';  // <-- new import
import 'package:segregate1/Authentication/RedeemScannerPage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.red,
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
