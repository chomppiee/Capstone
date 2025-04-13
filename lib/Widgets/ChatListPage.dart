import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatPage.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({Key? key}) : super(key: key);

  // A helper method to get a user's name from Firestore based on their UID.
  Future<String> _getUserName(String uid) async {
    final DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['username'] ?? "Unknown";
    }
    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final data = chatDoc.data() as Map<String, dynamic>;
              // Get the list of participants.
              final List participants = data["participants"] ?? [];
              // Determine the other user's ID.
              final String otherUserId = participants.firstWhere(
                  (id) => id != currentUser.uid,
                  orElse: () => "Unknown");
              final String lastMessage = data["lastMessage"] ?? "";
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final String otherUserName =
                      userData['username'] ?? "Unknown";
                  return ListTile(
                    title: Text(otherUserName),
                    subtitle: Text(lastMessage),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            recipientId: otherUserId,
                            recipientName: otherUserName,
                          ),
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
    );
  }
}
