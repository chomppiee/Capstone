// lib/admin_panel/AdminChatListPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AdminChatConversationPage.dart';

class AdminChatListPage extends StatelessWidget {
  const AdminChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Chats"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snap.data!.docs;
          if (chats.isEmpty) return const Center(child: Text("No active chats."));
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, i) {
              final doc = chats[i];
              final data = doc.data()! as Map<String, dynamic>;
              final participants = List<String>.from(data['participants'] ?? []);
              final lastMsg = data['lastMessage'] ?? '';
              final chatId  = doc.id;

              // Remove admin UID from display participants
              const adminUid = 'DCrRofsY8tTTD7xJldVnSaOOk0B2'; // define where you store this
              final otherUsers = participants.where((u) => u != adminUid).toList();
              final title = otherUsers.join(', ');

              return ListTile(
                leading: const Icon(Icons.forum, color: Colors.teal),
                title: Text(title.isNotEmpty ? title : "Unknown"),
                subtitle: Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminChatConversationPage(chatId: chatId, title: title),
                    ),
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
