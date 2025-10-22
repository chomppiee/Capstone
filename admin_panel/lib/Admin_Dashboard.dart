import 'package:admin_panel/AdminInventoryList.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:admin_panel/announcements_page.dart';
import 'package:admin_panel/community_highlights_page.dart';
import 'package:admin_panel/recycling_tips_page.dart';
import 'package:admin_panel/users_page.dart';
import 'package:admin_panel/AdminForumPage.dart';
import 'package:admin_panel/DonationApprovalPage.dart';
import 'package:admin_panel/redeem_items_page.dart';
import 'package:admin_panel/BarangayShareCenterPage.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ─── Data model for charts ──────────────────────────────────────────────
class ChartData {
  final String x;
  final num y;
  ChartData(this.x, this.y);
}

// ─── Main Dashboard ────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedSection = "Overview";

  void _navigateTo(String section) => setState(() => _selectedSection = section);

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF6F7FB),
    body: Row(
      children: [
        // ─── SIDEBAR ───────────────────────────────────────────────
        Container(
          width: 235,
          color: const Color(0xFF263238),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 40, width: 40),
                    const SizedBox(width: 8),
                    const Text(
                      "SEGREGATE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // — your nav items —
              _navItem("Overview", Icons.dashboard),
             // _navItem("Users", Icons.people),
              _navItem("Announcements", Icons.announcement),
              _navItem("Community Highlights", Icons.star),
              _navItem("Recycling Tips", Icons.recycling),
           //   _navItem("Share Center", Icons.store),
              _navItem("Manage Forum", Icons.forum),
              _navItem("Approve Donations", Icons.check_circle),
               _navItem("Inventory", Icons.inventory), 
              _navItem("Redeem Items", Icons.card_giftcard),

              const Spacer(),

              // ─── LOGOUT BUTTON ────────────────────────────────────────
         Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: InkWell(
    onTap: () async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You will be returned to the login screen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Log out'),
            ),
          ],
        ),
      ) ?? false;

      if (!shouldLogout) return;

      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      // Clear stack and go to login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    },
    child: Row(
      children: const [
        Icon(Icons.logout, color: Colors.white),
        SizedBox(width: 12),
        Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    ),
  ),
)
            ],
          ),
        ),

        // ─── MAIN CONTENT ───────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Text(
                  "BARANGAY CANUMAY WEST",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Dynamic area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildPageContent(),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _navItem(String title, IconData icon) {
    final selected = _selectedSection == title;
    return InkWell(
      onTap: () => _navigateTo(title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: selected
            ? BoxDecoration(color: Colors.blueGrey.shade700, borderRadius: BorderRadius.circular(8))
            : null,
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedSection) {
      case "Overview":
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (ctx, userSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('donations').snapshots(),
              builder: (ctx2, donSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('requests').snapshots(),
                  builder: (ctx3, reqSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('donationRequests').snapshots(),
                      builder: (ctx4, donReqSnap) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('community_highlights').snapshots(),
                          builder: (ctx5, evSnap) {
                            if (!userSnap.hasData ||
                                !donSnap.hasData ||
                                !reqSnap.hasData ||
                                !donReqSnap.hasData ||
                                !evSnap.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            // ── metrics ──────────────────────────────────────
                            final totalUsers = userSnap.data!.docs.length;
                            final totalDonations = donSnap.data!.docs.length;
                            final totalRequests = reqSnap.data!.docs.length;
                            final totalEvents = evSnap.data!.docs.length;

                            final totalPoints = userSnap.data!.docs.fold<int>(
                              0,
                              (sum, d) {
                                final m = d.data() as Map<String, dynamic>;
                                final p = m['points'];
                                if (p is int) return sum + p;
                                if (p is double) return sum + p.toInt();
                                return sum;
                              },
                            );
                            final pendingRequests = reqSnap.data!.docs
                                .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'open')
                                .length;
                            final confirmedDonations = donReqSnap.data!.docs
                                .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'accepted')
                                .length;

                            // ── layout ────────────────────────────────────────
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ► Stats column
                                SizedBox(
                                  width: 280,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildStatCard("Total Users", "$totalUsers", Icons.people, Colors.blue),
                                        const SizedBox(height: 20),
                                        _buildStatCard("Total Points", "$totalPoints", Icons.stars, Colors.amber),
                                        const SizedBox(height: 20),
                                        _buildStatCard(
                                            "Donations", "$totalDonations", Icons.volunteer_activism, Colors.green),
                                        const SizedBox(height: 20),
                                        _buildStatCard("Pending Requests", "$pendingRequests",
                                            Icons.hourglass_empty, Colors.orange),
                                        const SizedBox(height: 20),
                                        _buildStatCard("Confirmed Donations", "$confirmedDonations",
                                            Icons.check_circle, Colors.green),
                                        const SizedBox(height: 20),
                                        _buildStatCard("Events", "$totalEvents", Icons.event, Colors.purple),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // ► Charts column
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        SizedBox(height: 300, child: DonationsByCategoryChart()),
                                        const SizedBox(height: 40),
                                        SizedBox(height: 300, child: RequestStatusPieChart()),
                                        const SizedBox(height: 40),
                                        SizedBox(height: 300, child: TopUsersBarChart()),
                                        const SizedBox(height: 40),
                                        SizedBox(height: 300, child: PointsHistogram()),
                                        const SizedBox(height: 40),
                                        SizedBox(height: 300, child: EventsPerMonthLineChart()),
                                        const SizedBox(height: 40),
                                        SizedBox(height: 300, child: ParticipationStackedChart()),
                                        const SizedBox(height: 40),
                                        SizedBox(height: 300, child: CommonDonationCategoriesChart()),
                                        const SizedBox(height: 40),
                                        SizedBox(height: 300, child: ActiveUsersBarChart()),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );

      case "Users":
        return const UsersPage();
      case "Announcements":
        return const AnnouncementsPage();
      case "Community Highlights":
        return const CommunityHighlightsPage();
      case "Recycling Tips":
        return const AdminRecyclingPanel();
      case "Share Center":                            // ← new
        return const BarangayShareCenterPage();
      case "Manage Forum":
        return const AdminForumPage();
      case "Approve Donations":
        return const DonationApprovalPage();
      case "Inventory":                              // ← NEW
        return const AdminInventoryList();
      case "Redeem Items":
        return const RedeemItemsPage();
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  // ─── stat card ──────────────────────────────────────────────────────
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.05), offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chart widgets ────────────────────────────────────────────────────

// 1. Donations by category (Pie)
class DonationsByCategoryChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('donations').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final counts = <String, int>{};
        for (var d in snap.data!.docs) {
          final cat = (d.data() as Map<String, dynamic>)['category'] ?? 'Other';
          counts[cat] = (counts[cat] ?? 0) + 1;
        }
        final data = counts.entries.map((e) => ChartData(e.key, e.value)).toList();
        return SfCircularChart(
          title: ChartTitle(text: 'Donations by Category'),
          legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
          series: [
            PieSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

// 2. Requests by status (Doughnut)
class RequestStatusPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final counts = {'open': 0, 'accepted': 0, 'declined': 0};
        for (var d in snap.data!.docs) {
          final s = (d.data() as Map<String, dynamic>)['status'] ?? 'open';
          counts[s] = (counts[s] ?? 0) + 1;
        }
        final data = counts.entries.map((e) => ChartData(e.key, e.value)).toList();
        return SfCircularChart(
          title: ChartTitle(text: 'Requests by Status'),
          legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
          series: [
            DoughnutSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

// 3. Top 10 users by points (Bar)
class TopUsersBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('points', descending: true).limit(10).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data!.docs.map((d) {
          final m = d.data() as Map<String, dynamic>;
          return ChartData(m['username'] ?? 'Unknown', m['points'] ?? 0);
        }).toList();
        return SfCartesianChart(
          title: ChartTitle(text: 'Top 10 Users by Points'),
          primaryXAxis: CategoryAxis(),
          series: [
            BarSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

// 4. Points distribution (Histogram)
class PointsHistogram extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final raw = snap.data!.docs.map((d) {
          final p = (d.data() as Map<String, dynamic>)['points'];
          if (p is int) return p;
          if (p is double) return p.toInt();
          return 0;
        }).toList();
        final bins = {'0-20': 0, '21-50': 0, '51-100': 0, '101-200': 0, '201+': 0};
        for (var v in raw) {
          if (v <= 20) bins['0-20'] = bins['0-20']! + 1;
          else if (v <= 50) bins['21-50'] = bins['21-50']! + 1;
          else if (v <= 100) bins['51-100'] = bins['51-100']! + 1;
          else if (v <= 200) bins['101-200'] = bins['101-200']! + 1;
          else bins['201+'] = bins['201+']! + 1;
        }
        final data = bins.entries.map((e) => ChartData(e.key, e.value)).toList();
        return SfCartesianChart(
          title: ChartTitle(text: 'Points Distribution'),
          primaryXAxis: CategoryAxis(),
          series: [
            ColumnSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

// 5. Events per month (Line)
class EventsPerMonthLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('community_highlights').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final counts = <String, int>{};
        for (var d in snap.data!.docs) {
          final ts = (d.data() as Map<String, dynamic>)['date_time'] as Timestamp?;
          if (ts == null) continue;
          final dt = ts.toDate();
          final m = "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
          counts[m] = (counts[m] ?? 0) + 1;
        }
        final sorted = counts.keys.toList()..sort();
        final data = sorted.map((k) => ChartData(k, counts[k]!)).toList();
        return SfCartesianChart(
          title: ChartTitle(text: 'Events Posted Per Month'),
          primaryXAxis: CategoryAxis(),
          series: [
            LineSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

// 6. Participation vs Attendance (Stacked)
class ParticipationStackedChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('community_highlights').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = <Map<String, dynamic>>[];
        for (var d in snap.data!.docs) {
          final m = d.data() as Map<String, dynamic>;
          final title = (m['title'] as String?)?.substring(0, 10) ?? 'Event';
          final part = (m['participants'] as List?)?.length ?? 0;
          final att = (m['attendedUsers'] as List?)?.length ?? 0;
          items.add({'title': title, 'part': part, 'att': att});
        }
        return SfCartesianChart(
          title: ChartTitle(text: 'Participation vs Attendance'),
          primaryXAxis: CategoryAxis(),
          legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
          series: [
            StackedColumnSeries<Map<String, dynamic>, String>(
              dataSource: items,
              xValueMapper: (d, _) => d['title'],
              yValueMapper: (d, _) => d['part'],
              name: 'Registered',
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
            StackedColumnSeries<Map<String, dynamic>, String>(
              dataSource: items,
              xValueMapper: (d, _) => d['title'],
              yValueMapper: (d, _) => d['att'],
              name: 'Attended',
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        );
      },
    );
  }
}

// 7. Common donation categories (reuse #1)
class CommonDonationCategoriesChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DonationsByCategoryChart();
}

// 8. Active donors (Bar)
class ActiveUsersBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('donations').snapshots(),
      builder: (ctx, donationSnap) {
        if (!donationSnap.hasData) return const Center(child: CircularProgressIndicator());

        // 1️⃣ Count donations per userId
        final counts = <String,int>{};
        for (var doc in donationSnap.data!.docs) {
          final uid = (doc.data() as Map<String,dynamic>)['userId'] as String? ?? 'Unknown';
          counts[uid] = (counts[uid] ?? 0) + 1;
        }
        // sort descending
        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // 2️⃣ Now fetch users to get usernames
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (ctx2, userSnap) {
            if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());

            // map userId -> username
            final userMap = {
              for (var udoc in userSnap.data!.docs)
                udoc.id: (udoc.data() as Map<String,dynamic>)['username'] as String? ?? 'Unknown'
            };

            // take top 10 and map to ChartData(username, count)
            final data = sorted
              .take(10)
              .map((e) => ChartData(userMap[e.key] ?? 'Unknown', e.value))
              .toList();

            // 3️⃣ Render bar chart
            return SfCartesianChart(
              title: ChartTitle(text: 'Most Active Donors'),
              primaryXAxis: CategoryAxis(),
              series: <BarSeries<ChartData,String>>[
                BarSeries<ChartData,String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                )
              ],
            );
          },
        );
      },
    );
  }
}

