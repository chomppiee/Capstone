import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:logging/logging.dart';

class CommunityHighlightsPage extends StatefulWidget {
  const CommunityHighlightsPage({super.key});

  @override
  State<CommunityHighlightsPage> createState() => _CommunityHighlightsPageState();
}

class _CommunityHighlightsPageState extends State<CommunityHighlightsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;
  DateTime? _selectedDateTime; // New variable for storing the picked date & time

  final Logger _log = Logger('CommunityHighlights');

  Future<void> _pickImage() async {
    final image = await ImagePickerWeb.getImageAsBytes();
    if (image != null) {
      setState(() {
        _imageBytes = image;
        _imageName = 'highlight_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  // New function to pick date and time
  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _uploadHighlight() async {
    // Check for required fields (title, description, image, and date_time)
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _imageBytes == null ||
        _selectedDateTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields, select an image, and pick a date & time.")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      _log.info("Uploading image to Firebase Storage...");
      final ref = FirebaseStorage.instance
          .ref()
          .child('community_highlights/$_imageName');

      await ref.putData(_imageBytes!);
      final imageUrl = await ref.getDownloadURL();

      _log.info("Image uploaded successfully. URL: $imageUrl");

      // Save highlight document with the chosen date & time
      await FirebaseFirestore.instance.collection('community_highlights').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'date_time': Timestamp.fromDate(_selectedDateTime!),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _log.info("Highlight successfully saved to Firestore.");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Highlight uploaded successfully.")),
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _imageBytes = null;
        _imageName = null;
        _selectedDateTime = null;
      });
    } catch (e, stack) {
      _log.severe("Error during highlight upload", e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (!mounted) return;
    setState(() {
      _isUploading = false;
    });
  }

  // Deletes the highlight document and its image from storage
  Future<void> _deleteHighlight(String docId, String? imageUrl) async {
    try {
      // Delete the Firestore document
      await FirebaseFirestore.instance
          .collection('community_highlights')
          .doc(docId)
          .delete();

      // Delete the image from Firebase Storage (if available)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final uri = Uri.parse(imageUrl);
        // The file path is the part after '/o/'
        final parts = uri.path.split('/o/');
        if (parts.length > 1) {
          final filePathEncoded = parts[1];
          final filePath = Uri.decodeComponent(filePathEncoded);
          await FirebaseStorage.instance.ref().child(filePath).delete();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Highlight deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting highlight: $e")),
      );
    }
  }

  // Opens a dialog to edit the highlight
  void _editHighlight(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentTitle = data['title'] ?? '';
    final currentDescription = data['description'] ?? '';

    final titleController = TextEditingController(text: currentTitle);
    final descriptionController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Highlight"),
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
                    .collection('community_highlights')
                    .doc(doc.id)
                    .update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Highlight updated.")),
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add Community Highlight", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text("Select Image"),
          ),
          const SizedBox(height: 10),
          if (_imageBytes != null)
            Image.memory(_imageBytes!, height: 150),
          const SizedBox(height: 10),
          // New button to pick date and time
          ElevatedButton.icon(
            onPressed: _pickDateTime,
            icon: const Icon(Icons.calendar_today),
            label: const Text("Select Date & Time"),
          ),
          const SizedBox(height: 5),
          if (_selectedDateTime != null)
            Text(
              "Selected: ${_selectedDateTime!.toLocal()}".split('.')[0],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadHighlight,
            child: _isUploading
                ? const CircularProgressIndicator()
                : const Text("Upload Highlight"),
          ),
          const SizedBox(height: 40),
          const Text("Uploaded Highlights", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_highlights')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No highlights uploaded yet.");
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
                      leading: data['image_url'] != null
                          ? Image.network(data['image_url'], width: 60, fit: BoxFit.cover)
                          : const Icon(Icons.image),
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['description'] ?? 'No Description'),
                          // Optionally, display the selected date/time stored for the highlight:
                          if (data['date_time'] != null)
                            Text(
                              (data['date_time'] as Timestamp).toDate().toLocal().toString().split('.')[0],
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editHighlight(doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Delete Highlight"),
                                    content: const Text("Are you sure you want to delete this highlight?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirm == true) {
                                await _deleteHighlight(doc.id, data['image_url']);
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
    );
  }
}
