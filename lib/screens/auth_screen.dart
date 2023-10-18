import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:gather_app/components/sign_in_button.dart';
import 'package:gather_app/services/google_auth_service.dart';
import 'package:gather_app/components/user_image_picker.dart';
import 'package:gather_app/screens/home_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  var _isAuthenticating = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showSnackBar({required String message}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void isAuthenticating() {
    setState(() {
      _isAuthenticating = !_isAuthenticating;
    });
  }

  void _toggleFormMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _signInWithGoogle() async {
    String? imageUrl;
    String? displayName;
    String? userEmail;
    User? user;

    try {
      isAuthenticating();

      await GoogleAuthService().signInWithGoogle();

      user = _firebase.currentUser;

      if (user != null) {
        final displayNameParts = user.displayName?.split(' ');

        if (displayNameParts != null && displayNameParts.isNotEmpty) {
          displayName = displayNameParts[0];
        } else {
          displayName = user.displayName;
        }

        imageUrl = user.photoURL;
        userEmail = user.email;
        await user.updateDisplayName(displayName);
      }
    } catch (error) {
      showSnackBar(message: 'Google sign-in failed.');
    } finally {
      isAuthenticating();

      if (user != null &&
          imageUrl != null &&
          displayName != null &&
          userEmail != null) {
        navigateToHomeScreen(imageUrl, displayName, userEmail);
      }
    }
  }

  void navigateToHomeScreen(
      String photoURL, String displayName, String userEmail) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          photoURL: photoURL,
          displayName: displayName,
          userEmail: userEmail,
        ),
      ),
    );
  }

  void _submit(BuildContext context) async {
    final isValid = _form.currentState!.validate();
    String? imageUrl;
    String? displayName;
    String? userEmail;

    if (!isValid || !_isLogin && _selectedImage == null) {
      return;
    }
    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        final user = _firebase.currentUser;

        imageUrl = user?.photoURL;

        final displayNameParts = user?.displayName?.split(' ');
        if (displayNameParts != null && displayNameParts.isNotEmpty) {
          displayName = displayNameParts[0];
        } else {
          displayName = user?.displayName;
        }

        userEmail = user?.email;
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();

        final displayNameParts = _enteredUsername.split(' ');
        if (displayNameParts.isNotEmpty) {
          displayName = displayNameParts[0];
        } else {
          displayName = _enteredUsername;
        }

        userEmail = _enteredEmail;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': displayName,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });

        await _firebase.currentUser!.updatePhotoURL(imageUrl);
        await _firebase.currentUser!.updateDisplayName(displayName);
        await _firebase.currentUser!.updateEmail(_enteredEmail);
      }
    } on FirebaseAuthException catch (error) {
      showSnackBar(message: error.message ?? 'Authentication failed.');
      isAuthenticating();
    } finally {
      navigateToHomeScreen(
        imageUrl!,
        displayName!,
        userEmail!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: Text(
          _isLogin ? 'Sign In' : 'Sign Up',
          style: const TextStyle(fontSize: 21),
        ),
        backgroundColor: Colors.grey,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAuthenticating)
                Column(children: [
                  const CupertinoActivityIndicator(
                    color: Colors.black,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin ? "Logging in..." : "Signing up...",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ]),
              if (!_isAuthenticating)
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: const EdgeInsets.fromLTRB(35, 0, 35, 0),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Form(
                            key: _form,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_isLogin)
                                  UserImagePicker(
                                    onPickImage: (pickedImage) {
                                      _selectedImage = pickedImage;
                                    },
                                  ),
                                if (!_isLogin)
                                  const SizedBox(
                                    height: 5,
                                  ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        !value.contains('@')) {
                                      return 'Please enter a valid email address.';
                                    }

                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredEmail = value!;
                                  },
                                ),
                                if (!_isLogin)
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Username'),
                                    enableSuggestions: false,
                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty ||
                                          value.trim().length < 4) {
                                        return 'Please enter at least 4 characters.';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _enteredUsername = value!;
                                    },
                                  ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'Password'),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().length < 6) {
                                      return 'Password must be at least 6 characters long.';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredPassword = value!;
                                  },
                                ),
                                const SizedBox(height: 50),
                                ElevatedButton(
                                  onPressed: () => _submit(context),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 4,
                                    backgroundColor: Colors.grey,
                                    padding: const EdgeInsets.only(
                                      left: 25,
                                      right: 25,
                                      top: 15,
                                      bottom: 15,
                                    ),
                                  ),
                                  child: Text(
                                    _isLogin ? 'Login' : 'SignUp',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 50),
                                if (_isLogin)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          height: 1,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: const Text(
                                          "or",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          height: 1,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_isLogin) const SizedBox(height: 40),
                                if (_isLogin)
                                  SignInButton(
                                    ontap: _signInWithGoogle,
                                    isLogin: _isLogin,
                                  ),
                                if (_isLogin) const SizedBox(height: 30),
                                TextButton(
                                  onPressed: _toggleFormMode,
                                  child: Text(
                                    _isLogin
                                        ? 'Create an account.'
                                        : 'I already have an account.',
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
