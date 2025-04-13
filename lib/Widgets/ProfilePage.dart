import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode and debugPrint
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:segregate1/Authentication/Loginpage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:segregate1/Widgets/ChangePasswordPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  String profileImageUrl = ""; // Stores profile image URL

  String fullName = "";
  String username = "";
  String email = "";
  String address = "";
  int donated = 0;
  int posted = 0;

  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) debugPrint("initState: Loading user data...");
      _loadUserData(); // Load data AFTER the widget tree is built
    });
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          fullName = data.containsKey('fullname') ? data['fullname'] : "Not Provided";
          username = data.containsKey('username') ? data['username'] : "Not Provided";
          email = data.containsKey('email') ? data['email'] : "Not Provided";
          address = data.containsKey('address') ? data['address'] : "Not Provided";
          donated = data.containsKey('donated') ? data['donated'] : 0;
          posted = data.containsKey('posted') ? data['posted'] : 0;
          profileImageUrl = data.containsKey('profileImage') ? data['profileImage'] : "";
          _isLoading = false;
        });
        if (kDebugMode) {
          debugPrint("User data loaded:");
          debugPrint("Full Name: $fullName");
          debugPrint("Username: $username");
          debugPrint("Profile Image URL: $profileImageUrl");
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (kDebugMode) debugPrint("User document does not exist.");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (kDebugMode) debugPrint("Picked image path: ${pickedFile.path}");

      // Show preview and confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Save Profile Photo?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Would you like to save this image as your new profile photo?"),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(imageFile, height: 150),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          if (kDebugMode) debugPrint("Uploading profile image...");
          String downloadUrl = await _uploadImageToFirebase(imageFile);
          if (kDebugMode) debugPrint("Downloaded URL: $downloadUrl");
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update({'profileImage': downloadUrl});

          // Reload user data from Firestore to ensure everything is in sync
          if (!mounted) return;
          await _loadUserData();

          setState(() {
            _profileImage = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile photo updated successfully!")),
          );
        } catch (e) {
          if (kDebugMode) debugPrint("Error uploading image: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving image: ${e.toString()}")),
          );
        }
      }
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    String uid = _auth.currentUser!.uid;
    Reference storageRef = FirebaseStorage.instance.ref().child("profile_images/$uid.jpg");
    await storageRef.putFile(imageFile);
    String downloadUrl = await storageRef.getDownloadURL();
    if (kDebugMode) debugPrint("Image uploaded to Firebase Storage. URL: $downloadUrl");
    return downloadUrl;
  }

  void _logout() async {
    try {
      await _auth.signOut(); // Logs out the user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to LoginPage directly
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${e.toString()}")),
      );
    }
  }

  // Show a pop-up dialog to edit profile information
  void _showEditProfileDialog() {
    final TextEditingController fullNameController = TextEditingController(text: fullName);
    final TextEditingController usernameController = TextEditingController(text: username);
    final TextEditingController emailController = TextEditingController(text: email);
    final TextEditingController addressController = TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile Information"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).update({
                  'fullname': fullNameController.text,
                  'username': usernameController.text,
                  'email': emailController.text,
                  'address': addressController.text,
                });
                if (!mounted) return;
                setState(() {
                  fullName = fullNameController.text;
                  username = usernameController.text;
                  email = emailController.text;
                  address = addressController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile information updated.")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building ProfilePage with profileImageUrl: $profileImageUrl");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF1E88E5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // No extra top padding added here
              child: Column(
                children: [
                  // Blue header with profile image and welcome text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 40, bottom: 40),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E88E5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage("$profileImageUrl?cacheBust=${DateTime.now().millisecondsSinceEpoch}")
                                : null,
                            child: profileImageUrl.isEmpty
                                ? const Icon(Icons.account_circle, size: 100, color: Colors.grey)
                                : null,
                          ),
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Welcome text with username
                  Text(
  "$username",
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),
),
                  const SizedBox(height: 10),
                  // Stats Section (Donated & Posted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatsBox("Donated", donated),
                      const SizedBox(width: 20),
                      _buildStatsBox("Posted", posted),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Contact Info Section with editable fields via pop-up dialog
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("Profile Information",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: _showEditProfileDialog,
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildInfoRow(Icons.person, fullName),
                          _buildInfoRow(Icons.account_circle, username),
                          _buildInfoRow(Icons.email, email),
                          _buildInfoRow(Icons.location_on, address),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Change Password Button
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.lock, color: Colors.white),
                        label: const Text("Change Password", style: TextStyle(color: Colors.white, fontSize: 16)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text("Log Out", style: TextStyle(color: Colors.white, fontSize: 16)),
                        onPressed: _logout,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Proudly serving Valenzuelanos for a sustainable future!",
                    style: TextStyle(color: Color.fromARGB(255, 168, 168, 168), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  /// Build Info Row (Handles Null or Empty Values)
  Widget _buildInfoRow(IconData icon, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (value != null && value.isNotEmpty) ? value : "Not provided",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Stats Box
  Widget _buildStatsBox(String title, int value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          const Icon(Icons.refresh, color: Colors.blue, size: 18),
          Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
