import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:segregate1/Widgets/ChatPage.dart';

class RequestList extends StatelessWidget {
  const RequestList({super.key});

  /// Shows detailed information about a request.
  /// If the current user is not the requester, a Message button is shown.
  /// If the current user is the requester and the request status is "pending_confirmation",
  /// a Receive button is shown which marks the request as done.
  void _showRequestDetails(
      BuildContext context, Map<String, dynamic> request, String requestId) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    bool isOwner = request['userId'] == currentUser.uid;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Request Image
                request['imageUrl'] != null &&
                        request['imageUrl'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          request['imageUrl'],
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text("Image error")),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image,
                              size: 50, color: Colors.grey),
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['title'] ?? 'No Title',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        request['reason'] ?? 'No Details',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      // If the current user is not the owner, show a Message button.
                      if (!isOwner)
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Update the request document: set donorId and change status.
                              await FirebaseFirestore.instance
                                  .collection('requests')
                                  .doc(requestId)
                                  .update({
                                'donorId': currentUser.uid,
                                'status': 'pending_confirmation',
                              });
                              // Create an approval document in a new collection "approvals".
                              await FirebaseFirestore.instance
                                  .collection('approvals')
                                  .add({
                                'requestId': requestId,
                                'receiverId': request['userId'], // requester
                                'donorId': currentUser.uid,
                                'timestamp': FieldValue.serverTimestamp(),
                                'confirmed': false,
                                'type': 'request_approved',
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Message sent. Please click 'Received' when you get the item.")),
                              );
                              // Navigate to ChatPage with the requester.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    recipientId: request['userId'],
                                    recipientName: request['username'] ?? 'User',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Error sending message: $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text("Message",
                              style: TextStyle(color: Colors.white)),
                        ),
                      // If the current user is the owner and status is pending_confirmation,
                      // show a "Received" button.
                      if (isOwner && request['status'] == 'pending_confirmation')
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Find the matching approval document.
                              QuerySnapshot approvalSnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('approvals')
                                  .where('requestId', isEqualTo: requestId)
                                  .where('receiverId', isEqualTo: currentUser.uid)
                                  .get();
                              if (approvalSnapshot.docs.isNotEmpty) {
                                // Update the first matching approval to confirmed.
                                await approvalSnapshot.docs.first.reference
                                    .update({'confirmed': true});
                                // Update the request document to mark it as done.
                                await FirebaseFirestore.instance
                                    .collection('requests')
                                    .doc(requestId)
                                    .update({'status': 'done'});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Request confirmed as received.")),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Error confirming request: $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                          child: const Text("Received",
                              style: TextStyle(color: Colors.white)),
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Close"),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text("Error loading requests: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No requests yet."));
        }
        final requests = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 3,
            childAspectRatio: 0.7,
          ),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;
            final requestId = requests[index].id;
            return GestureDetector(
              onTap: () => _showRequestDetails(context, request, requestId),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request image.
                    Expanded(
                      child: request['imageUrl'] != null &&
                              request['imageUrl'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                request['imageUrl'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(child: Text("Image error")),
                              ),
                            )
                          : Container(
                              height: double.infinity,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey)),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        request['title'] ?? 'No Title',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        request['reason'] ?? 'No Details',
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
}
