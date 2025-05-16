// lib/Widgets/InventoryList.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryList extends StatelessWidget {
  const InventoryList({Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showItemDetails(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';
    final receivedTs = data['receivedDate'] as Timestamp?;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['title'] as String? ?? 'Item Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (data['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'] as String,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 12),
              Text('Category: ${data['category'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Status: $status'),
              if (receivedTs != null) ...[
                const SizedBox(height: 8),
                Text('Received: ${_formatTimestamp(receivedTs)}'),
              ],
              const SizedBox(height: 8),
              Text('Donor UID: ${data['donorUid'] ?? ''}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('barangay_inventory')
          .orderBy('receivedDate', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(child: Text('Failed to load inventory'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No items in inventory'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 4 / 7,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data()! as Map<String, dynamic>;
            final title    = data['title']    as String? ?? '';
            final category = data['category'] as String? ?? '';
            final status   = data['status']   as String? ?? '';
            final imgUrl   = data['imageUrl'] as String?;

            return GestureDetector(
              onTap: () => _showItemDetails(context, doc),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    Expanded(
                      flex: 7,
                      child: imgUrl != null
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(color: Colors.grey[200]),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text('Status: $status',
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
