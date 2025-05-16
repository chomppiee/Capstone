// lib/Widgets/DonationList.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DonationDetailsPage.dart';

class DonationList extends StatelessWidget {
  const DonationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      // Only show donations that are approved but not yet received
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'Approved')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final donations = snapshot.data!.docs;
        if (donations.isEmpty) {
          return const Center(child: Text('No available donations'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final doc = donations[index];
            final donation = doc.data()! as Map<String, dynamic>;
            final donationId = doc.id;
            final isOwner = donation['userId'] == currentUser?.uid;

            return GestureDetector(
              onTap: () => _showDonationDetails(
                  context, donation, donationId, isOwner),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Donation picture
                    Expanded(
                      child: Hero(
                        tag: 'donationImage-$donationId',
                        child: Image.network(
                          donation['imageUrl'] ?? '',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        donation['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Posted by
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        'by ${donation['username'] ?? 'Anonymous'}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
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

  void _showDonationDetails(
      BuildContext context,
      Map<String, dynamic> donation,
      String donationId,
      bool isOwner,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonationDetailsPage(
          donation: donation,
          donationId: donationId,
        ),
      ),
    );
  }
}
