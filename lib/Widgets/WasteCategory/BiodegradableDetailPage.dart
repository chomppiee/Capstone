import 'package:flutter/material.dart';

class BiodegradableDetailPage extends StatefulWidget {
  const BiodegradableDetailPage({Key? key}) : super(key: key);

  @override
  State<BiodegradableDetailPage> createState() => _BiodegradableDetailPageState();
}

class _BiodegradableDetailPageState extends State<BiodegradableDetailPage> {
  final TextEditingController _searchController = TextEditingController();

  // Sample list of biodegradable items
  final List<String> _allItems = [
    "Vegetable peels",
    "Small branches",
    "Newspaper",
  ];

  // This list will update based on the search text
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    // Initially, show all items
    _filteredItems = List.from(_allItems);

    // Listen to changes in the search bar
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      setState(() {
        _filteredItems = _allItems
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with back arrow and minimal style
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Segregation Guide",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications if needed
            },
          ),
        ],
      ),

      // Body content
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search waste items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section heading for "Biodegradable wastes"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEBFFF5), // light greenish background
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Biodegradable wastes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // The list of filtered items
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final displayIndex = index + 1; // to show 1-based numbering

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          "$displayIndex",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      title: Text(item),
                      onTap: () {
                        // If you want to show more details about each item, handle it here.
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Example bottom navigation bar (customize if needed)
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
}
