// lib/Widgets/DonationApprovalPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DonationApprovalPage extends StatelessWidget {
  const DonationApprovalPage({Key? key}) : super(key: key);

  Future<void> _approveDonation(
      BuildContext context, String donationId) async {
    final docRef =
        FirebaseFirestore.instance.collection('donations').doc(donationId);

    // 1) Mark donation approved
    await docRef.update({
      'approved': true,
      'status': 'Approved',
      'qrData': donationId,
    });

    // 2) Notify donor via Firestore
    final snap = await docRef.get();
    final donorUid = (snap.data()?['userId'] as String?);
    final title = (snap.data()?['title'] as String?) ?? 'Your donation';
    if (donorUid != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'to': donorUid,
        'type': 'donationApproved',
        'donationId': donationId,
        'message': '“$title” has been approved! Show your QR code when dropping off.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    // 3) Optional push via Cloud Function
    try {
      await FirebaseFunctions.instance
          .httpsCallable('notifyDonationApproved')
          .call({'donationId': donationId});
    } catch (e) {
      debugPrint('Cloud Function error: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation approved & donor notified')),
    );
  }

  void _showPendingDonations(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.8;
    final height = MediaQuery.of(context).size.height * 0.6;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 8, 0),
        title: Row(
          children: [
            const Expanded(child: Text('Pending Donations')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: width,
          height: height,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donations')
                .where('approved', isEqualTo: false)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return const Center(child: Text('Failed to load'));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No pending donations'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final data = doc.data()! as Map<String, dynamic>;
                  final title = data['title'] as String? ?? 'No Title';
                  final status = data['status'] as String? ?? 'Pending';

                  return ListTile(
                    leading: data['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              data['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                    title: Text(title),
                    subtitle: Text('Status: $status'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _approveDonation(context, doc.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await doc.reference.delete();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Donation deleted')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDonationDetails(BuildContext context, String docId) {
    final width = MediaQuery.of(context).size.width * 0.2;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donations')
                .doc(docId)
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snap.data!.data()! as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'Pending';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imageUrl'],
                          width: width * 0.7,
                          fit: BoxFit.contain,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      data['title'] as String? ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(data['description'] as String? ?? ''),
                    const SizedBox(height: 8),
                    Text('Category: ${data['category'] ?? 'Unspecified'}'),
                    const SizedBox(height: 8),
                    Text('Status: $status'),
                    const SizedBox(height: 8),
                    Text('Posted by: ${data['username'] ?? 'Unknown'}'),
                    if (data['createdAt'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'At: ${(data['createdAt'] as Timestamp).toDate().toLocal()}',
                          style: const TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Donations'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('donations')
              .where('approved', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return const Center(child: Text('Failed to load'));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No donations approved yet.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxis = constraints.maxWidth > 600 ? 4 : 2;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 4 / 6,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data()! as Map<String, dynamic>;
                    final title = data['title'] as String? ?? '';
                    final imageUrl = data['imageUrl'] as String?;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () => _showDonationDetails(context, doc.id),
                        child: Column(
                          children: [
                            Expanded(
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey[200]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
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
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPendingDonations(context),
        icon: const Icon(Icons.pending_actions),
        label: const Text('Pending'),
        backgroundColor: Colors.orange,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}
