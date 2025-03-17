import 'dart:io';
import 'package:flutter/material.dart';
import 'package:segregate1/Widgets/donatiion_list.dart';
import 'package:segregate1/Widgets/services/firebase_service.dart';
import 'package:segregate1/Widgets/services/image_service.dart';
import 'package:segregate1/Widgets/donatiion_list.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showDonateDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Post a Donation'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _selectedImagePath == null
                      ? const Placeholder(fallbackHeight: 100)
                      : Image.file(
                        File(_selectedImagePath!),
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Choose Image'),
                    onPressed: () async {
                      final path = await pickImage();
                      if (path != null) {
                        setState(() => _selectedImagePath = path);
                      }
                    },
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
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                onPressed: () async {
                  await postDonation(
                    _titleController.text,
                    _descController.text,
                    _selectedImagePath!,
                    context,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // ✅ Now safely closes the popup
                  }
                },

                child: const Text('Post'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donations'),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload), text: 'Donation'),
            Tab(icon: Icon(Icons.list), text: 'Request'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DonationList(), // List of donations
          Center(child: Text('Requests coming soon!')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: _showDonateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
