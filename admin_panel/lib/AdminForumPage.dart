import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:profanity_filter/profanity_filter.dart';

class AdminForumPage extends StatefulWidget {
  const AdminForumPage({super.key});

  @override
  State<AdminForumPage> createState() => _AdminForumPageState();
}

class _AdminForumPageState extends State<AdminForumPage> {
  final _filter = ProfanityFilter();

  // ➕ Custom Tagalog words (case-insensitive, word-boundary matches)
  final List<String> _customBadWords = ['bobo', 'tanga', 'ulol'];

  bool _showOnlyFlagged = false;
  String _search = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    // ✅ Uses your existing collection & fields
    return FirebaseFirestore.instance
        .collection('forum')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ---------- Profanity helpers (we DO NOT censor; only detect/flag) ----------
  bool _hasCustomProfanity(String input) {
    if (input.isEmpty) return false;
    final lower = input.toLowerCase();
    return _customBadWords.any((w) {
      final pattern = RegExp(r'(^|\W)' + RegExp.escape(w) + r'(\W|$)', caseSensitive: false, unicode: true);
      return pattern.hasMatch(lower);
    });
  }

  bool _hasAnyProfanity(String text) {
    return _filter.hasProfanity(text) || _hasCustomProfanity(text);
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Are you sure you want to delete this message? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Forum Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Row(
            children: [
              const Text('Flagged only'),
              Switch(
                value: _showOnlyFlagged,
                onChanged: (v) => setState(() => _showOnlyFlagged = v),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search text or author',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No forum messages found.'));
                }

                final items = docs.where((d) {
                  final data = d.data();
                  final text = (data['message'] ?? '').toString();
                  final author = (data['username'] ?? 'Unknown').toString();
                  final flagged = _hasAnyProfanity(text);

                  if (_showOnlyFlagged && !flagged) return false;

                  if (_search.isEmpty) return true;
                  final hay = ('$text $author').toLowerCase();
                  return hay.contains(_search);
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text('No results match the current filters.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = items[i];
                    final data = doc.data();
                    final text = (data['message'] ?? '').toString();
                    final author = (data['username'] ?? 'Unknown').toString();

                    final ts = data['timestamp'];
                    DateTime? createdAt;
                    if (ts is Timestamp) createdAt = ts.toDate();

                    final when = createdAt != null
                        ? timeago.format(createdAt, allowFromNow: true)
                        : 'Unknown time';

                    final flagged = _hasAnyProfanity(text);

                    return Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: flagged ? Colors.redAccent.withOpacity(0.35) : Colors.transparent,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                author,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (flagged)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Tooltip(
                                  message: 'Profanity detected',
                                  child: Chip(
                                    label: Text('FLAGGED'),
                                    avatar: Icon(Icons.warning_amber_rounded, size: 18),
                                    backgroundColor: Color(0xFFFFF3E0),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            // ⚠️ Show the original content (no censoring)
                            SelectableText(text),
                            const SizedBox(height: 8),
                            Text(
                              when,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete message',
                          onPressed: () async {
                            final ok = await _confirmDelete(context);
                            if (ok == true) {
                              await doc.reference.delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Message deleted')),
                                );
                              }
                            }
                          },
                        ),
                        onTap: () {
                          // Optional: show full post in a dialog
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(author),
                              content: SingleChildScrollView(child: SelectableText(text)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
