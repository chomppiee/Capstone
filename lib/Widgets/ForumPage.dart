import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:segregate1/Widgets/Dashboard.dart';
import 'package:segregate1/Widgets/DonationPage.dart';
import 'package:segregate1/Widgets/EventPage.dart';
import 'package:segregate1/Widgets/ProfilePage.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  const UserAvatar({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            backgroundColor: Colors.grey,
          );
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String profileImage = data['profileImage'] ?? "";
          if (profileImage.isNotEmpty) {
            return CircleAvatar(
              backgroundImage: NetworkImage(profileImage),
            );
          }
        }
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        );
      },
    );
  }
}

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  void _postMessage() async {
    if (_commentController.text.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      await FirebaseFirestore.instance.collection('forum').add({
        'message': _commentController.text,
        'fullname': userDoc['fullname'],
        'username': userDoc['username'],
        'userId': currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    }
  }

  Future<void> _editMessage(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final TextEditingController editController =
        TextEditingController(text: data['message'] ?? "");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Comment"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: "Comment"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('forum')
                  .doc(doc.id)
                  .update({'message': editController.text});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Comment updated.")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(DocumentSnapshot doc, Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Copy"),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message['message']));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Copied to clipboard")));
                },
              ),
              if (message['userId'] == currentUser!.uid)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Edit"),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(doc);
                  },
                ),
              if (message['userId'] == currentUser!.uid)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(context);
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: const Text('Confirm Delete'),
                        content: const Text('Are you sure you want to delete this comment?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                    if (shouldDelete ?? false) {
                      await FirebaseFirestore.instance.collection('forum').doc(doc.id).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment deleted successfully')));
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message, DocumentSnapshot doc) {
    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(doc, message);
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: UserAvatar(
            userId: message['userId'] ?? "",
          ),
          title: Text(
            message['username'] ?? 'Anonymous',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(message['message']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const DashboardPage()));
              break;
            case 1:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const DonationPage()));
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventPage()),
              );
              break;
            case 3:
              break; // Already on Forum Page
            case 4:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Donation'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 45), // Added top padding of 45
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Community Forum',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.black54),
                    onPressed: () {
                      // TODO: Implement notification functionality
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('forum')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final doc = messages[index];
                      final message = doc.data() as Map<String, dynamic>;
                      return _buildMessageCard(message, doc);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Add your message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1E88E5)),
                    onPressed: _postMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
