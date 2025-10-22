// lib/widgets/ChatWithAdminPage.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Replace this with your actual Admin user ID in Firebase Auth.
const String kAdminUid = 'YOUR_ADMIN_UID';

class ChatWithAdminPage extends StatefulWidget {
  const ChatWithAdminPage({super.key});

  @override
  State<ChatWithAdminPage> createState() => _ChatWithAdminPageState();
}

class _ChatWithAdminPageState extends State<ChatWithAdminPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final _messageController = TextEditingController();
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    // Generate a stable chatId so admin & user share the same thread.
    _chatId = _generateChatId(currentUser.uid, kAdminUid);
  }

  String _generateChatId(String a, String b) {
    return a.compareTo(b) <= 0 ? '$a-$b' : '$b-$a';
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId);

    // Update the chat document metadata.
    await chatRef.set({
      'participants': [currentUser.uid, kAdminUid],
      'lastMessage': text,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Add the actual message.
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Admin'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = docs[i].data()! as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser.uid;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
