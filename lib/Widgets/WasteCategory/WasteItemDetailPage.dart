// lib/widgets/WasteCategory/WasteItemDetailPage.dart

import 'package:flutter/material.dart';

class WasteItemDetailPage extends StatelessWidget {
  final String category;
  final String name;
  final String description;
  final String disposal;
  final String tips;

  const WasteItemDetailPage({
    Key? key,
    required this.category,
    required this.name,
    required this.description,
    required this.disposal,
    required this.tips,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Map category to a base color
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.label_outline,
                  size: 40,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description Section
            _SectionHeader(
              icon: Icons.info_outline,
              label: 'Description',
              accent: primary,
              theme: theme,
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),

            // Disposal Section
            _SectionHeader(
              icon: Icons.delete_outline,
              label: 'How to Dispose',
              accent: primary,
              theme: theme,
            ),
            const SizedBox(height: 8),
            Text(disposal, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),

            // Tips Section (if any)
            if (tips.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.lightbulb_outline,
                label: 'Tip',
                accent: primary,
                theme: theme,
              ),
              const SizedBox(height: 8),
              Text(tips, style: theme.textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final ThemeData theme;

  const _SectionHeader({
    Key? key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: accent),
        ),
      ],
    );
  }
}
