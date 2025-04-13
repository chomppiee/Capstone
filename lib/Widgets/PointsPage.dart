import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({Key? key}) : super(key: key);

  // Show info on how to earn points.
  void _showPointsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to Earn Points"),
        content: const Text(
          "You can earn points in the following ways:\n\n"
          "• Donate items: Every successful donation awards you 10 points.\n\n"
          "• Request fulfillment: When your donation request is confirmed as received, you earn 10 points.\n\n"
          "• Attend events: Participation in community events also earns you points. (More details coming soon)",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Points"),
        backgroundColor: Colors.green,
        // Info icon at the top left.
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showPointsInfo(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No data found."));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          // Use 0 as default if points field does not exist.
          final int points = data.containsKey('points') ? data['points'] : 0;
          return Column(
            children: [
              // User's points display.
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "You have earned",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$points points",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Thank you for your contributions!",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Leaderboard section
              const Expanded(child: LeaderboardSection()),
            ],
          );
        },
      ),
    );
  }
}

class LeaderboardSection extends StatelessWidget {
  const LeaderboardSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading leaderboard: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No leaderboard data available."));
        }
        final users = snapshot.data!.docs;
        // Get top 5 users.
        final topUsers = users.length > 5 ? users.sublist(0, 5) : users;
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: topUsers.length,
                itemBuilder: (context, index) {
                  final userData = topUsers[index].data() as Map<String, dynamic>;
                  final username = userData['username'] ?? "Unknown";
                  final userPoints = userData['points'] ?? 0;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text("${index + 1}"),
                    ),
                    title: Text(username),
                    trailing: Text("$userPoints pts"),
                  );
                },
              ),
            ),
            const Divider(),
            TextButton(
              onPressed: () {
                // Navigate to a full leaderboard page.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FullLeaderboardPage()),
                );
              },
              child: const Text("View More"),
            ),
          ],
        );
      },
    );
  }
}

class FullLeaderboardPage extends StatelessWidget {
  const FullLeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Leaderboard"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading leaderboard: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No leaderboard data available."));
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final username = userData['username'] ?? "Unknown";
              final userPoints = userData['points'] ?? 0;
              return ListTile(
                leading: CircleAvatar(
                  child: Text("${index + 1}"),
                ),
                title: Text(username),
                trailing: Text("$userPoints pts"),
              );
            },
          );
        },
      ),
    );
  }
}
