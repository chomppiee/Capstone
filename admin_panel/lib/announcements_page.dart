// lib/widgets/announcements_page.dart
//
// COMPLETE file — fixes RenderFlex overflow (11px) and keeps 2-column, auto-fit cards
// - Precise width math that accounts for outer padding + spacing (uses floorToDouble to avoid rounding overflow)
// - Two columns when >= 800px, one column below
// - Cards size to content; actions and title/date are Wraps to avoid flex overflow
// - Past-date protections preserved
//
// Prereqs:
//   cloud_firestore: ^5.x
//   firebase_storage: ^12.x
//   image_picker_web: ^3.x
//
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;
  DateTime? _selectedDate;

  DateTime _todayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select date';
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage() async {
    final image = await ImagePickerWeb.getImageAsBytes();
    if (image != null) {
      setState(() {
        _imageBytes = image;
        _imageName = 'announcement_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _pickDate() async {
    final today = _todayDateOnly();
    final initial = _selectedDate != null && !_selectedDate!.isBefore(today)
        ? _selectedDate!
        : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today, // 🚫 past dates
      lastDate: DateTime(2100),
      helpText: 'Select schedule date',
    );

    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _uploadAnnouncement() async {
    final today = _todayDateOnly();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a schedule date.')),
      );
      return;
    }
    if (_selectedDate!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot select a past date.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String imageUrl = '';
      if (_imageBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('announcements/${_imageName ?? 'announcement_${DateTime.now().millisecondsSinceEpoch}.jpg'}');
        await ref.putData(_imageBytes!);
        imageUrl = await ref.getDownloadURL();
      }

      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'scheduled_date': Timestamp.fromDate(_selectedDate!),
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef =
          await FirebaseFirestore.instance.collection('announcements').add(payload);

      await FirebaseFirestore.instance
          .collection('announcement_history')
          .doc(docRef.id)
          .set(payload);

      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _selectedDate = null;
        _imageBytes = null;
        _imageName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement posted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteAnnouncement(String docId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();

      if ((imageUrl ?? '').isNotEmpty) {
        final parts = imageUrl!.split('/o/');
        if (parts.length > 1) {
          final filePathEncoded = parts[1].split('?').first;
          final filePath = Uri.decodeComponent(filePathEncoded);
          await FirebaseStorage.instance.ref(filePath).delete();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Announcement deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  Future<void> _showEditUI(DocumentSnapshot doc) async {
    final data = doc.data()! as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final DateTime? currentScheduled = (data['scheduled_date'] is Timestamp)
        ? (data['scheduled_date'] as Timestamp).toDate()
        : null;

    DateTime? tempSelected = currentScheduled == null
        ? null
        : DateTime(currentScheduled.year, currentScheduled.month, currentScheduled.day);

    final isSmall = MediaQuery.of(context).size.width < 600;

    Future<void> pickEditDate() async {
      final today = _todayDateOnly();
      final initial = tempSelected != null && !tempSelected!.isBefore(today)
          ? tempSelected!
          : today;

      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: today,
        lastDate: DateTime(2100),
        helpText: 'Select schedule date',
      );
      if (picked != null) {
        tempSelected = DateTime(picked.year, picked.month, picked.day);
        setState(() {});
      }
    }

    Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: pickEditDate,
            icon: const Icon(Icons.date_range),
            label: Text(
              tempSelected == null
                  ? 'Select date'
                  : '${tempSelected!.year}-${tempSelected!.month.toString().padLeft(2, '0')}-${tempSelected!.day.toString().padLeft(2, '0')}',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  final today = _todayDateOnly();
                  if ((titleController.text.trim()).isEmpty ||
                      (descriptionController.text.trim()).isEmpty ||
                      tempSelected == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fill all fields and select a date.')),
                    );
                    return;
                  }
                  if (tempSelected!.isBefore(today)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You cannot select a past date.')),
                    );
                    return;
                  }

                  try {
                    final update = {
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'scheduled_date': Timestamp.fromDate(tempSelected!),
                    };

                    await FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(doc.id)
                        .update(update);

                    await FirebaseFirestore.instance
                        .collection('announcement_history')
                        .doc(doc.id)
                        .set({
                      ...data,
                      ...update,
                      'timestamp': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Announcement updated.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );

    if (isSmall) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
          child: content,
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
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
  Widget build(BuildContext context) {
    final today = _todayDateOnly();

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double outerPadding = 16; // must match SingleChildScrollView padding
          const double spacing = 16;      // Wrap spacing between columns
          final bool wide = constraints.maxWidth >= 800;

          // Width available INSIDE the scroll view padding
          final double available =
              (constraints.maxWidth - (outerPadding * 2)).clamp(0, double.infinity);

          // Exact two columns when wide; floorToDouble prevents 1–2px rounding overflow
          final double cardWidth = wide
              ? ((available - spacing) / 2).floorToDouble()
              : available;

          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(outerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------- Form -------
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Create Announcement',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickDate,
                                    icon: const Icon(Icons.date_range),
                                    label: Text(_formatDate(_selectedDate)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.image),
                                  label: Text(_imageBytes == null ? 'Add image' : 'Change image'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_selectedDate != null && _selectedDate!.isBefore(today))
                              const Text(
                                'Selected date is in the past. Please choose today or later.',
                                style: TextStyle(color: Colors.red),
                              ),
                            if (_imageBytes != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _imageBytes!,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isUploading ? null : _uploadAnnouncement,
                                child: _isUploading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Post Announcement'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------- Active Announcements -------
                  const Text('Announcements',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('announcements')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: const [
                                Icon(Icons.campaign_outlined),
                                SizedBox(width: 12),
                                Expanded(child: Text('No announcements yet. Create your first one above.')),
                              ],
                            ),
                          ),
                        );
                      }

                      if (wide) {
                        // Two columns with exact available width (prevents overflows)
                        return SizedBox(
                          width: available,
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (final d in docs)
                                SizedBox(
                                  width: cardWidth,
                                  child: _AnnouncementCard(
                                    title: d.data()['title'] ?? '',
                                    description: d.data()['description'] ?? '',
                                    imageUrl: (d.data()['image_url'] as String?) ?? '',
                                    scheduled: (d.data()['scheduled_date'] is Timestamp)
                                        ? (d.data()['scheduled_date'] as Timestamp).toDate()
                                        : null,
                                    onEdit: () => _showEditUI(d),
                                    onDelete: () => _deleteAnnouncement(
                                      d.id,
                                      (d.data()['image_url'] as String?) ?? '',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      } else {
                        return ListView.separated(
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final d = docs[i];
                            final data = d.data();
                            final imageUrl = (data['image_url'] as String?) ?? '';
                            final scheduled = (data['scheduled_date'] is Timestamp)
                                ? (data['scheduled_date'] as Timestamp).toDate()
                                : null;

                            return _AnnouncementCard(
                              title: data['title'] ?? '',
                              description: data['description'] ?? '',
                              imageUrl: imageUrl,
                              scheduled: scheduled,
                              onEdit: () => _showEditUI(d),
                              onDelete: () => _deleteAnnouncement(d.id, imageUrl),
                            );
                          },
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // ------- History -------
                  const Text('History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('announcement_history')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: const [
                                Icon(Icons.history),
                                SizedBox(width: 12),
                                Expanded(child: Text('No history yet. You’ll see a log here after posting.')),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final data = docs[i].data();
                          final imageUrl = (data['image_url'] as String?) ?? '';
                          final scheduled = (data['scheduled_date'] is Timestamp)
                              ? (data['scheduled_date'] as Timestamp).toDate()
                              : null;

                          return Card(
                            child: ListTile(
                              leading: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.history, size: 40),
                              title: Text(
                                data['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (scheduled != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Scheduled: ${scheduled.year}-${scheduled.month.toString().padLeft(2, '0')}-${scheduled.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
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
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final DateTime? scheduled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.scheduled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const double thumbWidth = 160;
    const double thumbHeight = 110; // compact to keep card short

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
                        child: const Center(child: Icon(Icons.campaign, size: 40)),
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
                  // Title + date chip — Wrap prevents row overflow
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Let title take whatever space is available
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 0, maxWidth: 9999),
                        child: Text(
                          title,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (scheduled != null)
                        Chip(
                          label: Text(
                            '${scheduled!.year}-${scheduled!.month.toString().padLeft(2, '0')}-${scheduled!.day.toString().padLeft(2, '0')}',
                          ),
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

                  // Compact actions — Wrap prevents tiny overflows on narrow widths
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
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
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
