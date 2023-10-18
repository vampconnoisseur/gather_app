import 'dart:async';

import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:gather_app/screens/auth_screen.dart';
import 'package:gather_app/screens/splash_screen.dart';
import 'package:gather_app/screens/home_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool splashOn = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      setState(() {
        splashOn = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (splashOn) {
            return const SplashScreen();
          }
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;

            if (user != null) {
              return HomeScreen(
                userEmail: user.email!,
                photoURL: user.photoURL!,
                displayName: user.displayName!,
              );
            } else {
              return const AuthScreen();
            }
          }

          return const SplashScreen();
        },
      ),
    );
  }
}
