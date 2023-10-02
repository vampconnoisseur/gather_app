import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:math';

import 'package:gather_app/screens/auth_screen.dart';
import 'package:gather_app/screens/participant_screen.dart';
import 'package:gather_app/screens/director_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:permission_handler/permission_handler.dart';

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
  final _channelName = TextEditingController();
  late int uid;

  @override
  void initState() {
    super.initState();
    generateSixDigitNumber();
  }

  void generateSixDigitNumber() {
    final random = Random();
    uid = 100000 + random.nextInt(900000);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        leading: TextButton(
          onPressed: () {
            showModalBottomSheet(
              useSafeArea: true,
              isScrollControlled: true,
              context: context,
              builder: (BuildContext context) {
                return LayoutBuilder(builder: (context, constraints) {
                  final keyboardSpace =
                      MediaQuery.of(context).viewInsets.bottom;
                  return SizedBox(
                    height: keyboardSpace + 275,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(30, 30, 30, keyboardSpace + 50),
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
                              width: MediaQuery.of(context).size.width * 0.85,
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
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                      Navigator.pop(
                                        context,
                                      );
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Participant(
                                            userName: widget.displayName,
                                            photoURL: widget.photoURL,
                                            channelName: _channelName.text,
                                            uid: uid,
                                          ),
                                        ),
                                      );
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
                                      Navigator.pop(
                                        context,
                                      );
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Director(
                                            channelName: _channelName.text,
                                            uid: uid,
                                          ),
                                        ),
                                      );
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                const SizedBox(
                                  height: 50,
                                ),
                              ],
                            ),
                          ],
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
          },
          color: Colors.black,
        ),
        backgroundColor: Colors.grey,
      ),
      body: Center(
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
    );
  }
}

void _log(String info) {
  debugPrint(info);
}
