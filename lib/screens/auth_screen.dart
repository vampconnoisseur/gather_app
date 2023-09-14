import 'dart:io';
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
    User? user;

    try {
      isAuthenticating();

      await GoogleAuthService().signInWithGoogle();

      user = _firebase.currentUser;

      if (user != null) {
        displayName = user.displayName;
        imageUrl = user.photoURL;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google sign-in failed.',
          ),
        ),
      );
    } finally {
      isAuthenticating();

      if (user != null && imageUrl != null && displayName != null) {
        navigateToHomeScreen(context, imageUrl, displayName);
      }
    }
  }

  void navigateToHomeScreen(
      BuildContext context, String photoURL, String displayName) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          photoURL: photoURL,
          displayName: displayName,
        ),
      ),
    );
  }

  void _submit(BuildContext context) async {
    final isValid = _form.currentState!.validate();
    String? imageUrl;
    String? displayName;

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
        displayName = user?.displayName;
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });

        await _firebase.currentUser!.updatePhotoURL(imageUrl);
        await _firebase.currentUser!.updateDisplayName(_enteredUsername);

        displayName = _enteredUsername;
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Authentication failed.',
          ),
        ),
      );

      isAuthenticating();
    } finally {
      navigateToHomeScreen(context, imageUrl!, displayName!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Authenticate',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
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
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Email Address'),
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
                              decoration:
                                  const InputDecoration(labelText: 'Username'),
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
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height: 35),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: () => _submit(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                padding: const EdgeInsets.only(
                                  left: 25,
                                  right: 25,
                                  top: 15,
                                  bottom: 15,
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Login' : 'Signup',
                                style: const TextStyle(fontSize: 17),
                              ),
                            ),
                          const SizedBox(height: 30),
                          if (!_isAuthenticating)
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    height: 1,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Divider(
                                    height: 1,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          if (!_isAuthenticating) const SizedBox(height: 30),
                          if (!_isAuthenticating)
                            SignInButton(
                              ontap: _signInWithGoogle,
                              isLogin: _isLogin,
                            ),
                          if (!_isAuthenticating) const SizedBox(height: 12),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: _toggleFormMode,
                              child: Text(_isLogin
                                  ? 'Create an account'
                                  : 'I already have an account'),
                            ),
                        ],
                      ),
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
