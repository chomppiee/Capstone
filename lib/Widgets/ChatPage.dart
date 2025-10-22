import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatPage({
    Key? key,
    required this.recipientId,
    required this.recipientName,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User currentUser = FirebaseAuth.instance.currentUser!;
  late final String chatId;

  @override
  void initState() {
    super.initState();
    chatId = _generateChatId(currentUser.uid, widget.recipientId);
  }

  String _generateChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) <= 0 ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  void _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Use the current user's displayName or fallback to "Anonymous"
    final String senderName = currentUser.displayName ?? "Anonymous";

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Update or create the main chat document with conversation details.
    // Note: "otherUserName" is set to widget.recipientName regardless of who sends the message.
    await chatRef.set({
      'participants': [currentUser.uid, widget.recipientId],
      'otherUserName': widget.recipientName,
      'lastMessage': text,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save the message with senderName.
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': currentUser.uid,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text(widget.recipientName),
  backgroundColor: Colors.blue,
  actions: [
    IconButton(
      icon: const Icon(
        Icons.support_agent,
        color: Colors.white,    // ← force it to white
      ),
      tooltip: 'Chat with Admin',
      onPressed: () {
        // ...
      },
    ),
  ],
),
      body: Column(
        children: [
          // Chat messages list.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUser.uid;
                    // Display the stored senderName from Firestore.
                    final String senderDisplayName = data['senderName'] ?? "Anonymous";
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderDisplayName,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Message input field.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
