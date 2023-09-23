import 'package:flutter/material.dart';

import 'package:gather_app/message.dart';
import 'package:gather_app/models/user_model.dart';
import 'package:gather_app/utils/config.dart';
import 'package:gather_app/models/director_model.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:permission_handler/permission_handler.dart';

class DirectorController extends StateNotifier<DirectorModel> {
  DirectorController() : super(DirectorModel());

  Future<void> _initialize() async {
    RtcEngine engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId: Config.engineAppID,
    ));

    AgoraRtmClient? client =
        await AgoraRtmClient.createInstance(Config.channelAppID);
    state = DirectorModel(engine: engine, client: client);
  }

  Future<void> joinCall({required String channelName, required int uid}) async {
    await _initialize();
    await [Permission.camera, Permission.microphone].request();

    state.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _log("Connection Establised.");
        },
        onLeaveChannel: (connection, stats) {
          _log("Channel Left.");
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _log("User joined.");
          state.channel!
              .sendMessage2(RtmMessage.fromText("sendName $remoteUid"));
        },
        onUserOffline: (connection, remoteUid, reason) {
          _log("User Left.");
          removeUser(rUid: remoteUid);
        },
        onRemoteAudioStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          if (state == RemoteAudioState.remoteAudioStateDecoding) {
            updateUserAudio(rUid: remoteUid, muted: false);
          } else if (state == RemoteAudioState.remoteAudioStateStopped) {
            updateUserAudio(rUid: remoteUid, muted: true);
          }
        },
        onRemoteVideoStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          if (state == RemoteVideoState.remoteVideoStateDecoding) {
            updateUserVideo(rUid: remoteUid, videoDisabled: false);
          } else if (state == RemoteVideoState.remoteVideoStateStopped) {
            updateUserVideo(rUid: remoteUid, videoDisabled: true);
          }
        },
      ),
    );

    await state.engine
        ?.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await state.engine
        ?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await state.engine?.enableVideo();

    state.client?.onMessageReceived = (message, peerId) {
      _log("Private Message from $peerId ${message.text}");
    };

    state.client?.onConnectionStateChanged2 = (state, reason) {
      _log(
          'Connection state changed: ${state.toString()}, reason: ${reason.toString()}');
      if (state == RtmConnectionState.aborted) {
        leaveCall();
        _log('Logout.');
      }
    };

    await state.client?.login(null, uid.toString());

    state.channel = await state.client?.createChannel(channelName);
    await state.channel?.join();

    await state.engine?.joinChannel(
      token: Config.engineAppToken,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    state.channel?.onMemberJoined = (member) {
      _log("Member joined: ${member.userId}, channel: ${member.channelId}");
    };

    state.channel?.onMemberLeft = (member) {
      _log("Member left: ${member.userId}, channel: ${member.channelId}");
      state.channel!.sendMessage2(
        RtmMessage.fromText(
          Message().sendActiveUsers(activeUsers: state.activeUsers),
        ),
      );
    };

    state.channel?.onMessageReceived = (message, fromMember) {
      List<String> parsedMessage = message.text.split(" ");

      String action = parsedMessage[0];
      String myUid = parsedMessage[1];
      String participantRuid = parsedMessage[2];
      String participantName = parsedMessage[3];

      _log(action);
      _log(myUid);
      _log(participantRuid);
      _log(participantName);

      switch (action) {
        case "theName":
          if (myUid == uid.toString()) {
            addUserToLobby(
                remoteUid: int.parse(participantRuid), name: participantName);
          }
          break;

        default:
      }
      _log("Public Message from ${fromMember.userId}: ${message.text}");
    };
  }

  Future<void> leaveCall() async {
    state.channel?.leave();
    state.client?.logout();
    state.client?.release();
    state.engine?.leaveChannel();
    state.engine?.release();
  }

  Future<void> toggleUserAudio(
      {required int index, required bool muted}) async {
    if (muted) {
      state.channel!.sendMessage2(RtmMessage.fromText(
          "unmute ${state.activeUsers.elementAt(index).rUid}"));
    } else {
      state.channel!.sendMessage2(RtmMessage.fromText(
          "mute ${state.activeUsers.elementAt(index).rUid}"));
    }
  }

  Future<void> updateUserAudio({required int rUid, required bool muted}) async {
    AgoraUser temp =
        state.activeUsers.singleWhere((element) => element.rUid == rUid);
    Set<AgoraUser> tempSet = state.activeUsers;
    tempSet.remove(temp);
    tempSet.add(temp.copyWith(muted: muted));
    state = state.copyWith(activeUsers: tempSet);
  }

  Future<void> toggleUserVideo(
      {required int index, required bool enable}) async {
    if (enable) {
      state.channel!.sendMessage2(RtmMessage.fromText(
          "disable ${state.activeUsers.elementAt(index).rUid}"));
    } else {
      state.channel!.sendMessage2(RtmMessage.fromText(
          "enable ${state.activeUsers.elementAt(index).rUid}"));
    }
  }

  Future<void> updateUserVideo(
      {required int rUid, required bool videoDisabled}) async {
    AgoraUser temp =
        state.activeUsers.singleWhere((element) => element.rUid == rUid);
    Set<AgoraUser> tempSet = state.activeUsers;
    tempSet.remove(temp);
    tempSet.add(temp.copyWith(videoDisabled: videoDisabled));
    state = state.copyWith(activeUsers: tempSet);
  }

  Future<void> addUserToLobby(
      {required int remoteUid, required String name}) async {
    state = state.copyWith(
      lobbyUsers: {
        ...state.lobbyUsers,
        AgoraUser(
          rUid: remoteUid,
          muted: true,
          videoDisabled: true,
          name: name,
          backgroundColor: Colors.blueAccent,
        )
      },
    );
  }

  Future<void> promoteToActiveUser({required int remoteUid}) async {
    Set<AgoraUser> tempLobby = state.lobbyUsers;
    Color? tempColor;
    String? tempName;

    for (int i = 0; i < tempLobby.length; i++) {
      if (tempLobby.elementAt(i).rUid == remoteUid) {
        tempColor = tempLobby.elementAt(i).backgroundColor;
        tempName = tempLobby.elementAt(i).name;
        tempLobby.remove(tempLobby.elementAt(i));
      }
    }
    state = state.copyWith(activeUsers: {
      ...state.activeUsers,
      AgoraUser(
        rUid: remoteUid,
        backgroundColor: tempColor,
        name: tempName,
      )
    }, lobbyUsers: tempLobby);

    state.channel!.sendMessage2(RtmMessage.fromText("unmute $remoteUid"));
    state.channel!.sendMessage2(RtmMessage.fromText("enable $remoteUid"));
    state.channel!.sendMessage2(
      RtmMessage.fromText(
        Message().sendActiveUsers(activeUsers: state.activeUsers),
      ),
    );
  }

  Future<void> demoteToLobbyUser({required int remoteUid}) async {
    Set<AgoraUser> temp = state.activeUsers;
    Color? tempColor;
    String? tempName;
    for (int i = 0; i < temp.length; i++) {
      if (temp.elementAt(i).rUid == remoteUid) {
        tempColor = temp.elementAt(i).backgroundColor;
        tempName = temp.elementAt(i).name;
        temp.remove(temp.elementAt(i));
      }
    }
    state = state.copyWith(activeUsers: temp, lobbyUsers: {
      ...state.lobbyUsers,
      AgoraUser(
        rUid: remoteUid,
        videoDisabled: true,
        muted: true,
        backgroundColor: tempColor,
        name: tempName,
      )
    });

    state.channel!.sendMessage2(RtmMessage.fromText("mute $remoteUid"));
    state.channel!.sendMessage2(RtmMessage.fromText("disable $remoteUid"));
    state.channel!.sendMessage2(
      RtmMessage.fromText(
        Message().sendActiveUsers(activeUsers: state.activeUsers),
      ),
    );
  }

  Future<void> removeUser({required int rUid}) async {
    Set<AgoraUser> tempActive = state.activeUsers;
    Set<AgoraUser> tempLobby = state.lobbyUsers;

    for (int i = 0; i < tempActive.length; i++) {
      if (tempActive.elementAt(i).rUid == rUid) {
        tempActive.remove(tempActive.elementAt(i));
      }
    }

    for (int i = 0; i < tempLobby.length; i++) {
      if (tempLobby.elementAt(i).rUid == rUid) {
        tempLobby.remove(tempLobby.elementAt(i));
      }
    }

    state = state.copyWith(activeUsers: tempActive, lobbyUsers: tempLobby);
    state.channel!.sendMessage2(
      RtmMessage.fromText(
        Message().sendActiveUsers(activeUsers: state.activeUsers),
      ),
    );
  }
}

final directorController =
    StateNotifierProvider.autoDispose<DirectorController, DirectorModel>((ref) {
  return DirectorController();
});

void _log(String info) {
  debugPrint(info);
}
