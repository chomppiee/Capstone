import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:segregate1/ChatWithAdminPage.dart';
import 'ChatPage.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({Key? key}) : super(key: key);

  /// Fetches the username for [uid], or returns "Unknown" if not found.
  Future<String> _getUserName(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return "Unknown";
    final data = doc.data();
    if (data == null) return "Unknown";
    return (data['username'] as String?) ?? "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
  title: Text('Chats'),
  backgroundColor: Colors.blue,
  actions: [
    IconButton(
      icon: const Icon(Icons.support_agent),
      tooltip: 'Chat with Admin',
      onPressed: () {
       Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatWithAdminPage()),
    );
      },
    ),
  ],
),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          final chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              // Pull participants list safely
              final rawList = chatData['participants'];
              final participants = <String>[];
              if (rawList is List) {
                for (var id in rawList) {
                  if (id is String) participants.add(id);
                }
              }

              // Find the other user's UID
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => "",
              );

              final lastMessage = (chatData['lastMessage'] as String?) ?? "";

              return FutureBuilder<String>(
                future: _getUserName(otherUserId),
                builder: (context, nameSnapshot) {
                  // While fetching username
                  if (nameSnapshot.connectionState != ConnectionState.done) {
                    return const ListTile(title: Text("Loading..."));
                  }
                  final otherUserName = nameSnapshot.data ?? "Unknown";

                  return ListTile(
                    title: Text(otherUserName),
                    subtitle: Text(lastMessage),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
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
