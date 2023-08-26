import 'package:flutter/material.dart';
import 'package:gather_app/screens/auth_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class HomeScreen extends StatefulWidget {
  final String photoURL;
  final String displayName;

  const HomeScreen({
    Key? key,
    required this.photoURL,
    required this.displayName,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _logout() async {
    await _firebase.signOut();
    navigateToAuthScreen();
  }

  void navigateToAuthScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gather'),
        actions: [
          IconButton(
            onPressed: () async {
              await _logout();
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
            Image.network(widget.photoURL),
            Text(widget.displayName),
            Text(_firebase.currentUser!.email!),
          ],
        ),
      ),
    );
  }
}
