import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatPage.dart';

class ApprovalRequestPage extends StatelessWidget {
  const ApprovalRequestPage({Key? key}) : super(key: key);

  // Helper: fetch a user's username from Firestore.
  Future<String> _getSenderName(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['username'] ?? "Unknown";
    }
    return "Unknown";
  }

  // Helper: fetch the donation title (product name) from a donation document using its id.
  Future<String> _getDonationTitle(String donationId) async {
    final doc =
        await FirebaseFirestore.instance.collection('donations').doc(donationId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['title'] ?? "Unknown Product";
    }
    return "Unknown Product";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Approval/Request"),
          backgroundColor: Colors.blue,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Requests"),
              Tab(text: "Confirmations"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Donation Requests (for donation owners)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donationRequests')
                  .where('receiverId', isEqualTo: currentUser.uid)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final requests = snapshot.data?.docs;
                if (requests == null || requests.isEmpty) {
                  return const Center(child: Text("No donation requests"));
                }
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;
                    return FutureBuilder<String>(
                      future: _getDonationTitle(data['donationId']),
                      builder: (context, donationSnapshot) {
                        final donationTitle = donationSnapshot.data ?? "Loading...";
                        return FutureBuilder<String>(
                          future: _getSenderName(data['senderId']),
                          builder: (context, senderSnapshot) {
                            final senderName = senderSnapshot.data ?? "Loading...";
                            return ListTile(
                              title: Text("Request from: $senderName"),
                              subtitle: Text("Product: $donationTitle"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Accept button.
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () async {
                                      try {
                                        // Accept the donation request.
                                        await request.reference.update({'status': 'accepted'});
                                        
                                        // Retrieve the donation document.
                                        DocumentSnapshot donationDoc = await FirebaseFirestore.instance
                                            .collection('donations')
                                            .doc(data['donationId'])
                                            .get();
                                        String approvalMessage;
                                        if (donationDoc.exists && donationDoc.data() != null) {
                                          final donationData = donationDoc.data() as Map<String, dynamic>;
                                          if (donationData.containsKey('claimedBy')) {
                                            approvalMessage =
                                                'Your donation request for "$donationTitle" has been accepted and the product has been claimed.';
                                          } else {
                                            approvalMessage =
                                                'Your donation request for "$donationTitle" has been accepted. Please click "Receive" when you have the product.';
                                          }
                                        } else {
                                          approvalMessage =
                                              'Your donation request for "$donationTitle" has been accepted. Please click "Receive" when you have the product.';
                                        }
                                        // Create a confirmation approval in the "approvals" collection with confirmed=false.
                                        await FirebaseFirestore.instance.collection('approvals').add({
                                          'receiverId': data['senderId'],
                                          'message': approvalMessage,
                                          'donationId': data['donationId'],
                                          'timestamp': FieldValue.serverTimestamp(),
                                          'type': 'donation_request_accepted',
                                          'confirmed': false,
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Request accepted. Approval sent.")),
                                        );
                                        // Navigate to ChatPage.
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatPage(
                                              recipientId: data['senderId'],
                                              recipientName: senderName,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        print("Error accepting request: $e");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error accepting request: $e")),
                                        );
                                      }
                                    },
                                  ),
                                  // Decline button.
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () async {
                                      try {
                                        await request.reference.update({'status': 'declined'});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Request declined")),
                                        );
                                      } catch (e) {
                                        print("Error declining request: $e");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error declining request: $e")),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            // Tab 2: Confirmations - show approval notifications for requesters.
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('approvals')
                  .where('receiverId', isEqualTo: currentUser.uid)
                  .where('type', isEqualTo: 'donation_request_accepted')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final approvals = snapshot.data?.docs;
                if (approvals == null || approvals.isEmpty) {
                  return const Center(child: Text("No confirmations"));
                }
                return ListView.builder(
                  itemCount: approvals.length,
                  itemBuilder: (context, index) {
                    final approvalData = approvals[index].data() as Map<String, dynamic>;
                    // Show the "Receive" button if not confirmed.
                    final isConfirmed = approvalData['confirmed'] == true;
                    return ListTile(
                      title: Text(approvalData["message"] ?? "No message"),
                      subtitle: approvalData["timestamp"] != null
                          ? Text((approvalData["timestamp"] as Timestamp).toDate().toString())
                          : null,
                      trailing: isConfirmed
                          ? const Text("Received", style: TextStyle(color: Colors.green))
                          : ElevatedButton(
                              onPressed: () async {
                                try {
                                  // When the requester taps "Receive," mark the donation as claimed.
                                  await FirebaseFirestore.instance
                                      .collection('donations')
                                      .doc(approvalData['donationId'])
                                      .update({'claimedBy': currentUser.uid});
                                  // Update the approval document to mark it as confirmed.
                                  await approvals[index].reference.update({
                                    'confirmed': true,
                                    'type': 'donation_request_confirmed'
                                  });
                                  // Update donor's points by incrementing by 10.
                                  // The donor is the one who posted the donation.
                                  DocumentSnapshot donationDoc = await FirebaseFirestore.instance
                                      .collection('donations')
                                      .doc(approvalData['donationId'])
                                      .get();
                                  if (donationDoc.exists) {
                                    final donationData = donationDoc.data() as Map<String, dynamic>;
                                    String donorId = donationData['userId'];
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(donorId)
                                        .update({'points': FieldValue.increment(10)});
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Donation confirmed. Points added.")),
                                  );
                                } catch (e) {
                                  print("Error confirming donation: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error confirming donation: $e")),
                                  );
                                }
                              },
                              child: const Text("Receive"),
                            ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
