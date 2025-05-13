import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:segregate1/Widgets/AllHighlightsPage.dart';
import 'package:segregate1/Widgets/ForumPage.dart';
import 'package:segregate1/Widgets/ProfilePage.dart';
import 'package:segregate1/Widgets/DonationPage.dart';
import 'package:segregate1/Widgets/AnnouncementsPage.dart';
import 'package:segregate1/Widgets/SegregationGuidePage.dart';
import 'package:segregate1/Widgets/PointsPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:segregate1/Widgets/BarangayShareCenterPage.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user ID
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DonationPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PointsPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism), label: 'Donation'),
          BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'Points'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(top: 45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with welcome message and profile image from Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final String username = data['username'] ?? "User";
                final String profileImageUrl = data['profileImage'] ?? "";
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey,
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage(
                                  "$profileImageUrl?cacheBust=${DateTime.now().millisecondsSinceEpoch}")
                              : null,
                          child: profileImageUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $username!',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Join the community for a greener city',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.black54),
                      onPressed: () {},
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // ---- CATEGORIES SECTION START ----
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Optional "See All" action, if you want a dedicated page
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
           // 2) In your build(), replace the two Row(...) blocks for Categories with:

const SizedBox(height: 8),

// --- Row 1: two half-width buttons ---
Row(
  children: [
    Expanded(
      child: _buildCategoryButton(
        context: context,
        icon: Icons.campaign,
        label: 'Announcements',
        targetPage: const AnnouncementsPage(),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _buildCategoryButton(
        context: context,
        icon: Icons.forum,
        label: 'Forum',
        targetPage: const ForumPage(),
      ),
    ),
  ],
),

const SizedBox(height: 8),

// --- Row 2: one full-width button ---
/**_buildCategoryButton(
  context: context,
  icon: Icons.storefront,  
  label: 'Barangay Share Center',
  targetPage: const BarangayShareCenterPage(), // or your ShareCenterPage
),**/

const SizedBox(height: 8),

// --- Row 3: two half-width buttons ---
Row(
  children: [
    Expanded(
      child: _buildCategoryButton(
        context: context,
        icon: Icons.recycling,
        label: 'Recycling Tips',
        targetPage: const SegregationGuidePage(),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _buildCategoryButton(
        context: context,
        icon: Icons.event,
        label: 'Community Events',
        targetPage: const AllHighlightsPage(),
      ),
    ),
  ],
),

const SizedBox(height: 16),

            // ---- CATEGORIES SECTION END ----

            const SizedBox(height: 16),
            // Community Highlights Section
            _buildSectionHeader(
                context, 'Community Highlights', const AllHighlightsPage()),
            _buildHighlightsList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Helper method to build a single category button with the icon fixed to the left.
  // 1) Updated helper: just the button
Widget _buildCategoryButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Widget targetPage,
}) {
  return ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    },
    icon: Icon(icon, size: 20),
    label: Text(label, style: const TextStyle(fontSize: 14)),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 60),  // full-width when expanded
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}


  /// Section header for Community Highlights.
  Widget _buildSectionHeader(BuildContext context, String title, Widget page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            // Use the passed page parameter for navigation
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
          },
          child: const Row(
            children: [
              Text('View More'),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// Community Highlights List (Horizontal List)
  Widget _buildHighlightsList() {
    return SizedBox(
      height: 260,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_highlights')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading highlights'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No community highlights yet.'));
          }
          final highlights = snapshot.data!.docs;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length,
            itemBuilder: (context, index) {
              final highlight = highlights[index].data() as Map<String, dynamic>;
              final title = highlight['title'] ?? 'Untitled';
              final imageUrl = highlight['image_url'];
              final description = highlight['description'] ?? 'No Description';
              final Timestamp? ts = highlight['date_time'] as Timestamp?;
              final dt = ts?.toDate();
              String dateStr = "";
              String timeStr = "";
              if (dt != null) {
                dateStr =
                    "${DateFormat('EEE').format(dt)}, ${DateFormat('MMM d').format(dt)}";
                timeStr = DateFormat('hh:mm a').format(dt);
              }
              return GestureDetector(
                onTap: () {
                  // Full-screen dialog with details
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
                              imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 60),
                                    )
                                  : Image.asset(
                                      'assets/images/imgError.png',
                                      fit: BoxFit.cover,
                                    ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    if (dateStr.isNotEmpty && timeStr.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.access_time,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey),
                                          ),
                                        ],
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Image.asset(
                                        'assets/images/imgError.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/imgError.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          if (dt != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
