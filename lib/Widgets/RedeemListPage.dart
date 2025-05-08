import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:segregate1/Widgets/services/cart_service.dart';
import 'BagPage.dart';

class RedeemListPage extends StatelessWidget {
  const RedeemListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primary = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Rewards'),
        backgroundColor: primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'View Bag',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BagPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('redeem_items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No items available to redeem.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      data['imageUrl'] ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(data['name'] ?? 'Unnamed'),
                  subtitle: Text('${data['cost'] ?? 0} pts'),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                    ),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Add to Bag'),
                    onPressed: () {
                      // build a CartItem and add it
                      final item = CartItem(
                        id: doc.id,
                        name: data['name'] ?? 'Unnamed',
                        cost: data['cost'] ?? 0,
                        imageUrl: data['imageUrl'] ?? '',
                      );
                      CartService.addItem(item);

                      // go to bag
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BagPage()),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
