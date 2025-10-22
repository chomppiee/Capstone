// lib/Widgets/SuperAdminPage.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// keep this import
import 'ThirdPartyAccountsTab.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({Key? key}) : super(key: key);

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final _usersStream = FirebaseFirestore.instance
      .collection('users')
      .orderBy('points', descending: true)
      .snapshots();

  // NEW: which right-side tab is shown (0 = Users, 1 = Third Parties)
  int _tab = 0;

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onEdit(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;

    final TextEditingController nameController =
        TextEditingController(text: data['fullname']);
    final TextEditingController usernameController =
        TextEditingController(text: data['username']);
    final TextEditingController addressController =
        TextEditingController(text: data['address']);
    String role = data['role'] ?? 'user';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => role = value);
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'fullname': nameController.text,
                    'username': usernameController.text,
                    'address': addressController.text,
                    'role': role,
                  });

                  final adminsRef = FirebaseFirestore.instance.collection('admins').doc(uid);
                  final superadminsRef = FirebaseFirestore.instance.collection('superadmins').doc(uid);

                  if (role == 'admin') {
                    await adminsRef.set({
                      'grantedBy': FirebaseAuth.instance.currentUser!.uid,
                      'grantedAt': FieldValue.serverTimestamp(),
                    });
                    await superadminsRef.delete().catchError((_) {});
                  } else if (role == 'superadmin') {
                    await superadminsRef.set({
                      'grantedBy': FirebaseAuth.instance.currentUser!.uid,
                      'grantedAt': FieldValue.serverTimestamp(),
                    });
                    await adminsRef.delete().catchError((_) {});
                  } else {
                    await adminsRef.delete().catchError((_) {});
                    await superadminsRef.delete().catchError((_) {});
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('User updated'),
                    backgroundColor: Colors.green,
                  ));
                },
                child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat.yMMMd().format(ts.toDate());
  }

  Widget _buildNavItem(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    return Container(
      color: selected ? Colors.black12 : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.black : Colors.grey),
        title: Text(label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.grey.shade600,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: const Color(0xFFF7F6F6),
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Image.asset('assets/logo.png', width: 80, height: 80),
                const SizedBox(height: 8),
                const Text('Super Admin',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                _buildNavItem(Icons.dashboard, 'Dashboard', false, () {}),
                // Users tab: selected when _tab == 0
                _buildNavItem(Icons.person, 'Users', _tab == 0, () {
                  setState(() => _tab = 0);
                }),
                // NEW: Third Parties tab: selected when _tab == 1
                _buildNavItem(Icons.business_center, 'Third Parties', _tab == 1, () {
                  setState(() => _tab = 1);
                }),

                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color.fromARGB(255, 0, 0, 0)),
                  title: const Text('Logout', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 56,
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Super Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Right-side body swaps between Users (existing) and Third Parties
                Expanded(
                  child: _tab == 0
                      // ===== Users Table (unchanged) =====
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _usersStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final docs = snapshot.data!.docs;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                                    columns: const [
                                      DataColumn(label: Text('Full Name')),
                                      DataColumn(label: Text('Username')),
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Registration Date')),
                                      DataColumn(label: Text('Points')),
                                      DataColumn(label: Text('Address')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: docs.map((doc) {
                                      final data = doc.data()! as Map<String, dynamic>;
                                      return DataRow(cells: [
                                        DataCell(Text(data['fullname'] ?? '')),
                                        DataCell(Text(data['username'] ?? '')),
                                        DataCell(Text(data['email'] ?? '')),
                                        DataCell(Text(_formatDate(data['createdAt'] as Timestamp?))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text((data['points'] ?? 0).toString()),
                                          ),
                                        ),
                                        DataCell(Text(data['address'] ?? '')),
                                        DataCell(Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              onPressed: () => _onEdit(doc.id),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              onPressed: () => _deleteUser(doc.id),
                                            ),
                                          ],
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      // ===== Third-Party Accounts Tab =====
                      : const Padding(
                          padding: EdgeInsets.all(16),
                          child: ThirdPartyAccountsTab(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
