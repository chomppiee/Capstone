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

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _exportToExcelWeb() {
    if (_docs == null || _docs!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    // 1) Create workbook & sheet
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Inventory'];

    // 2) Header row
    sheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Status'),
      TextCellValue('Received Date'),
      TextCellValue('Donor UID'),
    ]);

    // 3) Data rows
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

    // 4) Encode to bytes
    final List<int>? bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate Excel')),
      );
      return;
    }

    // 5) Make a Blob and anchor for download
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barangay Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export to Excel',
            onPressed: _exportToExcelWeb,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('barangay_inventory')
            .orderBy('receivedDate', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Failed to load inventory'));
          }
          _docs = snap.data?.docs;
          if (_docs!.isEmpty) {
            return const Center(child: Text('No items in inventory'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxis = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxis,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 4 / 7,
                ),
                itemCount: _docs!.length,
                itemBuilder: (context, i) {
                  final doc = _docs![i];
                  final data = doc.data()! as Map<String, dynamic>;
                  final title    = data['title']    as String? ?? '';
                  final category = data['category'] as String? ?? '';
                  final status   = data['status']   as String? ?? '';
                  final imgUrl   = data['imageUrl'] as String?;

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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    category,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Status: $status',
                                      style: const TextStyle(fontSize: 12)),
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
            },
          );
        },
      ),
    );
  }
}
