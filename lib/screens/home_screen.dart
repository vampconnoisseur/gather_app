import 'package:flutter/material.dart';

import 'package:gather_app/screens/auth_screen.dart';
import 'package:gather_app/screens/participant_screen.dart';
import 'package:gather_app/screens/director_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
  final _userName = TextEditingController();
  late int uid;

  @override
  void initState() {
    super.initState();
    getUserUid();
  }

  Future<void> getUserUid() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? storedUid = preferences.getInt("localUid");
    if (storedUid != null) {
      uid = storedUid;
      _log("storedUID: $uid");
    } else {
      int time = DateTime.now().microsecondsSinceEpoch;
      uid = int.parse(time.toString().substring(1, time.toString().length - 3));
      preferences.setInt("localUid", uid);
      _log("settingUID: $uid");
    }
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
            const Text("Multi Streaming With Friends"),
            const SizedBox(
              height: 40,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: TextField(
                controller: _userName,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  hintText: "User Name",
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: TextField(
                controller: _channelName,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  hintText: "Channel Name",
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await [Permission.camera, Permission.microphone].request();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Participant(
                      channelName: _channelName.text,
                      userName: _userName.text,
                      uid: uid,
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Participant ",
                    style: TextStyle(fontSize: 20),
                  ),
                  Icon(
                    Icons.live_tv,
                  )
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Director(
                      channelName: _channelName.text,
                      uid: uid,
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Director ",
                    style: TextStyle(fontSize: 20),
                  ),
                  Icon(
                    Icons.cut,
                  )
                ],
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
