import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:segregate1/Widgets/services/image_service.dart';

/// Function to post a request to Firestore.
/// The image is optional; if no image is provided, an empty string is saved.
Future<void> postRequest(
  String title,
  String reason,
  String? imagePath, // optional
  String category,
  BuildContext context,
) async {
  if (title.isEmpty || reason.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields')),
    );
    return;
  }
  try {
    final currentUser = FirebaseAuth.instance.currentUser!;
    // Retrieve username from the user document.
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final username = userDoc.exists
        ? (userDoc.data() as Map<String, dynamic>)['username'] ?? 'Unknown User'
        : 'Unknown User';

    String imageUrl = "";
    if (imagePath != null && imagePath.isNotEmpty) {
      final storageRef = FirebaseStorage.instance.ref().child(
        'request_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await storageRef.putFile(File(imagePath));
      imageUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('requests').add({
      'title': title,
      'reason': reason,
      'category': category,
      'imageUrl': imageUrl,
      'userId': currentUser.uid,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request posted successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to post request: $e')),
    );
  }
}

class PostRequestPage extends StatefulWidget {
  const PostRequestPage({super.key});

  @override
  State<PostRequestPage> createState() => _PostRequestPageState();
}

class _PostRequestPageState extends State<PostRequestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedImagePath;
  String? _selectedCategory;

  // List of categories for requested items.
  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Furniture',
    'Toys',
    'Kitchenware',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _selectImage() async {
    final path = await pickImage();
    if (path != null) {
      setState(() => _selectedImagePath = path);
    }
  }

  void _submitRequest() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill all required fields and choose a category')),
      );
      return;
    }

    await postRequest(
      _titleController.text,
      _descController.text,
      _selectedImagePath, // optional
      _selectedCategory!,
      context,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Request'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // If no image is selected, show a placeholder with “(Optional)” text.
            _selectedImagePath == null
                ? Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text("Image (Optional)",
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                : Image.file(
                    File(_selectedImagePath!),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _selectImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.image),
              label: const Text('Attach Image (Optional)',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Reason/Details',
                hintText: 'Enter request details, instructions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: _categories
                  .map((String category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('POST',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
