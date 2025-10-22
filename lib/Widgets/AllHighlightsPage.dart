import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AllHighlightsPage extends StatefulWidget {
  const AllHighlightsPage({Key? key}) : super(key: key);

  @override
  State<AllHighlightsPage> createState() => _AllHighlightsPageState();
}

class _AllHighlightsPageState extends State<AllHighlightsPage> {
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Events"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(
                _isAscending ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip:
                _isAscending ? 'Sort Descending' : 'Sort Ascending',
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
              });
            },
          ),
        ],
      ),
      body: _buildHighlightsList(context),
    );
  }

  Widget _buildHighlightsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_highlights')
          .orderBy('date_time', descending: !_isAscending)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child:
                  Text("Error loading highlights: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No community highlights yet."));
        }

        final highlights = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: highlights.length,
          itemBuilder: (context, index) {
            final data =
                highlights[index].data()! as Map<String, dynamic>;
            final docId = highlights[index].id;
            final title = data['title'] ?? 'Untitled';
            final imageUrl = data['image_url'] as String?;
            final bool allowParticipation =
                (data['allowParticipation'] as bool?) ?? false;

            // parse date/time
            String dateStr = '';
            String timeStr = '';
            bool isPast = false;
            if (data['date_time'] != null) {
              final ts = data['date_time'] as Timestamp;
              final dt = ts.toDate();
              dateStr = DateFormat('EEE, MMM d').format(dt);
              timeStr = DateFormat('hh:mm a').format(dt);
              isPast = dt.isBefore(DateTime.now());
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
                    // Image + DONE badge
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: Stack(
                        children: [
                          imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                  errorBuilder: (c, e, st) =>
                                      const Center(
                                          child: Icon(
                                    Icons.broken_image,
                                    size: 60,
                                  )),
                                )
                              : Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                      child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  )),
                                ),
                          if (isPast)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withOpacity(0.7),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "DONE",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Participation badge in list (optional mini badge)
                    if (allowParticipation)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4),
                        child: Text(
                          "Participation Open",
                          style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                    // Date & Time
                    if (dateStr.isNotEmpty && timeStr.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
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
          final data =
              snapshot.data!.data()! as Map<String, dynamic>;

          final title = data['title'] ?? 'Untitled';
          final description =
              data['description'] ?? 'No Description';
          final imageUrl = data['image_url'] ?? '';
          final bool allowParticipation =
              (data['allowParticipation'] as bool?) ?? false;

          // parse date/time
          String dateStr = '';
          String timeStr = '';
          if (data['date_time'] != null) {
            final ts = data['date_time'] as Timestamp;
            final dt = ts.toDate();
            dateStr = DateFormat('EEE, MMM d').format(dt);
            timeStr = DateFormat('hh:mm a').format(dt);
          }

          // participants & attendance
          final List<dynamic> participants =
              List<dynamic>.from(data['participants'] ?? []);
          final bool isParticipating =
              participants.contains(currentUser.uid);
          final int participantsCount = participants.length;

          final List<dynamic> attendedUsers =
              List<dynamic>.from(data['attendedUsers'] ?? []);
          final bool isAttended =
              attendedUsers.contains(currentUser.uid);

          // badge logic
          late Widget statusBadge;
          if (isAttended) {
            statusBadge = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Attended",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            );
          } else if (isParticipating) {
            statusBadge = Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Participated",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('community_highlights')
                        .doc(docId)
                        .update({
                      'participants':
                          FieldValue.arrayRemove([currentUser.uid])
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
                  'participants':
                      FieldValue.arrayUnion([currentUser.uid])
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
                    // Full image
                    imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            height: 300,
                            errorBuilder:
                                (c, e, st) => Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Icon(
                                  Icons.broken_image, size: 60),
                            ),
                          )
                        : Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image,
                                size: 60, color: Colors.grey),
                          ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (dateStr.isNotEmpty && timeStr.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(dateStr,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle:
                                            FontStyle.italic,
                                        color: Colors.grey)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(timeStr,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle:
                                            FontStyle.italic,
                                        color: Colors.grey)),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Text(description,
                              style:
                                  const TextStyle(fontSize: 16)),

                          // ─── only show participation UI if allowed ─
                          if (allowParticipation) ...[
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                statusBadge,
                                Text(
                                  "$participantsCount participants",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (isParticipating &&
                                !isAttended)
                              Center(
                                child:
                                    ElevatedButton.icon(
                                  icon: const Icon(
                                      Icons.qr_code),
                                  label: const Text(
                                      "Generate Attendance QR"),
                                  style:
                                      ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green),
                                  onPressed: () {
                                    final uid =
                                        currentUser.uid;
                                    final qrData = jsonEncode({
                                      "uid": uid,
                                      "eventId": docId
                                    });
                                    showDialog(
                                      context: context,
                                      builder:
                                          (BuildContext
                                              context) {
                                        return Dialog(
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    16),
                                          ),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(
                                                    20),
                                            width: MediaQuery.of(
                                                        context)
                                                    .size
                                                    .width *
                                                0.7,
                                            child: Column(
                                              mainAxisSize:
                                                  MainAxisSize
                                                      .min,
                                              children: [
                                                const Text(
                                                  "Show this QR to Admin",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                      fontSize:
                                                          18),
                                                ),
                                                const SizedBox(
                                                    height:
                                                        16),
                                                QrImageView(
                                                    data:
                                                        qrData,
                                                    version: QrVersions
                                                        .auto,
                                                    size: 200),
                                                const SizedBox(
                                                    height:
                                                        16),
                                                const Text(
                                                  "Ask the admin to scan this QR code to mark your attendance.",
                                                  textAlign:
                                                      TextAlign
                                                          .center,
                                                  style: TextStyle(
                                                      fontSize:
                                                          14),
                                                ),
                                                const SizedBox(
                                                    height:
                                                        20),
                                                ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context),
                                                    child: const Text(
                                                        "Close")),
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
}
