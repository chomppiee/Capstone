// lib/Widgets/ThirdPartyClaimPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ThirdPartyClaimPage extends StatelessWidget {
  const ThirdPartyClaimPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Reserved Items')),
        body: const Center(child: Text('You must be logged in to view this page.')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('third_party_inventory')
        .where('status', isEqualTo: 'Reserved')
        .where('reservedByUid', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Reserved Items')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reserved items yet.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final title =
                  (data['itemName'] ?? data['title'] ?? 'Untitled').toString();
              final category = (data['category'] ?? 'Uncategorized').toString();
              final imageUrl =
                  (data['imageUrl'] ?? data['photoUrl'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: _Thumb(imageUrl: imageUrl),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Category: $category'),
                  trailing: const Chip(
                    label: Text('Reserved'),
                    backgroundColor: Color(0x24FFA726), // orange-ish
                    labelStyle: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    // Optional: open detail dialog (reuse from Home if you want)
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

class _Thumb extends StatelessWidget {
  final String imageUrl;
  const _Thumb({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const SizedBox(
        width: 56, height: 56,
        child: Icon(Icons.image_not_supported),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover, // small thumb can be cropped
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 56, height: 56,
          child: Icon(Icons.broken_image),
        ),
      ),
    );
  }
}
