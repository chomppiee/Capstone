// lib/Widgets/PointsPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:segregate1/Widgets/Dashboard.dart';
import 'package:segregate1/Widgets/DonationPage.dart';
import 'package:segregate1/Widgets/ProfilePage.dart';
import 'package:segregate1/Widgets/RedeemListPage.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({Key? key}) : super(key: key);

  void _showPointsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to Earn Points"),
        content: const Text(
          "• Donate items: +10 points\n"
          "• Request fulfilled: +10 points\n"
          "• Attend events: Points awarded per event\n",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    const Color primary = Colors.green;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
  backgroundColor: primary,
  elevation: 0,
  centerTitle: true,
  title: const Text("My Points", style: TextStyle(fontWeight: FontWeight.bold)),
  leading: IconButton(
    icon: const Icon(Icons.info_outline), 
    tooltip: "Info", 
    onPressed: () => _showPointsInfo(context),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.redeem),        // the “redeem” gift-box icon
      tooltip: "Redeem Points",               // shows on long-press
      onPressed: () {
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RedeemListPage()),
        );
      },
    ),
  ],
),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          final points = data['points'] as int? ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Points Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.star, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        "$points",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Points",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Leaderboard Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Leaderboard",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top Users List
                const Expanded(child: LeaderboardSection()),

                // View Full Leaderboard Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FullLeaderboardPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("View Full Leaderboard", style: TextStyle(color: primary)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DonationPage()));
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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
}

class LeaderboardSection extends StatelessWidget {
  const LeaderboardSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primary = Colors.green;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("No data available."));
        }
        final topUsers = docs.length > 5 ? docs.sublist(0, 5) : docs;
        return ListView.builder(
          itemCount: topUsers.length,
          itemBuilder: (ctx, i) {
            final user = topUsers[i].data() as Map<String, dynamic>;
            final username = user['username'] ?? 'Unknown';
            final pts = user['points'] ?? 0;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Text("${i + 1}", style: const TextStyle(color: primary)),
                ),
                title: Text(username),
                trailing: Text("$pts pts", style: const TextStyle(color: primary)),
              ),
            );
          },
        );
      },
    );
  }
}

class FullLeaderboardPage extends StatelessWidget {
  const FullLeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primary = Colors.green;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Leaderboard"),
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No data available."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final user = docs[i].data() as Map<String, dynamic>;
              final username = user['username'] ?? 'Unknown';
              final pts = user['points'] ?? 0;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primary.withOpacity(0.1),
                    child: Text("${i + 1}", style: const TextStyle(color: primary)),
                  ),
                  title: Text(username),
                  trailing: Text("$pts pts", style: const TextStyle(color: primary)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
