import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:segregate1/Authentication/Loginpage.dart';
import 'package:segregate1/Widgets/ChangePasswordPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  // Firestore-backed fields
  String fullName = '';
  String username = '';
  String email = '';
  String address = '';
  String profileImageUrl = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return _onLoaded();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      fullName = data['fullname'] ?? '';
      username = data['username'] ?? '';
      email = data['email'] ?? '';
      address = data['address'] ?? '';
      profileImageUrl = data['profileImage'] ?? '';
    }

    _onLoaded();
  }

  void _onLoaded() {
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Profile Photo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(child: Image.file(File(picked.path), height: 120)),
            const SizedBox(height: 8),
            const Text('Use this image as your profile photo?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed != true) return;

    final ref = FirebaseStorage.instance
        .ref('profile_images/${_auth.currentUser!.uid}.jpg');
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'profileImage': url});

    await _loadUserData();
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // Optional: re-authentication may be required here
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .delete();
      await _auth.currentUser!.delete();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  void _showEditProfileDialog() {
    final fnCtrl = TextEditingController(text: fullName);
    final unCtrl = TextEditingController(text: username);
    final emCtrl = TextEditingController(text: email);
    final addrCtrl = TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: fnCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: unCtrl, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: emCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Street')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .update({
                'fullname': fnCtrl.text,
                'username': unCtrl.text,
                'email': emCtrl.text,
                'address': addrCtrl.text,
              });
              setState(() {
                fullName = fnCtrl.text;
                username = unCtrl.text;
                email = emCtrl.text;
                address = addrCtrl.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        children: [
          // ─── HEADER CARD ───────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                        child: profileImageUrl.isEmpty
                            ? const Icon(Icons.account_circle, size: 96, color: Colors.grey)
                            : null,
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('@$username', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── INFO CARD ─────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Profile Information', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _showEditProfileDialog,
                  ),
                ),
                const Divider(height: 1),
                _buildInfoTile(Icons.person, 'Full Name', fullName),
                _buildInfoTile(Icons.account_circle, 'Username', username),
                _buildInfoTile(Icons.email, 'Email Address', email),
                _buildInfoTile(Icons.location_on, 'Street', address),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── SECURITY ───────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
              },
            ),
          ),

          const SizedBox(height: 20),

          // ─── LOG OUT ────────────────────────────────────────────────────
          Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: TextButton.icon(
    onPressed: _logout,
    icon: Icon(Icons.logout, color: Colors.red.shade700),
    label: Text(
      'Log Out',
      style: TextStyle(
        color: Colors.red.shade700,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    style: TextButton.styleFrom(
      backgroundColor: Colors.red.shade50,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
),


          const SizedBox(height: 12),

          // ─── DELETE ACCOUNT ─────────────────────────────────────────────
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              onPressed: _deleteAccount,
            ),
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'Proudly serving Valenzuelanos for a sustainable future!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildInfoTile(IconData icon, String label, String value) {
  return ListTile(
    leading: Icon(icon, color: Colors.grey[700]),
    title: Text(label),
    subtitle: Text(value.isNotEmpty ? value : 'Not provided'),
    // ↓ shrink the top/bottom gap ↓
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: -2),
    // ↓ eliminate any extra min padding ↓
    minVerticalPadding: 0,
    // optionally nudge it even tighter:
    visualDensity: const VisualDensity(vertical: -2),
  );
}

}
