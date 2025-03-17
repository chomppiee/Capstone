import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> postDonation(
  String title,
  String description,
  String imagePath,
  BuildContext context,
) async {
  if (title.isEmpty || description.isEmpty || imagePath.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
    return;
  }

  try {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

    final username =
        userDoc.exists && userDoc.data()!.containsKey('username')
            ? userDoc['username']
            : currentUser.displayName ?? 'Unknown User';

    final storageRef = FirebaseStorage.instance.ref().child(
      'donation_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await storageRef.putFile(File(imagePath));
    final imageUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('donations').add({
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'userId': currentUser.uid,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation posted successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to post donation: $e')));
  }
}

Future<void> deleteDonation(String donationId) async {
  try {
    await FirebaseFirestore.instance
        .collection('donations')
        .doc(donationId)
        .delete();
  } catch (e) {
    print('Error deleting donation: $e');
  }
}

Future<void> claimDonation(String donationId, String userId) async {
  try {
    await FirebaseFirestore.instance
        .collection('donations')
        .doc(donationId)
        .update({
          'claimedBy': userId, // 🔥 Store the user who claimed it
          'claimedAt': FieldValue.serverTimestamp(),
        });
  } catch (e) {
    print('Error claiming donation: $e');
  }
}

// 🔹 Function to Update User Information
Future<void> updateUser(String userId, String fullname, String username) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fullname': fullname,
      'username': username,
    });
  } catch (e) {
    print('Error updating user: $e');
  }
}
