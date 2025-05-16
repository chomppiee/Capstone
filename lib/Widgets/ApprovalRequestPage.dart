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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Approval/Request"),
          backgroundColor: Colors.blue,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Donation Requests"),
              Tab(text: "Confirmations"),
              Tab(text: "Request Approvals"),
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
// ─── Tab 2: Confirmations (both donation and request receipts) ───
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('approvals')
    .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
    .where('confirmed',  isEqualTo: false)
    .where('type', whereIn: ['donation_request_accepted', 'request_fulfilled'])
    .orderBy('timestamp', descending: true)
    .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    // ← define docs here
    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return const Center(child: Text('No confirmations'));
    }

    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final approvalDoc  = docs[i];
        final data         = approvalDoc.data() as Map<String, dynamic>;

        // you can switch on data['type'] to customize text/buttons
        final isDonation   = data['type'] == 'donation_request_accepted';
        final buttonLabel  = isDonation ? 'Received' : 'Got it';
        final messageText  = isDonation
          ? 'Your donation request has been accepted!'
          : data['message'] ?? 'Your request was fulfilled.';

        return ListTile(
          title: Text(messageText),
          trailing: ElevatedButton(
            child: Text(buttonLabel),
            onPressed: () async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // 1) Update the donation or request status
  if (isDonation) {
    await FirebaseFirestore.instance
      .collection('donations')
      .doc(data['donationId'])
      .update({'status': 'received'});
  } else {
    await FirebaseFirestore.instance
      .collection('requests')
      .doc(data['requestId'])
      .update({'status': 'done'});
  }

  // 2) Increment the current user's points by 10
  await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .update({'points': FieldValue.increment(10)});

  // 3) Mark the approval doc as confirmed
  await approvalDoc.reference.update({
    'confirmed': true,
    'type': '${data['type']}_confirmed'
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('+10 points awarded!'))
  );
},

          ),
        );
      },
    );
  },
),

// ─── Tab 3: My Offers ───────────────────────────────────────────────
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('approvals')
      .where('donorId',   isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .where('type',      isEqualTo: 'request_approved')
      .where('confirmed', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    // 1) state checks
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    // 2) define docs here!
    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return const Center(child: Text('No pending offers'));
    }

    // 3) build list
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final approvalDoc = docs[i];
        final data        = approvalDoc.data() as Map<String, dynamic>;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('requests')
              .doc(data['requestId'])
              .get(),
          builder: (ctx2, reqSnap) {
            if (reqSnap.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }
            if (!reqSnap.hasData || !reqSnap.data!.exists) {
              return const ListTile(title: Text('Request not found'));
            }

            final req = reqSnap.data!.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(req['title'] ?? 'Unnamed Request'),
              subtitle: Text('Requester: ${req['username'] ?? 'Unknown'}'),
              trailing: ElevatedButton(
                child: const Text('Accept'),
                onPressed: () async {
                  // a) mark the request done
                  await FirebaseFirestore.instance
                      .collection('requests')
                      .doc(data['requestId'])
                      .update({'status': 'done'});

                  // b) mark this approval confirmed
                  await approvalDoc.reference.update({'confirmed': true});

                  // c) notify A that B has fulfilled
                  await FirebaseFirestore.instance
                      .collection('approvals')
                      .add({
                        'receiverId': req['userId'],          // A’s UID
                        'requestId':  data['requestId'],
                        'message':    'Your request for "${req['title']}" has been fulfilled. Please tap "Received" once you get it.',
                        'timestamp':  FieldValue.serverTimestamp(),
                        'type':       'request_fulfilled',
                        'confirmed':  false,
                      });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request fulfilled'))
                  );
                },
              ),
            );
          },
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
