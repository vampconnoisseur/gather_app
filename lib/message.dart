import 'package:gather_app/models/user_model.dart';
import 'package:flutter/material.dart';

class Message {
  String sendActiveUsers({required Set<AgoraUser> activeUsers}) {
    String userString = "";
    for (int i = 0; i < activeUsers.length; i++) {
      userString +=
          "${activeUsers.elementAt(i).uid}:${activeUsers.elementAt(i).rUid},";
    }
    return userString;
  }

  List<AgoraUser> parseActiveUsers({required String uids}) {
    _log(uids);
    List<String> userStrings = uids.split(",");
    List<AgoraUser> users = [];

    for (String userString in userStrings) {
      List<String> parts = userString.split(":");
      if (parts.length == 2) {
        int uid = int.tryParse(parts[0]) ?? 0;
        int rUid = int.tryParse(parts[1]) ?? 0;

        users.add(AgoraUser(
          uid: uid,
          rUid: rUid,
        ));
      }
    }
    return users;
  }
}

void _log(String info) {
  debugPrint(info);
}
