import 'package:flutter/material.dart';
import 'package:segregate1/Widgets/WasteCategory/BiodegradableDetailPage.dart';
import 'package:segregate1/Widgets/RecyclingTipsPage.dart';

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
            TextField(
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
                    builder: (context) => const BiodegradableDetailPage(),
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
                debugPrint("Non-Biodegradable tile clicked");
              },
            ),
            wasteCategoryTile(
              Icons.recycling,
              'Recyclable',
              'Paper, metal, glass',
              Colors.amber.shade50,
              Colors.amber.shade700,
              onArrowPressed: () {
                debugPrint("Recyclable tile clicked");
              },
            ),
            wasteCategoryTile(
              Icons.warning,
              'Hazardous',
              'Batteries, chemicals',
              Colors.red.shade50,
              Colors.red.shade700,
              onArrowPressed: () {
                debugPrint("Hazardous tile clicked");
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
                        debugPrint("View more recycling tips clicked");
                        Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecyclingTipsPage(),
                  ),
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Reward'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Donate'),
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
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.black38),
          onPressed: onArrowPressed,
        ),
        onTap: onArrowPressed,
      ),
    );
  }
}
