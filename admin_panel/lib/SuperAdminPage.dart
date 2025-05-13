// lib/Widgets/SuperAdminPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({Key? key}) : super(key: key);

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _userEmailController = TextEditingController();
  final _superEmailController = TextEditingController();
  bool _addingUser = false;
  bool _addingSuper = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _userEmailController.dispose();
    _superEmailController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _promoteToAdmin(String email) async {
    setState(() => _addingUser = true);
    try {
      final query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isEmpty) {
        _showSnack('User not found');
      } else {
        final uid = query.docs.first.id;
        await _firestore.collection('admins').doc(uid).set({
          'grantedBy': FirebaseAuth.instance.currentUser!.uid,
          'grantedAt': FieldValue.serverTimestamp(),
        });
        _showSnack('Promoted to Admin');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _addingUser = false);
      _userEmailController.clear();
    }
  }

  Future<void> _promoteToSuper(String email) async {
    setState(() => _addingSuper = true);
    try {
      final query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isEmpty) {
        _showSnack('User not found');
      } else {
        final uid = query.docs.first.id;
        await _firestore.collection('superadmins').doc(uid).set({
          'grantedBy': FirebaseAuth.instance.currentUser!.uid,
          'grantedAt': FieldValue.serverTimestamp(),
        });
        _showSnack('Promoted to SuperAdmin');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _addingSuper = false);
      _superEmailController.clear();
    }
  }

  Future<void> _revoke(String collection, String uid) async {
    await _firestore.collection(collection).doc(uid).delete();
    _showSnack('${collection == 'admins' ? 'Admin' : 'SuperAdmin'} revoked');
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(collection).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No $collection',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final uid = docs[i].id;
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(uid).get(),
              builder: (ctx2, userSnap) {
                if (!userSnap.hasData) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }
                final userData = userSnap.data!.data() as Map<String, dynamic>?;
                final email = userData != null && userData['email'] != null
                    ? userData['email'] as String
                    : uid;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(email[0].toUpperCase())),
                    title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      onPressed: () => _revoke(collection, uid),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('SuperAdmin', style: TextStyle(color: Colors.white, fontSize: 20)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Admins'), Tab(text: 'SuperAdmins')],
        ),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Admin tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _userEmailController,
                  decoration: InputDecoration(
                    labelText: 'Promote user to Admin',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                _addingUser
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _promoteToAdmin(_userEmailController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Promote to Admin'),
                        ),
                      ),
                const SizedBox(height: 16),
                Expanded(child: _buildList('admins')),
              ],
            ),
          ),

          // Superadmin tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _superEmailController,
                  decoration: InputDecoration(
                    labelText: 'Promote user to SuperAdmin',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                _addingSuper
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _promoteToSuper(_superEmailController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Promote to SuperAdmin'),
                        ),
                      ),
                const SizedBox(height: 16),
                Expanded(child: _buildList('superadmins')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
