// lib/Widgets/RedeemQrPage.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RedeemQrPage extends StatelessWidget {
  final String transactionId;
  const RedeemQrPage({Key? key, required this.transactionId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({'txnId': transactionId});
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Redeem QR'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 250.0,
        ),
      ),
    );
  }
}
