// lib/Widgets/SegregationGuidePage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:segregate1/Widgets/WasteCategory/WasteItemDetailPage.dart';
import 'package:segregate1/widgets/WasteCategory/WasteItemsListPage.dart';
import 'package:segregate1/Widgets/RecyclingTipsPage.dart';
import 'package:segregate1/Widgets/Dashboard.dart';
import 'package:segregate1/Widgets/DonationPage.dart';
import 'package:segregate1/Widgets/PointsPage.dart';
import 'package:segregate1/Widgets/ProfilePage.dart';

class SegregationGuidePage extends StatefulWidget {
  const SegregationGuidePage({super.key});

  @override
  State<SegregationGuidePage> createState() => _SegregationGuidePageState();
}

class _SegregationGuidePageState extends State<SegregationGuidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Segregation Guide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications if needed.
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Search bar now opens the search delegate:
            TextField(
              readOnly: true,
              onTap: () {
                showSearch(
                  context: context,
                  delegate: WasteItemSearchDelegate(),
                );
              },
              decoration: InputDecoration(
                hintText: 'Search waste items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Waste Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            wasteCategoryTile(
              Icons.eco,
              'Biodegradable',
              'Food scraps, garden waste',
              Colors.green.shade50,
              Colors.green,
              onArrowPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WasteItemsListPage(category: 'Biodegradable'),
                  ),
                );
              },
            ),
            wasteCategoryTile(
              Icons.delete,
              'Non-Biodegradable',
              'Plastics, rubber items',
              Colors.blue.shade50,
              Colors.blue,
              onArrowPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WasteItemsListPage(category: 'Non-Biodegradable'),
                  ),
                );
              },
            ),
            wasteCategoryTile(
              Icons.recycling,
              'Recyclable',
              'Paper, metal, glass',
              Colors.amber.shade50,
              Colors.amber.shade700,
              onArrowPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WasteItemsListPage(category: 'Recyclable'),
                  ),
                );
              },
            ),
            wasteCategoryTile(
              Icons.warning,
              'Hazardous',
              'Batteries, chemicals',
              Colors.red.shade50,
              Colors.red.shade700,
              onArrowPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WasteItemsListPage(category: 'Hazardous'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Did You Know?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.black54),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Every year, about 8 million tons of plastic waste escapes into the oceans.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recycling Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '♻️ Recycling helps reduce pollution and save energy. Clean and dry recyclables before disposing!',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecyclingTipsPage()),
                        );
                      },
                      child: const Text(
                        'View More',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DonationPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PointsPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
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
    );
  }

  Widget wasteCategoryTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Color iconColor, {
    required VoidCallback onArrowPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: iconColor),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.black38),
          onPressed: onArrowPressed,
        ),
        onTap: onArrowPressed,
      ),
    );
  }
}

// SearchDelegate to handle live Firestore search of waste items
class WasteItemSearchDelegate extends SearchDelegate<void> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search items'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('waste_items')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No items found'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data()! as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name']),
              subtitle: Text(data['category'] ?? ''),
              onTap: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WasteItemDetailPage(
                      category: data['category'] ?? '',
                      name: data['name'],
                      description: data['description'],
                      disposal: data['disposal'],
                      tips: data['tips'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
