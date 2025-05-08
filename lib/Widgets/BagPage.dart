// lib/Widgets/BagPage.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:segregate1/Widgets/services/cart_service.dart';

class BagPage extends StatefulWidget {
  const BagPage({Key? key}) : super(key: key);

  @override
  State<BagPage> createState() => _BagPageState();
}

class _BagPageState extends State<BagPage> {
  static const Color primary = Colors.green;

  int get _totalCost => CartService.items.fold<int>(
        0,
        (sum, item) => sum + item.cost * item.quantity,
      );

  Future<void> _onRedeemPressed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1️⃣ Check if the user has enough points
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userSnap = await userRef.get();
    final currentPoints = (userSnap.data()?['points'] ?? 0) as int;
    if (currentPoints < _totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points to redeem.')),
      );
      return;
    }

    // 2️⃣ Create pending transaction
    final txnRef = await FirebaseFirestore.instance
        .collection('redeem_transactions')
        .add({
      'userId': user.uid,
      'items': CartService.items
          .map((i) => {'id': i.id, 'qty': i.quantity})
          .toList(),
      'totalCost': _totalCost,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final qrData = jsonEncode({'txnId': txnRef.id});

    // 3️⃣ Listen for admin confirmation in Firestore
    late StreamSubscription<DocumentSnapshot> sub;
    sub = FirebaseFirestore.instance
        .collection('redeem_transactions')
        .doc(txnRef.id)
        .snapshots()
        .listen((docSnap) {
      final data = docSnap.data() as Map<String, dynamic>?;
      if (data != null && data['status'] == 'confirmed') {
        sub.cancel(); // stop listening
        // Close the dialog
        Navigator.of(context).pop();
        // Notify user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redemption successful!')),
        );
        // Clear cart now
        CartService.clear();
        setState(() {});
      }
    });

    // 4️⃣ Show QR in a dialog (matching AllHighlightsPage style)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Show this QR to Admin",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 16),
              const Text(
                "Ask the admin to scan this QR code to confirm your redemption.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                ),
                onPressed: () {
                  // Cancel listening & close
                  sub.cancel();
                  Navigator.of(ctx).pop();
                },
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Bag'),
        backgroundColor: primary,
      ),
      body: items.isEmpty
          ? const Center(child: Text('No items in your bag.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(item.name),
                          subtitle: Text('${item.cost} pts each'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      CartService.items.removeAt(i);
                                    }
                                  });
                                },
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon:
                                    const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    item.quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: primary,
                    ),
                    onPressed: _onRedeemPressed,
                    child: const Text('Redeem'),
                  ),
                ),
              ],
            ),
    );
  }
}
