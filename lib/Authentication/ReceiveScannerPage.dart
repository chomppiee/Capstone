// lib/Widgets/ReceiveScannerPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ReceiveScannerPage extends StatefulWidget {
  const ReceiveScannerPage({Key? key}) : super(key: key);

  @override
  State<ReceiveScannerPage> createState() => _ReceiveScannerPageState();
}

class _ReceiveScannerPageState extends State<ReceiveScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _processing = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((barcode) {
      final code = barcode.code;
      if (code != null) {
        _handleBarcode(code);
      }
    });
  }

  Future<void> _handleBarcode(String code) async {
    if (_processing) return;
    setState(() => _processing = true);

    final donationId = code.trim();
    final docRef = FirebaseFirestore.instance.collection('donations').doc(donationId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid QR'),
          content: Text('No donation found for ID "$donationId".'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      setState(() => _processing = false);
      return;
    }

    final data = snapshot.data()!;

    // 1) Update donation status
    await docRef.update({'status': 'Received'});

    // 2) Add to barangay_inventory
    await FirebaseFirestore.instance.collection('barangay_inventory').add({
      'itemId':       donationId,
      'title':        data['title']    ?? '',
      'category':     data['category'] ?? '',
      'status':       'Available',
      'receivedDate': FieldValue.serverTimestamp(),
      'donorUid':     data['userId']   ?? '',
      'imageUrl':     data['imageUrl'] ?? '',
    });

    // 3) Show confirmation
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Received'),
        content: const Text('Item marked “Received” and added to inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );

    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Drop-off QR'),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.orange,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
            ),
            formatsAllowed: const [BarcodeFormat.qrcode],
            cameraFacing: CameraFacing.back,
          ),
          if (_processing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
