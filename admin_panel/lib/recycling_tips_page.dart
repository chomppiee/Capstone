// lib/widgets/AdminRecyclingPanel.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:logging/logging.dart';

class AdminRecyclingPanel extends StatefulWidget {
  const AdminRecyclingPanel({super.key});

  @override
  State<AdminRecyclingPanel> createState() => _AdminRecyclingPanelState();
}

class _AdminRecyclingPanelState extends State<AdminRecyclingPanel> {
  // Controllers for Recycling Tip
  final TextEditingController _tipTitleController = TextEditingController();
  final TextEditingController _tipDescriptionController = TextEditingController();
  Uint8List? _tipImageBytes;
  String? _tipImageName;
  bool _isUploadingTip = false;

  // Controllers for Video Uploads (unchanged)
  final TextEditingController _videoTitleController1 = TextEditingController();
  Uint8List? _videoBytes1;
  String? _videoName1;
  final TextEditingController _videoTitleController2 = TextEditingController();
  Uint8List? _videoBytes2;
  String? _videoName2;
  final TextEditingController _videoTitleController3 = TextEditingController();
  Uint8List? _videoBytes3;
  String? _videoName3;
  bool _isUploadingVideo = false;

  final Logger _log = Logger('AdminRecyclingPanel');

  // ------------------------------
  // Recycling Tip Methods
  // ------------------------------

  Future<void> _pickTipImage() async {
    final image = await ImagePickerWeb.getImageAsBytes();
    if (image != null) {
      setState(() {
        _tipImageBytes = image;
        _tipImageName =
            'recycling_tip_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _uploadTip() async {
    if (_tipTitleController.text.isEmpty ||
        _tipDescriptionController.text.isEmpty ||
        _tipImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all tip fields and select an image.")),
      );
      return;
    }
    setState(() => _isUploadingTip = true);
    try {
      _log.info("Uploading tip image to Firebase Storage...");
      final ref = FirebaseStorage.instance.ref().child('recycling_tips/$_tipImageName');
      await ref.putData(_tipImageBytes!);
      final imageUrl = await ref.getDownloadURL();

      // add to active tips
      final docRef = await FirebaseFirestore.instance.collection('recycling_tips').add({
        'title': _tipTitleController.text.trim(),
        'description': _tipDescriptionController.text.trim(),
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // also add to history
      await FirebaseFirestore.instance
          .collection('recycling_tips_history')
          .doc(docRef.id)
          .set({
        'title': _tipTitleController.text.trim(),
        'description': _tipDescriptionController.text.trim(),
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recycling tip uploaded successfully.")),
      );
      _tipTitleController.clear();
      _tipDescriptionController.clear();
      setState(() {
        _tipImageBytes = null;
        _tipImageName = null;
      });
    } catch (e, stack) {
      _log.severe("Error uploading tip", e, stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isUploadingTip = false);
    }
  }

  Future<void> _deleteTip(String docId, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('recycling_tips').doc(docId).delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final uri = Uri.parse(imageUrl);
        final parts = uri.path.split('/o/');
        if (parts.length > 1) {
          final filePath = Uri.decodeComponent(parts[1]);
          await FirebaseStorage.instance.ref().child(filePath).delete();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tip deleted successfully.")),
      );
      // history remains intact
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting tip: $e")),
      );
    }
  }

  void _editTip(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController =
        TextEditingController(text: data['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Recycling Tip"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('recycling_tips')
                  .doc(doc.id)
                  .update({
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Tip updated.")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // Video Upload Methods (unchanged)
  // ------------------------------

  Future<void> _pickVideo({required int index}) async {
    final video = await ImagePickerWeb.getVideoAsBytes();
    if (video != null) {
      setState(() {
        switch (index) {
          case 1:
            _videoBytes1 = video;
            _videoName1 =
                'recycling_video_${DateTime.now().millisecondsSinceEpoch}_1.mp4';
            break;
          case 2:
            _videoBytes2 = video;
            _videoName2 =
                'recycling_video_${DateTime.now().millisecondsSinceEpoch}_2.mp4';
            break;
          case 3:
            _videoBytes3 = video;
            _videoName3 =
                'recycling_video_${DateTime.now().millisecondsSinceEpoch}_3.mp4';
            break;
        }
      });
    }
  }

  Future<void> _uploadVideo({required int index}) async {
    String? videoTitle;
    Uint8List? videoBytes;
    String? videoName;
    switch (index) {
      case 1:
        videoTitle = _videoTitleController1.text.trim();
        videoBytes = _videoBytes1;
        videoName = _videoName1;
        break;
      case 2:
        videoTitle = _videoTitleController2.text.trim();
        videoBytes = _videoBytes2;
        videoName = _videoName2;
        break;
      case 3:
        videoTitle = _videoTitleController3.text.trim();
        videoBytes = _videoBytes3;
        videoName = _videoName3;
        break;
    }
    if (videoTitle == null ||
        videoTitle.isEmpty ||
        videoBytes == null ||
        videoName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please provide a video title and select a video.")),
      );
      return;
    }
    setState(() => _isUploadingVideo = true);
    try {
      final ref =
          FirebaseStorage.instance.ref().child('recycling_videos/$videoName');
      await ref.putData(videoBytes);
      final videoUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('recycling_videos').add({
        'title': videoTitle,
        'video_url': videoUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Video $index uploaded successfully.")),
      );
      setState(() {
        switch (index) {
          case 1:
            _videoTitleController1.clear();
            _videoBytes1 = null;
            _videoName1 = null;
            break;
          case 2:
            _videoTitleController2.clear();
            _videoBytes2 = null;
            _videoName2 = null;
            break;
          case 3:
            _videoTitleController3.clear();
            _videoBytes3 = null;
            _videoName3 = null;
            break;
        }
      });
    } catch (e, stack) {
      _log.severe("Error uploading video $index", e, stack);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUploadingVideo = false);
    }
  }

  @override
  void dispose() {
    _tipTitleController.dispose();
    _tipDescriptionController.dispose();
    _videoTitleController1.dispose();
    _videoTitleController2.dispose();
    _videoTitleController3.dispose();
    super.dispose();
  }

  // ------------------------------
  // Build UI
  // ------------------------------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Tips and Videos
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(text: "Post Tip"),
              Tab(text: "Post Videos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Post Tip + Existing + History
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Post Tip Form ---
                  const Text(
                    "Post Recycling Tip",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _tipTitleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _tipDescriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                      hintText:
                          "Include details such as what items to recycle, tips, best practices, etc.",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _pickTipImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Select Image"),
                  ),
                  const SizedBox(height: 10),
                  if (_tipImageBytes != null)
                    Image.memory(_tipImageBytes!, height: 150),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isUploadingTip ? null : _uploadTip,
                    child: _isUploadingTip
                        ? const CircularProgressIndicator()
                        : const Text("Upload Recycling Tip"),
                  ),

                  // --- Existing Tips ---
                  const SizedBox(height: 40),
                  const Text(
                    "Existing Recycling Tips",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('recycling_tips')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text("No tips uploaded yet.");
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(),
                        itemBuilder: (ctx, i) {
                          final doc = docs[i];
                          final data = doc.data()! as Map<String, dynamic>;
                          return ListTile(
                            leading: (data['image_url']
                                        as String?)?.isNotEmpty ==
                                true
                                ? Image.network(data['image_url'],
                                    width: 60,
                                    fit: BoxFit.cover)
                                : const Icon(Icons.image),
                            title:
                                Text(data['title'] ?? 'No Title'),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(data['description'] ??
                                    'No Description'),
                                if (data['timestamp'] != null)
                                  Text(
                                    (data['timestamp']
                                            as Timestamp)
                                        .toDate()
                                        .toLocal()
                                        .toString()
                                        .split('.')[0],
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle:
                                            FontStyle.italic),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      _editTip(doc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          AlertDialog(
                                        title: const Text(
                                            "Delete Tip"),
                                        content: const Text(
                                            "Are you sure you want to delete this tip?"),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context,
                                                      false),
                                              child: const Text(
                                                  "Cancel")),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context,
                                                      true),
                                              child: const Text(
                                                  "Delete")),
                                        ],
                                      ),
                                    );
                                    if (confirm ==
                                        true) {
                                      await _deleteTip(
                                          doc.id,
                                          data['image_url']
                                              as String?);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // --- History of All Tips ---
                  const SizedBox(height: 40),
                  const Text(
                    "Recycling Tips History",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('recycling_tips_history')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, historySnap) {
                      if (historySnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final historyDocs =
                          historySnap.data?.docs ?? [];
                      if (historyDocs.isEmpty) {
                        return const Text("No history available.");
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: historyDocs.length,
                        itemBuilder: (ctx, i) {
                          final data = historyDocs[i]
                              .data()! as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: (data['image_url']
                                          as String?)?.isNotEmpty ==
                                      true
                                  ? Image.network(data['image_url'],
                                      width: 60,
                                      fit: BoxFit.cover)
                                  : const Icon(Icons.history, size: 60),
                              title:
                                  Text(data['title'] ?? 'No Title'),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(data['description'] ??
                                      'No Description'),
                                  if (data['timestamp'] != null)
                                    Text(
                                      (data['timestamp']
                                              as Timestamp)
                                          .toDate()
                                          .toLocal()
                                          .toString()
                                          .split('.')[0],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle:
                                              FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab 2: Post Videos (unchanged)
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Post Video Tutorials",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildVideoUploadSection(1, _videoTitleController1),
                  const SizedBox(height: 20),
                  _buildVideoUploadSection(2, _videoTitleController2),
                  const SizedBox(height: 20),
                  _buildVideoUploadSection(3, _videoTitleController3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for video sections (unchanged)
  Widget _buildVideoUploadSection(
      int index, TextEditingController titleController) {
    return Card(
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Video $index",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Video Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _pickVideo(index: index),
              icon: const Icon(Icons.video_library),
              label: const Text("Select Video"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isUploadingVideo
                  ? null
                  : () => _uploadVideo(index: index),
              child: _isUploadingVideo
                  ? const CircularProgressIndicator()
                  : const Text("Upload Video"),
            ),
          ],
        ),
      ),
    );
  }
}
