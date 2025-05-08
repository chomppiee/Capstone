import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'WasteItemDetailPage.dart';

class WasteItemsListPage extends StatelessWidget {
  final String category;
  const WasteItemsListPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine colors based on category
    late final MaterialColor baseColor;
    switch (category) {
      case 'Biodegradable':
        baseColor = Colors.green;
        break;
      case 'Non-Biodegradable':
        baseColor = Colors.blue;
        break;
      case 'Recyclable':
        baseColor = Colors.amber;
        break;
      case 'Hazardous':
        baseColor = Colors.red;
        break;
      default:
        baseColor = Colors.grey;
    }
    final Color primary = baseColor.shade700;
    final Color light = baseColor.shade50;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          '$category Items',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: WasteItemCategorySearchDelegate(category),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('waste_items')
            .where('category', isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No items found in $category.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              return Card(
                color: light,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: light,
                    child: Icon(
                      Icons.label_outline,
                      color: primary,
                    ),
                  ),
                  title: Text(
                    data['name'],
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: primary),
                  ),
                  subtitle: Text(
                    data['disposal'],
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: primary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WasteItemDetailPage(
                          category: category,
                          name: data['name'],
                          description: data['description'],
                          disposal: data['disposal'],
                          tips: data['tips'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// SearchDelegate filtered to only this category
class WasteItemCategorySearchDelegate extends SearchDelegate<void> {
  final String category;
  WasteItemCategorySearchDelegate(this.category);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search items'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('waste_items')
          .where('category', isEqualTo: category)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No items found'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data()! as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name']),
              subtitle: Text(data['disposal'], maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WasteItemDetailPage(
                      category: category,
                      name: data['name'],
                      description: data['description'],
                      disposal: data['disposal'],
                      tips: data['tips'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
