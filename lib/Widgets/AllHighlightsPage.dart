import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:segregate1/Widgets/CalendarPage.dart';

class AllHighlightsPage extends StatelessWidget {
  const AllHighlightsPage({Key? key}) : super(key: key);

  // Build list view for community highlights.
  Widget _buildHighlightsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_highlights')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading highlights: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No community highlights yet."));
        }
        final highlights = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: highlights.length,
          itemBuilder: (context, index) {
            final highlight = highlights[index].data() as Map<String, dynamic>;
            final docId = highlights[index].id;
            final title = highlight['title'] ?? 'Untitled';
            final imageUrl = highlight['image_url'];
            // Extract date/time from the document.
            String dateStr = '';
            String timeStr = '';
            if (highlight.containsKey('date_time') &&
                highlight['date_time'] != null) {
              final Timestamp ts = highlight['date_time'] as Timestamp;
              final DateTime dt = ts.toDate();
              dateStr = DateFormat('EEE, MMM d').format(dt);
              timeStr = DateFormat('hh:mm a').format(dt);
            }
            return GestureDetector(
              onTap: () => _showHighlightDetails(context, docId),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event image.
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: imageUrl != null && imageUrl.toString().isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.broken_image, size: 60)),
                            )
                          : Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                            ),
                    ),
                    // Title container.
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Date & Time Row (if available).
                    if (dateStr.isNotEmpty && timeStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show full-screen details for a community highlight.
  void _showHighlightDetails(BuildContext context, String docId) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_highlights')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'Untitled';
          final description = data['description'] ?? 'No Description Available';
          final imageUrl = data['image_url'] ?? '';
          String dateStr = "";
          String timeStr = "";
          if (data.containsKey('date_time') && data['date_time'] != null) {
            final Timestamp ts = data['date_time'] as Timestamp;
            final DateTime dt = ts.toDate();
            dateStr = DateFormat('EEE, MMM d').format(dt);
            timeStr = DateFormat('hh:mm a').format(dt);
          }
          // Get participants list.
          List<dynamic> participants = data.containsKey('participants')
              ? List<dynamic>.from(data['participants'])
              : [];
          bool isParticipating = participants.contains(currentUser.uid);
          int participantsCount = participants.length;

          // Get attended users list.
          List<dynamic> attendedUsers = data.containsKey('attendedUsers')
              ? List<dynamic>.from(data['attendedUsers'])
              : [];
          bool isAttended = attendedUsers.contains(currentUser.uid);

          // Determine which badge or button to show.
          late Widget statusBadge;
          if (isAttended) {
            statusBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Attended",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            );
          } else if (isParticipating) {
            statusBadge = Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Participated",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('community_highlights')
                        .doc(docId)
                        .update({
                      'participants': FieldValue.arrayRemove([currentUser.uid])
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Withdraw"),
                ),
              ],
            );
          } else {
            statusBadge = ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('community_highlights')
                    .doc(docId)
                    .update({
                  'participants': FieldValue.arrayUnion([currentUser.uid])
                });
                Navigator.pop(context);
              },
              child: const Text("Participate"),
            );
          }

          return Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.green,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(title),
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full image.
                    imageUrl.isNotEmpty
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              height: 300,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 300,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                          )
                        : Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 60, color: Colors.grey),
                          ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title.
                          Text(
                            title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          // Date & Time.
                          if (dateStr.isNotEmpty && timeStr.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // Description.
                          Text(
                            description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          // Participation/Attended badge row.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              statusBadge,
                              Text(
                                "$participantsCount participants",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // QR Button section.
                          if (isParticipating && !isAttended)
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.qr_code),
                                label: const Text("Generate Attendance QR"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () {
                                  final String uid = currentUser.uid;
                                  final Map<String, String> qrPayload = {"uid": uid, "eventId": docId};
                                  final String qrData = jsonEncode(qrPayload);
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          width: MediaQuery.of(context).size.width * 0.7,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                "Show this QR to Admin",
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                              ),
                                              const SizedBox(height: 16),
                                              QrImageView(data: qrData, version: QrVersions.auto, size: 200),
                                              const SizedBox(height: 16),
                                              const Text(
                                                "Ask the admin to scan this QR code to mark your attendance.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 20),
                                              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Community Events"),
  backgroundColor: Colors.green,
  actions: [
    IconButton(
      icon: const Icon(Icons.calendar_today),
      tooltip: 'View Calendar',
      onPressed: () {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CalendarPage()),
  );
      },
    ),
  ],
),
      body: _buildHighlightsList(context),
    );
  }
}
