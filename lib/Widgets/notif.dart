// lib/Widgets/notif.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
           '${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to see notifications.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Error loading notifications'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              return ListTile(
                leading: Icon(
                  data['type'] == 'donationApproved'
                      ? Icons.check_circle
                      : Icons.notifications,
                  color: data['read'] == true
                      ? Colors.grey
                      : Colors.blueAccent,
                ),
                title: Text(data['message'] ?? ''),
                subtitle:
                    ts != null ? Text(_formatTimestamp(ts)) : null,
                onTap: () async {
                  // mark as read:
                  await docs[i].reference.update({'read': true});
                  // you could also navigate to the donation details page here:
                  // Navigator.push(...)
                },
              );
            },
          );
        },
      ),
    );
  }
}
