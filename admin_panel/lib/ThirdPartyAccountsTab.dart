// lib/Widgets/ThirdPartyAccountsTab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Third-Party Accounts management (create/edit/delete).
/// Creation uses a SECONDARY FirebaseApp so the current admin session
/// is NOT affected (mirrors your Registration flow but without logging out).
class ThirdPartyAccountsTab extends StatefulWidget {
  const ThirdPartyAccountsTab({Key? key}) : super(key: key);

  @override
  State<ThirdPartyAccountsTab> createState() => _ThirdPartyAccountsTabState();
}

class _ThirdPartyAccountsTabState extends State<ThirdPartyAccountsTab> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Create an auth user on a secondary app so the admin stays logged in.
  Future<UserCredential> _createAuthOnSecondary(String email, String password) async {
    // Reuse if already initialized.
    FirebaseApp? secondary;
    try {
      secondary = Firebase.app('secondary');
    } catch (_) {
      secondary = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );
    }
    final auth = FirebaseAuth.instanceFor(app: secondary!);
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    // We do NOT sign this user in on the primary app.
    return cred;
  }

  Future<void> _openForm({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final editing = doc != null;
    final data = doc?.data() ?? {};

    final companyCtrl = TextEditingController(text: data['company'] ?? '');
    final contactCtrl = TextEditingController(text: data['contactName'] ?? '');
    final emailCtrl   = TextEditingController(text: data['email'] ?? '');
    final phoneCtrl   = TextEditingController(text: data['phone'] ?? '');
    final passCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();
    String status     = (data['status'] as String?) ?? 'Active';

    String? errorText;
    bool working = false;

    await showDialog(
      context: context,
      barrierDismissible: !working,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(editing ? 'Edit Third-Party Account' : 'Add Third-Party Account'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company / Organization',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact Person',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !editing, // like Registration, keep immutable after create
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (v) => status = v ?? 'Active',
                  ),
                  if (!editing) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ],
                  if (editing) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Send password reset email'),
                        onPressed: () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty) return;
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Password reset sent to $email')),
                          );
                        },
                      ),
                    ),
                  ],
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: working ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: working
                  ? null
                  : () async {
                      setState(() {
                        working = true;
                        errorText = null;
                      });

                      final company = companyCtrl.text.trim();
                      final contact = contactCtrl.text.trim();
                      final email   = emailCtrl.text.trim();
                      final phone   = phoneCtrl.text.trim();

                      if (company.isEmpty || contact.isEmpty || email.isEmpty) {
                        setState(() {
                          errorText = 'Company, Contact, and Email are required.';
                          working = false;
                        });
                        return;
                      }

                      try {
                        if (editing) {
                          await FirebaseFirestore.instance
                              .collection('third_party_accounts')
                              .doc(doc!.id)
                              .update({
                            'company': company,
                            'contactName': contact,
                            'phone': phone,
                            'status': status,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          final p1 = passCtrl.text;
                          final p2 = confirmCtrl.text;
                          if (p1.length < 6) {
                            throw Exception('Password must be at least 6 characters.');
                          }
                          if (p1 != p2) {
                            throw Exception('Passwords do not match.');
                          }

                          // Create auth user on secondary app (keeps admin logged in)
                          final cred = await _createAuthOnSecondary(email, p1);
                          final uid = cred.user!.uid;

                          // Write Firestore doc (doc id = auth uid)
                          await FirebaseFirestore.instance
                              .collection('third_party_accounts')
                              .doc(uid)
                              .set({
                            'company': company,
                            'contactName': contact,
                            'email': email,
                            'phone': phone,
                            'status': status,
                            'authUid': uid,
                            'createdAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(editing ? 'Account updated' : 'Account created')),
                        );
                      } catch (e) {
                        setState(() {
                          errorText = e.toString();
                          working = false;
                        });
                      }
                    },
              child: Text(editing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(DocumentSnapshot doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text('This will remove "${(doc.data() as Map)['company'] ?? 'Account'}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('third_party_accounts').doc(doc.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('third_party_accounts')
        .orderBy('createdAt', descending: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Third-Party Accounts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search company or contact…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Third-Party'),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return const Center(child: Text('Failed to load accounts'));
              }
              final q = _search.text.trim().toLowerCase();
              final docs = (snap.data?.docs ?? []).where((d) {
                final m = d.data() as Map<String, dynamic>? ?? {};
                final company = (m['company'] as String? ?? '').toLowerCase();
                final contact = (m['contactName'] as String? ?? '').toLowerCase();
                if (q.isEmpty) return true;
                return company.contains(q) || contact.contains(q);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('No third-party accounts found.'));
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Material(
                  color: Colors.white,
                  elevation: 1,
                  borderRadius: BorderRadius.circular(6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Company')),
                        DataColumn(label: Text('Contact')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: docs.map((d) {
                        final m = d.data() as Map<String, dynamic>? ?? {};
                        return DataRow(cells: [
                          DataCell(Text(m['company'] ?? '')),
                          DataCell(Text(m['contactName'] ?? '')),
                          DataCell(Text(m['email'] ?? '')),
                          DataCell(Text(m['phone'] ?? '')),
                          DataCell(
                            Chip(
                              label: Text((m['status'] ?? 'Active').toString()),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Edit',
                                  onPressed: () => _openForm(doc: d as DocumentSnapshot<Map<String, dynamic>>),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(d),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
