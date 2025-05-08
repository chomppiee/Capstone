// lib/Widgets/RedeemScannerPage.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart'; // make sure this is the plus package

class RedeemScannerPage extends StatefulWidget {
  const RedeemScannerPage({Key? key}) : super(key: key);

  @override
  State<RedeemScannerPage> createState() => _RedeemScannerPageState();
}

class _RedeemScannerPageState extends State<RedeemScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'RedeemQR');
  QRViewController? controller;
  bool _processed = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) async {
      if (_processed) return;
      _processed = true;

      try {
        final Map<String, dynamic> payload = jsonDecode(scanData.code!);
        final String txnId = payload['txnId'] as String;
        final txnRef = FirebaseFirestore.instance
            .collection('redeem_transactions')
            .doc(txnId);
        final txnSnap = await txnRef.get();
        if (!txnSnap.exists) throw Exception('Transaction not found');
        final txn = txnSnap.data()!;
        if (txn['status'] != 'pending') {
          throw Exception('Already redeemed');
        }

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(txn['userId'] as String);
        final totalCost = (txn['totalCost'] as num).toInt();

        await FirebaseFirestore.instance.runTransaction((tx) async {
          final userSnap = await tx.get(userRef);
          final currentPts = (userSnap.data()?['points'] ?? 0) as int;
          if (currentPts < totalCost) throw Exception('Insufficient points');
          tx.update(userRef, {'points': currentPts - totalCost});
          tx.update(txnRef, {
            'status': 'confirmed',
            'confirmedAt': FieldValue.serverTimestamp(),
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redemption confirmed!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine cutout size as 60% of screen width
    final double cutOutSize = MediaQuery.of(context).size.width * 0.6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Redemption QR'),
        backgroundColor: Colors.green,
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        // add this overlay for the guideline
        overlay: QrScannerOverlayShape(
          borderColor: Colors.green,
          borderRadius: 8,
          borderLength: 30,
          borderWidth: 8,
          cutOutSize: cutOutSize,
        ),
        // optional: give it some margin so overlay isn't flush to edges
        overlayMargin: const EdgeInsets.all(24),
      ),
    );
  }
}
