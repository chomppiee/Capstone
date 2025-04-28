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
        final Map<String, dynamic> data = jsonDecode(scanData.code!);
        final String uid = data['uid'];
        final String eventId = data['eventId'];

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final eventRef = FirebaseFirestore.instance.collection('community_highlights').doc(eventId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userSnap = await transaction.get(userRef);
final userData = userSnap.data() as Map<String, dynamic>;
final points = userData.containsKey('points') ? userData['points'] : 0;
final events = userData.containsKey('events_attended') ? userData['events_attended'] : 0;


          transaction.update(userRef, {
            'points': points + 10,
            'events_attended': events + 1,
          });

          transaction.set(eventRef.collection('attendees').doc(uid), {
            'attended': true,
            'timestamp': FieldValue.serverTimestamp(),
          });
        });

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

  if (status.isGranted) {
    // Permission granted, scanner will work
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
      Navigator.pop(context);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Attendance QR"), backgroundColor: Colors.green),
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
