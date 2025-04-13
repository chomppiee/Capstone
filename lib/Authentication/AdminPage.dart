import 'package:flutter/material.dart';
import 'package:segregate1/Authentication/QRScannerPage.dart';


class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  // Navigate to AttendancePage.
  void _navigateToAttendance(BuildContext context) {


  }

  // Dummy Use Points navigation.
  void _navigateToUsePoints(BuildContext context) {
    // TODO: Replace with your actual Use Points page navigation.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigating to Use Points...")),
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
              child: const Text("Attendance"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToUsePoints(context),
              child: const Text("Use Points"),
            ),
          ],
        ),
      ),
    );
  }
}
