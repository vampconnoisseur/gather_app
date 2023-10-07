import 'package:flutter/material.dart';

class CallLogItem extends StatelessWidget {
  final Widget child;
  final DateTime joinTime;

  const CallLogItem({super.key, required this.child, required this.joinTime});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
