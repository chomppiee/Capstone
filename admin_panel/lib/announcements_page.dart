import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:logging/logging.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  final Logger _log = Logger('Announcements');

  // Pick image from web
  Future<void> _pickImage() async {
    final image = await ImagePickerWeb.getImageAsBytes();
    if (image != null) {
      setState(() {
        _imageBytes = image;
        _imageName = 'announcement_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  // Upload announcement to Firestore (with optional image)
  Future<void> _uploadAnnouncement() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String imageUrl = "";
      if (_imageBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('announcements/$_imageName');
        await ref.putData(_imageBytes!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Announcement posted successfully.")),
      );
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _imageBytes = null;
        _imageName = null;
      });
    } catch (e, stack) {
      _log.severe("Error during announcement upload", e, stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
    setState(() {
      _isUploading = false;
    });
  }

  // Delete an announcement and its image (if any)
  Future<void> _deleteAnnouncement(String docId, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(docId)
          .delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final uri = Uri.parse(imageUrl);
        final parts = uri.path.split('/o/');
        if (parts.length > 1) {
          final filePathEncoded = parts[1];
          final filePath = Uri.decodeComponent(filePathEncoded);
          await FirebaseStorage.instance.ref().child(filePath).delete();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Announcement deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting announcement: $e")),
      );
    }
  }

  // Edit an existing announcement
  void _editAnnouncement(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentTitle = data['title'] ?? '';
    final currentDescription = data['description'] ?? '';

    final titleController = TextEditingController(text: currentTitle);
    final descriptionController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Announcement"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('announcements')
                    .doc(doc.id)
                    .update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Announcement updated.")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Post an Announcement",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: "Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: "Description", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Select Image (Optional)"),
            ),
            const SizedBox(height: 10),
            if (_imageBytes != null)
              Image.memory(_imageBytes!, height: 150, fit: BoxFit.cover),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadAnnouncement,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text("Post Announcement"),
            ),
            const SizedBox(height: 40),
            const Text("Announcements",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No announcements yet."));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: data['image_url'] != null &&
                                data['image_url'].toString().isNotEmpty
                            ? Image.network(data['image_url'],
                                width: 60, fit: BoxFit.cover)
                            : const Icon(Icons.announcement, size: 60),
                        title: Text(data['title'] ?? 'No Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? 'No Description'),
                            if (data['timestamp'] != null)
                              Text(
                                (data['timestamp'] as Timestamp)
                                    .toDate()
                                    .toLocal()
                                    .toString()
                                    .split('.')[0],
                                style: const TextStyle(
                                    fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editAnnouncement(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Delete Announcement"),
                                      content: const Text(
                                          "Are you sure you want to delete this announcement?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirm == true) {
                                  await _deleteAnnouncement(doc.id, data['image_url']);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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
