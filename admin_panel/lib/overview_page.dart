import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  Future<int> _getTotalCount(String collection) async {
    try {
      print("Fetching count for collection: $collection"); // ✅ Debug message
      final snapshot =
          await FirebaseFirestore.instance.collection(collection).get();
      print(
        "Fetched count for $collection: ${snapshot.size}",
      ); // ✅ Debug success
      return snapshot.size;
    } catch (e, stackTrace) {
      print("Error fetching $collection count: $e");
      print("StackTrace: $stackTrace"); // 🔥 Prints full error log
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _getTotalCount('users'), // Total users
        _getTotalCount('donations'), // Total donations
        _getTotalCount('forum'), // Total forum comments
      ]),
      builder: (context, AsyncSnapshot<List<int>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalUsers = snapshot.data![0];
        final totalDonations = snapshot.data![1];
        final totalComments = snapshot.data![2];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Admin Overview",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal, // ✅ Allows scrolling if needed
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _statCard(
                      "Total Users",
                      totalUsers,
                      Icons.people,
                      Colors.blue,
                    ),
                    _statCard(
                      "Total Donations",
                      totalDonations,
                      Icons.volunteer_activism,
                      Colors.green,
                    ),
                    _statCard(
                      "Total Forum Comments",
                      totalComments,
                      Icons.chat,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, int count, IconData icon, Color color) {
    return Container(
      width: 180,
      height: 140, // ✅ Adjust height to prevent text cutting
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),

          // ✅ Wrap title inside Flexible to prevent overflow
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14, // ✅ Slightly reduced font size
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2, // ✅ Prevents overflow
              overflow:
                  TextOverflow.ellipsis, // ✅ Adds "..." if text is too long
            ),
          ),

          const SizedBox(height: 8),

          // ✅ Ensures number is properly sized
          Text(
            "$count",
            style: TextStyle(
              fontSize: 28, // ✅ Increased number font size for visibility
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
