// lib/Widgets/NotificationPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp ts) {
    return DateFormat.yMd().add_jm().format(ts.toDate().toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body:
            const Center(child: Text('Please sign in to view notifications.')),
      );
    }

    final notifications = FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: notifications,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError)
            return const Center(child: Text('Error loading notifications'));

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No notifications yet.'));

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data()! as Map<String, dynamic>;
              final bool read = data['read'] as bool? ?? false;
              final String type = data['type'] as String? ?? '';
              final String message = data['message'] as String? ?? '';
              final Timestamp? ts = data['timestamp'] as Timestamp?;

              return ListTile(
                  leading: Icon(
  type == 'donationApproved'
      ? Icons.check_circle
      : type == 'donationDeclined'
          ? Icons.cancel
          : Icons.notifications,
  color: type == 'donationApproved'
      ? Colors.green
      : type == 'donationDeclined'
          ? Colors.red
          : Colors.grey,
),

                title: Text(message),
                subtitle: ts != null ? Text(_formatTimestamp(ts)) : null,
                tileColor: read ? null : Colors.blue.withOpacity(0.1),
                onTap: () async {
                  // mark it read
                  if (!read) await doc.reference.update({'read': true});

                  // if it’s an approval, show a simple reminder dialog
                  if (type == 'donationApproved') {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Donation Approved'),
                        content: const Text(
                          'Your donation has been approved! '
                          'Please bring your items to the barangay office and show this notification if needed.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
