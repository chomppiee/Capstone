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
  final TextEditingController _pickupTimeController = TextEditingController();

  String? _selectedImagePath;
  String? _selectedCategory;

  bool _isPosting = false; // ← loading flag

  final List<String> _categories = [
    'Adult Clothing',
    'Children\'s Clothing',
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
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    print("Categories: $_categories");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pickupTimeController.dispose();
    super.dispose();
  }

  void _selectImage() async {
    final path = await pickImage();
    if (path != null) {
      setState(() => _selectedImagePath = path);
    }
  }

  Future<void> _selectTimeRange() async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select Pickup Start Time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: const TimePickerThemeData(
            helpTextStyle:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        child: child!,
      ),
    );
    if (startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: startTime,
      helpText: 'Select Pickup End Time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: const TimePickerThemeData(
            helpTextStyle:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        child: child!,
      ),
    );
    if (endTime == null) return;

    setState(() {
      _pickupTimeController.text =
          "${startTime.format(context)} - ${endTime.format(context)}";
    });
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
        _selectedCategory == null ||
        _pickupTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all fields, select an image, choose a category, and select available pickup time',
          ),
        ),
      );
      return;
    }

    if (_isPosting) return; // already in progress

    setState(() {
      _isPosting = true;
    });

    _showLoadingDialog();

    await postDonation(
      _titleController.text,
      _descController.text,
      _selectedImagePath!,
      _selectedCategory!,
      context,
      pickupTime: _pickupTimeController.text,
    );

    if (mounted) {
      Navigator.pop(context); // close loading dialog
      Navigator.pop(context); // go back
    }

    setState(() {
      _isPosting = false;
    });
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
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              hint: const Text('Select a category'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pickupTimeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Available Pickup Time',
                hintText: 'Select available pickup time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: _selectTimeRange,
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
