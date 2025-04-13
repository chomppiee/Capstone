import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:segregate1/Widgets/services/firebase_service.dart';
import 'DonationDetailsPage.dart'; // Make sure this page is implemented

class DonationList extends StatelessWidget {
  const DonationList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final donations = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 0,
            crossAxisSpacing: 3,
            childAspectRatio: 0.7, // Adjust to fit your card design
          ),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index].data() as Map<String, dynamic>;
            final donationId = donations[index].id;
            final isOwner = donation['userId'] == currentUser?.uid;

            return GestureDetector(
              onTap: () => _showDonationDetails(context, donation, donationId, isOwner),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // Adjust roundness here if needed
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Donation picture at the top wrapped in a Hero widget for animation
                      Expanded(
                        child: Hero(
                          tag: 'donationImage-$donationId',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                            child: Image.network(
                              donation['imageUrl']!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Text('Image failed to load')),
                            ),
                          ),
                        ),
                      ),
                      // Title of the donation
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
                      // Owner information
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Text(
                          "by ${donation['username'] ?? 'Anonymous'}",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Navigates to a full-screen DonationDetailsPage.
  void _showDonationDetails(
    BuildContext context,
    Map<String, dynamic> donation,
    String donationId,
    bool isOwner,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonationDetailsPage(
          donation: donation,
          donationId: donationId,
        ),
      ),
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
              Navigator.pop(context); // Close the expanded view after claiming
            },
          ),
        ],
      );
    },
  );
}
