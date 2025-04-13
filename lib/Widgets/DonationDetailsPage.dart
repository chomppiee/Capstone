import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:segregate1/Widgets/services/firebase_service.dart';
import 'package:segregate1/Widgets/Chatpage.dart';

class DonationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> donation;
  final String donationId;

  const DonationDetailsPage({
    Key? key,
    required this.donation,
    required this.donationId,
  }) : super(key: key);

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
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve category from donation; if missing, use a default value.
    final String category = (donation['category'] != null &&
            donation['category'].toString().isNotEmpty)
        ? donation['category']
        : 'No Category';

    // Retrieve pickup time from donation; default to "Not provided".
    final String pickupTime = donation['pickupTime'] ?? 'Not provided';

    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = donation['userId'] == currentUser?.uid;
    final bool isClaimed = donation.containsKey('claimedBy');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: Text(donation['title'] ?? 'Donation Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full image using Hero animation and 60% of screen height.
            Hero(
              tag: 'donationImage-$donationId',
              child: Image.network(
                donation['imageUrl'] ?? '',
                height: MediaQuery.of(context).size.height * 0.6,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 60),
              ),
            ),
            const SizedBox(height: 15),
            // Title and Category Row.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      donation['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Description.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                donation['description'] ?? 'No Description',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 15),
            // Pickup Time Details.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Available Pickup Time: $pickupTime',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            // Buttons Section.
            if (!isOwner && !isClaimed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () async {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    await FirebaseFirestore.instance.collection('donationRequests').add({
                      'senderId': currentUser!.uid,
                      'receiverId': donation['userId'], // donation owner
                      'donationId': donationId,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Donation request sent")),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          recipientId: donation['userId'],
                          recipientName: donation['username'] ?? 'User',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Message', style: TextStyle(color: Colors.white)),
                ),
              ),
            if (isClaimed)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    'This donation has already been claimed.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (isOwner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => _showDeleteConfirmation(context, donationId),
                  child: const Text('Delete'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
