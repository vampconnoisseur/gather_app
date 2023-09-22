import 'package:gather_app/models/user_model.dart';
import 'package:flutter/material.dart';

class Message {
  String sendActiveUsers({required Set<AgoraUser> activeUsers}) {
    String userString = "activeUsers ";
    for (int i = 0; i < activeUsers.length; i++) {
      userString += "${activeUsers.elementAt(i).rUid},";
    }
    return userString;
  }

  List<AgoraUser> parseActiveUsers({required String uids}) {
    _log(uids);
    List<String> userStrings = uids.split(",");
    List<AgoraUser> users = [];

    for (String userString in userStrings) {
      if (userString == "") continue;

      users.add(
        AgoraUser(
          rUid: int.parse(
            userString,
          ),
        ),
      );
    }
    return users;
  }
}

void _log(String info) {
  debugPrint(info);
}
