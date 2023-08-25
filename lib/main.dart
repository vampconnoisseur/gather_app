import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:gather_app/screens/auth_screen.dart';
import 'package:gather_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final user = FirebaseAuth.instance.currentUser;

  runApp(
    App(
      initialScreen: user != null
          ? HomeScreen(photoURL: user.photoURL!, displayName: user.displayName!)
          : const AuthScreen(),
    ),
  );
}

class App extends StatelessWidget {
  final Widget initialScreen;

  const App({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: initialScreen,
    );
  }
}
