// lib/Widgets/ThirdPartyHomePage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:shared_preferences/shared_preferences.dart';

// Update these if your paths differ
import 'package:segregate1/Authentication/Loginpage.dart';
import 'package:segregate1/Widgets/ThirdPartyProfileTab.dart';
import 'package:segregate1/Widgets/ThirdPartyClaimPage.dart';


class ThirdPartyHomePage extends StatefulWidget {
  const ThirdPartyHomePage({Key? key}) : super(key: key);

  @override
  State<ThirdPartyHomePage> createState() => _ThirdPartyHomePageState();
}

class _ThirdPartyHomePageState extends State<ThirdPartyHomePage> {
  int _currentIndex = 0;
  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _accountStream() {
    final uid = _user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('third_party_accounts')
        .doc(uid)
        .snapshots();
  }

Future<void> _confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      // ✅ Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // ✅ Clear Remember Me data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('saved_remember');

      if (!mounted) return;

      // ✅ Navigate back to login page safely
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }
}


  void _openClaimPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ThirdPartyClaimPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _accountStream();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final company = (data?['company'] as String?)?.trim();
        final contactName = (data?['contactName'] as String?)?.trim();
        final email = (data?['email'] as String?)?.trim() ?? _user?.email ?? '';
        final phone = (data?['phone'] as String?)?.trim();
        final status = (data?['status'] as String?)?.trim();

        return Scaffold(
          appBar: AppBar(
            title: Text(_currentIndex == 0 ? 'Home' : 'Profile'),
            centerTitle: false,
            actions: [
              if (_currentIndex == 0)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: _openClaimPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_turned_in, size: 18),
                    label: const Text('Claim'),
                  ),
                ),
            ],
          ),
          body: _currentIndex == 0
              ? _HomeTab(
                  company: company,
                  contactName: contactName,
                  fallbackEmail: email,
                )
              : ThirdPartyProfileTab(
                  company: company,
                  contactName: contactName,
                  email: email,
                  phone: phone,
                  status: status,
                  onLogout: () => _confirmAndLogout(context),
                ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===================== HOME TAB =====================
class _HomeTab extends StatelessWidget {
  final String? company;
  final String? contactName;
  final String? fallbackEmail;

  const _HomeTab({
    Key? key,
    required this.company,
    required this.contactName,
    required this.fallbackEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final welcome = (company != null && company!.isNotEmpty)
        ? 'Welcome, $company!'
        : 'Welcome!';

    final inventoryStream =
        FirebaseFirestore.instance.collection('third_party_inventory').snapshots();

    final currentUid = FirebaseAuth.instance.currentUser?.uid?.trim();

    debugPrint('[HomeTab] build at ${DateTime.now().toIso8601String()} | uid=$currentUid');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            welcome,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: inventoryStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('[HomeTab] inventory: loading...');
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('[HomeTab] inventory: error=${snapshot.error}');
                  return Center(
                    child: Text('Error loading inventory: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  debugPrint('[HomeTab] inventory: empty');
                  return const Center(child: Text('No inventory found.'));
                }

                final docs = snapshot.data!.docs;
                debugPrint('[HomeTab] inventory: ${docs.length} items');

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final docId = doc.id;
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final title =
                        (data['itemName'] ?? data['title'] ?? 'Untitled').toString();
                    final category =
                        (data['category'] ?? 'Uncategorized').toString();
                    final description = (data['description'] ?? '').toString();
                    final imageUrl =
                        (data['imageUrl'] ?? data['photoUrl'] ?? '').toString();

                    // Source of truth: reservedByUid
                    final reservedByUid = (data['reservedByUid'] ?? '').toString().trim();
                    final reservedByYou =
                        currentUid != null && reservedByUid == currentUid;

                    // Legacy/fallback status (may vary)
                    final rawStatus = (data['status'] ?? '').toString();
                    final s = rawStatus.trim().toLowerCase();

                    // Normalized for UI: reserved if reservedByUid is set; otherwise available
                    final normalizedStatus =
                        reservedByUid.isNotEmpty ? 'reserved' : (s == 'reserved' ? 'reserved' : 'available');

                    debugPrint(
                        '[HomeTab] item[$index] docId=$docId | title="$title" | statusRaw="$rawStatus" | normalized="$normalizedStatus" | reservedByUid="$reservedByUid" | reservedByYou=$reservedByYou');

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        onTap: () {
                          debugPrint(
                              '[HomeTab] onTap docId=$docId | title="$title" | open popup');
                          _showItemDialog(
                            context: context,
                            docId: docId,
                            title: title,
                            category: category,
                            description: description,
                            status: rawStatus, // pass raw for debug/display if needed
                            reservedByUid: reservedByUid,
                            reservedByName: (data['reservedByName'] ?? '').toString(),
                            imageUrl: imageUrl,
                            currentUid: currentUid,
                            reserveDisplayName:
                                (company?.isNotEmpty ?? false)
                                    ? company!
                                    : (contactName?.isNotEmpty ?? false)
                                        ? contactName!
                                        : (fallbackEmail ?? 'Unknown'),
                          );
                        },
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(
                              status: normalizedStatus,    // 'available' | 'reserved'
                              reservedByYou: reservedByYou,
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Category: $category'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
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

  void _showItemDialog({
    required BuildContext context,
    required String docId,
    required String title,
    required String category,
    required String description,
    required String status, // raw (for debugging if needed)
    required String reservedByUid,
    required String reservedByName,
    required String imageUrl,
    required String? currentUid,
    required String reserveDisplayName,
  }) {
    final isReservedNow = reservedByUid.trim().isNotEmpty;
    final isReservedByYou =
        (currentUid != null && reservedByUid.trim().isNotEmpty && reservedByUid.trim() == currentUid.trim());

    debugPrint(
        '[Popup] open docId=$docId | title="$title" | rawStatus="${status.trim()}" | reservedByUid="$reservedByUid" | isReservedNow=$isReservedNow | isReservedByYou=$isReservedByYou');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _StatusChip(
                        status: isReservedNow ? 'reserved' : 'available',
                        reservedByYou: isReservedByYou,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Image — not cropped + pinch-to-zoom
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 420,
                          minHeight: 220,
                          minWidth: double.infinity,
                        ),
                        color: Colors.black12,
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    _ImagePlaceholder(),
                  const SizedBox(height: 16),

                  // Details
                  _detailRow(context, 'Category', category),
                  if (description.isNotEmpty)
                    _detailRow(context, 'Description', description),
                  const SizedBox(height: 24),

                  // Actions (Reserve + Close side-by-side)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Reserve is always tappable; transaction enforces correctness
                      ElevatedButton.icon(
                        onPressed: () async {
                          debugPrint(
                              '[Reserve] tap docId=$docId | user=${currentUid ?? "NULL"} | name="$reserveDisplayName" | time=${DateTime.now().toIso8601String()}');
                          try {
                            await _reserveItemTransaction(
                              docId: docId,
                              reserveUid: currentUid,
                              reserveName: reserveDisplayName,
                            );
                            if (context.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Item reserved successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('[Reserve] FAILED docId=$docId | error=$e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Reserve failed: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text('Reserve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isReservedNow ? Colors.grey.shade400 : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

Future<void> _reserveItemTransaction({
  required String docId,
  required String? reserveUid,
  required String reserveName,
}) async {
  if (reserveUid == null || reserveUid.trim().isEmpty) throw 'No authenticated user';

  final uidTrim = reserveUid.trim();
  final docRef = FirebaseFirestore.instance
      .collection('third_party_inventory')
      .doc(docId);

  await FirebaseFirestore.instance.runTransaction((txn) async {
    final snap = await txn.get(docRef);
    if (!snap.exists) throw 'Item no longer exists';

    final data = snap.data() as Map<String, dynamic>? ?? {};

    // Primary truth: reservedByUid
    final curReservedByUid = (data['reservedByUid'] ?? '').toString().trim();

    // ✅ If nobody reserved it, allow reserve (ignore legacy status text altogether)
    if (curReservedByUid.isNotEmpty) {
      if (curReservedByUid == uidTrim) throw 'You already reserved this item';
      throw 'Item is already reserved';
    }

    // Normalize going forward
    txn.update(docRef, {
      'status': 'Reserved',
      'reservedByUid': uidTrim,
      'reservedByName': reserveName,
      'reservedAt': FieldValue.serverTimestamp(),
    });
  });
}


  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== WIDGETS =====================
class _StatusChip extends StatelessWidget {
  final String status; // normalized: 'available' | 'reserved'
  final bool reservedByYou;
  const _StatusChip({
    required this.status,
    this.reservedByYou = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (status == 'reserved') {
      return Chip(
        label: Text(reservedByYou ? 'Reserved by You' : 'Reserved'),
        backgroundColor: Colors.orange.withOpacity(0.14),
        labelStyle:
            const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.orange.withOpacity(0.5)),
        ),
        visualDensity: VisualDensity.compact,
      );
    }
    // default Available
    return Chip(
      label: const Text('Available'),
      backgroundColor: Colors.green.withOpacity(0.12),
      labelStyle:
          const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.green.withOpacity(0.5)),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      ),
    );
  }
}
