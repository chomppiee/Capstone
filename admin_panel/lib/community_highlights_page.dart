// lib/widgets/CommunityHighlightsPage.dart
//
// COMPLETE file — Community Highlights themed like Announcements,
// RESTORES date & time feature and ENFORCES: you CANNOT enable participation
// once the highlight's date/time has passed (you can still disable it).
//
// Fields (same as your original):
//   title, description, image_url, date_time (Timestamp), allowParticipation (bool), timestamp
//
// Other features kept:
// - Image upload
// - Edit (title & description)
// - Delete (plus Storage cleanup)
// - Attendees count per highlight (subcollection 'attendees')
// - History mirror in 'community_highlights_history'
//
// Layout:
// - Two columns (>=800px) using Wrap with precise width math (no overflow)
// - Cards auto-fit content with compact thumbnail and tidy action row

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:logging/logging.dart';

class CommunityHighlightsPage extends StatefulWidget {
  const CommunityHighlightsPage({super.key});

  @override
  State<CommunityHighlightsPage> createState() => _CommunityHighlightsPageState();
}

class _CommunityHighlightsPageState extends State<CommunityHighlightsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  DateTime? _selectedDateTime; // RESTORED date+time
  bool _allowParticipation = false; // original field name kept
  final Logger _log = Logger('CommunityHighlights');

  // ------------ Helpers ------------
  bool _isPastDateTime(DateTime dt) => DateTime.now().isAfter(dt);

  String _fmtDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _pickImage() async {
    final image = await ImagePickerWeb.getImageAsBytes();
    if (image != null) {
      setState(() {
        _imageBytes = image;
        _imageName = 'highlight_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay(hour: _selectedDateTime!.hour, minute: _selectedDateTime!.minute)
          : TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      // If picked a past datetime and switch was ON, turn it OFF (can't enable on past)
      if (_selectedDateTime != null && _isPastDateTime(_selectedDateTime!) && _allowParticipation) {
        _allowParticipation = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Participation disabled: date/time is in the past.")),
        );
      }
    });
  }

  Future<void> _uploadHighlight() async {
    // Base validation
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _imageBytes == null ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields, select image & date/time.")),
      );
      return;
    }

    // Prevent enabling participation when creating a past event
    if (_selectedDateTime != null && _isPastDateTime(_selectedDateTime!) && _allowParticipation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot enable participation for a past date/time.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // upload image
      final ref = FirebaseStorage.instance.ref().child('community_highlights/${_imageName!}');
      await ref.putData(_imageBytes!);
      final imageUrl = await ref.getDownloadURL();

      // payload
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'date_time': Timestamp.fromDate(_selectedDateTime!), // RESTORED
        'timestamp': FieldValue.serverTimestamp(),
        'allowParticipation': _allowParticipation, // original field preserved
      };

      // write
      final docRef = await FirebaseFirestore.instance
          .collection('community_highlights')
          .add(data);

      await FirebaseFirestore.instance
          .collection('community_highlights_history')
          .doc(docRef.id)
          .set(data);

      // reset
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _imageBytes = null;
        _imageName = null;
        _selectedDateTime = null;
        _allowParticipation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Highlight uploaded successfully.")),
      );
    } catch (e, stack) {
      _log.severe("Error uploading highlight", e, stack);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
Future<void> _deleteHighlight(String docId, String? imageUrl) async {
  // ✅ Step 1: Ask for confirmation before deleting
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: const Text(
        'Are you sure you want to delete this highlight?\n\n'
        'It will be moved to the archive (History) and can no longer be edited.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes, Delete'),
        ),
      ],
    ),
  );

  if (confirm != true) return; // Cancelled by user

  try {
    final docRef = FirebaseFirestore.instance
        .collection('community_highlights')
        .doc(docId);

    final docSnap = await docRef.get();
    final data = docSnap.data();

    if (data != null) {
      // ✅ Step 2: Move document to archive (History)
      await FirebaseFirestore.instance
          .collection('community_highlights_history')
          .doc(docId)
          .set({
        ...data,
        'deleted_at': FieldValue.serverTimestamp(),
        'archived_reason': 'Deleted manually by admin',
      });
    }

    // ✅ Step 3: Delete from active collection
    await docRef.delete();

    // ✅ Step 4: Delete image from storage (optional)
    if ((imageUrl ?? '').isNotEmpty) {
      final uri = Uri.parse(imageUrl!);
      final parts = uri.path.split('/o/');
      if (parts.length > 1) {
        final filePath = Uri.decodeComponent(parts[1]);
        await FirebaseStorage.instance.ref().child(filePath).delete();
      }
    }

    // ✅ Step 5: Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Highlight moved to archive successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    // Error handling
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting highlight: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  void _editHighlight(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');

    final isSmall = MediaQuery.of(context).size.width < 600;

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: "Description"),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('community_highlights')
                      .doc(doc.id)
                      .update({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                  });
                  if (mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text("Highlight updated.")));
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ],
      ),
    );

    if (isSmall) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 12),
          child: content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(child: content),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

// ------------ UI ------------
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Community Highlights")),
    body: LayoutBuilder(
      builder: (context, constraints) {
        const double outerPadding = 16;
        const double spacing = 16;
        final bool wide = constraints.maxWidth >= 800;

        final double available =
            (constraints.maxWidth - (outerPadding * 2))
                .clamp(0, double.infinity);
        final double cardWidth =
            wide ? ((available - spacing) / 2).floorToDouble() : available;

        // ✅ Use ListView instead of IntrinsicHeight to fix hidden UI issue
        return ListView(
          padding: const EdgeInsets.all(outerPadding),
          children: [
            // ----- Create form (themed) -----
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Add Highlight",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                          labelText: "Title", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(_imageBytes == null
                              ? "Select Image"
                              : "Change Image"),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickDateTime,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text("Select Date & Time"),
                        ),
                      ],
                    ),

                    // --- Uploaded Image Placeholder (See Attachment) ---
                    if (_imageBytes != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 400,
                                        maxHeight: 300,
                                      ),
                                      child: Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Photo Uploaded (See Attachment)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (_selectedDateTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Selected: ${_fmtDateTime(_selectedDateTime!)}",
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Allow Participation — blocked if selected date/time is past
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Allow Participation"),
                      subtitle: (_selectedDateTime != null &&
                              _isPastDateTime(_selectedDateTime!))
                          ? const Text(
                              "Locked: date/time is already past",
                              style: TextStyle(color: Colors.red),
                            )
                          : null,
                      value: _allowParticipation,
                      onChanged: (val) {
                        if (_selectedDateTime != null &&
                            _isPastDateTime(_selectedDateTime!) &&
                            val == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Cannot enable participation for a past date/time."),
                            ),
                          );
                          return;
                        }
                        setState(() => _allowParticipation = val);
                      },
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isUploading ? null : _uploadHighlight,
                        child: _isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Upload Highlight"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ----- Highlights (two-column, themed) -----
            const Text("Highlights",
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_highlights')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: const [
                          Icon(Icons.emoji_events_outlined),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  "No highlights uploaded yet. Create the first one above.")),
                        ],
                      ),
                    ),
                  );
                }

                if (wide) {
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final doc in docs)
                        SizedBox(
                          width: cardWidth,
                          child: _HighlightCard(
                            doc: doc,
                            fmtDateTime: _fmtDateTime,
                            isPast: (() {
                              final dtTs =
                                  (doc['date_time'] as Timestamp?);
                              final dt = dtTs?.toDate();
                              return dt == null
                                  ? false
                                  : _isPastDateTime(dt);
                            })(),
                            onEdit: () => _editHighlight(doc),
                            onDelete: (imageUrl) =>
                                _deleteHighlight(doc.id, imageUrl),
                          ),
                        ),
                    ],
                  );
                } else {
                  return ListView.separated(
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final isPast = (() {
                        final dtTs =
                            (doc['date_time'] as Timestamp?);
                        final dt = dtTs?.toDate();
                        return dt == null
                            ? false
                            : _isPastDateTime(dt);
                      })();
                      return _HighlightCard(
                        doc: doc,
                        fmtDateTime: _fmtDateTime,
                        isPast: isPast,
                        onEdit: () => _editHighlight(doc),
                        onDelete: (imageUrl) =>
                            _deleteHighlight(doc.id, imageUrl),
                      );
                    },
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // ----- History (themed) -----
            const Text("History",
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
  .collection('community_highlights')
  .where('date_time', isLessThan: Timestamp.now())
  .orderBy('date_time', descending: true)
  .snapshots(),

              builder: (context, historySnapshot) {
                if (historySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final historyDocs = historySnapshot.data?.docs ?? [];
                if (historyDocs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: const [
                          Icon(Icons.history),
                          SizedBox(width: 12),
                          Expanded(child: Text("No history available.")),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: historyDocs.length,
                  itemBuilder: (context, idx) {
                    final data =
                        historyDocs[idx].data()! as Map<String, dynamic>;
                    final img = (data['image_url'] as String?) ?? '';
                    final dt =
                        (data['date_time'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        leading: img.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(img,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover),
                              )
                            : const Icon(Icons.history, size: 40),
                        title: Text(
                          (data['title'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data['description'] ?? '').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (dt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  _fmtDateTime(dt),
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection(
                                      'community_highlights_history')
                                  .doc(historyDocs[idx].id)
                                  .collection('attendees')
                                  .get(),
                              builder: (ctx, sn) {
                                if (!sn.hasData) {
                                  return const Text('Attendees: ...',
                                      style: TextStyle(fontSize: 12));
                                }
                                final cnt = sn.data!.docs.length;
                                return Text('Attendees: $cnt',
                                    style:
                                        const TextStyle(fontSize: 12));
                              },
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
        );
      },
    ),
  );
}

}

// ====== Card widget matching Announcements theme ======

class _HighlightCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onEdit;
  final void Function(String? imageUrl) onDelete;
  final bool isPast; // lock enabling when true
  final String Function(DateTime) fmtDateTime;

  const _HighlightCard({
    required this.doc,
    required this.onEdit,
    required this.onDelete,
    required this.isPast,
    required this.fmtDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data()! as Map<String, dynamic>;
    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final imageUrl = (data['image_url'] as String?) ?? '';
    final dateTs = data['date_time'] as Timestamp?;
    final dateTime = dateTs?.toDate();
    final allow = (data['allowParticipation'] as bool?) ?? false;

    const double thumbWidth = 160;
    const double thumbHeight = 110;

    Future<void> _toggleParticipation(bool desired) async {
      // Block enabling when date/time has passed
      if (isPast && desired == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot enable participation after the date/time.")),
        );
        return;
      }
      if (desired == allow) return; // no-op

      try {
        await FirebaseFirestore.instance
            .collection('community_highlights')
            .doc(doc.id)
            .update({'allowParticipation': desired});
      } catch (_) {}
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: thumbWidth,
                height: thumbHeight,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.emoji_events_outlined, size: 40)),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 0, maxWidth: 9999),
                        child: Text(
                          title,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Chip(
                        label: Text(allow ? 'Participation: On' : 'Participation: Off'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (dateTime != null)
                        Chip(
                          label: Text('When: ${fmtDateTime(dateTime)}'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (isPast)
                        Chip(
                          label: const Text('Past'),
                          avatar: const Icon(Icons.schedule, size: 16),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Attendees count
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('community_highlights')
                        .doc(doc.id)
                        .collection('attendees')
                        .get(),
                    builder: (ctx, attendeeSnap) {
                      if (!attendeeSnap.hasData) {
                        return const Text('Attendees: ...', style: TextStyle(fontSize: 12));
                      }
                      final count = attendeeSnap.data!.docs.length;
                      return Text('Attendees: $count', style: const TextStyle(fontSize: 12));
                    },
                  ),

                  const SizedBox(height: 8),

                  // Actions
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => onDelete(imageUrl),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // Participation button: disabled when isPast & currently Off
                      if (allow)
                        OutlinedButton(
                          onPressed: () => _toggleParticipation(false),
                          child: const Text('Disable participation'),
                        )
                      else
                        OutlinedButton(
                          onPressed: isPast ? null : () => _toggleParticipation(true),
                          child: const Text('Enable participation'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}