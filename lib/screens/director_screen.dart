import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:gather_app/models/director_model.dart';
import 'package:gather_app/components/meeting_chat.dart';
import 'package:gather_app/controllers/director_controller.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Director extends ConsumerStatefulWidget {
  final String channelName;
  final int uid;

  const Director({super.key, required this.channelName, required this.uid});

  @override
  ConsumerState<Director> createState() => _DirectorState();
}

class _DirectorState extends ConsumerState<Director> {
  int readMessageCount = 0;
  int unreadMessageCount = 0;
  String? meetingID;
  bool isModalPopupOn = false;

  StreamSubscription<QuerySnapshot>? meetingSnapshotSubscription;

  @override
  void initState() {
    super.initState();

    final joinedTime = DateTime.now();
    final joinedTimeString = joinedTime.millisecondsSinceEpoch.toString();

    meetingID = "$widget.channelName-$joinedTimeString";

    ref.read(directorController.notifier).joinCall(
          channelName: widget.channelName,
          uid: widget.uid,
          meetingID: meetingID!,
        );
    startListeningForUnreadMessages(meetingID!);
  }

  @override
  void dispose() {
    stopListeningForUnreadMessages();
    super.dispose();
  }

  void popScreen() {
    Navigator.pop(context);
  }

  void startListeningForUnreadMessages(String meetingID) {
    meetingSnapshotSubscription = FirebaseFirestore.instance
        .collection(meetingID)
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        unreadMessageCount = querySnapshot.docs.length - readMessageCount;
      });
    });
  }

  void stopListeningForUnreadMessages() {
    meetingSnapshotSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    DirectorModel directorData = ref.watch(directorController);
    DirectorController directorNotifier =
        ref.watch(directorController.notifier);

    Size size = MediaQuery.of(context).size;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: CupertinoNavigationBar(
          backgroundColor: Colors.grey,
          middle: const Text(
            "Desk",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          trailing: Stack(
            clipBehavior: Clip.none,
            children: [
              TextButton(
                onPressed: () {
                  readMessageCount += unreadMessageCount;
                  setState(() {
                    unreadMessageCount = 0;
                  });
                  isModalPopupOn = true;

                  showModalBottomSheet(
                    useSafeArea: true,
                    isScrollControlled: true,
                    showDragHandle: true,
                    context: context,
                    builder: (BuildContext context) {
                      return SafeArea(
                        bottom: true,
                        child: SizedBox(
                          height: 550,
                          child: ChatMessages(
                            isDirector: true,
                            meetingID: directorData.meetingID!,
                            uid: widget.uid.toString(),
                          ),
                        ),
                      );
                    },
                  ).whenComplete(() {
                    readMessageCount += unreadMessageCount;
                    isModalPopupOn = false;
                  });
                },
                child: const Text(
                  "Chat",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              if (unreadMessageCount > 0 && !isModalPopupOn)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.8),
                    ),
                    child: Text(
                      unreadMessageCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
            ],
          ),
          leading: CupertinoNavigationBarBackButton(
            onPressed: () async {
              await directorNotifier.removeUsers();
              popScreen();
            },
            color: Colors.black,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    SafeArea(
                      child: Container(),
                    ),
                  ],
                ),
              ),
              if (directorData.activeUsers.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: const Text("Empty Stage"),
                        ),
                      ),
                    ],
                  ),
                ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: StageUser(
                            channelName: widget.channelName,
                            directorData: directorData,
                            directorNotifier: directorNotifier,
                            index: index),
                      ),
                    ],
                  );
                }, childCount: directorData.activeUsers.length),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: size.width / 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        thickness: 3,
                        indent: 80,
                        endIndent: 80,
                      ),
                    ),
                  ],
                ),
              ),
              if (directorData.lobbyUsers.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: const Text("Empty Lobby"),
                        ),
                      ),
                    ],
                  ),
                ),
              SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: size.width / 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20),
                delegate: SliverChildBuilderDelegate((BuildContext ctx, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: LobbyUser(
                          channelName: widget.channelName,
                          directorData: directorData,
                          directorNotifier: directorNotifier,
                          index: index,
                        ),
                      ),
                    ],
                  );
                }, childCount: directorData.lobbyUsers.length),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StageUser extends StatelessWidget {
  const StageUser({
    Key? key,
    required this.channelName,
    required this.directorData,
    required this.directorNotifier,
    required this.index,
  }) : super(key: key);

  final String channelName;
  final DirectorModel directorData;
  final DirectorController directorNotifier;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: directorData.activeUsers.elementAt(index).videoDisabled
              ? Stack(children: [
                  Container(
                    color: Colors.grey,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 35,
                      foregroundImage: NetworkImage(
                          directorData.activeUsers.elementAt(index).photoURL!),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10)),
                          color: directorData.activeUsers
                              .elementAt(index)
                              .backgroundColor!
                              .withOpacity(1)),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        directorData.activeUsers.elementAt(index).name ??
                            "name error",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  )
                ])
              : Stack(children: [
                  AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: directorData.engine!,
                      canvas: VideoCanvas(
                          uid: directorData.activeUsers.elementAt(index).rUid),
                      connection: RtcConnection(channelId: channelName),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10)),
                          color: directorData.activeUsers
                              .elementAt(index)
                              .backgroundColor!
                              .withOpacity(1)),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        directorData.activeUsers.elementAt(index).name ??
                            "name error",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ]),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black45,
            ),
            child: IconButton(
              onPressed: () {
                directorNotifier.removeUser(
                  rUid: directorData.activeUsers.elementAt(index).rUid,
                  kicked: true,
                );
              },
              icon: const Icon(Icons.remove),
              color: Colors.red,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black54,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  if (directorData.activeUsers.elementAt(index).muted) {
                    directorNotifier.toggleUserAudio(index: index, muted: true);
                  } else {
                    directorNotifier.toggleUserAudio(
                        index: index, muted: false);
                  }
                },
                icon: const Icon(Icons.mic_off),
                color: directorData.activeUsers.elementAt(index).muted
                    ? Colors.red
                    : Colors.white,
              ),
              IconButton(
                onPressed: () {
                  if (directorData.activeUsers.elementAt(index).videoDisabled) {
                    directorNotifier.toggleUserVideo(
                        index: index, enable: false);
                  } else {
                    directorNotifier.toggleUserVideo(
                        index: index, enable: true);
                  }
                },
                icon: const Icon(Icons.videocam_off),
                color: directorData.activeUsers.elementAt(index).videoDisabled
                    ? Colors.red
                    : Colors.white,
              ),
              IconButton(
                onPressed: () {
                  directorNotifier.demoteToLobbyUser(
                    remoteUid: directorData.activeUsers.elementAt(index).rUid,
                  );
                },
                icon: const Icon(Icons.arrow_downward),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LobbyUser extends StatelessWidget {
  const LobbyUser({
    Key? key,
    required this.channelName,
    required this.directorData,
    required this.directorNotifier,
    required this.index,
  }) : super(key: key);

  final String channelName;
  final DirectorModel directorData;
  final DirectorController directorNotifier;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              color:
                  (directorData.lobbyUsers.elementAt(index).backgroundColor !=
                          null)
                      ? directorData.lobbyUsers
                          .elementAt(index)
                          .backgroundColor!
                          .withOpacity(1)
                      : Colors.grey,
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black45,
                ),
                child: IconButton(
                  onPressed: () {
                    directorNotifier.removeUser(
                      rUid: directorData.lobbyUsers.elementAt(index).rUid,
                      kicked: true,
                    );
                  },
                  icon: const Icon(Icons.remove),
                  color: Colors.red,
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 35,
                foregroundImage: NetworkImage(
                    directorData.lobbyUsers.elementAt(index).photoURL!),
                backgroundColor: Colors.transparent,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.only(topLeft: Radius.circular(10)),
                    color: directorData.lobbyUsers
                        .elementAt(index)
                        .backgroundColor!
                        .withOpacity(1)),
                padding: const EdgeInsets.all(16),
                child: Text(
                  directorData.lobbyUsers.elementAt(index).name ?? "name error",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black54),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      directorNotifier.promoteToActiveUser(
                        remoteUid:
                            directorData.lobbyUsers.elementAt(index).rUid,
                      );
                    },
                    icon: const Icon(Icons.arrow_upward),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
