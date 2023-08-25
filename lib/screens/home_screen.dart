import 'package:flutter/material.dart';
import 'package:gather_app/screens/auth_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class HomeScreen extends StatelessWidget {
  final String photoURL;
  final String displayName;

  const HomeScreen(
      {super.key, required this.photoURL, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gather',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(photoURL),
            Text(displayName),
            Text(_firebase.currentUser!.email!),
          ],
        ),
      ),
    );
  }
}
