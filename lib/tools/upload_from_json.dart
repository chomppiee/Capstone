import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // no options parameter

  // Load and parse your JSON asset
  final jsonString = await rootBundle.loadString('assets/waste_items.json');
  final List<dynamic> items = jsonDecode(jsonString);

  // Batch-write to Firestore
  final batch = FirebaseFirestore.instance.batch();
  for (var raw in items) {
    final data = Map<String, dynamic>.from(raw as Map);
    final doc  = FirebaseFirestore.instance.collection('waste_items').doc();
    batch.set(doc, data);
  }
  await batch.commit();

  print('✅ Uploaded ${items.length} waste items.');
}
