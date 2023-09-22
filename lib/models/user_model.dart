import 'package:flutter/material.dart';

class AgoraUser {
  int rUid;
  bool muted;
  bool videoDisabled;
  String? name;
  Color? backgroundColor;

  AgoraUser({
    required this.rUid,
    this.muted = false,
    this.videoDisabled = false,
    this.name,
    this.backgroundColor,
  });

  AgoraUser copyWith({
    int? rUid,
    bool? muted,
    bool? videoDisabled,
    String? name,
    Color? backgroundColor,
  }) {
    return AgoraUser(
      rUid: rUid ?? this.rUid,
      muted: muted ?? this.muted,
      videoDisabled: videoDisabled ?? this.videoDisabled,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
