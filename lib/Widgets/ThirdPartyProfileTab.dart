// lib/Widgets/ThirdPartyProfileTab.dart
import 'package:flutter/material.dart';

class ThirdPartyProfileTab extends StatelessWidget {
  final String? company;
  final String? contactName;
  final String? email;
  final String? phone;
  final String? status;
  final VoidCallback onLogout;

  const ThirdPartyProfileTab({
    Key? key,
    required this.company,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.status,
    required this.onLogout,
  }) : super(key: key);

  Widget _row(BuildContext context, String label, String? value) {
    final display = (value == null || value.isEmpty) ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row(context, 'Company', company),
                _row(context, 'Contact name', contactName),
                _row(context, 'Email', email),
                _row(context, 'Phone', phone),
                _row(context, 'Status', status),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ),
      ],
    );
  }
}
