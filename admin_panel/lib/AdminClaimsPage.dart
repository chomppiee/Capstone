// lib/Widgets/AdminClaimsPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'AdminAccountClaimsPage.dart';

class AdminClaimsPage extends StatelessWidget {
  const AdminClaimsPage({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _accountsStream() {
    return FirebaseFirestore.instance
        .collection('third_party_accounts')
        .orderBy('company', descending: false)
        .snapshots();
  }

  Future<int> _reservedCountFor(String uid) async {
    // Count reserved by this UID; using simple get(). If you prefer Aggregate Query:
    // return (await FirebaseFirestore.instance.collection('third_party_inventory')
    //   .where('reservedByUid', isEqualTo: uid).count().get()).count;
    final q = await FirebaseFirestore.instance
        .collection('third_party_inventory')
        .where('reservedByUid', isEqualTo: uid)
        .get();
    return q.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final stream = _accountsStream();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claims — Third-Party Accounts'),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final accounts = snap.data?.docs ?? [];
          if (accounts.isEmpty) {
            return const Center(child: Text('No third-party accounts found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = accounts[i];
              final m = d.data()! as Map<String, dynamic>;
              final uid = d.id;
              final company = (m['company'] ?? '').toString();
              final contactName = (m['contactName'] ?? '').toString();
              final email = (m['email'] ?? '').toString();
              final phone = (m['phone'] ?? '').toString();
              final status = (m['status'] ?? '').toString();

              final displayName = company.isNotEmpty
                  ? company
                  : (contactName.isNotEmpty ? contactName : (email.isNotEmpty ? email : uid));

              return Card(
                child: ListTile(
                  title: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (company.isNotEmpty) Text('Company: $company'),
                      if (contactName.isNotEmpty) Text('Contact: $contactName'),
                      if (email.isNotEmpty) Text('Email: $email'),
                      if (phone.isNotEmpty) Text('Phone: $phone'),
                      if (status.isNotEmpty) Text('Status: $status'),
                    ],
                  ),
                  trailing: FutureBuilder<int>(
                    future: _reservedCountFor(uid),
                    builder: (context, countSnap) {
                      final cnt = countSnap.data ?? 0;
                      return Chip(
                        label: Text('$cnt reserved'),
                        backgroundColor: Colors.blue.withOpacity(0.12),
                        labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminAccountClaimsPage(
                          accountUid: uid,
                          accountDisplayName: displayName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
