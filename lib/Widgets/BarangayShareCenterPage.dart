import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BarangayShareCenterPage extends StatelessWidget {
  const BarangayShareCenterPage({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Barangay Share Center'),
      backgroundColor: Colors.green,
    ),
    body: const Center(
      child: Text(
        'This page is under construction.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    ),
  );
}
}
