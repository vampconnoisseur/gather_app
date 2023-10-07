import 'dart:convert';

import 'package:gather_app/models/user_model.dart';
import 'package:flutter/material.dart';

class Message {
  String sendActiveUsers({required Set<AgoraUser> activeUsers}) {
    String userString = "activeUsers ";

    List<Map<String, dynamic>> userList = [];

    for (var user in activeUsers) {
      userList.add({
        'username': user.name!,
        'rUid': user.rUid.toString(),
        'videoDisabled': user.videoDisabled.toString(),
        'muted': user.muted.toString(),
        'photoURL': user.photoURL,
      });
    }

    userString += jsonEncode(userList);

    _log(userString);
    return userString;
  }

  List<AgoraUser> parseActiveUsers({required String userString}) {
    List<Map<String, dynamic>> userList = [];
    List<AgoraUser> users = [];

    userList = List<Map<String, dynamic>>.from(jsonDecode(userString));

    for (var userMap in userList) {
      final username = userMap['username'];
      final rUid = userMap['rUid'];
      final muted = userMap['muted'];
      final videoDisabled = userMap['videoDisabled'];
      final photoURL = userMap['photoURL'];

      users.add(
        AgoraUser(
          photoURL: photoURL,
          rUid: int.parse(rUid),
          name: username,
          muted: bool.parse(muted),
          videoDisabled: bool.parse(videoDisabled),
        ),
      );
    }

    return users;
  }

  String sendCredentials({
    required String fromUserId,
    required String myRuid,
    required String userName,
    required String photoURL,
  }) {
    final credentials = {
      'fromUserId': fromUserId,
      'myRuid': myRuid,
      'userName': userName,
      'photoURL': photoURL,
    };

    final encodedMessage = jsonEncode(credentials);

    final message = 'theCredentials $encodedMessage';

    return message;
  }
}

void _log(String info) {
  debugPrint(info);
}
