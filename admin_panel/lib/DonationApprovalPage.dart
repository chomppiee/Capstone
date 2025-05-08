// lib/Widgets/DonationApprovalPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationApprovalPage extends StatelessWidget {
  const DonationApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final unapprovedStream = FirebaseFirestore.instance
        .collection('donations')
        .where('approved', isEqualTo: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Donations'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: unapprovedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No pending donations"));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;
              final imageUrl = data['imageUrl'] as String? ?? '';
              final title = data['title'] as String? ?? 'No Title';
              final desc = data['description'] as String? ?? 'No Description';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  // Show a small thumbnail or default icon
                  leading: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 50),
                  title: Text(title),
                  subtitle: Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // When tapped, show all details
                  onTap: () => _showDonationDetails(context, doc.id),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => doc.reference.update({'approved': true}),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => doc.reference.delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDonationDetails(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .doc(docId)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>;

          final imageUrl = data['imageUrl'] as String? ?? '';
          final title = data['title'] as String? ?? 'No Title';
          final description = data['description'] as String? ?? 'No Description';
          final category = data['category'] as String? ?? 'Unspecified';
          final pickupTime = data['pickupTime'] as String? ?? 'N/A';
          final username = data['username'] as String? ?? 'Unknown';
          final userId = data['userId'] as String? ?? 'N/A';
          final timestamp = data['timestamp'] as Timestamp?;

          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imageUrl, height: 150, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 12),
                  Text(description),
                  const SizedBox(height: 12),
                  Text('Category: $category', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Pickup Time: $pickupTime', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('Posted by: $username (ID: $userId)'),
                  if (timestamp != null)
                    Text(
                      'Posted at: ${timestamp.toDate().toLocal()}'.split('.')[0],
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
