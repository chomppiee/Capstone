import 'dart:io';
import 'package:flutter/material.dart';
import 'package:segregate1/Widgets/donatiion_list.dart';
import 'package:segregate1/Widgets/RequestList.dart';
import 'package:segregate1/Widgets/services/firebase_service.dart';
import 'package:segregate1/Widgets/services/image_service.dart';
import 'package:segregate1/Widgets/Dashboard.dart';
import 'package:segregate1/Widgets/ProfilePage.dart';
import 'package:segregate1/Widgets/PostDonationPage.dart';
import 'package:segregate1/Widgets/NotificationPage.dart';
import 'package:segregate1/Widgets/ChatListPage.dart';
import 'package:segregate1/Widgets/EventPage.dart';
import 'package:segregate1/Widgets/ForumPage.dart';
import 'package:segregate1/Widgets/ApprovalRequestPage.dart';
import 'package:segregate1/Widgets/PostRequestPage.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedImagePath;
  String? _selectedCategoryForDonation;

  // List of categories
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Post a Donation'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // If no image selected, show a placeholder and indicate "Optional"
              _selectedImagePath == null
                  ? Column(
                      children: const [
                        Placeholder(fallbackHeight: 100),
                        SizedBox(height: 8),
                        Text("(Image is optional)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  : Image.file(File(_selectedImagePath!), height: 100, fit: BoxFit.cover),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Choose Image (Optional)'),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategoryForDonation,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategoryForDonation = newValue;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty || _descController.text.isEmpty || _selectedCategoryForDonation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill title, description, and choose a category')),
                );
                return;
              }
              await postDonation(
                _titleController.text,
                _descController.text,
                _selectedImagePath ?? '', // Send empty string if no image
                _selectedCategoryForDonation!,
                context,
              );
              if (context.mounted) {
                Navigator.pop(context);
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
      // AppBar with TabBar indicator.
      appBar: AppBar(
        title: const Text('Donations'),
        backgroundColor: const Color.fromARGB(255, 235, 235, 235),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "Donations"),
            Tab(text: "Requests"),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: Stack(
              children: [
                const Icon(Icons.more_vert, color: Colors.black54),
                // Demo red dot indicator (replace with real logic if needed)
                const Positioned(right: 0, top: 0, child: CircleAvatar(radius: 4, backgroundColor: Colors.red)),
              ],
            ),
            onSelected: (value) {
              if (value == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
              } else if (value == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListPage()));
              } else if (value == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ApprovalRequestPage()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Row(children: const [Icon(Icons.notifications, color: Colors.black54), SizedBox(width: 8), Text('Notifications')]),
              ),
              PopupMenuItem(
                value: 1,
                child: Row(children: const [Icon(Icons.message, color: Colors.black54), SizedBox(width: 8), Text('Messages')]),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(children: const [Icon(Icons.approval, color: Colors.black54), SizedBox(width: 8), Text('Approval/Requests')]),
              ),
            ],
          ),
        ],
      ),
      // Bottom Navigation Bar updated to match Dashboard.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
              break;
            case 1:
              break; // Already on Donation Page
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EventPage()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForumPage()));
              break;
            case 4:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Donation'),
          BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'Points'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DonationList(), // Displays donation list with donation details functionality.
          RequestList(),  // Displays request posts (from PostRequestPage) in grid view.
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E88E5),
        onPressed: () {
          // Modal bottom sheet to choose between Post Donation and Post Request.
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.post_add, color: Colors.green),
                    title: const Text("Post Donation"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PostDonationPage()));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.request_page, color: Colors.green),
                    title: const Text("Post Request"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PostRequestPage()));
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
