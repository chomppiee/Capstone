// lib/admin_panel/AdminChatConversationPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatConversationPage extends StatefulWidget {
  final String chatId;
  final String title;
  const AdminChatConversationPage({
    super.key,
    required this.chatId,
    required this.title,
  });
  @override
  State<AdminChatConversationPage> createState() => _AdminChatConversationPageState();
}

class _AdminChatConversationPageState extends State<AdminChatConversationPage> {
  final _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!; // Admin
  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.teal),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i].data()! as Map<String, dynamic>;
                    final isMe = m['senderId'] == currentUser.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
                    await chatDoc.set({
                      'lastMessage': text,
                      'timestamp': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    await chatDoc.collection('messages').add({
                      'text': text,
                      'senderId': currentUser.uid,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
