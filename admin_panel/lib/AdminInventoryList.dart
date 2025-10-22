// lib/Widgets/InventoryList.dart

import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class AdminInventoryList extends StatefulWidget {
  const AdminInventoryList({Key? key}) : super(key: key);

  @override
  State<AdminInventoryList> createState() => _AdminInventoryListState();
}

class _AdminInventoryListState extends State<AdminInventoryList> {
  List<QueryDocumentSnapshot>? _docs;

  static const List<String> _eligibleCategories = [
    'Recyclable Materials',
    'Mobile Phones',
    'Chargers & Cables',
    'Other',
    'Bicycles & Scooters',
    'Gardening Tools',
    'Hand Tools',
    'Radios / Flashlights / Lamps',
  ];

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

Future<void> _moveEligibleToThirdParty() async {
  final now = DateTime.now();
  final cutoff = Timestamp.fromDate(now.subtract(const Duration(days: 60)));

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Move eligible items?'),
      content: const Text(
        'Items in eligible categories that have been in inventory for 2 months or more will be moved to the Third-Party Disposition list.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Move'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final q = await FirebaseFirestore.instance
        .collection('barangay_inventory')
        .where('category', whereIn: _eligibleCategories)
        .where('receivedDate', isLessThanOrEqualTo: cutoff)
        .get();

    if (q.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No eligible items to move')),
      );
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    for (final d in q.docs) {
      final data = d.data();

      final dstRef = FirebaseFirestore.instance
          .collection('third_party_inventory')
          .doc(d.id);

      batch.set(dstRef, {
        ...data,
        'status': 'For Sale',
        'movedAt': FieldValue.serverTimestamp(),
        'sourceCollection': 'barangay_inventory',
      });

      batch.delete(d.reference);
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved ${q.docs.length} item(s) to Third-Party Disposition')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Move failed: $e')),
    );
  }
}


  void _exportToExcelWeb() {
    if (_docs == null || _docs!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final excel = Excel.createExcel();
    final Sheet sheet = excel['Inventory'];

    sheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Status'),
      TextCellValue('Received Date'),
      TextCellValue('Donor UID'),
    ]);

    for (final doc in _docs!) {
      final data = doc.data()! as Map<String, dynamic>;
      sheet.appendRow([
        TextCellValue(data['title'] ?? ''),
        TextCellValue(data['category'] ?? ''),
        TextCellValue(data['status'] ?? ''),
        TextCellValue(
          data['receivedDate'] != null
              ? _formatTimestamp(data['receivedDate'] as Timestamp)
              : '',
        ),
        TextCellValue(data['donorUid'] ?? ''),
      ]);
    }

    final List<int>? bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate Excel')),
      );
      return;
    }

    final blob = html.Blob([Uint8List.fromList(bytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..download = 'barangay_inventory.xlsx'
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  void _showItemDetails(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';
    final receivedTs = data['receivedDate'] as Timestamp?;
    final detailWidth = MediaQuery.of(context).size.width * 0.5;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: detailWidth),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['imageUrl'] as String,
                      width: detailWidth * 0.7,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  data['title'] as String? ?? 'Item Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Category: ${data['category'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Status: $status'),
                if (receivedTs != null) ...[
                  const SizedBox(height: 8),
                  Text('Received: ${_formatTimestamp(receivedTs)}'),
                ],
                const SizedBox(height: 8),
                Text('Donor UID: ${data['donorUid'] ?? ''}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (status != 'Claimed')
            TextButton(
              onPressed: () async {
                await doc.reference.update({'status': 'Claimed'});
                Navigator.pop(context);
              },
              child: const Text('Mark Claimed'),
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid(List<QueryDocumentSnapshot> docs, double maxWidth) {
    final crossAxis = maxWidth > 800 ? 4 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4 / 7,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final doc = docs[i];
        final data = doc.data()! as Map<String, dynamic>;
        final title = data['title'] as String? ?? '';
        final category = data['category'] as String? ?? '';
        final status = data['status'] as String? ?? '';
        final imgUrl = data['imageUrl'] as String?;

        return GestureDetector(
          onTap: () => _showItemDetails(context, doc),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                Expanded(
                  flex: 7,
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(color: Colors.grey[200]),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('Status: $status', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThirdPartyGrid(List<QueryDocumentSnapshot> docs, double maxWidth) {
    // Similar look, but read from third_party_inventory
    final crossAxis = maxWidth > 800 ? 4 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4 / 7,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final doc = docs[i];
        final data = doc.data()! as Map<String, dynamic>;
        final title = data['title'] as String? ?? '';
        final category = data['category'] as String? ?? '';
        final status = data['status'] as String? ?? 'For Sale';
        final imgUrl = data['imageUrl'] as String?;
        final ts = data['receivedDate'] as Timestamp?;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(color: Colors.grey[200]),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text('Status: $status', style: const TextStyle(fontSize: 12)),
                      if (ts != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Received: ${_formatTimestamp(ts)}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barangay Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export to Excel',
            onPressed: _exportToExcelWeb,
          ),
          IconButton(
            icon: const Icon(Icons.sync_alt),
            tooltip: 'Move eligible to Third-Party',
            onPressed: _moveEligibleToThirdParty,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Main Inventory =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('barangay_inventory')
                  .orderBy('receivedDate', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Failed to load inventory')),
                  );
                }
                _docs = snap.data?.docs;
                if (_docs == null || _docs!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No items in inventory')),
                  );
                }

                return _buildInventoryGrid(_docs!, width);
              },
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ===== Third-Party Disposition =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Text(
                    'Third-Party Disposition',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Items moved here are eligible for sale to third parties (auto: ≥ 2 months old in eligible categories).',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('third_party_inventory')
                  .orderBy('receivedDate', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Failed to load third-party items')),
                  );
                }
                final thirdDocs = snap.data?.docs ?? [];
                if (thirdDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No items in Third-Party Disposition')),
                  );
                }

                return _buildThirdPartyGrid(thirdDocs, width);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
