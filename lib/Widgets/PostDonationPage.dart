import 'dart:io';
import 'package:flutter/material.dart';
import 'package:segregate1/Widgets/services/firebase_service.dart';
import 'package:segregate1/Widgets/services/image_service.dart';

class PostDonationPage extends StatefulWidget {
  const PostDonationPage({super.key});

  @override
  State<PostDonationPage> createState() => _PostDonationPageState();
}

class _PostDonationPageState extends State<PostDonationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedImagePath;
  String? _selectedCategory;
  bool _isPosting = false;

  final List<String> _categories = [
    'Adult Clothing',
    'Children\'s Clothing',
    'Shoes & Footwear',
    'Recyclable Materials',
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

  void _showLoadingDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Posting Donation..."),
            ],
          ),
        ),
      ),
    );
  }

Future<void> _submitDonation() async {
  if (_titleController.text.isEmpty ||
      _descController.text.isEmpty ||
      _selectedImagePath == null ||
      _selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields and select an image and category')),
    );
    return;
  }

  if (_isPosting) return;

  setState(() => _isPosting = true);
  _showLoadingDialog();

  await postDonation(
    _titleController.text,
    _descController.text,
    _selectedImagePath!,
    _selectedCategory!,
    context,
  );

  if (mounted) {
    Navigator.pop(context); // Close loading dialog

    // Show "waiting for approval" dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submitted'),
        content: const Text('Your donation has been posted and is now waiting for admin approval.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close this dialog
              Navigator.pop(context); // Navigate back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  setState(() => _isPosting = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Donation'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _selectedImagePath == null
                ? Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  )
                : Image.file(File(_selectedImagePath!), height: 200, fit: BoxFit.cover),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selectImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Attach Image', style: TextStyle(color: Colors.white)),
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
                labelText: 'Description',
                hintText: 'Enter collection details, instructions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
DropdownButtonFormField<String>(
  value: _selectedCategory,
  isExpanded: true, // let the text take the full width of the field
  decoration: const InputDecoration(
    labelText: 'Category',
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(),            // ← keep the box
    enabledBorder: OutlineInputBorder(),     // ← keep the box (enabled)
    focusedBorder: OutlineInputBorder(),     // ← keep the box (focused)
  ),
  icon: const Icon(Icons.arrow_drop_down),   // use the built-in chevron
  hint: const Text(
    'Select a category',
    overflow: TextOverflow.ellipsis,         // prevent hint overflow
    maxLines: 1,
    softWrap: false,
  ),
  items: _categories.map((c) {
    return DropdownMenuItem<String>(
      value: c,
      child: Text(
        c,
        overflow: TextOverflow.ellipsis,      // prevent selected text overflow
        maxLines: 1,
        softWrap: false,
      ),
    );
  }).toList(),
  menuMaxHeight: 350,                         // optional: tidy long menus
  onChanged: (v) => setState(() => _selectedCategory = v),
),


            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isPosting ? null : _submitDonation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'POST',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
