import 'package:flutter/material.dart';

class AgoraUser {
  int rUid;
  bool muted;
  bool videoDisabled;
  String? name;
  Color? backgroundColor;
  String? photoURL;

  AgoraUser({
    required this.rUid,
    required this.photoURL,
    this.muted = true,
    this.videoDisabled = true,
    this.name,
    this.backgroundColor,
  });

  AgoraUser copyWith({
    int? rUid,
    bool? muted,
    bool? videoDisabled,
    String? name,
    Color? backgroundColor,
    String? photoURL,
  }) {
    return AgoraUser(
      photoURL: photoURL ?? this.photoURL,
      rUid: rUid ?? this.rUid,
      muted: muted ?? this.muted,
      videoDisabled: videoDisabled ?? this.videoDisabled,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
