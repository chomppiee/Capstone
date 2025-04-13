import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  // Stream for announcements that are less than 7 days old (i.e. "new")
  Stream<QuerySnapshot> _getUpcomingAnnouncements() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return FirebaseFirestore.instance
        .collection('announcements')
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Stream for all announcements
  Stream<QuerySnapshot> _getAllAnnouncements() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Builds a list of announcement cards from the given stream.
  Widget _buildAnnouncementsList({
    required Stream<QuerySnapshot> stream,
    required bool isUpcoming,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading announcements'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No announcements yet.'));
        }
        final docs = snapshot.data!.docs;

        // Filter by search text if provided.
        final searchText = _searchController.text.toLowerCase();
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final description =
              (data['description'] ?? '').toString().toLowerCase();
          return title.contains(searchText) || description.contains(searchText);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String title = data['title'] ?? 'No Title';
            final String description = data['description'] ?? 'No Description';
            final String imageUrl = data['image_url'] ?? "";
            String timeStr = "";
            if (data['timestamp'] != null) {
              final Timestamp ts = data['timestamp'] as Timestamp;
              final DateTime dt = ts.toDate();
              timeStr = DateFormat('MMM d, yyyy hh:mm a').format(dt);
            }
            return _buildAnnouncementCard(
              title: title,
              description: description,
              imageUrl: imageUrl,
              timeStr: timeStr,
              isUpcoming: isUpcoming,
            );
          },
        );
      },
    );
  }

  /// Builds a single announcement card.
  Widget _buildAnnouncementCard({
    required String title,
    required String description,
    required String imageUrl,
    required String timeStr,
    required bool isUpcoming,
  }) {
    return GestureDetector(
      onTap: () {
        // Full-screen dialog to maximize the announcement.
        showDialog(
          context: context,
          builder: (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.green,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(title),
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 300,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 60),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUpcoming ? const Color(0xFFE7F9EF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            if (timeStr.isNotEmpty)
              Positioned(
                right: 16,
                top: 16,
                child: Text(
                  timeStr.split(',').first, // e.g., "Jan 23"
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUpcoming)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "New",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (timeStr.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          timeStr.split(' ').sublist(1).join(' '),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Search announcements...",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.grey),
              onPressed: () {
                // TODO: Implement notifications logic
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "New"),
              Tab(text: "All"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnnouncementsList(
              stream: _getUpcomingAnnouncements(),
              isUpcoming: true,
            ),
            _buildAnnouncementsList(
              stream: _getAllAnnouncements(),
              isUpcoming: false,
            ),
          ],
        ),
      ),
    );
  }
}
