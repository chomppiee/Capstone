import 'package:admin_panel/announcements_page.dart';
import 'package:admin_panel/community_highlights_page.dart';
import 'package:admin_panel/overview_page.dart';
import 'package:admin_panel/recycling_tips_page.dart';
import 'package:admin_panel/users_page.dart';
import 'package:admin_panel/AdminForumPage.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedSection = "Overview"; // Default section

  void _navigateTo(String section) {
    setState(() {
      _selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Bar
          Container(
            width: 250, // Sidebar width
            color: Colors.blueGrey.shade900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "Admin Panel",
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                _navItem("Overview", Icons.dashboard),
                _navItem("Users", Icons.people),
                _navItem("Announcements", Icons.announcement),
                _navItem("Community Highlights", Icons.star),
                _navItem("Recycling Tips", Icons.recycling),
                _navItem("Manage Forum", Icons.forum),

              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: _buildPageContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      selected: _selectedSection == title,
      selectedTileColor: Colors.blueGrey.shade700,
      onTap: () => _navigateTo(title),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedSection) {
      case "Overview":
        return const OverviewPage();
      case "Users":
        return const UsersPage();
      case "Announcements":
        return const AnnouncementsPage();
      case "Community Highlights":
        return const CommunityHighlightsPage();
      case "Recycling Tips":
        return const AdminRecyclingPanel();
      case "Manage Forum":
       return const AdminForumPage();

      default:
        return const Center(child: Text("Page not found"));
    }
  }
}
