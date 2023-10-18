import 'package:gather_app/models/user_model.dart';

import 'package:agora_rtm/agora_rtm.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class DirectorModel {
  late RtcEngine? engine;
  Set<AgoraUser> activeUsers;
  Set<AgoraUser> lobbyUsers;
  AgoraRtmClient? client;
  AgoraRtmChannel? channel;
  AgoraUser? localUser;
  String? meetingID;
  Map<String, Map<String, String>> users;

  DirectorModel({
    this.engine,
    this.client,
    this.channel,
    this.activeUsers = const {},
    this.lobbyUsers = const {},
    this.localUser,
    this.meetingID,
    this.users = const {},
  });

  DirectorModel copyWith({
    RtcEngine? engine,
    AgoraRtmClient? client,
    AgoraRtmChannel? channel,
    Set<AgoraUser>? activeUsers,
    Set<AgoraUser>? lobbyUsers,
    AgoraUser? localUser,
    String? meetingID,
    Map<String, Map<String, String>>? users,
  }) {
    return DirectorModel(
      meetingID: meetingID ?? this.meetingID,
      engine: engine ?? this.engine,
      client: client ?? this.client,
      channel: channel ?? this.channel,
      activeUsers: activeUsers ?? this.activeUsers,
      lobbyUsers: lobbyUsers ?? this.lobbyUsers,
      localUser: localUser ?? this.localUser,
      users: users ?? this.users,
    );
  }
}
