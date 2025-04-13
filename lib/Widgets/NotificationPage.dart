import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatPage.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  // Helper: fetch a user's username from Firestore
  Future<String> _getSenderName(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['username'] ?? "Unknown";
    }
    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Notifications"),
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final requests = snapshot.data!.docs;
                if (requests.isEmpty)
                  return const Center(child: Text("No donation requests"));
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;
                    return FutureBuilder<String>(
                      future: _getSenderName(data['senderId']),
                      builder: (context, senderSnapshot) {
                        final senderName = senderSnapshot.data ?? "Loading...";
                        return ListTile(
                          title: Text("Request from: $senderName"),
                          subtitle: Text("Donation ID: ${data['donationId']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () async {
                                  try {
                                    // Accept the donation request.
                                    await request.reference.update({'status': 'accepted'});
                                    // Create a confirmation notification for the requester.
                                    await FirebaseFirestore.instance.collection('notifications').add({
                                      'receiverId': data['senderId'],
                                      'message':
                                          'Your donation request for donation ${data['donationId']} has been accepted.',
                                      'timestamp': FieldValue.serverTimestamp(),
                                      'type': 'donation_request_accepted',
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Request accepted. Confirmation sent.")),
                                    );
                                    // Navigate to ChatPage so the owner can start chatting with the requester.
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
            ),
            // Tab 2: Confirmations (notifications for the requester)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .where("receiverId", isEqualTo: currentUser.uid)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final notifs = snapshot.data!.docs;
                if (notifs.isEmpty)
                  return const Center(child: Text("No notifications"));
                return ListView.builder(
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    final data = notifs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data["message"] ?? "No message"),
                      subtitle: data["timestamp"] != null
                          ? Text((data["timestamp"] as Timestamp).toDate().toString())
                          : null,
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
