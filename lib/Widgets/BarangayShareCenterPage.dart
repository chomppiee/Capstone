import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class BarangayShareCenterPage extends StatelessWidget {
  const BarangayShareCenterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barangay Share Center'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'This page is under construction.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddShareItemPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Donation'),
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class AddShareItemPage extends StatefulWidget {
  const AddShareItemPage({Key? key}) : super(key: key);

  @override
  _AddShareItemPageState createState() => _AddShareItemPageState();
}

class _AddShareItemPageState extends State<AddShareItemPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _uploading = false;
  String? _selectedCategory;

  static const List<String> _categories = [
    'Adult Clothing',
    "Children's Clothing",
    'Shoes & Footwear',
    'Bags & Backpacks',
    'Accessories',
    'Small Furniture',
    'Kitchenware',
    'Linens (Blankets, Towels, etc.)',
    'Storage Containers',
    'Mobile Phones',
    'Chargers & Cables',
    'Small Appliances',
    'Radios / Flashlights / Lamps',
    'Textbooks',
    'Storybooks',
    'School Supplies',
    'Notebooks & Paper',
    'Toys',
    'Baby Clothes',
    'Cribs & Carriers',
    'Educational Toys',
    'Hand Tools',
    'Gardening Tools',
    'Sports Equipment',
    'Bicycles & Scooters',
    'Canned Goods',
    'Other',
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty || desc.isEmpty || _pickedImage == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields, select an image, and choose a category.')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pendingitem/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(File(_pickedImage!.path));
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('pendingitem').add({
        'name': name,
        'description': desc,
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Share Item'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedImage != null
                    ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                    : const Center(child: Text('Tap to select image')),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _uploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
