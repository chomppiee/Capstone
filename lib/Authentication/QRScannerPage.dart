import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (_scanned) return;
      _scanned = true;

      try {
        // decode the QR payload
        final Map<String, dynamic> data = jsonDecode(scanData.code!);
        final String uid     = data['uid'] as String;
        final String eventId = data['eventId'] as String;

        final userRef  = FirebaseFirestore.instance.collection('users').doc(uid);
        final eventRef = FirebaseFirestore.instance.collection('community_highlights').doc(eventId);

        // transaction: update points/events for payload-UID & mark them attended
        await FirebaseFirestore.instance.runTransaction((tx) async {
          // fetch current values
          final userSnap = await tx.get(userRef);
          final userData = userSnap.data() as Map<String, dynamic>;
          final points = (userData['points'] ?? 0) as int;
          final events = (userData['events_attended'] ?? 0) as int;

          // update user stats
          tx.update(userRef, {
            'points': points + 10,
            'events_attended': events + 1,
          });

          // record in subcollection
          tx.set(
            eventRef.collection('attendees').doc(uid),
            {
              'attended': true,
              'timestamp': FieldValue.serverTimestamp(),
            },
          );

          // update the event doc's array
          tx.update(eventRef, {
            'attendedUsers': FieldValue.arrayUnion([uid]),
          });
        });

        // success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Attendance recorded!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Error scanning: $e")),
          );
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Attendance QR"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "Align the QR code within the box",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
