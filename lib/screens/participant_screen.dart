import 'package:flutter/material.dart';

import 'package:gather_app/message.dart';
import 'package:gather_app/models/user_model.dart';
import 'package:gather_app/utils/config.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';

class Participant extends StatefulWidget {
  final String channelName;
  final String userName;
  final int uid;

  const Participant(
      {super.key,
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
  bool muted = false;
  bool videoDisabled = false;
  bool activeUser = false;

  var myRuid = "";

  List<AgoraUser> _users = [];

  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    _channel?.leave();
    _client?.logout();
    _client?.release();
    _users.clear();
    _engine.release();
    super.dispose();
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
      RtcEngineEventHandler(
        onError: (ErrorCodeType err, String msg) {
          _log('[onError] err: $err, msg: $msg');
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _log(
              '[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');

          myRuid = connection.localUid.toString();
        },
        onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
          _log(
              '[onUserJoined] connection: ${connection.toJson()} remoteUid[Set]: $rUid elapsed: $elapsed');
        },
        onUserOffline:
            (RtcConnection connection, int rUid, UserOfflineReasonType reason) {
          _log('userLeft: $rUid');
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _log('onLeaveChannel');
          _users.clear();
        },
      ),
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

    await _engine.joinChannel(
      token: Config.engineAppToken,
      channelId: widget.channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

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
        case "mute":
          if (participantRuid.toString() == myRuid) {
            setState(() {
              muted = true;
            });
            _engine.muteLocalAudioStream(true);
          }
          break;
        case "unmute":
          if (participantRuid.toString() == myRuid) {
            setState(() {
              muted = false;
            });
            _engine.muteLocalAudioStream(false);
          }
          break;
        case "disable":
          if (participantRuid.toString() == myRuid) {
            setState(() {
              videoDisabled = true;
            });
            _engine.muteLocalVideoStream(true);
          }
          break;
        case "enable":
          if (participantRuid.toString() == myRuid) {
            setState(() {
              videoDisabled = false;
            });
            _engine.muteLocalVideoStream(false);
          }
          break;
        case "activeUsers":
          _users = Message().parseActiveUsers(uids: participantRuid);
          setState(() {});
          break;
        default:
      }
      _log("Public Message from ${fromMember.userId}: ${message.text}");
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            _broadcastView(),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          activeUser
              ? RawMaterialButton(
                  onPressed: _onToggleMute,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                )
              : const SizedBox(),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          activeUser
              ? RawMaterialButton(
                  onPressed: _onToggleVideoDisabled,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: videoDisabled ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    videoDisabled ? Icons.videocam_off : Icons.videocam,
                    color: videoDisabled ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                )
              : const SizedBox(),
          activeUser
              ? RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
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
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].rUid.toString() == myRuid) {
        list.add(Stack(children: [
          AgoraVideoView(
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
                  color: Colors.white),
              child: Text(widget.userName),
            ),
          ),
        ]));
        checkIfLocalActive = true;
      } else {
        list.add(Stack(children: [
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: _users[i].rUid),
              connection: RtcConnection(channelId: _channel?.channelId),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                  color: Colors.white),
              child: Text(_users[i].rUid.toString()),
            ),
          ),
        ]));
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

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
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
}

void _log(String info) {
  debugPrint(info);
}
