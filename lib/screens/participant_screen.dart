import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:gather_app/message.dart';
import 'package:gather_app/utils/config.dart';
import 'package:gather_app/models/user_model.dart';
import 'package:gather_app/services/renew_token.dart';
import 'package:gather_app/components/whiteboard.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class Participant extends StatefulWidget {
  final String channelName;
  final String userName;
  final int uid;
  final String photoURL;

  const Participant(
      {super.key,
      required this.photoURL,
      required this.channelName,
      required this.userName,
      required this.uid});

  @override
  ParticipantState createState() => ParticipantState();
}

class ParticipantState extends State<Participant> {
  late RtcEngine _engine;
  AgoraRtmClient? _client;
  AgoraRtmChannel? _channel;
  bool muted = true;
  bool videoDisabled = true;
  bool activeUser = false;

  bool isAudioAlertActive = false;
  bool isVideoAlertActive = false;
  bool chatActive = false;
  bool whiteBoardActive = false;

  var myRuid = "";
  int? myRuid1;

  bool areControlButtonsActive = true;
  bool isEndCallButtonActive = true;
  Timer? buttonTimer;

  DateTime? joinedTime;
  String? joinedTimeString;

  List<AgoraUser> _users = [];

  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _channel?.leave();
    _client?.logout();
    _client?.release();
    if (_users.isNotEmpty) {
      _users.clear();
    }
    _users.clear();
    _engine.release();
    buttonTimer?.cancel();
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

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();

    await _engine.initialize(const RtcEngineContext(
      appId: Config.engineAppID,
    ));

    _client = await AgoraRtmClient.createInstance(Config.channelAppID);

    await _engine.enableVideo();
    await _engine.muteLocalAudioStream(true);
    await _engine.muteLocalVideoStream(true);
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  void initialize() async {
    await _initAgora();

    _engine.registerEventHandler(
      RtcEngineEventHandler(onError: (ErrorCodeType err, String msg) {
        _log('[onError] err: $err, msg: $msg');
      }, onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _log(
            '[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');

        myRuid = connection.localUid.toString();
      }, onUserJoined: (RtcConnection connection, int rUid, int elapsed) async {
        _log(
            '[onUserJoined] connection: ${connection.toJson()} remoteUid[Set]: $rUid elapsed: $elapsed');

        myRuid1 = rUid;

        joinedTime = DateTime.now();
        joinedTimeString = joinedTime?.millisecondsSinceEpoch.toString();

        await FirebaseFirestore.instance
            .collection('meetings')
            .doc(joinedTimeString)
            .set({
          'channel': widget.channelName,
          'uid': widget.uid,
          'username': widget.userName,
          'join_time': joinedTime,
        });
      }, onUserOffline:
          (RtcConnection connection, int rUid, UserOfflineReasonType reason) {
        _log('userLeft: $rUid');
      }, onLeaveChannel: (RtcConnection connection, RtcStats stats) async {
        _log('onLeaveChannel');
        if (_users.isNotEmpty) _users.clear();
      }),
    );

    _client?.onMessageReceived = (message, peerId) {
      _log("Private Message from $peerId ${message.text}");
    };

    _client?.onConnectionStateChanged2 = (state, reason) {
      _log(
          'Connection state changed: ${state.toString()}, reason: ${reason.toString()}');
      if (state == RtmConnectionState.aborted) {
        _channel?.leave();
        _client?.logout();
        _client?.release();
        _log('Logout.');
      }
    };

    await _client?.login(null, widget.uid.toString());

    _channel = await _client?.createChannel(widget.channelName);
    await _channel?.join();

    String? rtcToken = await fetchRtcToken(widget.channelName, widget.uid);

    if (rtcToken == null) {
      _log("Error fetching RTC Token. ");
    } else {
      await _engine.joinChannel(
        token: rtcToken,
        channelId: widget.channelName,
        uid: widget.uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    }

    _channel?.onMemberJoined = (member) {
      _log("Member joined: ${member.userId}, channel: ${member.channelId}");
    };

    _channel?.onMemberLeft = (member) {
      _log("Member left: ${member.userId}, channel: ${member.channelId}");
    };

    _channel?.onMessageReceived = (message, fromMember) {
      List<String> parsedMessage = message.text.split(" ");

      String action = parsedMessage[0];
      String participantRuid = parsedMessage[1];

      switch (action) {
        case "removedUser":
          String userName = parsedMessage[2];
          if (participantRuid != myRuid) {
            showSnackBar(message: "$userName has left");
          }
        case "userJoined":
          String userName = parsedMessage[2];
          if (participantRuid != myRuid) {
            showSnackBar(message: "$userName has joined");
          }
          break;
        case "unstaged":
          if (participantRuid == myRuid) {
            setState(() {
              isEndCallButtonActive = true;
            });
            showSnackBar(message: "Director has removed you from stage.");
          }
          break;
        case "staged":
          if (participantRuid == myRuid) {
            startButtonTimer();
            showSnackBar(message: "Director has added you to stage.");
          }
          break;
        case "sendCredentials":
          if (participantRuid.toString() == myRuid) {
            _channel!.sendMessage2(
              RtmMessage.fromText(
                Message().sendCredentials(
                  fromUserId: fromMember.userId,
                  myRuid: myRuid,
                  userName: widget.userName,
                  photoURL: widget.photoURL,
                ),
              ),
            );
          }
          break;
        case "mute":
          if (participantRuid.toString() == myRuid) {
            setState(() {
              muted = true;
            });
            _engine.muteLocalAudioStream(true);

            showSnackBar(message: "Director has muted you.");
          }
          break;
        case "unmute":
          if (participantRuid.toString() == myRuid && !isAudioAlertActive) {
            isAudioAlertActive = true;

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: const Text("Director Request"),
                  content:
                      const Text("The director wants to turn your audio on."),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        isAudioAlertActive = false;
                      },
                    ),
                    TextButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        Navigator.of(context).pop();

                        setState(() {
                          muted = false;
                        });
                        _engine.muteLocalAudioStream(false);

                        isAudioAlertActive = false;
                      },
                    ),
                  ],
                );
              },
            );
          }
          break;
        case "disable":
          if (participantRuid.toString() == myRuid) {
            setState(() {
              videoDisabled = true;
            });
            _engine.muteLocalVideoStream(true);

            showSnackBar(message: "Director has turned your video off.");
          }
          break;
        case "enable":
          if (participantRuid.toString() == myRuid) {
            if (participantRuid.toString() == myRuid && !isVideoAlertActive) {
              isVideoAlertActive = true;

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CupertinoAlertDialog(
                    title: const Text("Director Request"),
                    content:
                        const Text("The director wants to turn your video on."),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("No"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          isVideoAlertActive = false;
                        },
                      ),
                      TextButton(
                        child: const Text("Yes"),
                        onPressed: () {
                          Navigator.of(context).pop();

                          setState(() {
                            videoDisabled = false;
                          });
                          _engine.muteLocalVideoStream(false);

                          isVideoAlertActive = false;
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
          break;
        case "endCall":
          showSnackBar(message: "The director has ended the call.");
          _onCallEnd();
        case "activeUsers":
          _users = Message().parseActiveUsers(userString: participantRuid);
          setState(() {});
          break;
        default:
      }
    };
  }

  void startButtonTimer() {
    buttonTimer?.cancel();
    setState(() {
      areControlButtonsActive = true;
      isEndCallButtonActive = true;
    });
    buttonTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        areControlButtonsActive = false;
        isEndCallButtonActive = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: startButtonTimer,
              child: Stack(
                children: <Widget>[
                  _broadcastView(),
                  _toolbar(),
                  if (activeUser && areControlButtonsActive) chatButton(),
                ],
              ),
            ),
          ),
          if (whiteBoardActive) const Whiteboard(),
        ],
      ),
    );
  }

  Widget chatButton() {
    return Positioned(
      top: 50,
      right: 30,
      child: RawMaterialButton(
        onPressed: () {
          _onToggleChat();
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    "Chat Screen Content",
                  ),
                ),
              );
            },
          ).whenComplete(() {
            setState(() {
              chatActive = false;
            });
          });
        },
        shape: const CircleBorder(),
        constraints: const BoxConstraints(maxWidth: 82),
        elevation: 2.0,
        fillColor: chatActive ? Colors.white : Colors.grey,
        padding: const EdgeInsets.all(12.0),
        child: const Icon(
          Icons.chat,
          size: 25.0,
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Set the main axis size to min
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          (activeUser && areControlButtonsActive)
              ? RawMaterialButton(
                  onPressed: () {
                    startButtonTimer();
                    _onToggleWhiteBoard();
                  },
                  shape: const CircleBorder(),
                  constraints: const BoxConstraints(maxWidth: 52),
                  elevation: 2.0,
                  fillColor: whiteBoardActive ? Colors.white : Colors.grey,
                  padding: const EdgeInsets.all(12.0),
                  child: const Icon(
                    Icons.chat,
                    size: 20.0,
                  ),
                )
              : const SizedBox(),
          const SizedBox(
            width: 20,
          ),
          (activeUser && areControlButtonsActive)
              ? RawMaterialButton(
                  onPressed: () {
                    startButtonTimer();
                    _onToggleMute();
                  },
                  constraints: const BoxConstraints(maxWidth: 72),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.grey : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    size: 20.0,
                  ),
                )
              : const SizedBox(),
          const SizedBox(
            width: 20,
          ),
          if (isEndCallButtonActive)
            RawMaterialButton(
              onPressed: () {
                startButtonTimer();
                _onCallEnd();
              },
              shape: const CircleBorder(),
              constraints: const BoxConstraints(maxWidth: 72),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 35.0,
              ),
            ),
          const SizedBox(
            width: 20,
          ),
          (activeUser && areControlButtonsActive)
              ? RawMaterialButton(
                  onPressed: () {
                    startButtonTimer();
                    _onToggleVideoDisabled();
                  },
                  shape: const CircleBorder(),
                  constraints: const BoxConstraints(maxWidth: 72),
                  elevation: 2.0,
                  fillColor: videoDisabled ? Colors.grey : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    videoDisabled ? Icons.videocam_off : Icons.videocam,
                    size: 20.0,
                  ),
                )
              : const SizedBox(),
          const SizedBox(
            width: 20,
          ),
          (activeUser && areControlButtonsActive)
              ? RawMaterialButton(
                  onPressed: () {
                    startButtonTimer();
                    _onSwitchCamera();
                  },
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  constraints: const BoxConstraints(maxWidth: 72),
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: const Icon(
                    Icons.switch_camera,
                    size: 20.0,
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  List<Widget> _getRenderViews() {
    final List<Widget> list = [];
    bool checkIfLocalActive = false;

    if (_users.isEmpty) {
      list.add(
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(
              color: Colors.black,
            ),
            SizedBox(height: 28),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Hold on while the director adds you to stage.",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );

      return list;
    }

    for (int i = 0; i < _users.length; i++) {
      if (_users[i].rUid.toString() == myRuid) {
        list.add(Stack(children: [
          videoDisabled
              ? Stack(children: [
                  Container(
                    color: Colors.black,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 40,
                      foregroundImage: NetworkImage(widget.photoURL),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ])
              : AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                  onAgoraVideoViewCreated: (viewId) {
                    _engine.startPreview();
                  },
                ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                  color: Colors.grey),
              child: Text(widget.userName),
            ),
          ),
        ]));
        checkIfLocalActive = true;
      } else {
        list.add(
          Stack(
            children: [
              _users[i].videoDisabled
                  ? Stack(children: [
                      Container(
                        color: Colors.black,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: 40,
                          foregroundImage: NetworkImage(_users[i].photoURL!),
                          backgroundColor: Colors.transparent,
                        ),
                      )
                    ])
                  : AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine,
                        canvas: VideoCanvas(uid: _users[i].rUid),
                        connection:
                            RtcConnection(channelId: _channel?.channelId),
                      ),
                    ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(10)),
                      color: Colors.grey),
                  child: Text(_users[i].name ?? "error name"),
                ),
              ),
              _users[i].muted
                  ? const Positioned(
                      top: 25,
                      left: 25,
                      child: Icon(
                        Icons.mic_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  : Container(),
            ],
          ),
        );
      }
    }

    if (checkIfLocalActive) {
      activeUser = true;
    } else {
      activeUser = false;
    }
    return list;
  }

  Widget _expandedVideoView(List<Widget> views) {
    final wrappedViews = views
        .map<Widget>((view) => Expanded(child: Container(child: view)))
        .toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  Widget _broadcastView() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Column(
          children: <Widget>[
            _expandedVideoView([views[0]])
          ],
        );
      case 2:
        return Column(
          children: <Widget>[
            _expandedVideoView([views[0]]),
            _expandedVideoView([views[1]])
          ],
        );
      case 3:
        return Column(
          children: <Widget>[
            _expandedVideoView(views.sublist(0, 2)),
            _expandedVideoView(views.sublist(2, 3))
          ],
        );
      case 4:
        return Column(
          children: <Widget>[
            _expandedVideoView(views.sublist(0, 2)),
            _expandedVideoView(views.sublist(2, 4))
          ],
        );
      default:
    }
    return Container();
  }

  void _onCallEnd() async {
    // dispose();
    Navigator.pop(context);
    await FirebaseFirestore.instance
        .collection('meetings')
        .doc(joinedTimeString)
        .update({
      'left_time': DateTime.now(),
    }).onError((error, stackTrace) => _log(error.toString()));
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleVideoDisabled() {
    setState(() {
      videoDisabled = !videoDisabled;
    });
    _engine.muteLocalVideoStream(videoDisabled);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _onToggleChat() {
    setState(() {
      chatActive = !chatActive;
    });
  }

  void _onToggleWhiteBoard() {
    setState(() {
      whiteBoardActive = !whiteBoardActive;
    });
  }
}

void _log(String info) {
  debugPrint(info);
}
