import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:segregate1/Widgets/services/firebase_service.dart';

class DonationList extends StatelessWidget {
  const DonationList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('donations')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final donations = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index].data() as Map<String, dynamic>;
            final donationId = donations[index].id;
            final isOwner = donation['userId'] == currentUser?.uid;

            return GestureDetector(
              onTap:
                  () => _showDonationDetails(
                    context,
                    donation,
                    donationId,
                    isOwner,
                  ),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(donation['username'] ?? 'Anonymous'),
                      trailing:
                          isOwner
                              ? IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  _showDeleteConfirmation(context, donationId);
                                },
                              )
                              : null,
                    ),
                    Image.network(
                      donation['imageUrl']!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Image failed to load'),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        donation['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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

  void _showDeleteConfirmation(BuildContext context, String donationId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Donation'),
          content: const Text('Are you sure you want to delete this donation?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await deleteDonation(donationId);
                Navigator.pop(dialogContext);
              },
            ),
          ],
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isClaimed = donation.containsKey('claimedBy');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    donation['imageUrl']!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('Image failed to load'));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        donation['description'] ?? 'No Description',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),

                      // 🔥 Show "Claim" button if the user is NOT the owner
                      if (!isOwner && !isClaimed)
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _showClaimConfirmation(
                                context,
                                donationId,
                                currentUser!.uid,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text(
                              'Claim Donation',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),

                      if (isClaimed)
                        Center(
                          child: const Text(
                            'This donation has already been claimed.',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (isOwner)
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              _showDeleteConfirmation(context, donationId);
                            },
                            child: const Text('Delete'),
                          ),
                        ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _showClaimConfirmation(
  BuildContext context,
  String donationId,
  String userId,
) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Claim Donation'),
        content: const Text('Are you sure you want to claim this donation?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: const Text('Claim', style: TextStyle(color: Colors.green)),
            onPressed: () async {
              await claimDonation(donationId, userId);
              Navigator.pop(dialogContext);
              Navigator.pop(
                context,
              ); // ✅ Close the expanded view after claiming
            },
          ),
        ],
      );
    },
  );
}
