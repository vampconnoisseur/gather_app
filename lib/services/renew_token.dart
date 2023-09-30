import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<String?> fetchRtcToken(String channel, int uid) async {
  final url = Uri.parse('http://localhost:8080/rtc/$channel/$uid');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final rtcToken = data['rtcToken'];
      return rtcToken;
    } else {
      return null;
    }
  } catch (e) {
    _log(e.toString());
    return null;
  }
}

void _log(String info) {
  debugPrint(info);
}
