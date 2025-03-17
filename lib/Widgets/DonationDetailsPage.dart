import 'package:flutter/material.dart';

class DonationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> donation;
  final String donationId;

  const DonationDetailsPage({
    super.key,
    required this.donation,
    required this.donationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: Text(donation['title']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(donation['imageUrl'], height: 200, fit: BoxFit.cover),
            const SizedBox(height: 15),
            Text(
              donation['title'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(donation['description'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Example logic when "Claim" is clicked:
                // Update the status in Firestore (optional)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Donation claimed!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Claim', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
