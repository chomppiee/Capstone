// lib/Widgets/AdminAccountClaimsPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAccountClaimsPage extends StatefulWidget {
  final String accountUid;
  final String accountDisplayName;

  const AdminAccountClaimsPage({
    Key? key,
    required this.accountUid,
    required this.accountDisplayName,
  }) : super(key: key);

  @override
  State<AdminAccountClaimsPage> createState() => _AdminAccountClaimsPageState();
}

class _AdminAccountClaimsPageState extends State<AdminAccountClaimsPage> {
  final Set<String> _selectedIds = <String>{};

  Stream<QuerySnapshot> _reservedItemsStream() {
    // Items reserved by this account
    return FirebaseFirestore.instance
        .collection('third_party_inventory')
        .where('reservedByUid', isEqualTo: widget.accountUid)
        .snapshots();
  }

  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _selectAll(Iterable<QueryDocumentSnapshot> docs) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(docs.map((d) => d.id));
    });
  }

  Future<void> _markSelectedAsClaimed() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as claimed'),
        content: Text(
          'Mark ${_selectedIds.length} selected item(s) as claimed by ${widget.accountDisplayName}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Batch update status for selected docs
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        final ref = FirebaseFirestore.instance
            .collection('third_party_inventory')
            .doc(id);
        batch.update(ref, {
          'status': 'Claimed',
          'claimedByUid': widget.accountUid,
          'claimedByName': widget.accountDisplayName,
          'claimedAt': FieldValue.serverTimestamp(),
          // If you want to finalize and clear reservation metadata, uncomment:
          // 'reservedByUid': FieldValue.delete(),
          // 'reservedByName': FieldValue.delete(),
          // 'reservedAt': FieldValue.delete(),
        });
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked ${_selectedIds.length} item(s) as claimed')),
      );
      _clearSelection();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as claimed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _reservedItemsStream();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelecting
            ? '${_selectedIds.length} selected'
            : 'Reserved — ${widget.accountDisplayName}'),
        centerTitle: false,
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear selection',
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (_isSelecting)
            IconButton(
              tooltip: 'Claim selected',
              onPressed: _markSelectedAsClaimed,
              icon: const Icon(Icons.verified),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text('No reserved items for ${widget.accountDisplayName}.'),
            );
          }

          return Column(
            children: [
              if (_isSelecting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _selectAll(docs),
                        icon: const Icon(Icons.select_all),
                        label: const Text('Select all'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _clearSelection,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _markSelectedAsClaimed,
                        icon: const Icon(Icons.verified),
                        label: const Text('Claim'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final m = d.data()! as Map<String, dynamic>;
                    final id = d.id;

                    final title = (m['itemName'] ?? m['title'] ?? 'Untitled').toString();
                    final category = (m['category'] ?? 'Uncategorized').toString();
                    final status = (m['status'] ?? '').toString();
                    final imageUrl = (m['imageUrl'] ?? m['photoUrl'] ?? '').toString();
                    final reservedAt = m['reservedAt'] is Timestamp ? m['reservedAt'] as Timestamp : null;

                    final selected = _selectedIds.contains(id);

                    return InkWell(
                      onLongPress: () => _toggleSelection(id),
                      onTap: () {
                        if (_isSelecting) {
                          _toggleSelection(id);
                        } else {
                          _toggleSelection(id); // start selection on tap
                        }
                      },
                      child: Card(
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: (_) => _toggleSelection(id),
                              ),
                              _Thumb(imageUrl: imageUrl),
                            ],
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Category: $category'),
                              if (status.isNotEmpty) Text('Status: $status'),
                              if (reservedAt != null)
                                Text('Reserved at: ${reservedAt.toDate().toLocal()}'),
                            ],
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String imageUrl;
  const _Thumb({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const SizedBox(width: 48, height: 48, child: Icon(Icons.image_not_supported));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const SizedBox(width: 48, height: 48, child: Icon(Icons.broken_image)),
      ),
    );
    }
}
