import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThirdPartyHomePage extends StatelessWidget {
  const ThirdPartyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Third-Party Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
            },
          )
        ],
      ),
      body: Center(
        child: Text(
          'Welcome ${user?.email ?? ''}!\nThis is the Third-Party view.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
