import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:gather_app/screens/auth_screen.dart';
import 'package:gather_app/screens/home_screen.dart';
import 'package:gather_app/screens/splash_screen.dart';

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

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;

            if (user != null) {
              return HomeScreen(
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
