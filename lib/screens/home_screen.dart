import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:gather_app/components/call_logs.dart';
import 'package:gather_app/screens/auth_screen.dart';
import 'package:gather_app/screens/participant_screen.dart';
import 'package:gather_app/screens/director_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:permission_handler/permission_handler.dart';

final _firebase = FirebaseAuth.instance;

class HomeScreen extends StatefulWidget {
  final String photoURL;
  final String displayName;
  final String userEmail;

  const HomeScreen({
    Key? key,
    required this.userEmail,
    required this.photoURL,
    required this.displayName,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final _channelName = TextEditingController();
  int? uid;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    getUserUID();
  }

  Future<void> getUserUID() async {
    DocumentReference<Map<String, dynamic>> userCredentials =
        FirebaseFirestore.instance.collection('user-ids').doc(widget.userEmail);

    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userCredentials.get();

    if (snapshot.exists) {
      uid = snapshot.get('uid');
      debugPrint("Retrieved UID: $uid");
    } else {
      uid = generateRandomUid();
      await userCredentials.set({'uid': uid});
      debugPrint("Generated and saved UID: $uid");
    }
  }

  int generateRandomUid() {
    final random = Random();
    return 100000 + random.nextInt(900000);
  }

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

  void navigateToParticipantScreen() {
    if (uid != null) {
      Navigator.pop(
        context,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Participant(
            userName: widget.displayName,
            photoURL: widget.photoURL,
            channelName: _channelName.text,
            uid: uid!,
          ),
        ),
      );
    } else {
      return;
    }
  }

  void navigateToDirectorScreen() {
    if (uid != null) {
      Navigator.pop(context);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Director(
            channelName: _channelName.text,
            uid: uid!,
          ),
        ),
      );
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        leading: TextButton(
          onPressed: () {
            showModalBottomSheet(
              showDragHandle: true,
              isScrollControlled: true,
              context: context,
              builder: (BuildContext context) {
                return LayoutBuilder(builder: (context, constraints) {
                  final keyboardSpace =
                      MediaQuery.of(context).viewInsets.bottom;
                  return SafeArea(
                    bottom: true,
                    child: SizedBox(
                      height: keyboardSpace + 233,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                          child: Column(
                            children: [
                              const Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  "Join a meeting",
                                  style: TextStyle(
                                    fontSize: 31,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 25,
                              ),
                              SizedBox(
                                child: TextField(
                                  controller: _channelName,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    hintText: "Channel Name",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.all(15),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (_channelName.text.trim().isNotEmpty) {
                                        await [
                                          Permission.camera,
                                          Permission.microphone
                                        ].request();

                                        navigateToParticipantScreen();
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CupertinoAlertDialog(
                                              title: const Text("Error"),
                                              content: const Text(
                                                "Channel name cannot be empty.",
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: const Text("Okay"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          "Participant ",
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Icon(
                                          Icons.live_tv,
                                          color: Colors.black,
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.all(15),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (_channelName.text.trim().isNotEmpty) {
                                        await [
                                          Permission.camera,
                                          Permission.microphone
                                        ].request();
                                        navigateToDirectorScreen();
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CupertinoAlertDialog(
                                              title: const Text("Error"),
                                              content: const Text(
                                                  "Channel name cannot be empty."),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: const Text("Okay"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Director ",
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Icon(
                                          Icons.cut,
                                          color: Colors.black,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            );
          },
          child: const Text(
            "Join",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        middle: const Text(
          'Gather',
          style: TextStyle(fontSize: 21),
        ),
        trailing: CupertinoNavigationBarBackButton(
          onPressed: () async {
            await _logout();
            await GoogleSignIn().signOut();
          },
          color: Colors.black,
        ),
        backgroundColor: Colors.grey,
      ),
      body: _selectedTabIndex == 1
          ? CallLogsScreen(
              uid: uid.toString(),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    foregroundImage: NetworkImage(widget.photoURL),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    widget.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Logs',
          ),
        ],
        currentIndex: _selectedTabIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black45,
        backgroundColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }
}
